import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:logger/logger.dart';
import '../../domain/models/bacnet_object.dart';
import '../../domain/models/schedule.dart';

final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

/// Résultat d'un test de connexion
class ConnectionTestResult {
  final bool success;
  final String? apiVersion;
  final String? errorMessage;
  final String? certificateFingerprint;

  ConnectionTestResult({
    required this.success,
    this.apiVersion,
    this.errorMessage,
    this.certificateFingerprint,
  });
}

/// Service pour communiquer avec les automates ECLYPSE
class ApiService {
  late final Dio _dio;
  String? _lastCertificateFingerprint;

  ApiService() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      validateStatus: (status) => status != null && status < 500,
    ));
  }

  /// Configure le client HTTP pour accepter les certificats auto-signés
  void _configureForSelfSignedCerts(String host) {
    (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback = (X509Certificate cert, String host, int port) {
        // Calculer l'empreinte SHA256 du certificat
        _lastCertificateFingerprint = _calculateFingerprint(cert);
        // Accepter tous les certificats (TOFU sera géré au niveau supérieur)
        return true;
      };
      return client;
    };
  }

  /// Calcule l'empreinte SHA256 d'un certificat
  String _calculateFingerprint(X509Certificate cert) {
    // Utiliser le SHA1 du certificat comme identifiant
    return cert.sha1.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':').toUpperCase();
  }

  /// Teste la connexion à un automate et détecte la version de l'API
  Future<ConnectionTestResult> testConnection({
    required String host,
    required int port,
    required bool useHttps,
    required String username,
    required String password,
  }) async {
    // Validation des entrées
    final trimmedHost = host.trim();
    if (trimmedHost.isEmpty) {
      return ConnectionTestResult(success: false, errorMessage: 'Hôte requis');
    }
    if (port < 1 || port > 65535) {
      return ConnectionTestResult(success: false, errorMessage: 'Port invalide (1-65535)');
    }
    if (username.trim().isEmpty) {
      return ConnectionTestResult(success: false, errorMessage: 'Nom d\'utilisateur requis');
    }
    if (password.isEmpty) {
      return ConnectionTestResult(success: false, errorMessage: 'Mot de passe requis');
    }

    final scheme = useHttps ? 'https' : 'http';
    final baseUrl = '$scheme://$trimmedHost:$port';

    // Configurer pour accepter les certificats auto-signés
    if (useHttps) {
      _configureForSelfSignedCerts(trimmedHost);
    }

    // Créer l'en-tête Basic Auth
    final basicAuth = 'Basic ${base64Encode(utf8.encode('$username:$password'))}';

    // Essayer d'abord l'API V2
    try {
      final v2Result = await _testApiV2(baseUrl, basicAuth);
      if (v2Result.success) {
        return ConnectionTestResult(
          success: true,
          apiVersion: 'V2',
          certificateFingerprint: _lastCertificateFingerprint,
        );
      }
    } catch (e) {
      // V2 a échoué, on essaie V1
    }

    // Essayer l'API V1
    try {
      final v1Result = await _testApiV1(baseUrl, basicAuth);
      if (v1Result.success) {
        return ConnectionTestResult(
          success: true,
          apiVersion: 'V1',
          certificateFingerprint: _lastCertificateFingerprint,
        );
      }
      return v1Result;
    } catch (e) {
      return ConnectionTestResult(
        success: false,
        errorMessage: _formatError(e),
        certificateFingerprint: _lastCertificateFingerprint,
      );
    }
  }

  /// Teste l'API V2 (ECLYPSE 400/600, APEX)
  Future<ConnectionTestResult> _testApiV2(String baseUrl, String basicAuth) async {
    // En V2, on obtient d'abord un token puis on fait une requête
    // Mais pour un simple test, on peut essayer /api/rest/v2/services/platform
    final response = await _dio.get(
      '$baseUrl/api/rest/v2/services/platform',
      options: Options(
        headers: {'Authorization': basicAuth},
      ),
    );

    if (response.statusCode == 200) {
      return ConnectionTestResult(success: true, apiVersion: 'V2');
    } else if (response.statusCode == 401) {
      return ConnectionTestResult(
        success: false,
        errorMessage: 'Identifiants incorrects',
      );
    } else {
      return ConnectionTestResult(
        success: false,
        errorMessage: 'Erreur ${response.statusCode}',
      );
    }
  }

  /// Teste l'API V1 (anciens contrôleurs)
  Future<ConnectionTestResult> _testApiV1(String baseUrl, String basicAuth) async {
    // En V1, on utilise Basic Auth directement
    final response = await _dio.get(
      '$baseUrl/api/rest/v1/protocols/bacnet/local/objects/device',
      options: Options(
        headers: {'Authorization': basicAuth},
      ),
    );

    if (response.statusCode == 200) {
      return ConnectionTestResult(success: true, apiVersion: 'V1');
    } else if (response.statusCode == 401) {
      return ConnectionTestResult(
        success: false,
        errorMessage: 'Identifiants incorrects',
      );
    } else {
      return ConnectionTestResult(
        success: false,
        errorMessage: 'Erreur ${response.statusCode}',
      );
    }
  }

  /// Formate une erreur pour l'affichage
  String _formatError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          return 'Délai de connexion dépassé';
        case DioExceptionType.connectionError:
          return 'Impossible de se connecter à l\'hôte';
        case DioExceptionType.receiveTimeout:
          return 'Délai de réponse dépassé';
        case DioExceptionType.badResponse:
          return 'Réponse invalide du serveur';
        default:
          return error.message ?? 'Erreur de connexion';
      }
    }
    return error.toString();
  }

  /// Ferme le client HTTP
  void dispose() {
    _dio.close();
  }
}

/// Client connecté à un automate spécifique
class ConnectedApiClient {
  final Dio _dio;
  final String baseUrl;
  final String basicAuth;
  final String apiVersion;

  ConnectedApiClient({
    required this.baseUrl,
    required this.basicAuth,
    required this.apiVersion,
  }) : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 30),
          validateStatus: (status) => status != null && status < 500,
        )) {
    // Configurer pour les certificats auto-signés
    (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback = (cert, host, port) => true;
      return client;
    };
    _logger.i('ConnectedApiClient créé: baseUrl=$baseUrl, apiVersion=$apiVersion');
  }

  /// Chemin de base pour l'API BACnet
  String get _bacnetBasePath => apiVersion == 'V2'
      ? '/api/rest/v2/services/bacnet/local'
      : '/api/rest/v1/protocols/bacnet/local';

  /// Options HTTP avec authentification
  Options get _authOptions => Options(headers: {'Authorization': basicAuth});

  /// Récupère les informations de l'appareil
  Future<DeviceInfo> getDeviceInfo() async {
    // Pour V1, utiliser read-property-multiple pour récupérer toutes les propriétés en une requête
    if (apiVersion == 'V1') {
      return await _getDeviceInfoV1();
    }

    // V2: méthode standard
    final url = '$baseUrl$_bacnetBasePath/objects/device';
    _logger.i('getDeviceInfo: GET $url');

    try {
      final response = await _dio.get(url, options: _authOptions);
      _logger.i('getDeviceInfo: status=${response.statusCode}');
      _logger.d('getDeviceInfo: data=${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is List && data.isNotEmpty) {
          final firstItem = data.first;
          if (firstItem is int) {
            final detailUrl = '$baseUrl$_bacnetBasePath/objects/device/$firstItem';
            _logger.i('getDeviceInfo: fetching details from $detailUrl');
            final detailResponse = await _dio.get(detailUrl, options: _authOptions);
            if (detailResponse.statusCode == 200 && detailResponse.data != null) {
              return DeviceInfo.fromJson(detailResponse.data as Map<String, dynamic>);
            }
          } else if (firstItem is Map<String, dynamic>) {
            return DeviceInfo.fromJson(firstItem);
          }
        } else if (data is Map<String, dynamic>) {
          return DeviceInfo.fromJson(data);
        }
      }
    } catch (e) {
      _logger.e('getDeviceInfo error: $e');
    }

    throw Exception('Impossible de récupérer les informations de l\'appareil');
  }

  /// Récupère les infos du device pour V1 depuis /info/device et /bacnet/local
  Future<DeviceInfo> _getDeviceInfoV1() async {
    String? bacnetName;

    // 1. Récupérer le nom BACnet depuis /bacnet/local
    try {
      final localUrl = '$baseUrl$_bacnetBasePath';
      _logger.i('_getDeviceInfoV1: GET $localUrl');
      final localResponse = await _dio.get(localUrl, options: _authOptions);
      if (localResponse.statusCode == 200 && localResponse.data is Map<String, dynamic>) {
        bacnetName = (localResponse.data as Map<String, dynamic>)['name'] as String?;
      }
    } catch (e) {
      _logger.w('_getDeviceInfoV1: /bacnet/local error: $e');
    }

    // 2. Récupérer les infos détaillées depuis /info/device
    try {
      final infoUrl = '$baseUrl/api/rest/v1/info/device';
      _logger.i('_getDeviceInfoV1: GET $infoUrl');
      final infoResponse = await _dio.get(infoUrl, options: _authOptions);
      _logger.d('_getDeviceInfoV1: /info/device response=${infoResponse.data}');

      if (infoResponse.statusCode == 200 && infoResponse.data is Map<String, dynamic>) {
        final data = infoResponse.data as Map<String, dynamic>;
        return DeviceInfo.fromDeviceInfoJson(data, bacnetName: bacnetName);
      }
    } catch (e) {
      _logger.w('_getDeviceInfoV1: /info/device error: $e');
    }

    // Fallback si les deux endpoints échouent
    return DeviceInfo(objectName: bacnetName ?? 'Automate V1');
  }

  /// Récupère le résumé des objets disponibles
  Future<ObjectsSummary> getObjectsSummary() async {
    final url = '$baseUrl$_bacnetBasePath/objects';
    _logger.i('getObjectsSummary: GET $url');

    try {
      final response = await _dio.get(url, options: _authOptions);
      _logger.i('getObjectsSummary: status=${response.statusCode}');
      _logger.d('getObjectsSummary: data=${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        // Vérifier que la réponse est bien du JSON
        if (response.data is! Map<String, dynamic>) {
          _logger.w('getObjectsSummary: réponse non-JSON: ${response.data.runtimeType}');
          throw Exception('Réponse non-JSON reçue');
        }
        final data = response.data as Map<String, dynamic>;
        _logger.i('getObjectsSummary: keys=${data.keys.toList()}');

        // V1 format: {bacnetObjectTypes: [{href: "...", name: "analogValue"}, ...]}
        if (data.containsKey('bacnetObjectTypes')) {
          return await _getObjectsSummaryV1(data);
        }

        // V2 format: {analog-value: [...], binary-value: [...], ...}
        return ObjectsSummary(
          analogInputs: _countObjects(data, 'analog-input', 'analog-inputs'),
          analogOutputs: _countObjects(data, 'analog-output', 'analog-outputs'),
          analogValues: _countObjects(data, 'analog-value', 'analog-values'),
          binaryInputs: _countObjects(data, 'binary-input', 'binary-inputs'),
          binaryOutputs: _countObjects(data, 'binary-output', 'binary-outputs'),
          binaryValues: _countObjects(data, 'binary-value', 'binary-values'),
          multiStateInputs: _countObjects(data, 'multi-state-input', 'multi-state-inputs'),
          multiStateOutputs: _countObjects(data, 'multi-state-output', 'multi-state-outputs'),
          multiStateValues: _countObjects(data, 'multi-state-value', 'multi-state-values'),
          schedules: _countObjects(data, 'schedule', 'schedules'),
        );
      }
    } catch (e) {
      _logger.e('getObjectsSummary error: $e');
      rethrow;
    }

    throw Exception('Impossible de récupérer la liste des objets');
  }

  /// Parse le résumé des objets pour V1 via read-property-multiple (1 seule requête!)
  Future<ObjectsSummary> _getObjectsSummaryV1(Map<String, dynamic> data) async {
    _logger.i('_getObjectsSummaryV1: using read-property-multiple');

    // Utiliser read-property-multiple avec instance=-1 pour récupérer TOUS les objets de chaque type
    final rpmUrl = '$baseUrl$_bacnetBasePath/objects/read-property-multiple';

    // Liste des types à compter avec instance=-1 (tous les objets du type)
    final propertyRefs = <Map<String, dynamic>>[];
    for (final type in _importantTypes) {
      propertyRefs.add({
        'type': type,
        'instance': -1,  // -1 = tous les instances
        'property': 'objectName',
        'arrayIndex': -1,
      });
    }

    final body = {
      'encode': 'text',
      'propertyReferences': propertyRefs,
    };

    _logger.i('_getObjectsSummaryV1: POST $rpmUrl with ${propertyRefs.length} types');

    try {
      final response = await _dio.post(
        rpmUrl,
        data: body,
        options: Options(
          headers: {
            'Authorization': basicAuth,
            'Content-Type': 'application/json',
          },
        ),
      );

      _logger.d('_getObjectsSummaryV1: response status=${response.statusCode}');
      _logger.d('_getObjectsSummaryV1: response data=${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        return _parseObjectsSummaryFromRpm(response.data);
      }
    } catch (e) {
      _logger.w('_getObjectsSummaryV1: read-property-multiple failed: $e');
      // Fallback: compter depuis la liste des types
      return _getObjectsSummaryV1Fallback(data);
    }

    return ObjectsSummary();
  }

  /// Types d'objets importants à compter
  static const _importantTypes = [
    'analogInput', 'analogOutput', 'analogValue',
    'binaryInput', 'binaryOutput', 'binaryValue',
    'multiStateInput', 'multiStateOutput', 'multiStateValue',
    'schedule',
  ];

  /// Parse la réponse read-property-multiple pour compter les objets
  ObjectsSummary _parseObjectsSummaryFromRpm(dynamic data) {
    final counts = <String, int>{};

    // La réponse peut être une List directement ou un Map avec propertyReferences
    List refs;
    if (data is List) {
      refs = data;
    } else if (data is Map<String, dynamic>) {
      refs = data['propertyReferences'] as List? ?? [];
    } else {
      refs = [];
    }

    // Compter les objets par type (chaque entrée avec instance différent = 1 objet)
    final instancesByType = <String, Set<int>>{};

    for (final ref in refs) {
      if (ref is! Map<String, dynamic>) continue;
      final type = ref['type'] as String? ?? '';
      final instance = ref['instance'] as int? ?? 0;

      if (_importantTypes.contains(type)) {
        instancesByType.putIfAbsent(type, () => <int>{});
        instancesByType[type]!.add(instance);
      }
    }

    for (final entry in instancesByType.entries) {
      counts[entry.key] = entry.value.length;
    }

    _logger.i('_parseObjectsSummaryFromRpm: ${counts.entries.map((e) => '${e.key}=${e.value}').join(', ')}');

    return ObjectsSummary(
      analogInputs: counts['analogInput'] ?? 0,
      analogOutputs: counts['analogOutput'] ?? 0,
      analogValues: counts['analogValue'] ?? 0,
      binaryInputs: counts['binaryInput'] ?? 0,
      binaryOutputs: counts['binaryOutput'] ?? 0,
      binaryValues: counts['binaryValue'] ?? 0,
      multiStateInputs: counts['multiStateInput'] ?? 0,
      multiStateOutputs: counts['multiStateOutput'] ?? 0,
      multiStateValues: counts['multiStateValue'] ?? 0,
      schedules: counts['schedule'] ?? 0,
    );
  }

  /// Fallback: compter les objets via requêtes individuelles (si RPM échoue)
  Future<ObjectsSummary> _getObjectsSummaryV1Fallback(Map<String, dynamic> data) async {
    _logger.i('_getObjectsSummaryV1Fallback: using individual requests');
    final objectTypes = data['bacnetObjectTypes'] as List? ?? [];
    final counts = <String, int>{};

    // Traiter par lots de 4
    final typesToCount = <Map<String, String>>[];
    for (final typeInfo in objectTypes) {
      if (typeInfo is! Map<String, dynamic>) continue;
      final name = typeInfo['name'] as String? ?? '';
      final href = typeInfo['href'] as String?;
      if (href != null && _importantTypes.contains(name)) {
        typesToCount.add({'name': name, 'href': href});
      }
    }

    const batchSize = 4;
    for (var i = 0; i < typesToCount.length; i += batchSize) {
      final batch = typesToCount.skip(i).take(batchSize);
      await Future.wait(batch.map((t) async {
        try {
          final response = await _dio.get('$baseUrl${t['href']}', options: _authOptions);
          if (response.statusCode == 200 && response.data is List) {
            counts[t['name']!] = (response.data as List).length;
          }
        } catch (e) {
          counts[t['name']!] = 0;
        }
      }));
    }

    return ObjectsSummary(
      analogInputs: counts['analogInput'] ?? 0,
      analogOutputs: counts['analogOutput'] ?? 0,
      analogValues: counts['analogValue'] ?? 0,
      binaryInputs: counts['binaryInput'] ?? 0,
      binaryOutputs: counts['binaryOutput'] ?? 0,
      binaryValues: counts['binaryValue'] ?? 0,
      multiStateInputs: counts['multiStateInput'] ?? 0,
      multiStateOutputs: counts['multiStateOutput'] ?? 0,
      multiStateValues: counts['multiStateValue'] ?? 0,
      schedules: counts['schedule'] ?? 0,
    );
  }

  int _countObjects(Map<String, dynamic> data, String key1, String key2) {
    final value = data[key1] ?? data[key2];
    if (value is List) return value.length;
    if (value is Map) return value.length;  // V2 format: {instance: {...}, ...}
    if (value is int) return value;
    return 0;
  }

  /// Récupère tous les objets d'un type donné
  Future<List<BacnetObject>> getObjectsByType(BacnetObjectType type) async {
    final response = await _dio.get(
      '$baseUrl$_bacnetBasePath/objects/${type.apiName}',
      options: _authOptions,
    );

    if (response.statusCode == 200 && response.data != null) {
      final data = response.data;
      final objects = <BacnetObject>[];

      if (data is List) {
        // Liste d'IDs ou liste d'objets complets
        for (var i = 0; i < data.length; i++) {
          final item = data[i];
          if (item is Map<String, dynamic>) {
            // Objet complet
            final instance = item['object-identifier']?['instance'] ??
                            item['objectIdentifier']?['instance'] ?? i + 1;
            objects.add(BacnetObject.fromJson(type, instance, item));
          } else if (item is int) {
            // Juste un ID, on doit récupérer les détails
            final details = await getObjectDetails(type, item);
            if (details != null) objects.add(details);
          }
        }
      } else if (data is Map<String, dynamic>) {
        // Un seul objet ou map d'objets par ID
        data.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            final instance = int.tryParse(key) ??
                            value['object-identifier']?['instance'] ?? 1;
            objects.add(BacnetObject.fromJson(type, instance, value));
          }
        });
      }

      return objects;
    }

    return [];
  }

  /// Récupère les détails d'un objet spécifique
  Future<BacnetObject?> getObjectDetails(BacnetObjectType type, int instance) async {
    try {
      final response = await _dio.get(
        '$baseUrl$_bacnetBasePath/objects/${type.apiName}/$instance',
        options: _authOptions,
      );

      if (response.statusCode == 200 && response.data != null) {
        return BacnetObject.fromJson(type, instance, response.data);
      }
    } catch (e) {
      // Ignorer les erreurs pour les objets individuels
    }
    return null;
  }

  /// Récupère tous les objets avec leurs valeurs actuelles
  Future<List<BacnetObject>> getAllObjects() async {
    final objects = <BacnetObject>[];

    // Types d'objets principaux à récupérer
    final types = [
      BacnetObjectType.analogInput,
      BacnetObjectType.analogOutput,
      BacnetObjectType.analogValue,
      BacnetObjectType.binaryInput,
      BacnetObjectType.binaryOutput,
      BacnetObjectType.binaryValue,
    ];

    for (final type in types) {
      try {
        final typeObjects = await getObjectsByType(type);
        objects.addAll(typeObjects);
      } catch (e) {
        // Continuer même si un type échoue
      }
    }

    return objects;
  }

  /// Récupère tous les points avec read-property-multiple (optimisé)
  Future<List<BacnetObject>> getAllPointsOptimized() async {
    if (apiVersion == 'V1') {
      return _getAllPointsV1Optimized();
    }
    // V2: utiliser batch API avec $select
    return _getAllPointsV2Optimized();
  }

  /// Récupère tous les points V1 via read-property-multiple en une seule requête
  Future<List<BacnetObject>> _getAllPointsV1Optimized() async {
    _logger.i('_getAllPointsV1Optimized: fetching all points with read-property-multiple');

    // Types de points qu'on veut récupérer (en camelCase comme attendu par l'API)
    const pointTypes = [
      'analogInput', 'analogOutput', 'analogValue',
      'binaryInput', 'binaryOutput', 'binaryValue',
      'multistateInput', 'multistateOutput', 'multistateValue',
    ];

    // Types commandables (peuvent avoir un priority-array / forçage)
    const commandableTypes = [
      'analogOutput', 'analogValue',
      'binaryOutput', 'binaryValue',
      'multistateOutput', 'multistateValue',
    ];

    // Types binaires (ont active-text et inactive-text)
    const binaryTypes = [
      'binaryInput', 'binaryOutput', 'binaryValue',
    ];

    // Construire les propertyReferences pour lire toutes les instances de chaque type
    // On utilise instance=-1 pour toutes les instances
    final propertyRefs = <Map<String, dynamic>>[];

    for (final typeName in pointTypes) {
      // Lire les propriétés essentielles pour toutes les instances de ce type
      propertyRefs.add({
        'type': typeName,
        'instance': -1,  // -1 = toutes les instances
        'property': 'objectName',
        'arrayIndex': -1,
      });
      propertyRefs.add({
        'type': typeName,
        'instance': -1,
        'property': 'presentValue',
        'arrayIndex': -1,
      });
      propertyRefs.add({
        'type': typeName,
        'instance': -1,
        'property': 'units',
        'arrayIndex': -1,
      });
      propertyRefs.add({
        'type': typeName,
        'instance': -1,
        'property': 'outOfService',
        'arrayIndex': -1,
      });
      propertyRefs.add({
        'type': typeName,
        'instance': -1,
        'property': 'description',
        'arrayIndex': -1,
      });

      // Ajouter priorityArray uniquement pour les types commandables
      if (commandableTypes.contains(typeName)) {
        propertyRefs.add({
          'type': typeName,
          'instance': -1,
          'property': 'priorityArray',
          'arrayIndex': -1,
        });
      }

      // Ajouter activeText et inactiveText pour les types binaires
      if (binaryTypes.contains(typeName)) {
        propertyRefs.add({
          'type': typeName,
          'instance': -1,
          'property': 'activeText',
          'arrayIndex': -1,
        });
        propertyRefs.add({
          'type': typeName,
          'instance': -1,
          'property': 'inactiveText',
          'arrayIndex': -1,
        });
      }
    }

    _logger.i('_getAllPointsV1Optimized: requesting ${propertyRefs.length} property references');

    // Faire la requête read-property-multiple
    final rpmUrl = '$baseUrl$_bacnetBasePath/objects/read-property-multiple';

    try {
      final rpmResponse = await _dio.post(
        rpmUrl,
        data: {
          'encode': 'text',
          'propertyReferences': propertyRefs,
        },
        options: Options(
          headers: {
            'Authorization': basicAuth,
            'Content-Type': 'application/json',
          },
        ),
      );

      _logger.d('_getAllPointsV1Optimized: response status=${rpmResponse.statusCode}');

      if (rpmResponse.statusCode == 200 && rpmResponse.data != null) {
        return _parsePointsFromRpm(rpmResponse.data);
      }
    } catch (e) {
      _logger.e('_getAllPointsV1Optimized: read-property-multiple failed: $e');
      // En cas d'échec, on fallback sur la méthode classique
      _logger.i('_getAllPointsV1Optimized: falling back to getAllObjects()');
      return getAllObjects();
    }

    return [];
  }

  /// Récupère tous les points V2 via batch API
  Future<List<BacnetObject>> _getAllPointsV2Optimized() async {
    _logger.i('_getAllPointsV2Optimized: fetching all points with batch API');

    // Types de points à récupérer (format V2 kebab-case)
    const pointTypes = [
      'analog-inputs', 'analog-outputs', 'analog-values',
      'binary-inputs', 'binary-outputs', 'binary-values',
      'multi-state-inputs', 'multi-state-outputs', 'multi-state-values',
    ];

    // Construire les requêtes batch
    final requests = <Map<String, dynamic>>[];
    for (final typeName in pointTypes) {
      requests.add({
        'id': typeName,
        'method': 'GET',
        'url': '$_bacnetBasePath/objects/$typeName',
      });
    }

    final batchUrl = '$baseUrl/api/rest/v2/batch';
    _logger.i('_getAllPointsV2Optimized: POST $batchUrl with ${requests.length} requests');

    try {
      final response = await _dio.post(
        batchUrl,
        data: {'requests': requests},
        options: Options(
          headers: {
            'Authorization': basicAuth,
            'Content-Type': 'application/json',
          },
        ),
      );

      _logger.d('_getAllPointsV2Optimized: response status=${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        return _parsePointsFromBatchV2(response.data);
      }
    } catch (e) {
      _logger.e('_getAllPointsV2Optimized: batch API failed: $e');
      // En cas d'échec, fallback sur la méthode classique
      _logger.i('_getAllPointsV2Optimized: falling back to getAllObjects()');
      return getAllObjects();
    }

    return [];
  }

  /// Parse la réponse batch V2 pour construire les objets BACnet
  List<BacnetObject> _parsePointsFromBatchV2(dynamic data) {
    _logger.d('_parsePointsFromBatchV2: data type=${data.runtimeType}');

    final results = <BacnetObject>[];

    // La réponse batch peut être une liste directement ou un wrapper {"responses": [...]}
    List<dynamic> responses;
    if (data is List) {
      responses = data;
    } else if (data is Map<String, dynamic>) {
      // Essayer d'extraire "responses" du wrapper
      final responsesList = data['responses'];
      if (responsesList is List) {
        responses = responsesList;
        _logger.d('_parsePointsFromBatchV2: extracted ${responses.length} responses from wrapper');
      } else {
        _logger.w('_parsePointsFromBatchV2: no responses key found, keys=${data.keys.toList()}');
        return results;
      }
    } else {
      _logger.w('_parsePointsFromBatchV2: expected List or Map, got ${data.runtimeType}');
      return results;
    }

    for (final batchResponse in responses) {
      if (batchResponse is! Map<String, dynamic>) continue;

      final id = batchResponse['id'] as String?;
      final body = batchResponse['body'];

      if (id == null || body == null) continue;

      // Mapper l'ID (type kebab-case) vers BacnetObjectType
      final objectType = _mapTypeNameV2(id);
      if (objectType == null) continue;

      // Body contient directement les instances {instance: {props...}, ...}
      if (body is Map<String, dynamic>) {
        for (final entry in body.entries) {
          final instance = int.tryParse(entry.key);
          if (instance == null) continue;

          final props = entry.value;
          if (props is! Map<String, dynamic>) continue;

          // Parser le priority-array (format V2 = List)
          final priorityArray = props['priority-array'];
          final overrideInfo = BacnetObject.parsePriorityArray(priorityArray);

          results.add(BacnetObject(
            type: objectType,
            instance: instance,
            objectName: props['object-name']?.toString() ?? '$id-$instance',
            presentValue: _parseValue(props['present-value']),
            units: _extractUnitsV2(props['units']),
            outOfService: props['out-of-service'] as bool?,
            description: props['description']?.toString(),
            priorityArrayRaw: priorityArray?.toString(),
            isOverridden: overrideInfo.isOverridden,
            overridePriority: overrideInfo.priority,
            overrideValue: overrideInfo.value,
            activeText: props['active-text']?.toString(),
            inactiveText: props['inactive-text']?.toString(),
          ));
        }
      }
    }

    _logger.i('_parsePointsFromBatchV2: parsed ${results.length} objects');

    // Log des points forcés pour debug
    final overriddenCount = results.where((p) => p.isOverridden).length;
    if (overriddenCount > 0) {
      _logger.i('_parsePointsFromBatchV2: $overriddenCount points are overridden');
    }

    return results;
  }

  /// Mappe le nom de type V2 (kebab-case pluriel) vers BacnetObjectType
  BacnetObjectType? _mapTypeNameV2(String typeName) {
    switch (typeName) {
      case 'analog-inputs':
        return BacnetObjectType.analogInput;
      case 'analog-outputs':
        return BacnetObjectType.analogOutput;
      case 'analog-values':
        return BacnetObjectType.analogValue;
      case 'binary-inputs':
        return BacnetObjectType.binaryInput;
      case 'binary-outputs':
        return BacnetObjectType.binaryOutput;
      case 'binary-values':
        return BacnetObjectType.binaryValue;
      case 'multi-state-inputs':
        return BacnetObjectType.multiStateInput;
      case 'multi-state-outputs':
        return BacnetObjectType.multiStateOutput;
      case 'multi-state-values':
        return BacnetObjectType.multiStateValue;
      case 'schedules':
        return BacnetObjectType.schedule;
      case 'calendars':
        return BacnetObjectType.calendar;
      case 'trend-logs':
        return BacnetObjectType.trendLog;
      case 'devices':
        return BacnetObjectType.device;
      default:
        return null;
    }
  }

  /// Extrait les unités pour V2 (peut être un objet avec $value)
  String? _extractUnitsV2(dynamic units) {
    if (units == null) return null;
    if (units is String) return units.isEmpty ? null : units;
    if (units is Map) {
      return units['\$value']?.toString() ?? units['value']?.toString();
    }
    return units.toString();
  }

  /// Parse la réponse read-property-multiple pour construire les objets BACnet
  List<BacnetObject> _parsePointsFromRpm(dynamic data) {
    _logger.d('_parsePointsFromRpm: data type=${data.runtimeType}');

    final objects = <String, Map<String, dynamic>>{};

    List refs;
    if (data is List) {
      refs = data;
    } else if (data is Map<String, dynamic>) {
      refs = data['propertyReferences'] as List? ?? [];
      _logger.d('_parsePointsFromRpm: found ${refs.length} propertyReferences');
    } else {
      _logger.w('_parsePointsFromRpm: unexpected data format');
      return [];
    }

    // Grouper les propriétés par objet (type:instance)
    for (final ref in refs) {
      if (ref is! Map<String, dynamic>) continue;

      final type = ref['type'] as String? ?? '';
      final instance = ref['instance'];
      final property = ref['property'] as String? ?? '';

      // La valeur peut être dans 'value' ou 'message' selon le format
      var value = ref['value'] ?? ref['message'];

      // Ignorer les entrées avec instance = -1 (ce sont les requêtes, pas les réponses)
      if (instance == -1 || instance == null) continue;

      final instanceInt = instance is int ? instance : int.tryParse(instance.toString()) ?? 0;

      final key = '$type:$instanceInt';
      objects.putIfAbsent(key, () => {'type': type, 'instance': instanceInt});
      objects[key]![property] = value;
    }

    _logger.d('_parsePointsFromRpm: grouped into ${objects.length} objects');

    // Convertir en liste de BacnetObject
    final result = <BacnetObject>[];
    for (final entry in objects.entries) {
      final props = entry.value;
      final typeName = props['type'] as String;
      final instance = props['instance'] as int;

      // Mapper le nom de type camelCase vers BacnetObjectType
      final objectType = _mapTypeName(typeName);

      if (objectType != null) {
        // Parser le priority-array pour détecter les forçages
        // Le format peut être String (V1) ou List (V2)
        final priorityArrayData = props['priorityArray'];
        final priorityArrayRaw = priorityArrayData is String
            ? priorityArrayData
            : (priorityArrayData is List ? priorityArrayData.toString() : null);
        final overrideInfo = BacnetObject.parsePriorityArray(priorityArrayData);

        result.add(BacnetObject(
          type: objectType,
          instance: instance,
          objectName: _extractStringValue(props['objectName']) ?? '$typeName-$instance',
          presentValue: _parseValue(props['presentValue']),
          units: _extractStringValue(props['units']),
          outOfService: _extractBoolValue(props['outOfService']),
          description: _extractStringValue(props['description']),
          priorityArrayRaw: priorityArrayRaw,
          isOverridden: overrideInfo.isOverridden,
          overridePriority: overrideInfo.priority,
          overrideValue: overrideInfo.value,
          activeText: _extractStringValue(props['activeText']),
          inactiveText: _extractStringValue(props['inactiveText']),
        ));
      }
    }

    _logger.i('_parsePointsFromRpm: parsed ${result.length} objects');

    // Log des points forcés pour debug
    final overriddenCount = result.where((p) => p.isOverridden).length;
    if (overriddenCount > 0) {
      _logger.i('_parsePointsFromRpm: $overriddenCount points are overridden');
    }

    return result;
  }

  /// Mappe le nom de type de l'API vers BacnetObjectType
  BacnetObjectType? _mapTypeName(String typeName) {
    final normalized = typeName.toLowerCase();

    switch (normalized) {
      case 'analoginput':
        return BacnetObjectType.analogInput;
      case 'analogoutput':
        return BacnetObjectType.analogOutput;
      case 'analogvalue':
        return BacnetObjectType.analogValue;
      case 'binaryinput':
        return BacnetObjectType.binaryInput;
      case 'binaryoutput':
        return BacnetObjectType.binaryOutput;
      case 'binaryvalue':
        return BacnetObjectType.binaryValue;
      case 'multistateinput':
        return BacnetObjectType.multiStateInput;
      case 'multistateoutput':
        return BacnetObjectType.multiStateOutput;
      case 'multistatevalue':
        return BacnetObjectType.multiStateValue;
      case 'schedule':
        return BacnetObjectType.schedule;
      case 'calendar':
        return BacnetObjectType.calendar;
      case 'trendlog':
        return BacnetObjectType.trendLog;
      case 'device':
        return BacnetObjectType.device;
      default:
        _logger.w('_mapTypeName: unknown type $typeName');
        return null;
    }
  }

  /// Extrait une valeur string d'un champ qui peut être string, map ou autre
  String? _extractStringValue(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.isEmpty ? null : value;
    if (value is Map) {
      // Parfois la valeur est dans un objet {value: "xxx"}
      return value['value']?.toString();
    }
    return value.toString();
  }

  /// Extrait une valeur bool d'un champ
  bool? _extractBoolValue(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    if (value is num) return value != 0;
    return null;
  }

  dynamic _parseValue(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    if (value is bool) return value;
    if (value is String) {
      // Essayer de parser comme nombre
      final numValue = num.tryParse(value);
      if (numValue != null) return numValue;
      // Essayer comme booléen
      if (value.toLowerCase() == 'true' || value == 'active' || value == '1') return true;
      if (value.toLowerCase() == 'false' || value == 'inactive' || value == '0') return false;
      return value;
    }
    return value;
  }

  /// Écrit une valeur simple sur un objet (sans priorité)
  /// Fonctionne uniquement sur les Values (AV, BV, MSV)
  Future<bool> writeValue(BacnetObjectType type, int instance, dynamic value) async {
    if (apiVersion == 'V2') {
      return _writeValueV2(type, instance, value);
    }
    // V1: écriture sans priorité
    return _writeValueV1(type, instance, value, priority: null);
  }

  /// Force une valeur sur un objet avec une priorité donnée
  /// Fonctionne sur les Outputs et Values (AO, BO, MSO, AV, BV, MSV)
  Future<bool> writeOverride(BacnetObjectType type, int instance, dynamic value, {int priority = 8}) async {
    if (apiVersion == 'V2') {
      return _writeOverrideV2(type, instance, value, priority: priority);
    }
    // V1: écriture avec priorité (forçage)
    return _writeValueV1(type, instance, value, priority: priority);
  }

  /// Libère le forçage d'un objet (retour en mode auto)
  /// Libère la priorité spécifiée (par défaut 8)
  Future<bool> releaseOverride(BacnetObjectType type, int instance, {int priority = 8}) async {
    if (apiVersion == 'V2') {
      return _releaseOverrideV2(type, instance, priority: priority);
    }
    return _releaseOverrideV1(type, instance, priority: priority);
  }

  /// Libération d'urgence - libère TOUTES les priorités (1-16)
  /// Remet l'objet en mode complètement automatique
  Future<bool> emergencyRelease(BacnetObjectType type, int instance) async {
    if (apiVersion == 'V2') {
      return _emergencyReleaseV2(type, instance);
    }
    // V1: libérer manuellement toutes les priorités 1-16
    return _emergencyReleaseV1(type, instance);
  }

  /// Force une entrée en mettant out-of-service à true puis en écrivant present-value
  /// Utilisé pour les entrées (AI, BI, MSI) qui n'ont pas de priority-array
  Future<bool> forceInput(BacnetObjectType type, int instance, dynamic value) async {
    if (apiVersion == 'V2') {
      return _forceInputV2(type, instance, value);
    }
    return _forceInputV1(type, instance, value);
  }

  /// Libère une entrée forcée en remettant out-of-service à false
  Future<bool> releaseInput(BacnetObjectType type, int instance) async {
    if (apiVersion == 'V2') {
      return _releaseInputV2(type, instance);
    }
    return _releaseInputV1(type, instance);
  }

  // ============ Méthodes V1 ============

  /// Écriture V1 via write-property-multiple
  /// Si priority est null, c'est une écriture simple (sans forçage)
  /// Si priority est spécifié, c'est un forçage à ce niveau
  Future<bool> _writeValueV1(BacnetObjectType type, int instance, dynamic value, {int? priority}) async {
    final url = '$baseUrl$_bacnetBasePath/objects/write-property-multiple';

    // Convertir le type en camelCase pour l'API V1
    final typeName = _objectTypeToCamelCase(type);

    // Formater la valeur pour l'API - toujours en String
    final formattedValue = _formatValueForWriteV1(type, value);

    final propertyRef = <String, dynamic>{
      'type': typeName,
      'instance': instance,
      'property': 'presentValue',
      'value': formattedValue,
    };

    // Ajouter la priorité seulement si spécifiée
    if (priority != null) {
      propertyRef['priority'] = priority;
    }

    final body = {
      'encode': 'text',
      'propertyReferences': [propertyRef],
    };

    _logger.i('_writeValueV1: POST $url with priority=$priority, value=$formattedValue');

    try {
      final response = await _dio.post(
        url,
        data: body,
        options: Options(
          headers: {
            'Authorization': basicAuth,
            'Content-Type': 'application/json',
          },
        ),
      );

      _logger.i('_writeValueV1: status=${response.statusCode}');
      _logger.d('_writeValueV1: response=${response.data}');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      _logger.e('_writeValueV1 error: $e');
      return false;
    }
  }

  /// Libération V1 via write-property-multiple avec "Null"
  Future<bool> _releaseOverrideV1(BacnetObjectType type, int instance, {int priority = 8}) async {
    final url = '$baseUrl$_bacnetBasePath/objects/write-property-multiple';
    final typeName = _objectTypeToCamelCase(type);

    final body = {
      'encode': 'text',
      'propertyReferences': [
        {
          'type': typeName,
          'instance': instance,
          'property': 'presentValue',
          'priority': priority,
          'value': 'Null',
        }
      ],
    };

    _logger.i('_releaseOverrideV1: POST $url with priority=$priority, value=Null');

    try {
      final response = await _dio.post(
        url,
        data: body,
        options: Options(
          headers: {
            'Authorization': basicAuth,
            'Content-Type': 'application/json',
          },
        ),
      );

      _logger.i('_releaseOverrideV1: status=${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      _logger.e('_releaseOverrideV1 error: $e');
      return false;
    }
  }

  /// Formate une valeur pour l'écriture V1 - TOUJOURS en String
  String _formatValueForWriteV1(BacnetObjectType type, dynamic value) {
    // Pour les types binaires, convertir en 'active'/'inactive'
    // L'API V1 Distech attend 'active'/'inactive' pour les valeurs binaires
    if (type.isBinary) {
      if (value == true || value == 1 || value == 'active' || value == 'ON' || value == 'true') {
        return 'active';
      }
      if (value == false || value == 0 || value == 'inactive' || value == 'OFF' || value == 'false') {
        return 'inactive';
      }
    }

    // Tout le reste en String
    return value.toString();
  }

  /// Libération d'urgence V1 - libère toutes les priorités
  Future<bool> _emergencyReleaseV1(BacnetObjectType type, int instance) async {
    final url = '$baseUrl$_bacnetBasePath/objects/write-property-multiple';
    final typeName = _objectTypeToCamelCase(type);

    // Créer les requêtes pour libérer toutes les priorités 1-16
    final propertyRefs = <Map<String, dynamic>>[];
    for (int priority = 1; priority <= 16; priority++) {
      propertyRefs.add({
        'type': typeName,
        'instance': instance,
        'property': 'presentValue',
        'priority': priority,
        'value': 'Null',
      });
    }

    final body = {
      'encode': 'text',
      'propertyReferences': propertyRefs,
    };

    _logger.i('_emergencyReleaseV1: releasing all priorities for $typeName:$instance');

    try {
      final response = await _dio.post(
        url,
        data: body,
        options: Options(
          headers: {
            'Authorization': basicAuth,
            'Content-Type': 'application/json',
          },
        ),
      );

      _logger.i('_emergencyReleaseV1: status=${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      _logger.e('_emergencyReleaseV1 error: $e');
      return false;
    }
  }

  /// Force une entrée V1 en mettant out-of-service à true puis en écrivant present-value
  Future<bool> _forceInputV1(BacnetObjectType type, int instance, dynamic value) async {
    final url = '$baseUrl$_bacnetBasePath/objects/write-property-multiple';
    final typeName = _objectTypeToCamelCase(type);
    final formattedValue = _formatValueForWriteV1(type, value);

    // Étape 1: Mettre out-of-service à true
    final oosBody = {
      'encode': 'text',
      'propertyReferences': [
        {
          'type': typeName,
          'instance': instance,
          'property': 'outOfService',
          'value': 'true',
        },
      ],
    };

    _logger.i('_forceInputV1: Setting out-of-service=true for $typeName:$instance');

    try {
      final oosResponse = await _dio.post(
        url,
        data: oosBody,
        options: Options(
          headers: {
            'Authorization': basicAuth,
            'Content-Type': 'application/json',
          },
        ),
      );

      if (oosResponse.statusCode != 200 && oosResponse.statusCode != 204) {
        _logger.e('_forceInputV1: Failed to set out-of-service, status=${oosResponse.statusCode}');
        return false;
      }

      // Étape 2: Écrire present-value
      final pvBody = {
        'encode': 'text',
        'propertyReferences': [
          {
            'type': typeName,
            'instance': instance,
            'property': 'presentValue',
            'value': formattedValue,
          },
        ],
      };

      _logger.i('_forceInputV1: Writing present-value=$formattedValue for $typeName:$instance');

      final pvResponse = await _dio.post(
        url,
        data: pvBody,
        options: Options(
          headers: {
            'Authorization': basicAuth,
            'Content-Type': 'application/json',
          },
        ),
      );

      _logger.i('_forceInputV1: status=${pvResponse.statusCode}');
      return pvResponse.statusCode == 200 || pvResponse.statusCode == 204;
    } catch (e) {
      _logger.e('_forceInputV1 error: $e');
      return false;
    }
  }

  /// Libère une entrée forcée V1 en remettant out-of-service à false
  Future<bool> _releaseInputV1(BacnetObjectType type, int instance) async {
    final url = '$baseUrl$_bacnetBasePath/objects/write-property-multiple';
    final typeName = _objectTypeToCamelCase(type);

    final body = {
      'encode': 'text',
      'propertyReferences': [
        {
          'type': typeName,
          'instance': instance,
          'property': 'outOfService',
          'value': 'false',
        },
      ],
    };

    _logger.i('_releaseInputV1: Setting out-of-service=false for $typeName:$instance');

    try {
      final response = await _dio.post(
        url,
        data: body,
        options: Options(
          headers: {
            'Authorization': basicAuth,
            'Content-Type': 'application/json',
          },
        ),
      );

      _logger.i('_releaseInputV1: status=${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      _logger.e('_releaseInputV1 error: $e');
      return false;
    }
  }

  // ============ Méthodes V2 ============

  /// Écriture simple V2 via set-value
  Future<bool> _writeValueV2(BacnetObjectType type, int instance, dynamic value) async {
    final typePath = _objectTypeToKebabCasePlural(type);
    final url = '$baseUrl$_bacnetBasePath/objects/$typePath/$instance/set-value';

    final formattedValue = _formatValueForWrite(type, value);

    _logger.i('_writeValueV2: POST $url with value=$formattedValue');

    try {
      final response = await _dio.post(
        url,
        data: {'value': formattedValue},
        options: Options(
          headers: {
            'Authorization': basicAuth,
            'Content-Type': 'application/json',
          },
        ),
      );

      _logger.i('_writeValueV2: status=${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      _logger.e('_writeValueV2 error: $e');
      return false;
    }
  }

  /// Forçage V2 via set-value-at
  Future<bool> _writeOverrideV2(BacnetObjectType type, int instance, dynamic value, {int priority = 8}) async {
    final typePath = _objectTypeToKebabCasePlural(type);
    final url = '$baseUrl$_bacnetBasePath/objects/$typePath/$instance/set-value-at';

    final formattedValue = _formatValueForWrite(type, value);

    _logger.i('_writeOverrideV2: POST $url with value=$formattedValue, priority=$priority');

    try {
      final response = await _dio.post(
        url,
        data: {
          'value': formattedValue,
          'priority': priority,
        },
        options: Options(
          headers: {
            'Authorization': basicAuth,
            'Content-Type': 'application/json',
          },
        ),
      );

      _logger.i('_writeOverrideV2: status=${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      _logger.e('_writeOverrideV2 error: $e');
      return false;
    }
  }

  /// Libération V2 via set-value-at avec null
  Future<bool> _releaseOverrideV2(BacnetObjectType type, int instance, {int priority = 8}) async {
    final typePath = _objectTypeToKebabCasePlural(type);
    final url = '$baseUrl$_bacnetBasePath/objects/$typePath/$instance/set-value-at';

    _logger.i('_releaseOverrideV2: POST $url with value=null, priority=$priority');

    try {
      final response = await _dio.post(
        url,
        data: {
          'value': null,
          'priority': priority,
        },
        options: Options(
          headers: {
            'Authorization': basicAuth,
            'Content-Type': 'application/json',
          },
        ),
      );

      _logger.i('_releaseOverrideV2: status=${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      _logger.e('_releaseOverrideV2 error: $e');
      return false;
    }
  }

  /// Libération d'urgence V2 via emergency-auto
  Future<bool> _emergencyReleaseV2(BacnetObjectType type, int instance) async {
    final typePath = _objectTypeToKebabCasePlural(type);
    final url = '$baseUrl$_bacnetBasePath/objects/$typePath/$instance/emergency-auto';

    _logger.i('_emergencyReleaseV2: POST $url');

    try {
      final response = await _dio.post(
        url,
        data: {},
        options: Options(
          headers: {
            'Authorization': basicAuth,
            'Content-Type': 'application/json',
          },
        ),
      );

      _logger.i('_emergencyReleaseV2: status=${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      _logger.e('_emergencyReleaseV2 error: $e');
      return false;
    }
  }

  /// Force une entrée V2 en mettant out-of-service à true puis en écrivant present-value
  Future<bool> _forceInputV2(BacnetObjectType type, int instance, dynamic value) async {
    final typePath = _objectTypeToKebabCasePlural(type);
    final formattedValue = _formatValueForWrite(type, value);

    // Étape 1: Mettre out-of-service à true via POST sur la propriété
    final oosUrl = '$baseUrl$_bacnetBasePath/objects/$typePath/$instance/out-of-service';
    _logger.i('_forceInputV2: Setting out-of-service=true for $typePath/$instance');

    try {
      final oosResponse = await _dio.post(
        oosUrl,
        data: {'\$value': true},
        options: Options(
          headers: {
            'Authorization': basicAuth,
            'Content-Type': 'application/json',
          },
        ),
      );

      if (oosResponse.statusCode != 200 && oosResponse.statusCode != 204) {
        _logger.e('_forceInputV2: Failed to set out-of-service, status=${oosResponse.statusCode}');
        return false;
      }

      // Étape 2: Écrire present-value via POST sur la propriété
      final pvUrl = '$baseUrl$_bacnetBasePath/objects/$typePath/$instance/present-value';
      _logger.i('_forceInputV2: Writing present-value=$formattedValue for $typePath/$instance');

      final pvResponse = await _dio.post(
        pvUrl,
        data: {'\$value': formattedValue},
        options: Options(
          headers: {
            'Authorization': basicAuth,
            'Content-Type': 'application/json',
          },
        ),
      );

      _logger.i('_forceInputV2: status=${pvResponse.statusCode}');
      return pvResponse.statusCode == 200 || pvResponse.statusCode == 204;
    } catch (e) {
      _logger.e('_forceInputV2 error: $e');
      return false;
    }
  }

  /// Libère une entrée forcée V2 en remettant out-of-service à false
  Future<bool> _releaseInputV2(BacnetObjectType type, int instance) async {
    final typePath = _objectTypeToKebabCasePlural(type);
    final url = '$baseUrl$_bacnetBasePath/objects/$typePath/$instance/out-of-service';

    _logger.i('_releaseInputV2: Setting out-of-service=false for $typePath/$instance');

    try {
      final response = await _dio.post(
        url,
        data: {'\$value': false},
        options: Options(
          headers: {
            'Authorization': basicAuth,
            'Content-Type': 'application/json',
          },
        ),
      );

      _logger.i('_releaseInputV2: status=${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      _logger.e('_releaseInputV2 error: $e');
      return false;
    }
  }

  // ============ Helpers ============

  /// Convertit BacnetObjectType en camelCase pour V1
  String _objectTypeToCamelCase(BacnetObjectType type) {
    switch (type) {
      case BacnetObjectType.analogInput:
        return 'analogInput';
      case BacnetObjectType.analogOutput:
        return 'analogOutput';
      case BacnetObjectType.analogValue:
        return 'analogValue';
      case BacnetObjectType.binaryInput:
        return 'binaryInput';
      case BacnetObjectType.binaryOutput:
        return 'binaryOutput';
      case BacnetObjectType.binaryValue:
        return 'binaryValue';
      case BacnetObjectType.multiStateInput:
        return 'multistateInput';
      case BacnetObjectType.multiStateOutput:
        return 'multistateOutput';
      case BacnetObjectType.multiStateValue:
        return 'multistateValue';
      default:
        return type.name;
    }
  }

  /// Convertit BacnetObjectType en kebab-case pluriel pour V2
  String _objectTypeToKebabCasePlural(BacnetObjectType type) {
    switch (type) {
      case BacnetObjectType.analogInput:
        return 'analog-inputs';
      case BacnetObjectType.analogOutput:
        return 'analog-outputs';
      case BacnetObjectType.analogValue:
        return 'analog-values';
      case BacnetObjectType.binaryInput:
        return 'binary-inputs';
      case BacnetObjectType.binaryOutput:
        return 'binary-outputs';
      case BacnetObjectType.binaryValue:
        return 'binary-values';
      case BacnetObjectType.multiStateInput:
        return 'multi-state-inputs';
      case BacnetObjectType.multiStateOutput:
        return 'multi-state-outputs';
      case BacnetObjectType.multiStateValue:
        return 'multi-state-values';
      default:
        return type.apiName;
    }
  }

  /// Formate une valeur pour l'écriture selon le type d'objet
  dynamic _formatValueForWrite(BacnetObjectType type, dynamic value) {
    // Pour les types binaires, convertir en 'active'/'inactive'
    if (type.isBinary) {
      if (value == true || value == 1 || value == 'active' || value == 'ON') {
        return 'active';
      }
      if (value == false || value == 0 || value == 'inactive' || value == 'OFF') {
        return 'inactive';
      }
    }

    // Pour les types multi-états, s'assurer que c'est un entier
    if (type.isMultiState) {
      if (value is String) {
        return int.tryParse(value) ?? value;
      }
      return value;
    }

    // Pour les types analogiques, garder la valeur numérique
    if (type.isAnalog) {
      if (value is String) {
        return double.tryParse(value) ?? value;
      }
      return value;
    }

    return value;
  }

  // ============ Méthodes Trend Log ============

  /// Récupère tous les trend-logs de l'automate
  Future<List<Map<String, dynamic>>> getTrendLogs() async {
    if (apiVersion == 'V2') {
      return _getTrendLogsV2();
    }
    return _getTrendLogsV1();
  }

  /// Récupère les trend-logs V1
  Future<List<Map<String, dynamic>>> _getTrendLogsV1() async {
    _logger.i('_getTrendLogsV1: fetching trend-logs');

    final url = '$baseUrl$_bacnetBasePath/objects/trendLog';

    try {
      final response = await _dio.get(url, options: _authOptions);
      _logger.d('_getTrendLogsV1: status=${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final trendLogs = <Map<String, dynamic>>[];

        if (data is List) {
          _logger.d('_getTrendLogsV1: data is List with ${data.length} items');
          // Liste d'objets ou d'IDs
          for (final item in data) {
            int? instance;
            if (item is int) {
              instance = item;
            } else if (item is Map<String, dynamic>) {
              // Format: {href: "/api/.../300672", name: "trendLog_300672"}
              // Extraire l'instance depuis 'name' ou 'href'
              final name = item['name']?.toString();
              final href = item['href']?.toString();

              if (name != null) {
                // Parser "trendLog_300672" -> 300672
                final match = RegExp(r'_(\d+)$').firstMatch(name);
                if (match != null) {
                  instance = int.tryParse(match.group(1)!);
                }
              }
              if (instance == null && href != null) {
                // Parser "/api/.../trend-log/300672" -> 300672
                final match = RegExp(r'/(\d+)$').firstMatch(href);
                if (match != null) {
                  instance = int.tryParse(match.group(1)!);
                }
              }

              instance ??= item['instance'] ?? item['objectInstance'];

              if (instance != null) {
                trendLogs.add({'instance': instance, ...item});
                continue;
              }
            }

            if (instance != null) {
              trendLogs.add({'instance': instance});
            }
          }
        }

        _logger.i('_getTrendLogsV1: parsed ${trendLogs.length} trend-logs: ${trendLogs.map((t) => t['instance']).toList()}');
        return trendLogs;
      }
    } catch (e) {
      _logger.e('_getTrendLogsV1 error: $e');
    }

    return [];
  }

  /// Récupère les trend-logs V2
  Future<List<Map<String, dynamic>>> _getTrendLogsV2() async {
    _logger.i('_getTrendLogsV2: fetching trend-logs');

    final url = '$baseUrl$_bacnetBasePath/objects/trend-logs';

    try {
      final response = await _dio.get(url, options: _authOptions);
      _logger.d('_getTrendLogsV2: status=${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final trendLogs = <Map<String, dynamic>>[];

        if (data is Map<String, dynamic>) {
          // Format V2: {"1": {...}, "2": {...}}
          data.forEach((key, value) {
            final instance = int.tryParse(key);
            if (instance != null && value is Map<String, dynamic>) {
              trendLogs.add({'instance': instance, ...value});
            }
          });
        } else if (data is List) {
          for (final item in data) {
            if (item is int) {
              trendLogs.add({'instance': item});
            } else if (item is Map<String, dynamic>) {
              trendLogs.add(item);
            }
          }
        }

        return trendLogs;
      }
    } catch (e) {
      _logger.e('_getTrendLogsV2 error: $e');
    }

    return [];
  }

  /// Récupère le mapping trend-log -> objet tracké via read-property-multiple (V1)
  /// Retourne un Map<String, int> où la clé est "objectType:objectInstance" et la valeur est l'instance du trend-log
  Future<Map<String, int>> getTrendLogMapping() async {
    if (apiVersion == 'V2') {
      return _getTrendLogMappingV2();
    }
    return _getTrendLogMappingV1();
  }

  /// Récupère le mapping V1 via read-property-multiple
  Future<Map<String, int>> _getTrendLogMappingV1() async {
    _logger.i('_getTrendLogMappingV1: loading trend log mapping');

    final mapping = <String, int>{};

    // D'abord récupérer la liste des trend-logs
    final trendLogs = await _getTrendLogsV1();
    _logger.i('_getTrendLogMappingV1: got ${trendLogs.length} trend-logs');
    if (trendLogs.isEmpty) {
      _logger.w('_getTrendLogMappingV1: no trend-logs found, returning empty mapping');
      return mapping;
    }

    // Utiliser read-property-multiple pour récupérer log-device-object-property
    final rpmUrl = '$baseUrl$_bacnetBasePath/objects/read-property-multiple';

    final propertyRefs = trendLogs.map((tl) => {
      'type': 'trendLog',
      'instance': tl['instance'],
      'property': 'logDeviceObjectProperty',
      'arrayIndex': -1,
    }).toList();

    _logger.d('_getTrendLogMappingV1: requesting ${propertyRefs.length} properties');

    try {
      final response = await _dio.post(
        rpmUrl,
        data: {
          'encode': 'text',
          'propertyReferences': propertyRefs,
        },
        options: Options(
          headers: {
            'Authorization': basicAuth,
            'Content-Type': 'application/json',
          },
        ),
      );

      _logger.d('_getTrendLogMappingV1: status=${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        List refs;
        if (response.data is List) {
          refs = response.data;
        } else if (response.data is Map<String, dynamic>) {
          refs = response.data['propertyReferences'] as List? ?? [];
        } else {
          refs = [];
        }

        for (final ref in refs) {
          if (ref is! Map<String, dynamic>) continue;

          final instance = ref['instance'];
          final value = ref['value']?.toString() ?? ref['message']?.toString();

          if (instance == null || instance == -1 || value == null) continue;

          // Parser le format "[Analog Value 454,Present Value,,]"
          final match = RegExp(r'\[([^,]+)\s+(\d+),').firstMatch(value);
          if (match != null) {
            final objectTypeRaw = match.group(1)?.trim();
            final objectInstance = int.tryParse(match.group(2) ?? '');

            if (objectTypeRaw != null && objectInstance != null) {
              // Convertir "Analog Value" -> "analog-value"
              final objectType = objectTypeRaw.toLowerCase().replaceAll(RegExp(r'\s+'), '-');
              final key = '$objectType:$objectInstance';
              final trendLogInstance = instance is int ? instance : int.tryParse(instance.toString()) ?? 0;
              mapping[key] = trendLogInstance;
            }
          }
        }
      }
    } catch (e) {
      _logger.e('_getTrendLogMappingV1 error: $e');
    }

    _logger.i('_getTrendLogMappingV1: found ${mapping.length} mappings');
    return mapping;
  }

  /// Récupère le mapping V2
  Future<Map<String, int>> _getTrendLogMappingV2() async {
    _logger.i('_getTrendLogMappingV2: loading trend log mapping');

    final mapping = <String, int>{};

    // En V2, récupérer les trend-logs
    final url = '$baseUrl$_bacnetBasePath/objects/trend-logs';

    try {
      final response = await _dio.get(url, options: _authOptions);

      _logger.d('_getTrendLogMappingV2: status=${response.statusCode}, data type=${response.data?.runtimeType}');
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        _logger.d('_getTrendLogMappingV2: ${data.length} entries, keys=${data.keys.take(3).toList()}');

        data.forEach((key, value) {
          final instance = int.tryParse(key);
          if (instance == null || value is! Map<String, dynamic>) return;

          // En V2, la propriété s'appelle 'source-reference'
          final logProp = value['source-reference'];
          if (logProp == null || logProp is! Map<String, dynamic>) return;

          // Parser le format V2: {object-identifier: {object-type: "AnalogValue", object-instance: 17}}
          String? objectType;
          int? objectInstance;

          final objectId = logProp['object-identifier'];
          if (objectId is Map<String, dynamic>) {
            // Format V2: object-type est en PascalCase (AnalogValue, BinaryInput, etc.)
            final rawType = objectId['object-type']?.toString();
            objectInstance = objectId['object-instance'] as int?;

            // Convertir PascalCase en kebab-case (AnalogValue -> analog-value)
            if (rawType != null) {
              objectType = rawType
                  .replaceAllMapped(RegExp(r'([A-Z])'), (m) => '-${m.group(1)!.toLowerCase()}')
                  .replaceFirst('-', ''); // Enlever le tiret initial
            }
          }

          if (objectType != null && objectInstance != null) {
            final objKey = '$objectType:$objectInstance';
            mapping[objKey] = instance;
            _logger.d('_getTrendLogMappingV2: mapped $objKey -> trend-log $instance');
          }
        });
      }
    } catch (e) {
      _logger.e('_getTrendLogMappingV2 error: $e');
    }

    _logger.i('_getTrendLogMappingV2: found ${mapping.length} mappings');
    return mapping;
  }

  /// Récupère le log buffer d'un trend-log spécifique (V1)
  Future<String?> getTrendLogBuffer(int trendLogInstance) async {
    if (apiVersion == 'V2') {
      return _getTrendLogBufferV2(trendLogInstance);
    }
    return _getTrendLogBufferV1(trendLogInstance);
  }

  /// Récupère le log buffer V1
  /// Note: Le buffer peut être très volumineux, on utilise un timeout plus long
  Future<String?> _getTrendLogBufferV1(int trendLogInstance) async {
    _logger.i('_getTrendLogBufferV1: fetching log-buffer for trend-log $trendLogInstance');

    final url = '$baseUrl$_bacnetBasePath/objects/trendLog/$trendLogInstance/properties/logBuffer';

    try {
      // Timeout plus long pour les gros buffers (5 minutes)
      final response = await _dio.get(
        url,
        options: Options(
          headers: {'Authorization': basicAuth},
          receiveTimeout: const Duration(minutes: 5),
          sendTimeout: const Duration(minutes: 1),
        ),
      );
      _logger.d('_getTrendLogBufferV1: status=${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        // Le buffer peut être dans 'value' ou directement la donnée
        if (response.data is Map<String, dynamic>) {
          final value = response.data['value']?.toString();
          _logger.d('_getTrendLogBufferV1: got ${value?.length ?? 0} chars');
          return value;
        }
        final value = response.data.toString();
        _logger.d('_getTrendLogBufferV1: got ${value.length} chars');
        return value;
      }
    } catch (e) {
      _logger.e('_getTrendLogBufferV1 error: $e');
    }

    return null;
  }

  /// Récupère le log buffer V2 via l'API history
  Future<String?> _getTrendLogBufferV2(int trendLogInstance) async {
    _logger.i('_getTrendLogBufferV2: fetching history for trend-log $trendLogInstance');

    // D'abord récupérer le nom de l'historique depuis le trend-log
    String? historyName;
    try {
      final trendLogUrl = '$baseUrl$_bacnetBasePath/objects/trend-logs/$trendLogInstance';
      final trendLogResponse = await _dio.get(trendLogUrl, options: _authOptions);
      if (trendLogResponse.statusCode == 200 && trendLogResponse.data is Map<String, dynamic>) {
        historyName = trendLogResponse.data['history']?.toString();
        _logger.d('_getTrendLogBufferV2: got history name: $historyName');
      }
    } catch (e) {
      _logger.w('_getTrendLogBufferV2: failed to get history name: $e');
    }

    if (historyName == null || historyName.isEmpty) {
      _logger.w('_getTrendLogBufferV2: no history name found for trend-log $trendLogInstance');
      return null;
    }

    // En V2, utiliser l'API history avec get-history
    final url = '$baseUrl/api/rest/v2/services/history/groups/bacnet/histories/get-history';

    // Calculer la plage de temps (30 derniers jours pour couvrir toutes les périodes UI)
    // Format requis: "2022-01-01T00:00:00/2024-09-25T00:00:00" (sans millisecondes ni timezone)
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 30));
    String formatDate(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}T${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')}';
    final timeRange = '${formatDate(startDate)}/${formatDate(now)}';

    final requestData = {
      'history': historyName,
      'delta': false,
      'time-range': timeRange,
      'interval': null,
      'delta-timestamps': 'Leading',
    };
    _logger.d('_getTrendLogBufferV2: POST $url');
    _logger.d('_getTrendLogBufferV2: body=$requestData');

    try {
      final response = await _dio.post(
        url,
        data: requestData,
        options: Options(
          headers: {
            'Authorization': basicAuth,
            'Content-Type': 'application/json',
          },
        ),
      );

      _logger.d('_getTrendLogBufferV2: status=${response.statusCode}, response=${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        // Retourner les données JSON comme chaîne encodée proprement
        // Format V2: {columns: [...], rows: [...]}
        if (response.data is Map || response.data is List) {
          return jsonEncode(response.data);
        }
        return response.data.toString();
      }
    } catch (e) {
      _logger.e('_getTrendLogBufferV2 error: $e');
    }

    return null;
  }

  /// Récupère l'historique d'un trend-log avec filtre de période (V2 uniquement)
  Future<List<Map<String, dynamic>>?> getTrendLogHistoryV2({
    required int trendLogInstance,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (apiVersion != 'V2') {
      _logger.w('getTrendLogHistoryV2: not supported in V1');
      return null;
    }

    _logger.i('getTrendLogHistoryV2: fetching history for trend-log $trendLogInstance');

    final url = '$baseUrl/api/rest/v2/services/history/groups/bacnet/histories/get-history';
    final timeRange = '${startDate.toIso8601String()}/${endDate.toIso8601String()}';

    try {
      final response = await _dio.post(
        url,
        data: {
          'history': 'trend-log-$trendLogInstance',
          'delta': false,
          'time-range': timeRange,
          'interval': null,
          'delta-timestamps': 'Leading',
        },
        options: Options(
          headers: {
            'Authorization': basicAuth,
            'Content-Type': 'application/json',
          },
        ),
      );

      _logger.d('getTrendLogHistoryV2: status=${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        if (response.data is List) {
          return (response.data as List).cast<Map<String, dynamic>>();
        }
      }
    } catch (e) {
      _logger.e('getTrendLogHistoryV2 error: $e');
    }

    return null;
  }

  /// Récupère le trend (historique) d'un point spécifique (V1)
  /// Endpoint: /objects/{type}/{instance}/trend?dataOnly=true
  Future<String?> getPointTrendV1(BacnetObjectType type, int instance) async {
    if (apiVersion != 'V1') {
      _logger.w('getPointTrendV1: only supported in V1');
      return null;
    }

    final typeName = _objectTypeToCamelCase(type);
    final url = '$baseUrl$_bacnetBasePath/objects/$typeName/$instance/trend?dataOnly=true';

    _logger.i('getPointTrendV1: GET $url');

    try {
      final response = await _dio.get(url, options: _authOptions);
      _logger.d('getPointTrendV1: status=${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        return response.data.toString();
      }
    } catch (e) {
      _logger.e('getPointTrendV1 error: $e');
    }

    return null;
  }

  // ============ Méthodes Schedule ============

  /// Récupère la liste des schedules
  Future<List<ScheduleSummary>> getSchedules() async {
    if (apiVersion == 'V2') {
      return _getSchedulesV2();
    }
    return _getSchedulesV1();
  }

  /// Récupère les schedules V1
  Future<List<ScheduleSummary>> _getSchedulesV1() async {
    _logger.i('_getSchedulesV1: fetching schedules');

    // D'abord récupérer la liste des instances
    final listUrl = '$baseUrl$_bacnetBasePath/objects/schedule';

    try {
      final listResponse = await _dio.get(listUrl, options: _authOptions);
      _logger.d('_getSchedulesV1: list status=${listResponse.statusCode}');

      if (listResponse.statusCode != 200 || listResponse.data == null) {
        return [];
      }

      final schedules = <ScheduleSummary>[];
      final instances = <int>[];

      // Parser la liste des instances
      if (listResponse.data is List) {
        for (final item in listResponse.data) {
          if (item is int) {
            instances.add(item);
          } else if (item is Map<String, dynamic>) {
            // Format: {href: "/api/.../schedule/1", name: "schedule_1"}
            final href = item['href']?.toString();
            if (href != null) {
              final match = RegExp(r'/(\d+)$').firstMatch(href);
              if (match != null) {
                instances.add(int.parse(match.group(1)!));
              }
            }
          }
        }
      }

      _logger.i('_getSchedulesV1: found ${instances.length} schedules: $instances');

      // Utiliser read-property-multiple pour récupérer les infos de base
      if (instances.isNotEmpty) {
        final rpmUrl = '$baseUrl$_bacnetBasePath/objects/read-property-multiple';
        final propertyRefs = <Map<String, dynamic>>[];

        for (final instance in instances) {
          propertyRefs.add({
            'type': 'schedule',
            'instance': instance,
            'property': 'objectName',
            'arrayIndex': -1,
          });
          propertyRefs.add({
            'type': 'schedule',
            'instance': instance,
            'property': 'presentValue',
            'arrayIndex': -1,
          });
          propertyRefs.add({
            'type': 'schedule',
            'instance': instance,
            'property': 'description',
            'arrayIndex': -1,
          });
        }

        final rpmResponse = await _dio.post(
          rpmUrl,
          data: {
            'encode': 'text',
            'propertyReferences': propertyRefs,
          },
          options: Options(
            headers: {
              'Authorization': basicAuth,
              'Content-Type': 'application/json',
            },
          ),
        );

        if (rpmResponse.statusCode == 200 && rpmResponse.data != null) {
          // Grouper les propriétés par instance
          final propsById = <int, Map<String, dynamic>>{};

          List refs;
          if (rpmResponse.data is List) {
            refs = rpmResponse.data;
          } else if (rpmResponse.data is Map<String, dynamic>) {
            refs = rpmResponse.data['propertyReferences'] as List? ?? [];
          } else {
            refs = [];
          }

          for (final ref in refs) {
            if (ref is! Map<String, dynamic>) continue;
            final instance = ref['instance'];
            if (instance == null || instance == -1) continue;

            final instanceInt = instance is int ? instance : int.tryParse(instance.toString()) ?? 0;
            propsById.putIfAbsent(instanceInt, () => {});

            final property = ref['property'] as String? ?? '';
            final value = ref['value'] ?? ref['message'];
            propsById[instanceInt]![property] = value;
          }

          for (final instance in instances) {
            final props = propsById[instance] ?? {};
            schedules.add(ScheduleSummary(
              instance: instance,
              objectName: _extractStringValue(props['objectName']) ?? 'Schedule $instance',
              description: _extractStringValue(props['description']),
              presentValue: props['presentValue'],
              valueType: ScheduleValueType.fromValue(props['presentValue']),
            ));
          }
        }
      }

      return schedules;
    } catch (e) {
      _logger.e('_getSchedulesV1 error: $e');
      return [];
    }
  }

  /// Récupère les schedules V2
  Future<List<ScheduleSummary>> _getSchedulesV2() async {
    _logger.i('_getSchedulesV2: fetching schedules');

    final url = '$baseUrl$_bacnetBasePath/objects/schedules';

    try {
      final response = await _dio.get(url, options: _authOptions);
      _logger.d('_getSchedulesV2: status=${response.statusCode}');
      _logger.d('_getSchedulesV2: response type=${response.data.runtimeType}');
      _logger.d('_getSchedulesV2: response data=${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        final schedules = <ScheduleSummary>[];

        if (response.data is Map<String, dynamic>) {
          final data = response.data as Map<String, dynamic>;
          _logger.d('_getSchedulesV2: data keys=${data.keys.toList()}');
          data.forEach((key, value) {
            final instance = int.tryParse(key);
            _logger.d('_getSchedulesV2: key=$key, instance=$instance, value type=${value.runtimeType}');
            if (instance != null && value is Map<String, dynamic>) {
              schedules.add(ScheduleSummary.fromV2(instance, value));
            }
          });
        }

        _logger.i('_getSchedulesV2: found ${schedules.length} schedules');
        return schedules;
      }
    } catch (e) {
      _logger.e('_getSchedulesV2 error: $e');
    }

    return [];
  }

  /// Récupère un schedule complet avec son planning hebdomadaire
  Future<Schedule?> getScheduleDetail(int instance) async {
    if (apiVersion == 'V2') {
      return _getScheduleDetailV2(instance);
    }
    return _getScheduleDetailV1(instance);
  }

  /// Récupère un schedule V1
  Future<Schedule?> _getScheduleDetailV1(int instance) async {
    _logger.i('_getScheduleDetailV1: fetching schedule $instance');

    try {
      // Récupérer les propriétés principales via read-property-multiple
      final rpmUrl = '$baseUrl$_bacnetBasePath/objects/read-property-multiple';
      final propertyRefs = [
        {'type': 'schedule', 'instance': instance, 'property': 'objectName', 'arrayIndex': -1},
        {'type': 'schedule', 'instance': instance, 'property': 'description', 'arrayIndex': -1},
        {'type': 'schedule', 'instance': instance, 'property': 'presentValue', 'arrayIndex': -1},
        {'type': 'schedule', 'instance': instance, 'property': 'scheduleDefault', 'arrayIndex': -1},
        {'type': 'schedule', 'instance': instance, 'property': 'stateTextReference', 'arrayIndex': -1},
      ];

      final rpmResponse = await _dio.post(
        rpmUrl,
        data: {'encode': 'text', 'propertyReferences': propertyRefs},
        options: Options(
          headers: {'Authorization': basicAuth, 'Content-Type': 'application/json'},
        ),
      );

      String objectName = 'Schedule $instance';
      String? description;
      dynamic presentValue;
      dynamic scheduleDefault;

      if (rpmResponse.statusCode == 200 && rpmResponse.data != null) {
        List refs;
        if (rpmResponse.data is List) {
          refs = rpmResponse.data;
        } else if (rpmResponse.data is Map<String, dynamic>) {
          refs = rpmResponse.data['propertyReferences'] as List? ?? [];
        } else {
          refs = [];
        }

        for (final ref in refs) {
          if (ref is! Map<String, dynamic>) continue;
          if (ref['instance'] == -1) continue;

          final property = ref['property'] as String? ?? '';
          final value = ref['value'] ?? ref['message'];

          switch (property) {
            case 'objectName':
              objectName = _extractStringValue(value) ?? objectName;
              break;
            case 'description':
              description = _extractStringValue(value);
              break;
            case 'presentValue':
              presentValue = value;
              break;
            case 'scheduleDefault':
              scheduleDefault = value;
              break;
          }
        }
      }

      // Récupérer le weekly-schedule
      final weeklyUrl = '$baseUrl$_bacnetBasePath/objects/schedule/$instance/properties/weekly-schedule';
      final weeklyResponse = await _dio.get(weeklyUrl, options: _authOptions);

      WeeklySchedule weeklySchedule = WeeklySchedule.empty();
      if (weeklyResponse.statusCode == 200 && weeklyResponse.data != null) {
        weeklySchedule = WeeklySchedule.fromV1(weeklyResponse.data as Map<String, dynamic>);
      }

      // Récupérer les state-texts
      final stateTexts = await _getScheduleStateTextsV1(instance);

      // Déterminer le type de valeur
      final valueType = ScheduleValueType.fromValue(presentValue);

      return Schedule(
        instance: instance,
        objectName: objectName,
        description: description,
        weeklySchedule: weeklySchedule,
        stateTexts: stateTexts,
        valueType: valueType,
        presentValue: presentValue,
        scheduleDefault: scheduleDefault,
      );
    } catch (e) {
      _logger.e('_getScheduleDetailV1 error: $e');
      return null;
    }
  }

  /// Récupère les state-texts d'un schedule V1
  /// Format V1: {value: "{Hors_Gel;Enumerated:1,Reduit;Enumerated:2,Confort;Enumerated:3}"}
  Future<List<ScheduleStateText>> _getScheduleStateTextsV1(int instance) async {
    final stateTexts = <ScheduleStateText>[];

    try {
      // Endpoint correct pour V1
      final url = '$baseUrl$_bacnetBasePath/objects/schedule/$instance/properties/schedule-state-text';
      final response = await _dio.get(url, options: _authOptions);

      _logger.d('_getScheduleStateTextsV1: response=${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;

        String? valueStr;
        if (data is Map<String, dynamic>) {
          final value = data['value'];
          if (value is String) {
            valueStr = value;
          } else if (value is List) {
            // Format liste simple
            for (int i = 0; i < value.length; i++) {
              stateTexts.add(ScheduleStateText(index: i, text: value[i].toString()));
            }
          }
        } else if (data is String) {
          valueStr = data;
        }

        // Parser le format V1: "{Label1;Enumerated:1,Label2;Enumerated:2,...}"
        if (valueStr != null && valueStr.isNotEmpty) {
          stateTexts.addAll(_parseScheduleStateTextV1(valueStr));
        }
      }
    } catch (e) {
      _logger.w('_getScheduleStateTextsV1: error fetching state texts: $e');
    }

    // Si pas de state-texts, retourner des valeurs par défaut pour boolean
    if (stateTexts.isEmpty) {
      stateTexts.add(ScheduleStateText(index: 0, text: 'Inactif'));
      stateTexts.add(ScheduleStateText(index: 1, text: 'Actif'));
    }

    return stateTexts;
  }

  /// Parse le format V1 des state-texts
  /// Format: "{Hors_Gel;Enumerated:1,Reduit;Enumerated:2,Confort;Enumerated:3,Vacances;Enumerated:4}"
  List<ScheduleStateText> _parseScheduleStateTextV1(String value) {
    final stateTexts = <ScheduleStateText>[];

    // Enlever les accolades
    String cleaned = value.trim();
    if (cleaned.startsWith('{')) cleaned = cleaned.substring(1);
    if (cleaned.endsWith('}')) cleaned = cleaned.substring(0, cleaned.length - 1);

    if (cleaned.isEmpty) return stateTexts;

    // Séparer par virgules : "Hors_Gel;Enumerated:1,Reduit;Enumerated:2,..."
    final entries = cleaned.split(',');

    for (final entry in entries) {
      final trimmed = entry.trim();
      if (trimmed.isEmpty) continue;

      // Format: "Label;Enumerated:index" ou "Label;Type:index"
      final semiColonIndex = trimmed.indexOf(';');
      if (semiColonIndex > 0) {
        final label = trimmed.substring(0, semiColonIndex).trim();
        final typeAndIndex = trimmed.substring(semiColonIndex + 1).trim();

        // Extraire l'index après le ":"
        final colonIndex = typeAndIndex.indexOf(':');
        if (colonIndex > 0) {
          final indexStr = typeAndIndex.substring(colonIndex + 1).trim();
          final index = int.tryParse(indexStr);
          if (index != null) {
            // Remplacer les underscores par des espaces dans le label
            final displayLabel = label.replaceAll('_', ' ');
            stateTexts.add(ScheduleStateText(index: index, text: displayLabel));
            _logger.d('_parseScheduleStateTextV1: parsed state $index = "$displayLabel"');
          }
        }
      }
    }

    // Trier par index
    stateTexts.sort((a, b) => a.index.compareTo(b.index));

    return stateTexts;
  }

  /// Récupère un schedule V2
  Future<Schedule?> _getScheduleDetailV2(int instance) async {
    _logger.i('_getScheduleDetailV2: fetching schedule $instance');

    try {
      // Récupérer les propriétés principales (sans $select qui cause des problèmes)
      final url = '$baseUrl$_bacnetBasePath/objects/schedules/$instance';
      final response = await _dio.get(url, options: _authOptions);

      if (response.statusCode != 200 || response.data == null) {
        return null;
      }

      final data = response.data as Map<String, dynamic>;
      _logger.d('_getScheduleDetailV2: data keys=${data.keys.toList()}');

      final objectName = data['object-name']?.toString() ?? 'Schedule $instance';
      final description = data['description']?.toString();
      final presentValue = data['present-value'];
      final scheduleDefault = data['schedule-default'];

      // Parser les state-texts (V2 utilise 'schedule-state-text')
      final stateTexts = <ScheduleStateText>[];
      final stateTextData = data['schedule-state-text'];
      _logger.d('_getScheduleDetailV2: schedule-state-text=$stateTextData');

      if (stateTextData is List) {
        // V2: [{string: "Hors gel", value: 1}, {string: "Vacances", value: 2}, ...]
        for (final item in stateTextData) {
          if (item is Map<String, dynamic>) {
            final value = item['value'];
            final text = item['string']?.toString();
            if (value is int && text != null) {
              stateTexts.add(ScheduleStateText(index: value, text: text));
            }
          }
        }
      } else if (stateTextData is Map<String, dynamic>) {
        stateTextData.forEach((key, value) {
          final index = int.tryParse(key);
          if (index != null) {
            final text = value is Map ? value['\$value']?.toString() : value?.toString();
            stateTexts.add(ScheduleStateText(index: index, text: text ?? 'État $index'));
          }
        });
      }

      _logger.d('_getScheduleDetailV2: parsed stateTexts=${stateTexts.length}');

      // Valeurs par défaut si vide
      if (stateTexts.isEmpty) {
        stateTexts.add(ScheduleStateText(index: 0, text: 'Inoccupé'));
        stateTexts.add(ScheduleStateText(index: 1, text: 'Occupé'));
      }

      // Récupérer le weekly-schedule
      final weeklyUrl = '$baseUrl$_bacnetBasePath/objects/schedules/$instance/weekly-schedule';
      final weeklyResponse = await _dio.get(weeklyUrl, options: _authOptions);

      WeeklySchedule weeklySchedule = WeeklySchedule.empty();
      if (weeklyResponse.statusCode == 200 && weeklyResponse.data != null) {
        weeklySchedule = WeeklySchedule.fromV2(weeklyResponse.data as Map<String, dynamic>);
      }

      return Schedule(
        instance: instance,
        objectName: objectName,
        description: description,
        weeklySchedule: weeklySchedule,
        stateTexts: stateTexts,
        valueType: ScheduleValueType.fromValue(presentValue),
        presentValue: presentValue,
        scheduleDefault: scheduleDefault,
      );
    } catch (e) {
      _logger.e('_getScheduleDetailV2 error: $e');
      return null;
    }
  }

  /// Écrit le planning hebdomadaire d'un schedule
  Future<bool> writeWeeklySchedule(int instance, WeeklySchedule weeklySchedule) async {
    if (apiVersion == 'V2') {
      return _writeWeeklyScheduleV2(instance, weeklySchedule);
    }
    return _writeWeeklyScheduleV1(instance, weeklySchedule);
  }

  /// Écrit le weekly-schedule V1
  Future<bool> _writeWeeklyScheduleV1(int instance, WeeklySchedule weeklySchedule) async {
    _logger.i('_writeWeeklyScheduleV1: writing schedule $instance');

    final url = '$baseUrl$_bacnetBasePath/objects/schedule/$instance/properties/weekly-schedule';
    final body = weeklySchedule.toV1Json();

    _logger.d('_writeWeeklyScheduleV1: body=$body');

    try {
      final response = await _dio.post(
        url,
        data: body,
        options: Options(
          headers: {
            'Authorization': basicAuth,
            'Content-Type': 'application/json',
          },
        ),
      );

      _logger.i('_writeWeeklyScheduleV1: status=${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      _logger.e('_writeWeeklyScheduleV1 error: $e');
      return false;
    }
  }

  /// Écrit le weekly-schedule V2
  Future<bool> _writeWeeklyScheduleV2(int instance, WeeklySchedule weeklySchedule) async {
    _logger.i('_writeWeeklyScheduleV2: writing schedule $instance');

    final url = '$baseUrl$_bacnetBasePath/objects/schedules/$instance/weekly-schedule';
    final body = weeklySchedule.toV2Json();

    _logger.d('_writeWeeklyScheduleV2: url=$url');
    _logger.d('_writeWeeklyScheduleV2: body=$body');

    try {
      final response = await _dio.post(
        url,
        data: body,
        options: Options(
          headers: {
            'Authorization': basicAuth,
            'Content-Type': 'application/json',
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      _logger.i('_writeWeeklyScheduleV2: status=${response.statusCode}');

      if (response.statusCode == 400) {
        _logger.e('_writeWeeklyScheduleV2: 400 Bad Request - response=${response.data}');
        return false;
      }

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      if (e is DioException) {
        _logger.e('_writeWeeklyScheduleV2 DioException: ${e.message}');
        _logger.e('_writeWeeklyScheduleV2 response: ${e.response?.data}');
      } else {
        _logger.e('_writeWeeklyScheduleV2 error: $e');
      }
      return false;
    }
  }

  /// Ferme le client
  void dispose() {
    _dio.close();
  }
}
