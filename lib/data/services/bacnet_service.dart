import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:logger/logger.dart';

import 'bacnet/bacnet_constants.dart';
import 'bacnet/bacnet_encoder.dart';
import 'bacnet/bacnet_decoder.dart';
import '../../domain/models/bacnet_object.dart';

// Re-export pour usage externe
export 'bacnet/bacnet_encoder.dart' show ReadRangeType;
export 'bacnet/bacnet_decoder.dart' show TrendLogRecordData, ReadRangeResult;

final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

/// Résultat d'un test de connexion BACnet
class BacnetConnectionResult {
  final bool success;
  final int? deviceId;
  final String? deviceName;
  final String? vendorName;
  final String? modelName;
  final String? errorMessage;

  BacnetConnectionResult({
    required this.success,
    this.deviceId,
    this.deviceName,
    this.vendorName,
    this.modelName,
    this.errorMessage,
  });
}

/// Service BACnet/IP en Dart pur
/// Supporte ReadProperty, WriteProperty, ReadPropertyMultiple, Who-Is
class BacnetService {
  RawDatagramSocket? _socket;
  int _invokeId = 0;
  final Map<int, Completer<BacnetResponse>> _pendingRequests = {};
  final Duration _timeout;
  bool _isInitialized = false;

  BacnetService({
    Duration timeout = const Duration(seconds: 5),
  }) : _timeout = timeout;

  /// Initialise le socket UDP
  Future<void> init() async {
    if (_isInitialized) return;

    _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    _socket!.listen(_handleResponse);
    _isInitialized = true;
    _logger.d('BACnet service initialized on port ${_socket!.port}');
  }

  /// Ferme le socket et libère les ressources
  void dispose() {
    _socket?.close();
    _socket = null;
    _isInitialized = false;
    _pendingRequests.clear();
    _iAmController.close(); // Fermer le StreamController pour éviter les fuites mémoire
    _logger.d('BACnet service disposed');
  }

  /// Vérifie que le service est initialisé
  void _ensureInitialized() {
    if (!_isInitialized || _socket == null) {
      throw StateError('BacnetService not initialized. Call init() first.');
    }
  }

  /// Génère un nouvel Invoke ID
  int _nextInvokeId() {
    _invokeId = (_invokeId + 1) & 0xFF;
    return _invokeId;
  }

  /// Gère les réponses UDP entrantes
  void _handleResponse(RawSocketEvent event) {
    if (event != RawSocketEvent.read) return;

    final datagram = _socket!.receive();
    if (datagram == null) return;

    // Debug: afficher les premiers bytes du paquet reçu
    final hexBytes = datagram.data.take(30).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
    _logger.d('BACnet raw packet received (${datagram.data.length} bytes): $hexBytes...');

    try {
      final response = BacnetDecoder.decode(datagram.data);
      _logger.d('BACnet response: ${response.type}, invokeId: ${response.invokeId}');

      // Si c'est un I-Am, le traiter séparément (pas d'invokeId associé)
      if (response.type == BacnetResponseType.iAm) {
        _handleIAm(response, datagram.address);
        return;
      }

      // Debug: si c'est une erreur, afficher les détails
      if (response.isError) {
        _logger.w('BACnet error response: class=${response.errorClass}, code=${response.errorCode}, msg=${response.errorMessage}');
      }

      // Trouver la requête en attente
      if (response.invokeId != null) {
        final completer = _pendingRequests.remove(response.invokeId);
        if (completer != null && !completer.isCompleted) {
          completer.complete(response);
        } else {
          _logger.w('BACnet response for unknown invokeId: ${response.invokeId}');
        }
      }
    } catch (e, st) {
      _logger.e('Error decoding BACnet response: $e\n$st');
    }
  }

  /// Gère les messages I-Am (pour la découverte)
  final _iAmController = StreamController<IAmInfo>.broadcast();
  Stream<IAmInfo> get iAmStream => _iAmController.stream;

  void _handleIAm(BacnetResponse response, InternetAddress address) {
    if (response.objectInstance != null) {
      _iAmController.add(IAmInfo(
        address: address,
        deviceId: response.objectInstance!,
      ));
    }
  }

  /// Envoie un paquet et attend la réponse
  Future<BacnetResponse> _sendAndWait(
    Uint8List packet,
    String host,
    int port,
    int invokeId,
  ) async {
    _ensureInitialized();

    final completer = Completer<BacnetResponse>();
    _pendingRequests[invokeId] = completer;

    try {
      final address = InternetAddress(host);
      _socket!.send(packet, address, port);
      _logger.d('BACnet request sent to $host:$port, invokeId: $invokeId');

      // Attendre la réponse avec timeout
      final response = await completer.future.timeout(
        _timeout,
        onTimeout: () {
          _logger.w('BACnet TIMEOUT for invokeId: $invokeId (after ${_timeout.inSeconds}s)');
          _pendingRequests.remove(invokeId);
          return BacnetResponse.error('Timeout waiting for response');
        },
      );

      return response;
    } catch (e) {
      _pendingRequests.remove(invokeId);
      return BacnetResponse.error('Error sending request: $e');
    }
  }

  // =========================================================================
  // Public API
  // =========================================================================

  /// Test de connexion BACnet
  /// Essaie de lire les propriétés du device object
  Future<BacnetConnectionResult> testConnection({
    required String host,
    required int port,
    int? deviceId,
  }) async {
    await init();

    try {
      // Si deviceId n'est pas fourni, essayer de le trouver via Who-Is
      int targetDeviceId = deviceId ?? 0;

      if (deviceId == null) {
        // Envoyer Who-Is et attendre I-Am
        final devices = await whoIs(
          host: host,
          port: port,
          timeout: const Duration(seconds: 3),
        );

        if (devices.isEmpty) {
          return BacnetConnectionResult(
            success: false,
            errorMessage: 'No BACnet device responded',
          );
        }

        targetDeviceId = devices.first.deviceId;
      }

      // Lire object-name du device
      final nameResult = await readProperty(
        host: host,
        port: port,
        objectType: BacnetObjectTypeCode.device,
        objectInstance: targetDeviceId,
        propertyId: BacnetPropertyId.objectName,
      );

      String? deviceName;
      if (nameResult.isSuccess && nameResult.value is String) {
        deviceName = nameResult.value as String;
      }

      // Lire vendor-name
      final vendorResult = await readProperty(
        host: host,
        port: port,
        objectType: BacnetObjectTypeCode.device,
        objectInstance: targetDeviceId,
        propertyId: BacnetPropertyId.vendorName,
      );

      String? vendorName;
      if (vendorResult.isSuccess && vendorResult.value is String) {
        vendorName = vendorResult.value as String;
      }

      // Lire model-name
      final modelResult = await readProperty(
        host: host,
        port: port,
        objectType: BacnetObjectTypeCode.device,
        objectInstance: targetDeviceId,
        propertyId: BacnetPropertyId.modelName,
      );

      String? modelName;
      if (modelResult.isSuccess && modelResult.value is String) {
        modelName = modelResult.value as String;
      }

      return BacnetConnectionResult(
        success: true,
        deviceId: targetDeviceId,
        deviceName: deviceName,
        vendorName: vendorName,
        modelName: modelName,
      );
    } catch (e) {
      return BacnetConnectionResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Envoie Who-Is et collecte les I-Am
  Future<List<IAmInfo>> whoIs({
    required String host,
    required int port,
    int? lowLimit,
    int? highLimit,
    Duration timeout = const Duration(seconds: 3),
  }) async {
    await init();

    final devices = <IAmInfo>[];
    final subscription = iAmStream.listen((device) {
      devices.add(device);
    });

    try {
      // Construire et envoyer le paquet Who-Is
      final packet = BacnetEncoder.encodeWhoIsRequest(
        lowLimit: lowLimit,
        highLimit: highLimit,
        broadcast: false, // Unicast vers l'IP spécifiée
      );

      final address = InternetAddress(host);
      _socket!.send(packet, address, port);
      _logger.d('Who-Is sent to $host:$port');

      // Attendre les réponses
      await Future.delayed(timeout);

      return devices;
    } finally {
      await subscription.cancel();
    }
  }

  /// Lit une propriété BACnet
  Future<BacnetResponse> readProperty({
    required String host,
    required int port,
    required int objectType,
    required int objectInstance,
    required int propertyId,
    int? arrayIndex,
  }) async {
    await init();

    final invokeId = _nextInvokeId();
    final packet = BacnetEncoder.encodeReadPropertyRequest(
      invokeId: invokeId,
      objectType: objectType,
      objectInstance: objectInstance,
      propertyId: propertyId,
      arrayIndex: arrayIndex,
    );

    return _sendAndWait(packet, host, port, invokeId);
  }

  /// Écrit une propriété BACnet
  Future<BacnetResponse> writeProperty({
    required String host,
    required int port,
    required int objectType,
    required int objectInstance,
    required int propertyId,
    required dynamic value,
    int? priority,
    int? arrayIndex,
  }) async {
    await init();

    final invokeId = _nextInvokeId();
    final packet = BacnetEncoder.encodeWritePropertyRequest(
      invokeId: invokeId,
      objectType: objectType,
      objectInstance: objectInstance,
      propertyId: propertyId,
      value: value,
      priority: priority,
      arrayIndex: arrayIndex,
    );

    return _sendAndWait(packet, host, port, invokeId);
  }

  /// Lit plusieurs propriétés d'un ou plusieurs objets
  Future<BacnetResponse> readPropertyMultiple({
    required String host,
    required int port,
    required List<ReadPropertyMultipleItem> items,
  }) async {
    await init();

    final invokeId = _nextInvokeId();
    final packet = BacnetEncoder.encodeReadPropertyMultipleRequest(
      invokeId: invokeId,
      items: items,
    );

    return _sendAndWait(packet, host, port, invokeId);
  }

  /// Découvre les objets d'un device BACnet
  /// Retourne une liste de BacnetObject avec les propriétés de base
  Future<List<BacnetObject>> discoverObjects({
    required String host,
    required int port,
    required int deviceId,
    List<int>? objectTypesFilter,
  }) async {
    await init();

    final objects = <BacnetObject>[];

    // 1. Lire la liste des objets (object-list)
    final objectListResult = await readProperty(
      host: host,
      port: port,
      objectType: BacnetObjectTypeCode.device,
      objectInstance: deviceId,
      propertyId: BacnetPropertyId.objectList,
    );

    if (!objectListResult.isSuccess) {
      _logger.e('Failed to read object-list: ${objectListResult.errorMessage}');
      return objects;
    }

    // Parser la liste des objets
    final objectList = _parseObjectList(objectListResult.value);

    // 2. Filtrer si nécessaire
    final filteredObjects = objectTypesFilter != null
        ? objectList.where((o) => objectTypesFilter.contains(o.type)).toList()
        : objectList;

    // 3. Lire les propriétés de chaque objet
    for (final objInfo in filteredObjects) {
      try {
        final obj = await _readObjectProperties(
          host: host,
          port: port,
          objectType: objInfo.type,
          objectInstance: objInfo.instance,
        );
        if (obj != null) {
          objects.add(obj);
        }
      } catch (e) {
        _logger.e('Error reading object ${objInfo.type}:${objInfo.instance}: $e');
      }
    }

    return objects;
  }

  /// Parse la valeur object-list en liste d'ObjectInfo
  List<_ObjectInfo> _parseObjectList(dynamic value) {
    final objects = <_ObjectInfo>[];

    _logger.d('_parseObjectList: input type=${value.runtimeType}');

    if (value is List) {
      _logger.d('_parseObjectList: list has ${value.length} items');
      for (int i = 0; i < value.length; i++) {
        final item = value[i];
        if (item is Map) {
          // Essayer différentes clés possibles
          final type = item['type'] ?? item['objectType'];
          final instance = item['instance'] ?? item['objectInstance'];
          if (i < 5 || type == 20) {
            _logger.d('_parseObjectList: item[$i] = $item -> type=$type, instance=$instance');
          }
          if (type != null && instance != null) {
            objects.add(_ObjectInfo(
              type: type as int,
              instance: instance as int,
            ));
          }
        } else {
          if (i < 5) {
            _logger.d('_parseObjectList: item[$i] is not a Map, it is ${item.runtimeType}: $item');
          }
        }
      }
    } else if (value is Map) {
      _logger.d('_parseObjectList: single map: $value');
      // Si c'est un seul objet (pas une liste)
      final type = value['type'] ?? value['objectType'];
      final instance = value['instance'] ?? value['objectInstance'];
      if (type != null && instance != null) {
        objects.add(_ObjectInfo(
          type: type as int,
          instance: instance as int,
        ));
      }
    } else {
      _logger.w('_parseObjectList: unexpected value type: ${value.runtimeType}');
    }

    _logger.d('_parseObjectList: parsed ${objects.length} objects');
    return objects;
  }

  /// Lit les propriétés d'un objet et crée un BacnetObject
  Future<BacnetObject?> _readObjectProperties({
    required String host,
    required int port,
    required int objectType,
    required int objectInstance,
  }) async {
    // Propriétés à lire
    final propertyIds = [
      BacnetPropertyId.objectName,
      BacnetPropertyId.presentValue,
      BacnetPropertyId.description,
      BacnetPropertyId.units,
      BacnetPropertyId.outOfService,
    ];

    // Ajouter les propriétés spécifiques aux types
    final bacnetType = _objectTypeCodeToBacnetType(objectType);
    if (bacnetType?.isBinary == true) {
      propertyIds.addAll([
        BacnetPropertyId.activeText,
        BacnetPropertyId.inactiveText,
      ]);
    } else if (bacnetType?.isMultiState == true) {
      propertyIds.add(BacnetPropertyId.stateText);
    }

    // Ajouter priority-array pour les objets commandables (détection forçage)
    if (bacnetType != null && bacnetType.isCommandable) {
      propertyIds.add(BacnetPropertyId.priorityArray);
    }

    // Utiliser ReadPropertyMultiple si possible
    final rpmResult = await readPropertyMultiple(
      host: host,
      port: port,
      items: [
        ReadPropertyMultipleItem(
          objectType: objectType,
          objectInstance: objectInstance,
          propertyIds: propertyIds,
        ),
      ],
    );

    if (rpmResult.isSuccess && rpmResult.multipleResults != null) {
      final result = rpmResult.multipleResults!.first;
      return _createBacnetObjectFromProperties(
        objectType: objectType,
        objectInstance: objectInstance,
        properties: result.properties,
      );
    }

    // Fallback: lire les propriétés une par une
    final properties = <int, dynamic>{};

    for (final propId in propertyIds) {
      final result = await readProperty(
        host: host,
        port: port,
        objectType: objectType,
        objectInstance: objectInstance,
        propertyId: propId,
      );

      if (result.isSuccess) {
        properties[propId] = result.value;
      }
    }

    if (properties.isEmpty) return null;

    return _createBacnetObjectFromPropertiesMap(
      objectType: objectType,
      objectInstance: objectInstance,
      properties: properties,
    );
  }

  /// Crée un BacnetObject depuis les propriétés RPM
  BacnetObject _createBacnetObjectFromProperties({
    required int objectType,
    required int objectInstance,
    required List<PropertyResult> properties,
  }) {
    final propMap = <int, dynamic>{};
    for (final prop in properties) {
      propMap[prop.propertyId] = prop.value;
    }

    return _createBacnetObjectFromPropertiesMap(
      objectType: objectType,
      objectInstance: objectInstance,
      properties: propMap,
    );
  }

  /// Crée un BacnetObject depuis une map de propriétés
  BacnetObject _createBacnetObjectFromPropertiesMap({
    required int objectType,
    required int objectInstance,
    required Map<int, dynamic> properties,
  }) {
    final bacnetType = _objectTypeCodeToBacnetType(objectType);

    // Parser le priority-array pour détecter les forçages
    final priorityArray = properties[BacnetPropertyId.priorityArray];
    final overrideInfo = _parsePriorityArray(priorityArray);

    return BacnetObject(
      type: bacnetType ?? BacnetObjectType.analogValue,
      instance: objectInstance,
      objectName: properties[BacnetPropertyId.objectName]?.toString() ??
                  '${BacnetObjectTypeCode.getName(objectType)}:$objectInstance',
      description: properties[BacnetPropertyId.description]?.toString(),
      presentValue: properties[BacnetPropertyId.presentValue],
      units: properties[BacnetPropertyId.units]?.toString(),
      outOfService: properties[BacnetPropertyId.outOfService] as bool?,
      activeText: properties[BacnetPropertyId.activeText]?.toString(),
      inactiveText: properties[BacnetPropertyId.inactiveText]?.toString(),
      stateText: _parseStateText(properties[BacnetPropertyId.stateText]),
      isOverridden: overrideInfo.isOverridden,
      overridePriority: overrideInfo.priority,
      overrideValue: overrideInfo.value,
    );
  }

  /// Parse le priority-array BACnet et retourne les infos de forçage
  /// Le priority-array est une liste de 16 valeurs (priorités 1-16)
  /// Si une valeur aux positions 1-15 (indices 0-14) n'est pas null, c'est un forçage
  ({bool isOverridden, int? priority, dynamic value}) _parsePriorityArray(dynamic priorityArray) {
    if (priorityArray == null) {
      return (isOverridden: false, priority: null, value: null);
    }

    // Format liste (le plus courant en BACnet natif)
    if (priorityArray is List) {
      for (int i = 0; i < 15 && i < priorityArray.length; i++) {
        final value = priorityArray[i];
        // Vérifier si la valeur n'est pas null
        if (value != null && !_isNullValue(value)) {
          return (
            isOverridden: true,
            priority: i + 1, // Priorité 1-15
            value: _extractPriorityValue(value),
          );
        }
      }
    }

    return (isOverridden: false, priority: null, value: null);
  }

  /// Vérifie si une valeur du priority-array représente "null" (pas de forçage)
  bool _isNullValue(dynamic value) {
    if (value == null) return true;
    if (value is Map) {
      // Format {"null": ...} ou {"type": "null"}
      if (value.containsKey('null')) return true;
      if (value['type'] == 'null' || value['type'] == 0) return true;
    }
    return false;
  }

  /// Extrait la valeur réelle d'une entrée du priority-array
  dynamic _extractPriorityValue(dynamic value) {
    if (value is Map) {
      // Formats possibles: {"real": 21.5}, {"unsigned": 1}, {"boolean": true}, etc.
      if (value.containsKey('real')) return value['real'];
      if (value.containsKey('unsigned')) return value['unsigned'];
      if (value.containsKey('boolean')) return value['boolean'];
      if (value.containsKey('enumerated')) return value['enumerated'];
      if (value.containsKey('value')) return value['value'];
      // Retourner la première valeur non-null trouvée
      for (final v in value.values) {
        if (v != null && v != 'Null') return v;
      }
    }
    return value;
  }

  /// Convertit un code de type d'objet en BacnetObjectType
  BacnetObjectType? _objectTypeCodeToBacnetType(int code) {
    switch (code) {
      case BacnetObjectTypeCode.analogInput:
        return BacnetObjectType.analogInput;
      case BacnetObjectTypeCode.analogOutput:
        return BacnetObjectType.analogOutput;
      case BacnetObjectTypeCode.analogValue:
        return BacnetObjectType.analogValue;
      case BacnetObjectTypeCode.binaryInput:
        return BacnetObjectType.binaryInput;
      case BacnetObjectTypeCode.binaryOutput:
        return BacnetObjectType.binaryOutput;
      case BacnetObjectTypeCode.binaryValue:
        return BacnetObjectType.binaryValue;
      case BacnetObjectTypeCode.multiStateInput:
        return BacnetObjectType.multiStateInput;
      case BacnetObjectTypeCode.multiStateOutput:
        return BacnetObjectType.multiStateOutput;
      case BacnetObjectTypeCode.multiStateValue:
        return BacnetObjectType.multiStateValue;
      case BacnetObjectTypeCode.schedule:
        return BacnetObjectType.schedule;
      case BacnetObjectTypeCode.calendar:
        return BacnetObjectType.calendar;
      case BacnetObjectTypeCode.trendLog:
        return BacnetObjectType.trendLog;
      case BacnetObjectTypeCode.device:
        return BacnetObjectType.device;
      default:
        return null;
    }
  }

  /// Parse state-text en liste de strings
  List<String>? _parseStateText(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return null;
  }

  /// Lit et rafraîchit la valeur d'un point
  Future<dynamic> refreshPointValue({
    required String host,
    required int port,
    required int objectType,
    required int objectInstance,
  }) async {
    final result = await readProperty(
      host: host,
      port: port,
      objectType: objectType,
      objectInstance: objectInstance,
      propertyId: BacnetPropertyId.presentValue,
    );

    if (result.isSuccess) {
      return result.value;
    }

    throw Exception(result.errorMessage ?? 'Failed to read present-value');
  }

  /// Rafraîchit les valeurs de plusieurs points en parallèle
  /// Retourne une Map avec objectId comme clé et les infos rafraîchies
  Future<Map<String, RefreshedPointData>> refreshMultiplePointValues({
    required String host,
    required int port,
    required List<({int objectType, int objectInstance, bool isCommandable, bool isInput})> points,
    int batchSize = 10,
  }) async {
    await init();

    final results = <String, RefreshedPointData>{};

    // Traiter les points par batch pour éviter de surcharger le réseau
    for (int i = 0; i < points.length; i += batchSize) {
      final batch = points.skip(i).take(batchSize).toList();

      // Lancer les requêtes du batch en parallèle
      final futures = batch.map((point) async {
        final key = '${point.objectType}:${point.objectInstance}';
        try {
          // Propriétés à lire
          final propertyIds = [BacnetPropertyId.presentValue];

          // Ajouter priority-array pour les objets commandables (AO, BO, MSO, AV, BV, MSV)
          if (point.isCommandable) {
            propertyIds.add(BacnetPropertyId.priorityArray);
          }

          // Ajouter out-of-service pour les entrées (AI, BI, MSI) - forçage via OOS
          if (point.isInput) {
            propertyIds.add(BacnetPropertyId.outOfService);
          }

          // Lire via ReadPropertyMultiple pour l'efficacité
          final result = await readPropertyMultiple(
            host: host,
            port: port,
            items: [
              ReadPropertyMultipleItem(
                objectType: point.objectType,
                objectInstance: point.objectInstance,
                propertyIds: propertyIds,
              ),
            ],
          );

          if (result.isSuccess && result.multipleResults != null && result.multipleResults!.isNotEmpty) {
            final props = result.multipleResults!.first.properties;

            // Extraire present-value
            dynamic presentValue;
            for (final prop in props) {
              if (prop.propertyId == BacnetPropertyId.presentValue) {
                presentValue = prop.value;
                break;
              }
            }

            // Extraire et parser priority-array (pour commandables)
            ({bool isOverridden, int? priority, dynamic value}) overrideInfo =
                (isOverridden: false, priority: null, value: null);

            if (point.isCommandable) {
              for (final prop in props) {
                if (prop.propertyId == BacnetPropertyId.priorityArray) {
                  overrideInfo = _parsePriorityArray(prop.value);
                  break;
                }
              }
            }

            // Extraire out-of-service (pour entrées)
            bool? outOfService;
            if (point.isInput) {
              for (final prop in props) {
                if (prop.propertyId == BacnetPropertyId.outOfService) {
                  outOfService = prop.value as bool?;
                  break;
                }
              }
            }

            return MapEntry(key, RefreshedPointData(
              presentValue: presentValue,
              isOverridden: overrideInfo.isOverridden,
              overridePriority: overrideInfo.priority,
              overrideValue: overrideInfo.value,
              outOfService: outOfService,
            ));
          }
        } catch (e) {
          _logger.e('Error refreshing $key: $e');
        }
        return MapEntry<String, RefreshedPointData?>(key, null);
      });

      final batchResults = await Future.wait(futures);
      for (final entry in batchResults) {
        if (entry.value != null) {
          results[entry.key] = entry.value!;
        }
      }
    }

    return results;
  }

  /// Écrit la valeur d'un point
  Future<void> writePointValue({
    required String host,
    required int port,
    required int objectType,
    required int objectInstance,
    required dynamic value,
    int? priority,
  }) async {
    final result = await writeProperty(
      host: host,
      port: port,
      objectType: objectType,
      objectInstance: objectInstance,
      propertyId: BacnetPropertyId.presentValue,
      value: value,
      priority: priority,
    );

    if (!result.isSuccess) {
      throw Exception(result.errorMessage ?? 'Failed to write present-value');
    }
  }

  // =========================================================================
  // TrendLog Support
  // =========================================================================

  /// Découvre les TrendLog d'un device BACnet
  Future<List<BacnetTrendLog>> discoverTrendLogs({
    required String host,
    required int port,
    required int deviceId,
  }) async {
    await init();

    final trendLogs = <BacnetTrendLog>[];

    _logger.i('discoverTrendLogs: starting discovery on $host:$port, deviceId=$deviceId');

    // 1. Lire la liste des objets
    final objectListResult = await readProperty(
      host: host,
      port: port,
      objectType: BacnetObjectTypeCode.device,
      objectInstance: deviceId,
      propertyId: BacnetPropertyId.objectList,
    );

    if (!objectListResult.isSuccess) {
      _logger.e('discoverTrendLogs: Failed to read object-list: ${objectListResult.errorMessage}');
      return trendLogs;
    }

    _logger.d('discoverTrendLogs: object-list raw value type: ${objectListResult.value.runtimeType}');
    _logger.d('discoverTrendLogs: object-list raw value: ${objectListResult.value}');

    // Parser la liste et filtrer les TrendLog (type 20)
    final objectList = _parseObjectList(objectListResult.value);
    _logger.i('discoverTrendLogs: parsed ${objectList.length} total objects');

    // Log tous les types d'objets trouvés
    final typeCount = <int, int>{};
    for (final obj in objectList) {
      typeCount[obj.type] = (typeCount[obj.type] ?? 0) + 1;
    }
    _logger.i('discoverTrendLogs: object types found: $typeCount');

    final trendLogObjects = objectList.where((o) => o.type == BacnetObjectTypeCode.trendLog).toList();

    _logger.i('discoverTrendLogs: Found ${trendLogObjects.length} TrendLog objects (type 20)');

    // 2. Lire les propriétés de chaque TrendLog
    for (final obj in trendLogObjects) {
      try {
        final trendLog = await _readTrendLogProperties(
          host: host,
          port: port,
          objectInstance: obj.instance,
        );
        if (trendLog != null) {
          trendLogs.add(trendLog);
        }
      } catch (e) {
        _logger.e('Error reading TrendLog ${obj.instance}: $e');
      }
    }

    return trendLogs;
  }

  /// Lit les propriétés d'un TrendLog
  Future<BacnetTrendLog?> _readTrendLogProperties({
    required String host,
    required int port,
    required int objectInstance,
  }) async {
    // Propriétés à lire pour un TrendLog
    final propertyIds = [
      BacnetPropertyId.objectName,
      BacnetPropertyId.description,
      BacnetPropertyId.logDeviceObjectProperty,
      BacnetPropertyId.logInterval,
      BacnetPropertyId.bufferSize,
      BacnetPropertyId.recordCount,
      BacnetPropertyId.enable,
    ];

    final rpmResult = await readPropertyMultiple(
      host: host,
      port: port,
      items: [
        ReadPropertyMultipleItem(
          objectType: BacnetObjectTypeCode.trendLog,
          objectInstance: objectInstance,
          propertyIds: propertyIds,
        ),
      ],
    );

    if (rpmResult.isSuccess && rpmResult.multipleResults != null && rpmResult.multipleResults!.isNotEmpty) {
      final result = rpmResult.multipleResults!.first;
      return _createTrendLogFromProperties(
        objectInstance: objectInstance,
        properties: result.properties,
      );
    }

    // Fallback: lire les propriétés une par une
    final properties = <int, dynamic>{};

    for (final propId in propertyIds) {
      final result = await readProperty(
        host: host,
        port: port,
        objectType: BacnetObjectTypeCode.trendLog,
        objectInstance: objectInstance,
        propertyId: propId,
      );

      if (result.isSuccess) {
        properties[propId] = result.value;
      }
    }

    if (properties.isEmpty) return null;

    return _createTrendLogFromPropertiesMap(
      objectInstance: objectInstance,
      properties: properties,
    );
  }

  /// Crée un BacnetTrendLog depuis les propriétés RPM
  BacnetTrendLog _createTrendLogFromProperties({
    required int objectInstance,
    required List<PropertyResult> properties,
  }) {
    final propMap = <int, dynamic>{};
    for (final prop in properties) {
      propMap[prop.propertyId] = prop.value;
    }
    return _createTrendLogFromPropertiesMap(
      objectInstance: objectInstance,
      properties: propMap,
    );
  }

  /// Crée un BacnetTrendLog depuis une map de propriétés
  BacnetTrendLog _createTrendLogFromPropertiesMap({
    required int objectInstance,
    required Map<int, dynamic> properties,
  }) {
    _logger.d('_createTrendLogFromPropertiesMap: TrendLog $objectInstance, properties keys: ${properties.keys.toList()}');
    _logger.d('_createTrendLogFromPropertiesMap: all properties: $properties');

    // Parser log-device-object-property pour obtenir l'objet tracké
    final logDeviceObjectProperty = properties[BacnetPropertyId.logDeviceObjectProperty];
    _logger.d('_createTrendLogFromPropertiesMap: logDeviceObjectProperty (propId=${BacnetPropertyId.logDeviceObjectProperty}) = $logDeviceObjectProperty (type: ${logDeviceObjectProperty.runtimeType})');

    String? trackedObjectType;
    int? trackedObjectInstance;

    if (logDeviceObjectProperty != null) {
      final parsed = _parseLogDeviceObjectProperty(logDeviceObjectProperty);
      trackedObjectType = parsed.$1;
      trackedObjectInstance = parsed.$2;
      _logger.d('_createTrendLogFromPropertiesMap: parsed -> type=$trackedObjectType, instance=$trackedObjectInstance');
    }

    return BacnetTrendLog(
      instance: objectInstance,
      objectName: properties[BacnetPropertyId.objectName]?.toString() ?? 'Trend Log $objectInstance',
      description: properties[BacnetPropertyId.description]?.toString(),
      logDeviceObjectProperty: logDeviceObjectProperty?.toString(),
      trackedObjectType: trackedObjectType,
      trackedObjectInstance: trackedObjectInstance,
      logInterval: _toInt(properties[BacnetPropertyId.logInterval]),
      bufferSize: _toInt(properties[BacnetPropertyId.bufferSize]),
      recordCount: _toInt(properties[BacnetPropertyId.recordCount]),
      enabled: properties[BacnetPropertyId.enable] as bool?,
    );
  }

  /// Parse la propriété log-device-object-property
  /// Format BACnet natif: {objectIdentifier: {type: X, instance: Y}, propertyIdentifier: Z, ...}
  (String?, int?) _parseLogDeviceObjectProperty(dynamic value) {
    _logger.d('_parseLogDeviceObjectProperty: input=$value (type=${value.runtimeType})');

    if (value == null) return (null, null);

    // Format Map (BACnet natif - depuis _decodeConstructedValue)
    if (value is Map) {
      _logger.d('_parseLogDeviceObjectProperty: Map keys=${value.keys.toList()}');

      // Essayer différentes clés possibles
      final objectId = value['objectIdentifier'] ?? value['object-identifier'] ?? value['context0'];
      _logger.d('_parseLogDeviceObjectProperty: objectId=$objectId (type=${objectId.runtimeType})');

      if (objectId is Map) {
        final typeCode = objectId['type'] ?? objectId['objectType'];
        final instance = objectId['instance'] ?? objectId['objectInstance'];
        _logger.d('_parseLogDeviceObjectProperty: typeCode=$typeCode, instance=$instance');

        if (typeCode != null && instance != null) {
          final typeName = BacnetObjectTypeCode.getName(typeCode as int);
          _logger.d('_parseLogDeviceObjectProperty: resolved -> typeName=$typeName, instance=$instance');
          return (typeName, instance as int);
        }
      }
    }

    // Format String (comme dans l'API V1)
    if (value is String) {
      // Format: "[Analog Value 454,Present Value,,]"
      final match = RegExp(r'\[([^,]+)\s+(\d+),').firstMatch(value);
      if (match != null) {
        final objectTypeRaw = match.group(1)?.trim();
        final objectInstance = int.tryParse(match.group(2) ?? '');
        if (objectTypeRaw != null && objectInstance != null) {
          final objectType = objectTypeRaw.toLowerCase().replaceAll(RegExp(r'\s+'), '-');
          return (objectType, objectInstance);
        }
      }
    }

    _logger.w('_parseLogDeviceObjectProperty: could not parse value');
    return (null, null);
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Lit le buffer d'un TrendLog via ReadRange
  Future<BacnetResponse> readRange({
    required String host,
    required int port,
    required int objectType,
    required int objectInstance,
    required int propertyId,
    ReadRangeType rangeType = ReadRangeType.all,
    int? referenceIndex,
    int? count,
    DateTime? referenceTime,
  }) async {
    await init();

    final invokeId = _nextInvokeId();
    final packet = BacnetEncoder.encodeReadRangeRequest(
      invokeId: invokeId,
      objectType: objectType,
      objectInstance: objectInstance,
      propertyId: propertyId,
      rangeType: rangeType,
      referenceIndex: referenceIndex,
      count: count,
      referenceTime: referenceTime,
    );

    return _sendAndWait(packet, host, port, invokeId);
  }

  /// Lit le log-buffer d'un TrendLog (données les plus récentes)
  /// Utilise ReadRange byTime avec count négatif pour lire depuis maintenant vers le passé
  Future<List<TrendLogRecordData>> readTrendLogBuffer({
    required String host,
    required int port,
    required int trendLogInstance,
    int? maxRecords,
  }) async {
    _logger.i('readTrendLogBuffer: starting for TrendLog $trendLogInstance on $host:$port');

    // Utiliser une liste temporaire pour éviter insertAll(0,...) qui est O(n)
    // On collecte les records en ordre inverse puis on inverse à la fin -> O(n) total
    final tempRecords = <TrendLogRecordData>[];

    // Lire par chunks (le BACnet peut limiter la taille de réponse)
    // Note: Les contrôleurs Distech retournent max ~65 records par requête
    const int chunkSize = 65; // Nombre de records par requête (ajusté pour Distech)
    const int defaultMaxRecords = 1000; // Limite par défaut (~10 jours à 15min d'intervalle)
    final int recordsToRead = maxRecords ?? defaultMaxRecords;

    // Utiliser byTime avec count négatif pour lire depuis maintenant vers le passé
    DateTime referenceTime = DateTime.now();
    bool moreData = true;
    int iteration = 0;

    _logger.i('readTrendLogBuffer: reading up to $recordsToRead records backwards from ${referenceTime.toIso8601String()}');

    while (moreData && tempRecords.length < recordsToRead) {
      iteration++;
      final remaining = recordsToRead - tempRecords.length;
      // Count négatif = lire vers le passé depuis referenceTime
      final requestCount = -remaining.clamp(1, chunkSize);

      _logger.d('readTrendLogBuffer: iteration $iteration, referenceTime=$referenceTime, requesting $requestCount');

      final response = await readRange(
        host: host,
        port: port,
        objectType: BacnetObjectTypeCode.trendLog,
        objectInstance: trendLogInstance,
        propertyId: BacnetPropertyId.logBuffer,
        rangeType: ReadRangeType.byTime,
        referenceTime: referenceTime,
        count: requestCount,
      );

      _logger.d('readTrendLogBuffer: response.type=${response.type}, isSuccess=${response.isSuccess}, value type=${response.value?.runtimeType}');

      if (!response.isSuccess) {
        _logger.e('readTrendLogBuffer: Failed - ${response.errorMessage}, errorClass=${response.errorClass}, errorCode=${response.errorCode}');
        break;
      }

      if (response.value is! ReadRangeResult) {
        _logger.e('readTrendLogBuffer: Unexpected value type: ${response.value?.runtimeType}');
        break;
      }

      final result = response.value as ReadRangeResult;
      _logger.i('readTrendLogBuffer: received ${result.records.length} records, itemCount=${result.itemCount}, firstSeq=${result.firstSequenceNumber}, moreItems=${result.moreItems}');

      if (result.records.isEmpty) {
        _logger.w('readTrendLogBuffer: no records returned, stopping');
        break;
      }

      // Les records sont retournés du plus récent au plus ancien avec count négatif
      // On les ajoute à la fin (ordre inverse), on inversera à la fin
      tempRecords.addAll(result.records);

      // Mettre à jour referenceTime pour la prochaine itération
      // Prendre le timestamp du record le plus ancien reçu
      if (result.records.isNotEmpty) {
        final oldestRecord = result.records.last;
        referenceTime = oldestRecord.timestamp.subtract(const Duration(milliseconds: 1));
      }

      // Continuer tant qu'on reçoit des records (ignorer moreItems car souvent incorrect)
      // S'arrêter si on reçoit moins que demandé (fin du buffer)
      final receivedLessThanRequested = result.records.length < requestCount.abs();
      moreData = !receivedLessThanRequested && result.records.isNotEmpty;

      _logger.d('readTrendLogBuffer: total so far: ${tempRecords.length}, receivedLessThanRequested=$receivedLessThanRequested, continue: $moreData');
    }

    // Inverser pour obtenir l'ordre chronologique (du plus ancien au plus récent)
    final allRecords = tempRecords.reversed.toList();

    _logger.i('readTrendLogBuffer: completed with ${allRecords.length} total records');
    return allRecords;
  }
}

/// Info minimale d'un objet découvert
class _ObjectInfo {
  final int type;
  final int instance;

  _ObjectInfo({required this.type, required this.instance});
}

/// Info d'un device répondant à Who-Is
class IAmInfo {
  final InternetAddress address;
  final int deviceId;

  IAmInfo({required this.address, required this.deviceId});
}

/// Données rafraîchies d'un point BACnet
class RefreshedPointData {
  final dynamic presentValue;
  final bool isOverridden;
  final int? overridePriority;
  final dynamic overrideValue;
  final bool? outOfService;

  RefreshedPointData({
    this.presentValue,
    this.isOverridden = false,
    this.overridePriority,
    this.overrideValue,
    this.outOfService,
  });
}

/// Modèle pour un TrendLog BACnet découvert
class BacnetTrendLog {
  final int instance;
  final String objectName;
  final String? description;
  final String? logDeviceObjectProperty;
  final String? trackedObjectType;
  final int? trackedObjectInstance;
  final int? logInterval;
  final int? bufferSize;
  final int? recordCount;
  final bool? enabled;

  BacnetTrendLog({
    required this.instance,
    required this.objectName,
    this.description,
    this.logDeviceObjectProperty,
    this.trackedObjectType,
    this.trackedObjectInstance,
    this.logInterval,
    this.bufferSize,
    this.recordCount,
    this.enabled,
  });

  /// Clé pour le mapping: "objectType:objectInstance"
  String? get trackedObjectKey {
    if (trackedObjectType == null || trackedObjectInstance == null) {
      return null;
    }
    return '$trackedObjectType:$trackedObjectInstance';
  }
}
