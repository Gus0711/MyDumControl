import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:logger/logger.dart';

import 'bacnet/bacnet_constants.dart';
import 'bacnet/bacnet_encoder.dart';
import 'bacnet/bacnet_decoder.dart';
import '../../domain/models/bacnet_object.dart';

// Re-export pour usage externe
export 'bacnet/bacnet_encoder.dart' show ReadRangeType, BacnetTimeValue, BacnetDailySchedule, BacnetWeeklySchedule, ScheduleValueTag;
export 'bacnet/bacnet_decoder.dart' show TrendLogRecordData, ReadRangeResult, DecodedTimeValue, DecodedDailySchedule, DecodedWeeklySchedule, BacnetScheduleDecoder;

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
  bool _isInitializing = false; // Protection contre les initialisations concurrentes

  BacnetService({
    Duration timeout = const Duration(seconds: 5),
  }) : _timeout = timeout;

  /// Initialise le socket UDP
  /// Utilise le port 47808 (BACnet standard) comme port source pour la découverte
  /// Certains devices ne répondent qu'aux requêtes venant de ce port
  Future<void> init() async {
    if (_isInitialized) return;

    // Protection contre les appels concurrents
    if (_isInitializing) {
      // Attendre que l'initialisation en cours se termine
      while (_isInitializing && !_isInitialized) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return;
    }
    _isInitializing = true;

    // Essayer d'abord le port BACnet standard 47808 (meilleure compatibilité)
    // Si déjà utilisé, fallback sur un port dynamique
    try {
      _socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        47808,
        reuseAddress: true,
      );
      _logger.i('BACnet service bound to port 47808 (standard BACnet port)');
    } catch (e) {
      _logger.w('Could not bind to port 47808: $e. Using dynamic port.');
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      _logger.d('BACnet service bound to dynamic port ${_socket!.port}');
    }

    _socket!.broadcastEnabled = true; // Activer le broadcast pour Who-Is

    // Essayer de joindre l'adresse broadcast pour recevoir les I-Am envoyés en broadcast
    // Certains devices répondent à l'adresse broadcast plutôt qu'à l'IP source
    try {
      // Note: sur certaines plateformes, il faut être sur le port 47808 pour recevoir les broadcasts
      _logger.d('Socket local address: ${_socket!.address.address}:${_socket!.port}');
    } catch (e) {
      _logger.w('Could not get socket info: $e');
    }

    _socket!.listen(_handleResponse);
    _isInitialized = true;
    _isInitializing = false;
    _logger.i('BACnet service initialized on port ${_socket!.port}, broadcast enabled');
  }

  /// Ferme le socket et libère les ressources
  void dispose() {
    _socket?.close();
    _socket = null;
    _isInitialized = false;
    _isInitializing = false;
    _pendingRequests.clear();
    if (!_iAmController.isClosed) {
      _iAmController.close();
    }
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

    // Protection: ignorer si le service est fermé ou en cours de fermeture
    if (!_isInitialized || _socket == null) return;

    final datagram = _socket?.receive();
    if (datagram == null) return;

    // Filtre rapide: ignorer les paquets trop courts
    if (datagram.data.length < 4) return;

    // Vérifier le type BVLC (0x81 = BACnet/IP)
    if (datagram.data[0] != 0x81) return;

    final bvlcFunc = datagram.data[1];

    // Filtre: ignorer les messages BVLC qu'on ne traite pas
    // 0x0a = Original-Unicast-NPDU (réponses directes) - GARDER
    // 0x0b = Original-Broadcast-NPDU (broadcasts) - GARDER pour I-Am
    // 0x04 = Forwarded-NPDU - GARDER pour I-Am depuis BBMD
    // Autres (0x00, 0x01, etc.) = BVLC management, ignorer
    if (bvlcFunc != 0x0a && bvlcFunc != 0x0b && bvlcFunc != 0x04) {
      return; // Ignorer silencieusement les messages de gestion BVLC
    }

    try {
      final response = BacnetDecoder.decode(datagram.data);

      // Si c'est un I-Am, le traiter séparément (pas d'invokeId associé)
      if (response.type == BacnetResponseType.iAm) {
        _logger.i('I-Am received from ${datagram.address.address}:${datagram.port}, deviceId: ${response.objectInstance}');
        _handleIAm(response, datagram.address);
        return;
      }

      // Ignorer les autres unconfirmedRequests (COV notifications, Who-Is relayés, etc.)
      if (response.type == BacnetResponseType.unconfirmedRequest) {
        return; // Ignorer silencieusement
      }

      // Debug: si c'est une erreur, afficher les détails
      if (response.isError) {
        _logger.w('BACnet error response: class=${response.errorClass}, code=${response.errorCode}, msg=${response.errorMessage}');
      }

      // Trouver la requête en attente
      if (response.invokeId != null) {
        final completer = _pendingRequests.remove(response.invokeId);
        if (completer != null && !completer.isCompleted) {
          _logger.d('BACnet response for invokeId: ${response.invokeId}');
          completer.complete(response);
        }
      }
    } catch (e) {
      // Ignorer les erreurs de décodage silencieusement pour les paquets malformés
      // (on reçoit beaucoup de paquets sur le port 47808)
    }
  }

  /// Gère les messages I-Am (pour la découverte)
  final _iAmController = StreamController<IAmInfo>.broadcast();
  Stream<IAmInfo> get iAmStream => _iAmController.stream;

  void _handleIAm(BacnetResponse response, InternetAddress address) {
    if (response.objectInstance != null && !_iAmController.isClosed) {
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
  /// Optimisé: utilise ReadPropertyMultiple pour une seule requête au lieu de 3
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

      // Lire les 3 propriétés en une seule requête (optimisation 3x)
      final rpmResult = await readPropertyMultiple(
        host: host,
        port: port,
        items: [
          ReadPropertyMultipleItem(
            objectType: BacnetObjectTypeCode.device,
            objectInstance: targetDeviceId,
            propertyIds: [
              BacnetPropertyId.objectName,
              BacnetPropertyId.vendorName,
              BacnetPropertyId.modelName,
            ],
          ),
        ],
      );

      String? deviceName;
      String? vendorName;
      String? modelName;

      if (rpmResult.isSuccess && rpmResult.multipleResults != null && rpmResult.multipleResults!.isNotEmpty) {
        final props = rpmResult.multipleResults!.first.properties;
        for (final prop in props) {
          switch (prop.propertyId) {
            case BacnetPropertyId.objectName:
              deviceName = prop.value?.toString();
            case BacnetPropertyId.vendorName:
              vendorName = prop.value?.toString();
            case BacnetPropertyId.modelName:
              modelName = prop.value?.toString();
          }
        }
      } else {
        // Fallback: si RPM échoue, essayer les requêtes individuelles
        _logger.w('testConnection: RPM failed, falling back to individual reads');

        final nameResult = await readProperty(
          host: host,
          port: port,
          objectType: BacnetObjectTypeCode.device,
          objectInstance: targetDeviceId,
          propertyId: BacnetPropertyId.objectName,
        );
        if (nameResult.isSuccess && nameResult.value is String) {
          deviceName = nameResult.value as String;
        }

        final vendorResult = await readProperty(
          host: host,
          port: port,
          objectType: BacnetObjectTypeCode.device,
          objectInstance: targetDeviceId,
          propertyId: BacnetPropertyId.vendorName,
        );
        if (vendorResult.isSuccess && vendorResult.value is String) {
          vendorName = vendorResult.value as String;
        }

        final modelResult = await readProperty(
          host: host,
          port: port,
          objectType: BacnetObjectTypeCode.device,
          objectInstance: targetDeviceId,
          propertyId: BacnetPropertyId.modelName,
        );
        if (modelResult.isSuccess && modelResult.value is String) {
          modelName = modelResult.value as String;
        }
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
      // Détecter si c'est une adresse broadcast
      final isBroadcast = host == '255.255.255.255' || host.endsWith('.255');

      // Construire et envoyer le paquet Who-Is
      final packet = BacnetEncoder.encodeWhoIsRequest(
        lowLimit: lowLimit,
        highLimit: highLimit,
        broadcast: isBroadcast,
      );

      final address = InternetAddress(host);
      _socket!.send(packet, address, port);
      _logger.d('Who-Is sent to $host:$port (broadcast: $isBroadcast)');

      // Attendre les réponses
      await Future.delayed(timeout);

      return devices;
    } finally {
      await subscription.cancel();
    }
  }

  /// Découverte broadcast sur le réseau local
  /// Envoie Who-Is à toutes les adresses de broadcast détectées
  Future<List<IAmInfo>> discoverLocalDevices({
    int port = 47808,
    Duration timeout = const Duration(seconds: 3),
  }) async {
    await init();

    final devices = <IAmInfo>[];
    final subscription = iAmStream.listen((device) {
      // Éviter les doublons
      if (!devices.any((d) => d.deviceId == device.deviceId)) {
        devices.add(device);
        _logger.i('Discovered device ${device.deviceId} at ${device.address.address}');
      }
    });

    try {
      // Obtenir les adresses de broadcast du réseau local
      final broadcastAddresses = await _getLocalBroadcastAddresses();
      _logger.i('Broadcast addresses: $broadcastAddresses');

      // Construire le paquet Who-Is broadcast
      final packet = BacnetEncoder.encodeWhoIsRequest(broadcast: true);

      // Envoyer sur toutes les interfaces
      for (final broadcastAddr in broadcastAddresses) {
        try {
          final address = InternetAddress(broadcastAddr);
          _socket!.send(packet, address, port);
          _logger.d('Who-Is broadcast sent to $broadcastAddr:$port');
        } catch (e) {
          _logger.w('Failed to send to $broadcastAddr: $e');
        }
      }

      // Aussi envoyer sur 255.255.255.255 (global broadcast)
      try {
        final globalBroadcast = InternetAddress('255.255.255.255');
        _socket!.send(packet, globalBroadcast, port);
        _logger.d('Who-Is global broadcast sent to 255.255.255.255:$port');
      } catch (e) {
        _logger.w('Failed to send global broadcast: $e');
      }

      // Attendre les réponses
      await Future.delayed(timeout);

      _logger.i('Discovery completed: ${devices.length} devices found');
      return devices;
    } finally {
      await subscription.cancel();
    }
  }

  /// Scan d'une plage d'adresses IP pour trouver des devices BACnet
  /// Envoie un Who-Is unicast à chaque adresse de la plage
  /// [startIp] et [endIp] doivent être sur le même sous-réseau /24
  /// [onProgress] callback appelé avec (current, total) pour afficher la progression
  /// [onDeviceFound] callback appelé immédiatement quand un device est trouvé
  Future<List<IAmInfo>> scanIpRange({
    required String startIp,
    required String endIp,
    int port = 47808,
    Duration timeout = const Duration(milliseconds: 500),
    void Function(int current, int total)? onProgress,
    void Function(IAmInfo device)? onDeviceFound,
  }) async {
    await init();

    final devices = <IAmInfo>[];

    // Parser les IPs
    final startParts = startIp.split('.').map(int.parse).toList();
    final endParts = endIp.split('.').map(int.parse).toList();

    if (startParts.length != 4 || endParts.length != 4) {
      throw ArgumentError('Invalid IP address format');
    }

    // Vérifier que c'est le même sous-réseau /24
    if (startParts[0] != endParts[0] ||
        startParts[1] != endParts[1] ||
        startParts[2] != endParts[2]) {
      throw ArgumentError('Start and end IP must be on the same /24 subnet');
    }

    final baseIp = '${startParts[0]}.${startParts[1]}.${startParts[2]}';
    final startHost = startParts[3];
    final endHost = endParts[3];
    final total = endHost - startHost + 1;

    _logger.i('Scanning IP range: $startIp to $endIp ($total addresses)');

    // Écouter les réponses I-Am
    final subscription = iAmStream.listen((device) {
      if (!devices.any((d) => d.deviceId == device.deviceId)) {
        devices.add(device);
        _logger.i('Scan found device ${device.deviceId} at ${device.address.address}');
        onDeviceFound?.call(device);
      }
    });

    try {
      // Construire le paquet Who-Is unicast
      final packet = BacnetEncoder.encodeWhoIsRequest(broadcast: false);

      int scanned = 0;

      // Scanner par batch pour ne pas surcharger le réseau
      const batchSize = 10;

      for (int i = startHost; i <= endHost; i += batchSize) {
        final batchEnd = (i + batchSize - 1).clamp(startHost, endHost);

        // Envoyer Who-Is à chaque IP du batch
        for (int j = i; j <= batchEnd; j++) {
          final ip = '$baseIp.$j';
          try {
            final address = InternetAddress(ip);
            _socket!.send(packet, address, port);
          } catch (e) {
            // Ignorer les erreurs d'envoi
          }
          scanned++;
          onProgress?.call(scanned, total);
        }

        // Attendre un peu pour recevoir les réponses du batch
        await Future.delayed(timeout);
      }

      // Attendre un peu plus à la fin pour les dernières réponses
      await Future.delayed(const Duration(milliseconds: 500));

      _logger.i('Scan completed: ${devices.length} devices found');
      return devices;
    } finally {
      await subscription.cancel();
    }
  }

  /// Récupère les adresses de broadcast de toutes les interfaces réseau
  Future<List<String>> _getLocalBroadcastAddresses() async {
    final broadcastAddresses = <String>[];

    try {
      final interfaces = await NetworkInterface.list();
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4) {
            // Calculer l'adresse de broadcast (simplification: /24)
            final parts = addr.address.split('.');
            if (parts.length == 4) {
              final broadcast = '${parts[0]}.${parts[1]}.${parts[2]}.255';
              if (!broadcastAddresses.contains(broadcast)) {
                broadcastAddresses.add(broadcast);
              }
            }
          }
        }
      }
    } catch (e) {
      _logger.e('Error getting network interfaces: $e');
    }

    // Fallback si aucune interface trouvée
    if (broadcastAddresses.isEmpty) {
      broadcastAddresses.add('255.255.255.255');
    }

    return broadcastAddresses;
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
      BacnetPropertyId.statusFlags, // Pour détecter les alarmes (in-alarm)
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

    // Parser status-flags pour détecter les alarmes
    final statusFlags = properties[BacnetPropertyId.statusFlags];
    _logger.d('_createBacnetObject: ${BacnetObjectTypeCode.getName(objectType)}:$objectInstance, statusFlags=$statusFlags');
    final statusInfo = _parseStatusFlags(statusFlags);

    if (statusInfo.inAlarm) {
      _logger.i('_createBacnetObject: ALARM detected on ${BacnetObjectTypeCode.getName(objectType)}:$objectInstance');
    }

    return BacnetObject(
      type: bacnetType ?? BacnetObjectType.analogValue,
      instance: objectInstance,
      objectName: properties[BacnetPropertyId.objectName]?.toString() ??
                  '${BacnetObjectTypeCode.getName(objectType)}:$objectInstance',
      description: properties[BacnetPropertyId.description]?.toString(),
      presentValue: properties[BacnetPropertyId.presentValue],
      units: _parseUnit(properties[BacnetPropertyId.units]),
      outOfService: properties[BacnetPropertyId.outOfService] as bool?,
      activeText: properties[BacnetPropertyId.activeText]?.toString(),
      inactiveText: properties[BacnetPropertyId.inactiveText]?.toString(),
      stateText: _parseStateText(properties[BacnetPropertyId.stateText]),
      isOverridden: overrideInfo.isOverridden,
      overridePriority: overrideInfo.priority,
      overrideValue: overrideInfo.value,
      inAlarm: statusInfo.inAlarm,
    );
  }

  /// Parse le status-flags BACnet et retourne les infos d'état
  /// status-flags est un bitstring de 4 bits:
  /// - Bit 0: in-alarm
  /// - Bit 1: fault
  /// - Bit 2: overridden
  /// - Bit 3: out-of-service
  ({bool inAlarm, bool fault, bool overridden, bool outOfService}) _parseStatusFlags(dynamic statusFlags) {
    if (statusFlags == null) {
      return (inAlarm: false, fault: false, overridden: false, outOfService: false);
    }

    _logger.d('_parseStatusFlags: received ${statusFlags.runtimeType}: $statusFlags');

    // Format liste de booléens (le plus courant depuis notre décodeur)
    if (statusFlags is List) {
      return (
        inAlarm: statusFlags.isNotEmpty && statusFlags[0] == true,
        fault: statusFlags.length > 1 && statusFlags[1] == true,
        overridden: statusFlags.length > 2 && statusFlags[2] == true,
        outOfService: statusFlags.length > 3 && statusFlags[3] == true,
      );
    }

    // Format Map avec les clés nommées
    if (statusFlags is Map) {
      return (
        inAlarm: statusFlags['inAlarm'] == true || statusFlags['in-alarm'] == true || statusFlags[0] == true,
        fault: statusFlags['fault'] == true || statusFlags[1] == true,
        overridden: statusFlags['overridden'] == true || statusFlags[2] == true,
        outOfService: statusFlags['outOfService'] == true || statusFlags['out-of-service'] == true || statusFlags[3] == true,
      );
    }

    // Format entier (bitfield brut)
    if (statusFlags is int) {
      return (
        inAlarm: (statusFlags & 0x01) != 0,      // Bit 0
        fault: (statusFlags & 0x02) != 0,        // Bit 1
        overridden: (statusFlags & 0x04) != 0,   // Bit 2
        outOfService: (statusFlags & 0x08) != 0, // Bit 3
      );
    }

    // Format String (ex: "0000" ou "{in-alarm=false, ...}")
    if (statusFlags is String) {
      final lower = statusFlags.toLowerCase();
      // Format bitstring "0000"
      if (RegExp(r'^[01]+$').hasMatch(statusFlags)) {
        final bits = statusFlags.split('').map((b) => b == '1').toList();
        return (
          inAlarm: bits.isNotEmpty && bits[0],
          fault: bits.length > 1 && bits[1],
          overridden: bits.length > 2 && bits[2],
          outOfService: bits.length > 3 && bits[3],
        );
      }
      // Format texte
      return (
        inAlarm: lower.contains('in-alarm=true') || lower.contains('inalarm=true'),
        fault: lower.contains('fault=true'),
        overridden: lower.contains('overridden=true'),
        outOfService: lower.contains('out-of-service=true') || lower.contains('outofservice=true'),
      );
    }

    _logger.d('_parseStatusFlags: unknown format ${statusFlags.runtimeType}: $statusFlags');
    return (inAlarm: false, fault: false, overridden: false, outOfService: false);
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
      // Filtrer les valeurs nulles ou vides
      final result = value
          .where((e) => e != null)
          .map((e) => e.toString())
          .where((s) => s.isNotEmpty)
          .toList();
      return result.isEmpty ? null : result;
    }
    // Si c'est une seule chaîne, la retourner comme liste d'un élément
    if (value is String && value.isNotEmpty) {
      return [value];
    }
    return null;
  }

  /// Parse et convertit un code d'unité BACnet en symbole lisible
  /// Ex: 62 -> "°C", 95 -> "%", "DegreesCelsius" -> "°C"
  String? _parseUnit(dynamic value) {
    if (value == null) return null;
    final result = BacnetUnits.getUnitText(value);
    return result.isEmpty ? null : result;
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
          final propertyIds = [
            BacnetPropertyId.presentValue,
            BacnetPropertyId.statusFlags, // Pour détecter les alarmes
            BacnetPropertyId.units, // Pour afficher les unités
          ];

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

            // Extraire et parser status-flags (pour alarmes)
            ({bool inAlarm, bool fault, bool overridden, bool outOfService}) statusInfo =
                (inAlarm: false, fault: false, overridden: false, outOfService: false);
            for (final prop in props) {
              if (prop.propertyId == BacnetPropertyId.statusFlags) {
                _logger.d('refreshMultiplePointValues: $key statusFlags=${prop.value}');
                statusInfo = _parseStatusFlags(prop.value);
                if (statusInfo.inAlarm) {
                  _logger.i('refreshMultiplePointValues: ALARM on $key');
                }
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

            // Extraire et parser les unités
            String? units;
            for (final prop in props) {
              if (prop.propertyId == BacnetPropertyId.units) {
                units = _parseUnit(prop.value);
                break;
              }
            }

            return MapEntry(key, RefreshedPointData(
              presentValue: presentValue,
              isOverridden: overrideInfo.isOverridden,
              overridePriority: overrideInfo.priority,
              overrideValue: overrideInfo.value,
              outOfService: outOfService,
              inAlarm: statusInfo.inAlarm,
              units: units,
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
      BacnetPropertyId.totalRecordCount, // Pour pagination bySequenceNumber
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
      totalRecordCount: _toInt(properties[BacnetPropertyId.totalRecordCount]),
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
  /// Utilise ReadRange bySequenceNumber avec count négatif pour pagination fiable
  ///
  /// [totalRecordCount] : Si fourni, évite une requête supplémentaire pour le lire.
  /// C'est le numéro de séquence du dernier record (= point de départ de la pagination).
  Future<List<TrendLogRecordData>> readTrendLogBuffer({
    required String host,
    required int port,
    required int trendLogInstance,
    int? maxRecords,
    int? totalRecordCount,
  }) async {
    _logger.i('readTrendLogBuffer: starting for TrendLog $trendLogInstance on $host:$port');

    // 1. Obtenir totalRecordCount si pas fourni (c'est le seqNum du dernier record)
    int? lastSeqNum = totalRecordCount;
    if (lastSeqNum == null) {
      _logger.d('readTrendLogBuffer: reading totalRecordCount property...');
      final trcResponse = await readProperty(
        host: host,
        port: port,
        objectType: BacnetObjectTypeCode.trendLog,
        objectInstance: trendLogInstance,
        propertyId: BacnetPropertyId.totalRecordCount,
      );

      if (trcResponse.isSuccess && trcResponse.value != null) {
        lastSeqNum = trcResponse.value is int
            ? trcResponse.value as int
            : int.tryParse(trcResponse.value.toString());
        _logger.i('readTrendLogBuffer: totalRecordCount=$lastSeqNum');
      }

      if (lastSeqNum == null || lastSeqNum == 0) {
        _logger.w('readTrendLogBuffer: totalRecordCount is null or 0, no records available');
        return [];
      }
    }

    // Liste pour collecter les records (on les ajoute au début à chaque itération)
    final allRecords = <TrendLogRecordData>[];

    // Paramètres de pagination
    const int chunkSize = 65; // Max records par requête (limite Distech)
    const int defaultMaxRecords = 1000; // ~10 jours à 15min d'intervalle
    final int recordsToRead = maxRecords ?? defaultMaxRecords;

    // Point de départ : le dernier record (seqNum le plus élevé)
    int referenceSeqNum = lastSeqNum;
    int iteration = 0;

    _logger.i('readTrendLogBuffer: using bySequenceNumber, starting from seqNum=$lastSeqNum, reading up to $recordsToRead records');

    while (allRecords.length < recordsToRead && referenceSeqNum > 0) {
      iteration++;
      final remaining = recordsToRead - allRecords.length;
      // Count négatif = lire vers le passé (records plus anciens)
      final requestCount = -remaining.clamp(1, chunkSize);

      _logger.d('readTrendLogBuffer: iteration $iteration, referenceSeqNum=$referenceSeqNum, requesting $requestCount');

      final response = await readRange(
        host: host,
        port: port,
        objectType: BacnetObjectTypeCode.trendLog,
        objectInstance: trendLogInstance,
        propertyId: BacnetPropertyId.logBuffer,
        rangeType: ReadRangeType.bySequenceNumber,
        referenceIndex: referenceSeqNum,
        count: requestCount,
      );

      _logger.d('readTrendLogBuffer: response.type=${response.type}, isSuccess=${response.isSuccess}');

      if (!response.isSuccess) {
        _logger.e('readTrendLogBuffer: Failed - ${response.errorMessage}, errorClass=${response.errorClass}, errorCode=${response.errorCode}');
        break;
      }

      if (response.value is! ReadRangeResult) {
        _logger.e('readTrendLogBuffer: Unexpected value type: ${response.value?.runtimeType}');
        break;
      }

      final result = response.value as ReadRangeResult;
      _logger.i('readTrendLogBuffer: received ${result.records.length} records, firstSeqNum=${result.firstSequenceNumber}, moreItems=${result.moreItems}');

      if (result.records.isEmpty) {
        _logger.w('readTrendLogBuffer: no records returned, stopping');
        break;
      }

      // Avec count négatif, les records sont retournés du plus ancien au plus récent
      // (le referenceSeqNum est le DERNIER retourné, pas le premier)
      // On insère au début pour maintenir l'ordre chronologique
      allRecords.insertAll(0, result.records);

      // Mettre à jour le point de référence pour la prochaine itération
      // firstSequenceNumber = numéro de séquence du premier record retourné (le plus ancien)
      if (result.firstSequenceNumber != null && result.firstSequenceNumber! > 0) {
        // Prochain point de départ = juste avant le premier record qu'on vient de lire
        referenceSeqNum = result.firstSequenceNumber! - 1;
        _logger.d('readTrendLogBuffer: next referenceSeqNum=$referenceSeqNum');
      } else {
        // Pas de firstSequenceNumber, on estime basé sur le nombre de records reçus
        referenceSeqNum -= result.records.length;
        _logger.d('readTrendLogBuffer: estimated next referenceSeqNum=$referenceSeqNum (no firstSeqNum in response)');
      }

      // S'arrêter si on a atteint le début du buffer
      if (referenceSeqNum <= 0) {
        _logger.i('readTrendLogBuffer: reached beginning of buffer (seqNum <= 0)');
        break;
      }

      // S'arrêter si on reçoit moins que demandé (fin du buffer disponible)
      if (result.records.length < requestCount.abs()) {
        _logger.i('readTrendLogBuffer: received less than requested, likely end of buffer');
        break;
      }

      _logger.d('readTrendLogBuffer: total so far: ${allRecords.length}, continue: ${allRecords.length < recordsToRead}');
    }

    _logger.i('readTrendLogBuffer: completed with ${allRecords.length} total records over $iteration iterations');
    return allRecords;
  }

  // =========================================================================
  // Schedule Support
  // =========================================================================

  /// Découvre les schedules d'un device BACnet
  Future<List<BacnetScheduleInfo>> discoverSchedules({
    required String host,
    required int port,
    required int deviceId,
  }) async {
    await init();

    final schedules = <BacnetScheduleInfo>[];

    _logger.i('discoverSchedules: starting discovery on $host:$port, deviceId=$deviceId');

    // 1. Lire la liste des objets
    final objectListResult = await readProperty(
      host: host,
      port: port,
      objectType: BacnetObjectTypeCode.device,
      objectInstance: deviceId,
      propertyId: BacnetPropertyId.objectList,
    );

    if (!objectListResult.isSuccess) {
      _logger.e('discoverSchedules: Failed to read object-list: ${objectListResult.errorMessage}');
      return schedules;
    }

    // Parser la liste et filtrer les schedules (type 17)
    final objectList = _parseObjectList(objectListResult.value);
    final scheduleObjects = objectList.where((o) => o.type == BacnetObjectTypeCode.schedule).toList();

    _logger.i('discoverSchedules: Found ${scheduleObjects.length} Schedule objects');

    // 2. Lire les propriétés de base de chaque schedule
    for (final obj in scheduleObjects) {
      try {
        final scheduleInfo = await readScheduleBasicInfo(
          host: host,
          port: port,
          scheduleInstance: obj.instance,
        );
        if (scheduleInfo != null) {
          schedules.add(scheduleInfo);
        }
      } catch (e) {
        _logger.e('Error reading Schedule ${obj.instance}: $e');
      }
    }

    return schedules;
  }

  /// Lit les informations de base d'un schedule (sans le weekly-schedule complet)
  Future<BacnetScheduleInfo?> readScheduleBasicInfo({
    required String host,
    required int port,
    required int scheduleInstance,
    int? deviceId,
  }) async {
    await init();

    // Propriétés à lire - inclure list-of-object-property-references pour trouver l'objet cible
    final propertyIds = [
      BacnetPropertyId.objectName,
      BacnetPropertyId.description,
      BacnetPropertyId.presentValue,
      BacnetPropertyId.scheduleDefault,
      BacnetPropertyId.outOfService,
      BacnetPropertyId.stateText,
      BacnetPropertyId.listOfObjectPropertyReferences, // Pour récupérer les state-text de l'objet cible
    ];

    final rpmResult = await readPropertyMultiple(
      host: host,
      port: port,
      items: [
        ReadPropertyMultipleItem(
          objectType: BacnetObjectTypeCode.schedule,
          objectInstance: scheduleInstance,
          propertyIds: propertyIds,
        ),
      ],
    );

    if (!rpmResult.isSuccess || rpmResult.multipleResults == null || rpmResult.multipleResults!.isEmpty) {
      _logger.e('readScheduleBasicInfo: Failed to read properties for schedule $scheduleInstance');
      return null;
    }

    final props = rpmResult.multipleResults!.first.properties;
    final propMap = <int, dynamic>{};
    for (final prop in props) {
      propMap[prop.propertyId] = prop.value;
      _logger.d('readScheduleBasicInfo: prop ${prop.propertyId} = ${prop.value} (${prop.value?.runtimeType})');
    }

    // Essayer de récupérer les state-text
    List<String>? stateTexts = _parseStateText(propMap[BacnetPropertyId.stateText]);
    _logger.d('readScheduleBasicInfo: stateTexts from schedule = $stateTexts');

    // Si pas de state-text sur le schedule, essayer de les récupérer depuis l'objet référencé
    if (stateTexts == null || stateTexts.isEmpty) {
      // D'abord essayer depuis le RPM
      var objRefs = propMap[BacnetPropertyId.listOfObjectPropertyReferences];
      _logger.d('readScheduleBasicInfo: list-of-object-property-references from RPM = $objRefs (${objRefs?.runtimeType})');

      // Si pas dans RPM, lire séparément avec ReadProperty
      if (objRefs == null) {
        _logger.d('readScheduleBasicInfo: trying to read list-of-object-property-references separately');
        final refResult = await readProperty(
          host: host,
          port: port,
          objectType: BacnetObjectTypeCode.schedule,
          objectInstance: scheduleInstance,
          propertyId: BacnetPropertyId.listOfObjectPropertyReferences,
        );
        if (refResult.isSuccess && refResult.value != null) {
          objRefs = refResult.value;
          _logger.d('readScheduleBasicInfo: list-of-object-property-references from ReadProperty = $objRefs (${objRefs?.runtimeType})');
        }
      }

      if (objRefs != null) {
        stateTexts = await _getStateTextsFromReferencedObject(host, port, objRefs);
        _logger.d('readScheduleBasicInfo: stateTexts from referenced object = $stateTexts');
      }

      // Si toujours pas de state-text, essayer les propriétés propriétaires Distech
      if ((stateTexts == null || stateTexts.isEmpty) && deviceId != null) {
        // Propriétés propriétaires Distech pour les state-texts
        // 1031, 1001, 1002 sont des propriétés propriétaires trouvées dans le schedule
        for (final propId in [1031, 1001, 1002]) {
          final propResult = await readProperty(
            host: host,
            port: port,
            objectType: BacnetObjectTypeCode.schedule,
            objectInstance: scheduleInstance,
            propertyId: propId,
          );
          if (propResult.isSuccess && propResult.value != null) {
            _logger.i('readScheduleBasicInfo: proprietary prop $propId = ${propResult.value} (${propResult.value.runtimeType})');
            // Essayer de parser comme state-text si c'est une liste de strings
            final parsed = _parseStateText(propResult.value);
            if (parsed != null && parsed.isNotEmpty) {
              _logger.i('readScheduleBasicInfo: found state-texts in prop $propId: $parsed');
              stateTexts = parsed;
              break;
            }
          }
        }

        // Si toujours pas trouvé, chercher par nom
        if (stateTexts == null || stateTexts.isEmpty) {
          final scheduleName = propMap[BacnetPropertyId.objectName]?.toString() ?? '';
          _logger.d('readScheduleBasicInfo: searching for multistate by schedule name "$scheduleName"');

          if (scheduleName.toLowerCase().contains('enum')) {
            stateTexts = await _findStateTextsFromMultistateByName(host, port, deviceId, 'enum');
          }
        }
      }
    }

    return BacnetScheduleInfo(
      instance: scheduleInstance,
      objectName: propMap[BacnetPropertyId.objectName]?.toString() ?? 'Schedule $scheduleInstance',
      description: propMap[BacnetPropertyId.description]?.toString(),
      presentValue: propMap[BacnetPropertyId.presentValue],
      scheduleDefault: propMap[BacnetPropertyId.scheduleDefault],
      outOfService: propMap[BacnetPropertyId.outOfService] as bool?,
      stateTexts: stateTexts,
    );
  }

  /// Cherche un objet Multi-state par son nom et retourne ses state-text
  Future<List<String>?> _findStateTextsFromMultistateByName(String host, int port, int deviceId, String searchName) async {
    _logger.d('_findStateTextsFromMultistateByName: searching for "$searchName" on device $deviceId');

    // Types Multi-state à chercher
    const multistateTypes = [
      BacnetObjectTypeCode.multiStateInput,  // 13
      BacnetObjectTypeCode.multiStateOutput, // 14
      BacnetObjectTypeCode.multiStateValue,  // 19
    ];

    final objectListResult = await readProperty(
      host: host,
      port: port,
      objectType: BacnetObjectTypeCode.device,
      objectInstance: deviceId,
      propertyId: BacnetPropertyId.objectList,
    );

    if (!objectListResult.isSuccess || objectListResult.value == null) {
      _logger.d('_findStateTextsFromMultistateByName: could not read object list');
      return null;
    }

    final objects = _parseObjectList(objectListResult.value);

    // Filtrer les objets Multi-state
    final multistateObjects = objects.where((obj) => multistateTypes.contains(obj.type)).toList();
    _logger.d('_findStateTextsFromMultistateByName: found ${multistateObjects.length} multistate objects');

    // Chercher l'objet par son nom
    for (final obj in multistateObjects) {
      final nameResult = await readProperty(
        host: host,
        port: port,
        objectType: obj.type,
        objectInstance: obj.instance,
        propertyId: BacnetPropertyId.objectName,
      );

      if (nameResult.isSuccess && nameResult.value != null) {
        final objName = nameResult.value.toString();
        _logger.d('_findStateTextsFromMultistateByName: object ${obj.type}:${obj.instance} name="$objName"');

        if (objName.toLowerCase().contains(searchName.toLowerCase())) {
          _logger.i('_findStateTextsFromMultistateByName: found matching object "$objName" (${obj.type}:${obj.instance})');

          // Lire ses state-text
          final stateTextResult = await readProperty(
            host: host,
            port: port,
            objectType: obj.type,
            objectInstance: obj.instance,
            propertyId: BacnetPropertyId.stateText,
          );

          if (stateTextResult.isSuccess && stateTextResult.value != null) {
            final stateTexts = _parseStateText(stateTextResult.value);
            _logger.i('_findStateTextsFromMultistateByName: state-texts = $stateTexts');
            return stateTexts;
          }
        }
      }
    }

    _logger.d('_findStateTextsFromMultistateByName: no matching object found');
    return null;
  }

  /// Récupère les state-text depuis un objet référencé par le schedule
  Future<List<String>?> _getStateTextsFromReferencedObject(String host, int port, dynamic objRefs) async {
    // list-of-object-property-references peut être:
    // - Une liste de BACnetDeviceObjectPropertyReference
    // - Un seul objet {objectType, instance, propertyId}
    // - Une liste de maps

    try {
      // Parser le premier objet référencé
      int? objectType;
      int? objectInstance;

      if (objRefs is List && objRefs.isNotEmpty) {
        final firstRef = objRefs.first;
        if (firstRef is Map) {
          objectType = firstRef['type'] as int?;
          objectInstance = firstRef['instance'] as int?;
        }
      } else if (objRefs is Map) {
        objectType = objRefs['type'] as int?;
        objectInstance = objRefs['instance'] as int?;
      }

      if (objectType == null || objectInstance == null) {
        _logger.d('_getStateTextsFromReferencedObject: could not parse object reference');
        return null;
      }

      _logger.d('_getStateTextsFromReferencedObject: reading state-text from object type=$objectType instance=$objectInstance');

      // Lire le state-text de l'objet référencé
      final result = await readProperty(
        host: host,
        port: port,
        objectType: objectType,
        objectInstance: objectInstance,
        propertyId: BacnetPropertyId.stateText,
      );

      if (result.isSuccess && result.value != null) {
        return _parseStateText(result.value);
      }
    } catch (e) {
      _logger.e('_getStateTextsFromReferencedObject: error $e');
    }

    return null;
  }

  /// Lit le weekly-schedule complet d'un objet Schedule BACnet
  Future<DecodedWeeklySchedule?> readWeeklySchedule({
    required String host,
    required int port,
    required int scheduleInstance,
  }) async {
    await init();

    _logger.i('readWeeklySchedule: reading schedule $scheduleInstance from $host:$port');

    // Lire la propriété weekly-schedule (123)
    final result = await readProperty(
      host: host,
      port: port,
      objectType: BacnetObjectTypeCode.schedule,
      objectInstance: scheduleInstance,
      propertyId: BacnetPropertyId.weeklySchedule,
    );

    if (!result.isSuccess) {
      _logger.e('readWeeklySchedule: Failed - ${result.errorMessage}');
      return null;
    }

    _logger.d('readWeeklySchedule: raw value type=${result.value.runtimeType}');

    // Vérifier si le décodeur a déjà retourné un DecodedWeeklySchedule
    DecodedWeeklySchedule decoded;
    if (result.value is DecodedWeeklySchedule) {
      // Déjà décodé par BacnetDecoder._decodeReadPropertyAck
      decoded = result.value as DecodedWeeklySchedule;
      _logger.d('readWeeklySchedule: value already decoded');
    } else {
      // Décoder le weekly-schedule depuis les données brutes
      decoded = BacnetScheduleDecoder.decodeWeeklySchedule(result.value);
      _logger.d('readWeeklySchedule: decoded from raw data');
    }

    _logger.i('readWeeklySchedule: decoded ${decoded.days.length} days');
    for (int i = 0; i < decoded.days.length; i++) {
      final day = decoded.days[i];
      _logger.d('  Day ${i + 1}: ${day.timeValues.length} transitions');
    }

    return decoded;
  }

  /// Lit un schedule complet (infos de base + weekly-schedule)
  Future<BacnetScheduleInfo?> readScheduleFull({
    required String host,
    required int port,
    required int scheduleInstance,
    int? deviceId,
  }) async {
    // Lire les infos de base
    final basicInfo = await readScheduleBasicInfo(
      host: host,
      port: port,
      scheduleInstance: scheduleInstance,
      deviceId: deviceId,
    );

    if (basicInfo == null) return null;

    // Lire le weekly-schedule
    final weeklySchedule = await readWeeklySchedule(
      host: host,
      port: port,
      scheduleInstance: scheduleInstance,
    );

    return BacnetScheduleInfo(
      instance: basicInfo.instance,
      objectName: basicInfo.objectName,
      description: basicInfo.description,
      weeklySchedule: weeklySchedule,
      presentValue: basicInfo.presentValue,
      scheduleDefault: basicInfo.scheduleDefault,
      stateTexts: basicInfo.stateTexts,
      outOfService: basicInfo.outOfService,
    );
  }

  /// Écrit le weekly-schedule complet d'un objet Schedule BACnet
  /// Utilise WriteProperty avec l'encodage correct des BACnetTimeValue
  Future<bool> writeWeeklySchedule({
    required String host,
    required int port,
    required int scheduleInstance,
    required BacnetWeeklySchedule weeklySchedule,
  }) async {
    await init();

    _logger.i('writeWeeklySchedule: writing to schedule $scheduleInstance on $host:$port');

    // Debug: log what we're trying to write
    for (int i = 0; i < 7; i++) {
      final day = weeklySchedule.days[i];
      if (day.timeValues.isNotEmpty) {
        _logger.d('writeWeeklySchedule: Day ${i + 1}: ${day.timeValues.length} transitions');
        for (final tv in day.timeValues) {
          _logger.d('  - ${tv.hour}:${tv.minute} = ${tv.value} (tag: ${tv.valueTag})');
        }
      }
    }

    final invokeId = _nextInvokeId();
    final packet = BacnetEncoder.encodeWriteWeeklyScheduleRequest(
      invokeId: invokeId,
      scheduleInstance: scheduleInstance,
      weeklySchedule: weeklySchedule,
    );

    _logger.d('writeWeeklySchedule: sending packet (${packet.length} bytes)');

    final response = await _sendAndWait(packet, host, port, invokeId);

    if (response.isSuccess) {
      _logger.i('writeWeeklySchedule: Success');
      return true;
    } else {
      _logger.e('writeWeeklySchedule: Failed - ${response.errorMessage}');
      _logger.e('writeWeeklySchedule: error class=${response.errorClass}, code=${response.errorCode}');
      return false;
    }
  }

  /// Écrit un jour spécifique du weekly-schedule
  /// [dayIndex]: 1-7 (1=Lundi, 7=Dimanche)
  Future<bool> writeDailySchedule({
    required String host,
    required int port,
    required int scheduleInstance,
    required int dayIndex,
    required BacnetDailySchedule dailySchedule,
  }) async {
    await init();

    if (dayIndex < 1 || dayIndex > 7) {
      _logger.e('writeDailySchedule: Invalid dayIndex $dayIndex (must be 1-7)');
      return false;
    }

    _logger.i('writeDailySchedule: writing day $dayIndex to schedule $scheduleInstance');

    final invokeId = _nextInvokeId();
    final packet = BacnetEncoder.encodeWriteDailyScheduleRequest(
      invokeId: invokeId,
      scheduleInstance: scheduleInstance,
      dayIndex: dayIndex,
      dailySchedule: dailySchedule,
    );

    final response = await _sendAndWait(packet, host, port, invokeId);

    if (response.isSuccess) {
      _logger.i('writeDailySchedule: Success for day $dayIndex');
      return true;
    } else {
      _logger.e('writeDailySchedule: Failed for day $dayIndex - ${response.errorMessage}');
      return false;
    }
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
  final bool inAlarm;
  final String? units;

  RefreshedPointData({
    this.presentValue,
    this.isOverridden = false,
    this.overridePriority,
    this.overrideValue,
    this.outOfService,
    this.inAlarm = false,
    this.units,
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
  final int? totalRecordCount; // Numéro de séquence du dernier record (pour pagination)
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
    this.totalRecordCount,
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

// =========================================================================
// Schedule BACnet Models
// =========================================================================

/// Informations complètes d'un schedule BACnet
class BacnetScheduleInfo {
  final int instance;
  final String objectName;
  final String? description;
  final DecodedWeeklySchedule? weeklySchedule;
  final dynamic presentValue;
  final dynamic scheduleDefault;
  final List<String>? stateTexts;
  final int? effectivePeriodStart; // En jours depuis 1900
  final int? effectivePeriodEnd;
  final bool? outOfService;

  BacnetScheduleInfo({
    required this.instance,
    required this.objectName,
    this.description,
    this.weeklySchedule,
    this.presentValue,
    this.scheduleDefault,
    this.stateTexts,
    this.effectivePeriodStart,
    this.effectivePeriodEnd,
    this.outOfService,
  });
}
