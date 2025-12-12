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

  /// Récupère la date et l'heure de l'automate
  /// Retourne un ControllerTime avec l'heure de l'automate et le décalage avec l'heure locale
  Future<ControllerTime> getControllerTime() async {
    if (apiVersion == 'V1') {
      return await _getControllerTimeV1();
    }
    return await _getControllerTimeV2();
  }

  /// Récupère l'heure de l'automate via API V2
  Future<ControllerTime> _getControllerTimeV2() async {
    final url = '$baseUrl/api/rest/v2/services/platform/time';
    _logger.i('_getControllerTimeV2: GET $url');

    try {
      final response = await _dio.get(url, options: _authOptions);
      _logger.d('_getControllerTimeV2: response=${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;

        // Format V2: {"date-time": "2025-12-01T14:32:15", "utc-offset": 60, ...}
        // ou {"dateTime": "...", "utcOffset": ...}
        String? dateTimeStr = data['date-time'] ?? data['dateTime'] ?? data['local-date-time'];

        // Si pas de date-time direct, essayer date + time séparés
        if (dateTimeStr == null) {
          final date = data['date'] ?? data['local-date'];
          final time = data['time'] ?? data['local-time'];
          if (date != null && time != null) {
            dateTimeStr = '${date}T$time';
          }
        }

        if (dateTimeStr != null) {
          final controllerDateTime = DateTime.tryParse(dateTimeStr);
          if (controllerDateTime != null) {
            return ControllerTime.fromDateTime(controllerDateTime);
          }
        }
      }
    } catch (e) {
      _logger.w('_getControllerTimeV2: error: $e');
    }

    // Essayer l'endpoint alternatif
    try {
      final altUrl = '$baseUrl/api/rest/v2/services/platform/time/date-time';
      _logger.i('_getControllerTimeV2: trying alternate GET $altUrl');
      final response = await _dio.get(altUrl, options: _authOptions);

      if (response.statusCode == 200 && response.data != null) {
        final dateTimeStr = response.data.toString();
        final controllerDateTime = DateTime.tryParse(dateTimeStr);
        if (controllerDateTime != null) {
          return ControllerTime.fromDateTime(controllerDateTime);
        }
      }
    } catch (e) {
      _logger.w('_getControllerTimeV2: alternate endpoint error: $e');
    }

    throw Exception('Impossible de récupérer l\'heure de l\'automate');
  }

  /// Récupère l'heure de l'automate via API V1 (BACnet Device object)
  Future<ControllerTime> _getControllerTimeV1() async {
    final rpmUrl = '$baseUrl$_bacnetBasePath/objects/read-property-multiple';
    _logger.i('_getControllerTimeV1: POST $rpmUrl');

    try {
      // Lire localTime et localDate depuis l'objet Device
      final body = {
        'encode': 'text',
        'propertyReferences': [
          {'type': 'device', 'instance': -1, 'property': 'localTime', 'arrayIndex': -1},
          {'type': 'device', 'instance': -1, 'property': 'localDate', 'arrayIndex': -1},
        ],
      };

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

      _logger.d('_getControllerTimeV1: response=${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        String? localTime;
        String? localDate;

        // Parser la réponse RPM
        final refs = response.data is List
            ? response.data
            : (response.data['propertyReferences'] as List? ?? []);

        for (final ref in refs) {
          if (ref is! Map<String, dynamic>) continue;
          final property = ref['property'] as String?;
          var value = ref['value'] ?? ref['message'];

          // Extraire la valeur du Map si nécessaire
          if (value is Map) {
            value = value['value'] ?? value['\$value'] ?? value.values.firstOrNull;
          }

          if (property == 'localTime' && value != null) {
            localTime = value.toString();
          } else if (property == 'localDate' && value != null) {
            localDate = value.toString();
          }
        }

        _logger.i('_getControllerTimeV1: localDate=$localDate, localTime=$localTime');

        if (localDate != null && localTime != null) {
          // Parser les formats BACnet
          // Date: peut être "2025-12-01", "Mon, 01 Dec 2025", etc.
          // Time: peut être "14:32:15", "14:32:15.000", etc.
          final dateTime = _parseBacnetDateTime(localDate, localTime);
          if (dateTime != null) {
            return ControllerTime.fromDateTime(dateTime);
          }
        }
      }
    } catch (e) {
      _logger.w('_getControllerTimeV1: error: $e');
    }

    throw Exception('Impossible de récupérer l\'heure de l\'automate V1');
  }

  /// Met à jour la date et l'heure de l'automate (synchronise avec l'heure locale)
  /// Disponible uniquement pour API V1
  /// Retourne true si la mise à jour a réussi
  Future<bool> setControllerTime(DateTime dateTime) async {
    if (apiVersion == 'V1') {
      return await _setControllerTimeV1(dateTime);
    }
    // API V2 ne supporte pas la modification de l'heure via REST
    throw UnsupportedError('La modification de l\'heure n\'est pas disponible via l\'API V2. '
        'Utilisez l\'interface web EC-NetAX ou configurez le NTP.');
  }

  /// Met à jour l'heure de l'automate via API V1
  /// POST /api/rest/v1/system/date-time
  Future<bool> _setControllerTimeV1(DateTime dateTime) async {
    final url = '$baseUrl/api/rest/v1/system/date-time';
    _logger.i('_setControllerTimeV1: POST $url');

    // Format attendu par l'API V1:
    // - date: "MM-dd-yyyy" (ex: "12-10-2025")
    // - time: "HH:mm:ss" (ex: "14:30:00")
    final dateStr = '${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')}-'
        '${dateTime.year}';
    final timeStr = '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}:'
        '${dateTime.second.toString().padLeft(2, '0')}';

    final body = {
      'date': dateStr,
      'time': timeStr,
    };

    _logger.d('_setControllerTimeV1: body=$body');

    try {
      final response = await _dio.post(
        url,
        data: body,
        options: Options(
          headers: {
            'Authorization': basicAuth,
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      _logger.i('_setControllerTimeV1: response status=${response.statusCode}');

      // Succès si status 200 ou 204
      if (response.statusCode == 200 || response.statusCode == 204) {
        _logger.i('_setControllerTimeV1: Heure mise à jour avec succès');
        return true;
      }

      _logger.w('_setControllerTimeV1: Échec, status=${response.statusCode}');
      return false;
    } catch (e) {
      _logger.e('_setControllerTimeV1: Erreur: $e');
      rethrow;
    }
  }

  /// Vérifie si la modification de l'heure est supportée
  bool get canSetControllerTime => apiVersion == 'V1';

  /// Récupère les informations réseau de l'automate
  /// API V1: GET /api/rest/v1/info/network/adapters/ethernet
  /// API V2: GET /api/rest/v2/services/platform/network/interfaces
  Future<NetworkInfo?> getNetworkInfo() async {
    if (apiVersion == 'V1') {
      return await _getNetworkInfoV1();
    }
    return await _getNetworkInfoV2();
  }

  /// Récupère les infos réseau pour API V1
  Future<NetworkInfo?> _getNetworkInfoV1() async {
    final url = '$baseUrl/api/rest/v1/info/network/adapters/ethernet';
    _logger.i('_getNetworkInfoV1: GET $url');

    try {
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Authorization': basicAuth,
            'Accept': 'application/json',
          },
        ),
      );

      _logger.i('_getNetworkInfoV1: status=${response.statusCode}');
      _logger.d('_getNetworkInfoV1: data=${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          return NetworkInfo.fromJsonV1(data);
        }
      }

      return null;
    } catch (e) {
      _logger.w('_getNetworkInfoV1: Erreur: $e');
      return null;
    }
  }

  /// Récupère les infos réseau pour API V2
  /// Récupère toutes les interfaces : bridge, primary, secondary, wireless
  Future<NetworkInfo?> _getNetworkInfoV2() async {
    final url = '$baseUrl/api/rest/v2/services/platform/network/interfaces';
    _logger.i('_getNetworkInfoV2: GET $url');

    try {
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Authorization': basicAuth,
            'Accept': 'application/json',
          },
        ),
      );

      _logger.i('_getNetworkInfoV2: status=${response.statusCode}');
      _logger.d('_getNetworkInfoV2: data=${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          return NetworkInfo.fromJsonV2(data);
        }
      }

      return null;
    } catch (e) {
      _logger.w('_getNetworkInfoV2: Erreur: $e');
      return null;
    }
  }

  /// Parse une date et heure BACnet en DateTime
  DateTime? _parseBacnetDateTime(String dateStr, String timeStr) {
    try {
      // Nettoyer le temps (enlever les millisecondes si présentes)
      String cleanTime = timeStr.split('.').first;

      // Nettoyer la date (enlever le jour de la semaine si présent)
      // Format V1: "2025-12-01-Mon" -> "2025-12-01"
      String cleanDate = dateStr;
      final dashParts = dateStr.split('-');
      if (dashParts.length == 4) {
        // Format YYYY-MM-DD-Day, garder seulement les 3 premières parties
        cleanDate = '${dashParts[0]}-${dashParts[1]}-${dashParts[2]}';
      }

      // Essayer le format ISO standard
      final isoStr = '${cleanDate}T$cleanTime';
      final parsed = DateTime.tryParse(isoStr);
      if (parsed != null) return parsed;

      // Essayer de parser la date séparément
      // Format possible: "Mon, 01 Dec 2025" ou "01/12/2025" ou "2025-12-01"
      DateTime? date;

      // Format ISO
      date = DateTime.tryParse(cleanDate);

      // Format DD/MM/YYYY
      if (date == null) {
        final parts = cleanDate.split('/');
        if (parts.length == 3) {
          date = DateTime.tryParse('${parts[2]}-${parts[1]}-${parts[0]}');
        }
      }

      if (date == null) return null;

      // Parser l'heure
      final timeParts = cleanTime.split(':');
      if (timeParts.length >= 2) {
        final hour = int.tryParse(timeParts[0]) ?? 0;
        final minute = int.tryParse(timeParts[1]) ?? 0;
        final second = timeParts.length > 2 ? (int.tryParse(timeParts[2]) ?? 0) : 0;

        return DateTime(date.year, date.month, date.day, hour, minute, second);
      }

      return date;
    } catch (e) {
      _logger.w('_parseBacnetDateTime: error parsing $dateStr $timeStr: $e');
      return null;
    }
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

    // Types multistate (ont state-text)
    const multistateTypes = [
      'multistateInput', 'multistateOutput', 'multistateValue',
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
      // Ajouter statusFlags pour détecter les alarmes
      propertyRefs.add({
        'type': typeName,
        'instance': -1,
        'property': 'statusFlags',
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

      // Ajouter stateText pour les types multistate
      if (multistateTypes.contains(typeName)) {
        propertyRefs.add({
          'type': typeName,
          'instance': -1,
          'property': 'stateText',
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

          // Parser state-text pour les multistate
          List<String>? stateText;
          final stateTextRaw = props['state-text'];
          if (stateTextRaw is List) {
            stateText = stateTextRaw.map((e) => e?.toString() ?? '').toList();
          }

          // Parser status-flags pour in-alarm
          final statusFlags = props['status-flags'];
          bool inAlarm = false;
          if (statusFlags is Map<String, dynamic>) {
            inAlarm = statusFlags['in-alarm'] == true;
          }

          // Parser les informations d'alarme
          DateTime? alarmTimestamp;
          String? alarmMessage;
          final alarmData = props['alarm'];
          if (alarmData is Map<String, dynamic> && inAlarm) {
            // Parser le timestamp de l'événement
            final eventTimeStamps = alarmData['event-time-stamps'];
            if (eventTimeStamps is Map<String, dynamic>) {
              alarmTimestamp = _parseAlarmTimestamp(eventTimeStamps);
            }
            // Parser le message d'alarme
            final eventMessages = alarmData['event-message-texts'];
            if (eventMessages is Map<String, dynamic>) {
              alarmMessage = eventMessages['to-off-normal']?.toString() ??
                            eventMessages['to-fault']?.toString();
            }
          }

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
            stateText: stateText,
            inAlarm: inAlarm,
            alarmTimestamp: alarmTimestamp,
            alarmMessage: alarmMessage,
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
  /// et convertit le nom BACnet en symbole court (ex: DegreesCelsius -> °C)
  String? _extractUnitsV2(dynamic units) {
    if (units == null) return null;
    String? unitStr;
    if (units is String) {
      unitStr = units.isEmpty ? null : units;
    } else if (units is Map) {
      unitStr = units['\$value']?.toString() ?? units['value']?.toString();
    } else {
      unitStr = units.toString();
    }
    if (unitStr == null) return null;
    return BacnetObject.convertUnitSymbol(unitStr);
  }

  /// Parse le timestamp d'alarme depuis event-time-stamps
  /// Format: {"to-off-normal": {"date-time": {"date": {...}, "time": "HH:mm:ss.cc"}}}
  DateTime? _parseAlarmTimestamp(Map<String, dynamic> eventTimeStamps) {
    // Essayer d'abord to-off-normal, puis to-fault
    final timestamps = eventTimeStamps['to-off-normal'] ?? eventTimeStamps['to-fault'];
    if (timestamps == null) return null;

    try {
      Map<String, dynamic>? dateTime;
      if (timestamps is Map<String, dynamic>) {
        dateTime = timestamps['date-time'] as Map<String, dynamic>?;
      }
      if (dateTime == null) return null;

      final dateData = dateTime['date'];
      if (dateData is! Map<String, dynamic>) return null;

      // Vérifier que la date n'est pas un wildcard (****)
      final year = dateData['year'];
      final month = dateData['month'];
      final day = dateData['day-of-month'];

      if (year == null || month == null || day == null) return null;

      // Parser le temps
      final timeStr = dateTime['time']?.toString();
      int hour = 0, minute = 0, second = 0;
      if (timeStr != null && !timeStr.contains('**')) {
        final timeParts = timeStr.split(':');
        if (timeParts.isNotEmpty) hour = int.tryParse(timeParts[0]) ?? 0;
        if (timeParts.length > 1) minute = int.tryParse(timeParts[1]) ?? 0;
        if (timeParts.length > 2) {
          // Le format peut être "ss.cc" ou juste "ss"
          final secStr = timeParts[2].split('.')[0];
          second = int.tryParse(secStr) ?? 0;
        }
      }

      return DateTime(year as int, month as int, day as int, hour, minute, second);
    } catch (e) {
      _logger.w('_parseAlarmTimestamp: failed to parse: $e');
      return null;
    }
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

        // Parser stateText pour les multistate (V1)
        List<String>? stateText;
        final stateTextData = props['stateText'];
        if (stateTextData != null) {
          stateText = _parseStateTextV1(stateTextData);
        }

        // Parser status-flags pour in-alarm (V1 format: "[inAlarm,fault,overridden,outOfService]")
        // Les flags actifs ont leur nom, les inactifs sont vides
        // Ex: "[inAlarm,,,outOfService]" = in-alarm et out-of-service actifs
        // Ex: "[,,,]" = aucun flag actif
        bool inAlarm = false;
        final statusFlagsData = props['statusFlags'];
        if (statusFlagsData is Map<String, dynamic>) {
          inAlarm = statusFlagsData['inAlarm'] == true || statusFlagsData['in-alarm'] == true;
        } else if (statusFlagsData is String) {
          // Format V1: "[inAlarm,fault,overridden,outOfService]"
          // Le premier élément est inAlarm
          inAlarm = statusFlagsData.toLowerCase().contains('inalarm');
        }

        result.add(BacnetObject(
          type: objectType,
          instance: instance,
          objectName: _extractStringValue(props['objectName']) ?? '$typeName-$instance',
          presentValue: _parseValue(props['presentValue']),
          units: _extractUnitsV2(props['units']),
          outOfService: _extractBoolValue(props['outOfService']),
          description: _extractStringValue(props['description']),
          priorityArrayRaw: priorityArrayRaw,
          isOverridden: overrideInfo.isOverridden,
          overridePriority: overrideInfo.priority,
          overrideValue: overrideInfo.value,
          activeText: _extractStringValue(props['activeText']),
          inactiveText: _extractStringValue(props['inactiveText']),
          stateText: stateText,
          inAlarm: inAlarm,
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

  /// Parse le state-text format V1
  /// Peut être une liste, une chaîne "{text1, text2, ...}" ou un Map avec 'value'
  List<String>? _parseStateTextV1(dynamic data) {
    if (data == null) return null;

    // Si c'est déjà une liste
    if (data is List) {
      return data.map((e) => e?.toString() ?? '').toList();
    }

    // Si c'est un Map avec 'value'
    String? valueStr;
    if (data is Map) {
      valueStr = data['value']?.toString();
    } else if (data is String) {
      valueStr = data;
    }

    if (valueStr == null || valueStr.isEmpty) return null;

    // Parser le format "{text1, text2, text3}"
    String cleaned = valueStr.trim();
    if (cleaned.startsWith('{')) cleaned = cleaned.substring(1);
    if (cleaned.endsWith('}')) cleaned = cleaned.substring(0, cleaned.length - 1);

    if (cleaned.isEmpty) return null;

    // Séparer par virgules
    return cleaned.split(',').map((e) => e.trim()).toList();
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

  /// Écrit la description d'un objet BACnet
  Future<bool> writeDescription(BacnetObjectType type, int instance, String description) async {
    if (apiVersion == 'V2') {
      return _writePropertyV2(type, instance, 'description', description);
    }
    return _writePropertyV1(type, instance, 'description', description);
  }

  /// Écrit une propriété quelconque sur un objet (V1)
  Future<bool> _writePropertyV1(BacnetObjectType type, int instance, String property, dynamic value) async {
    final url = '$baseUrl$_bacnetBasePath/objects/write-property-multiple';
    final typeName = _objectTypeToCamelCase(type);

    final body = {
      'encode': 'text',
      'propertyReferences': [
        {
          'type': typeName,
          'instance': instance,
          'property': property,
          'value': value.toString(),
        }
      ],
    };

    _logger.i('_writePropertyV1: POST $url property=$property, value=$value');

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

      _logger.i('_writePropertyV1: status=${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      _logger.e('_writePropertyV1 error: $e');
      return false;
    }
  }

  /// Écrit une propriété quelconque sur un objet (V2)
  /// Utilise write-property-multiple avec property-references (format V2)
  Future<bool> _writePropertyV2(BacnetObjectType type, int instance, String property, dynamic value) async {
    final url = '$baseUrl$_bacnetBasePath/objects/write-property-multiple';
    final typeName = _objectTypeToCamelCase(type);

    final body = {
      'encode': 'text',
      'property-references': [
        {
          'type': typeName,
          'instance': instance,
          'property': property,
          'value': value.toString(),
        }
      ],
    };

    _logger.i('_writePropertyV2: POST $url property=$property, value=$value');

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

      _logger.i('_writePropertyV2: status=${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      _logger.e('_writePropertyV2 error: $e');
      return false;
    }
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
  /// Si allData=true, récupère tout l'historique sans limite de temps
  Future<String?> getTrendLogBuffer(int trendLogInstance, {bool allData = false}) async {
    if (apiVersion == 'V2') {
      return _getTrendLogBufferV2(trendLogInstance, allData: allData);
    }
    return _getTrendLogBufferV1(trendLogInstance, allData: allData);
  }

  /// Récupère le log buffer V1 via l'endpoint /trend
  /// Utilise les paramètres start/stop pour la plage de temps et limit pour le nombre de records
  /// Si allData=true, ne met pas de limite de temps (récupère tout)
  /// Doc: https://wiki.distech-controls.com/RestAPI/Protocols/BACnet/Local/Objects/ObjectType/ObjectInstance/Trend/GET-trend
  Future<String?> _getTrendLogBufferV1(int trendLogInstance, {int? maxRecords, bool allData = false}) async {
    _logger.i('_getTrendLogBufferV1: fetching trend data for trend-log $trendLogInstance, allData=$allData');

    // D'abord, récupérer les infos du trend-log pour trouver l'objet source
    String? sourceObjectType;
    String? sourceObjectInstance;

    // Méthode 1: Essayer de récupérer les infos du trend-log directement
    try {
      final infoUrl = '$baseUrl$_bacnetBasePath/objects/trendLog/$trendLogInstance';
      _logger.d('_getTrendLogBufferV1: fetching trend-log info from $infoUrl');
      final infoResponse = await _dio.get(infoUrl, options: Options(headers: {'Authorization': basicAuth}));

      if (infoResponse.statusCode == 200 && infoResponse.data is Map<String, dynamic>) {
        final data = infoResponse.data as Map<String, dynamic>;
        _logger.d('_getTrendLogBufferV1: trend-log response keys: ${data.keys.toList()}');

        final recordCount = data['record-count'] ?? data['recordCount'];
        final bufferSize = data['buffer-size'] ?? data['bufferSize'];
        final logInterval = data['log-interval'] ?? data['logInterval'];
        final logProp = data['log-device-object-property']?.toString() ?? data['logDeviceObjectProperty']?.toString();
        _logger.i('_getTrendLogBufferV1: trend-log info: recordCount=$recordCount, bufferSize=$bufferSize, logInterval=$logInterval, logProp=$logProp');

        // Parser l'objet source depuis log-device-object-property
        // Format: "[Analog Input 101,Present Value,,]"
        if (logProp != null && logProp != 'null') {
          final match = RegExp(r'\[([^,]+)\s+(\d+),').firstMatch(logProp);
          if (match != null) {
            sourceObjectType = match.group(1)?.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '-');
            sourceObjectInstance = match.group(2);
            _logger.i('_getTrendLogBufferV1: source object from logProp: $sourceObjectType/$sourceObjectInstance');
          }
        }
      }
    } catch (e) {
      _logger.w('_getTrendLogBufferV1: failed to get trend-log info: $e');
    }

    // Méthode 2: Si pas trouvé, essayer de déduire l'objet source depuis l'instance du trend-log
    // Convention Distech: trendLog 100101 -> analog-input 101, 200050 -> analog-value 50, etc.
    if (sourceObjectType == null || sourceObjectInstance == null) {
      final instanceStr = trendLogInstance.toString();
      if (instanceStr.length >= 4) {
        // Les 2-3 premiers chiffres indiquent le type, le reste l'instance
        // 10xxxx = Analog Input, 20xxxx = Analog Output, 30xxxx = Analog Value
        // 40xxxx = Binary Input, 50xxxx = Binary Output, 60xxxx = Binary Value
        final prefix = instanceStr.substring(0, instanceStr.length > 5 ? 2 : 1);
        final suffix = instanceStr.substring(instanceStr.length > 5 ? 2 : 1);

        final typeMap = {
          '10': 'analog-input',
          '20': 'analog-output',
          '30': 'analog-value',
          '40': 'binary-input',
          '50': 'binary-output',
          '60': 'binary-value',
          '1': 'analog-input',
          '2': 'analog-output',
          '3': 'analog-value',
          '4': 'binary-input',
          '5': 'binary-output',
          '6': 'binary-value',
        };

        sourceObjectType = typeMap[prefix];
        sourceObjectInstance = suffix.replaceFirst(RegExp(r'^0+'), ''); // Enlever les zéros en tête
        if (sourceObjectInstance.isEmpty) sourceObjectInstance = '0';

        _logger.i('_getTrendLogBufferV1: deduced source object from instance: $sourceObjectType/$sourceObjectInstance (prefix=$prefix)');
      }
    }

    // Si on a trouvé l'objet source, utiliser l'endpoint /trend avec les bons paramètres
    if (sourceObjectType != null && sourceObjectInstance != null) {
      final now = DateTime.now();
      final limit = maxRecords ?? 50000; // Limite haute pour "tout"

      String trendUrl;
      if (allData) {
        // Pas de limite de temps - récupérer tout l'historique
        trendUrl = '$baseUrl$_bacnetBasePath/objects/$sourceObjectType/$sourceObjectInstance/trend'
            '?dataOnly=true&iso8601=true&limit=$limit';
        _logger.i('_getTrendLogBufferV1: fetching ALL data from /trend endpoint');
      } else {
        // Limiter aux 30 derniers jours
        final start = now.subtract(const Duration(days: 30));
        final startMs = start.millisecondsSinceEpoch;
        final stopMs = now.millisecondsSinceEpoch;
        trendUrl = '$baseUrl$_bacnetBasePath/objects/$sourceObjectType/$sourceObjectInstance/trend'
            '?dataOnly=true&iso8601=true&start=$startMs&stop=$stopMs&limit=$limit';
        _logger.i('_getTrendLogBufferV1: fetching 30 days from /trend endpoint');
        _logger.d('_getTrendLogBufferV1: time range: ${start.toIso8601String()} -> ${now.toIso8601String()}');
      }

      _logger.i('_getTrendLogBufferV1: URL=$trendUrl');

      try {
        final response = await _dio.get(
          trendUrl,
          options: Options(
            headers: {'Authorization': basicAuth},
            receiveTimeout: const Duration(minutes: 5),
            sendTimeout: const Duration(minutes: 1),
          ),
        );

        _logger.i('_getTrendLogBufferV1: /trend response status=${response.statusCode}, dataType=${response.data?.runtimeType}');

        if (response.statusCode == 200 && response.data != null) {
          // La réponse est une liste JSON de records
          if (response.data is List) {
            final records = response.data as List;
            _logger.i('_getTrendLogBufferV1: got ${records.length} records from /trend endpoint');

            // Log le premier record pour debug
            if (records.isNotEmpty) {
              _logger.d('_getTrendLogBufferV1: first record: ${records.first}');
            }

            // Encoder en JSON pour le parser
            return jsonEncode(response.data);
          } else if (response.data is Map) {
            // Parfois la réponse est dans un wrapper
            _logger.d('_getTrendLogBufferV1: response is Map with keys: ${(response.data as Map).keys}');
            return jsonEncode(response.data);
          } else {
            _logger.w('_getTrendLogBufferV1: unexpected response type: ${response.data.runtimeType}');
          }
        } else {
          _logger.w('_getTrendLogBufferV1: /trend returned status=${response.statusCode}');
        }
      } catch (e, st) {
        _logger.e('_getTrendLogBufferV1: /trend endpoint failed: $e');
        _logger.d('_getTrendLogBufferV1: stacktrace: $st');
      }
    } else {
      _logger.w('_getTrendLogBufferV1: source object not found (type=$sourceObjectType, instance=$sourceObjectInstance)');
    }

    // Fallback: essayer le logBuffer directement (moins fiable)
    _logger.w('_getTrendLogBufferV1: falling back to logBuffer property');
    final logBufferUrl = '$baseUrl$_bacnetBasePath/objects/trendLog/$trendLogInstance/properties/logBuffer';

    try {
      final response = await _dio.get(
        logBufferUrl,
        options: Options(
          headers: {'Authorization': basicAuth},
          receiveTimeout: const Duration(minutes: 5),
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        String? value;
        if (response.data is Map<String, dynamic>) {
          value = response.data['value']?.toString();
        } else {
          value = response.data.toString();
        }

        if (value != null && value.isNotEmpty) {
          _logger.i('_getTrendLogBufferV1: got ${value.length} chars from logBuffer');
          return value;
        }
      }
    } catch (e) {
      _logger.e('_getTrendLogBufferV1: logBuffer fallback failed: $e');
    }

    _logger.e('_getTrendLogBufferV1: all attempts failed for trend-log $trendLogInstance');
    return null;
  }

  /// Récupère le log buffer V2 via l'API history
  /// Si allData=true, récupère tout l'historique (depuis 10 ans)
  Future<String?> _getTrendLogBufferV2(int trendLogInstance, {bool allData = false}) async {
    _logger.i('_getTrendLogBufferV2: fetching history for trend-log $trendLogInstance, allData=$allData');

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

    // En V2, utiliser l'API history avec get-table (données brutes, pas d'agrégation)
    // get-history fait de l'agrégation automatique, get-table retourne les données brutes
    final url = '$baseUrl/api/rest/v2/services/history/groups/bacnet/histories/get-table';

    // Calculer la plage de temps
    final now = DateTime.now();
    final startDate = allData
        ? now.subtract(const Duration(days: 3650)) // ~10 ans pour "tout"
        : now.subtract(const Duration(days: 30));  // 30 jours par défaut

    // Formater avec timezone
    String formatDate(DateTime d) {
      final offset = d.timeZoneOffset;
      final sign = offset.isNegative ? '-' : '+';
      final hours = offset.inHours.abs().toString().padLeft(2, '0');
      final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}T'
             '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')}.000$sign$hours:$minutes';
    }
    final timeRange = '${formatDate(startDate)}/${formatDate(now)}';

    _logger.i('_getTrendLogBufferV2: ${allData ? "fetching ALL data" : "fetching 30 days"}');

    final requestData = {
      'history': historyName,
      'time-range': timeRange,
      'limit': 0, // 0 = pas de limite, retourne toutes les données
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

  // ==========================================================================
  // === Super Favoris : Lecture batch de points multiples ===
  // ==========================================================================

  /// Lit les valeurs actuelles de plusieurs points en une seule requête
  /// Optimisé pour les super favoris affichés sur la page de connexions
  /// Retourne une Map pointRef -> BacnetObject avec les valeurs à jour
  Future<Map<String, BacnetObject>> readMultiplePoints(List<String> pointRefs) async {
    if (pointRefs.isEmpty) return {};

    _logger.i('readMultiplePoints: reading ${pointRefs.length} points');

    if (apiVersion == 'V2') {
      return _readMultiplePointsV2(pointRefs);
    } else {
      return _readMultiplePointsV1(pointRefs);
    }
  }

  /// Lecture batch V1 via read-property-multiple
  Future<Map<String, BacnetObject>> _readMultiplePointsV1(List<String> pointRefs) async {
    final rpmUrl = '$baseUrl$_bacnetBasePath/objects/read-property-multiple';
    _logger.i('_readMultiplePointsV1: POST $rpmUrl for ${pointRefs.length} points');

    // Construire les propertyReferences pour chaque point
    final propertyRefs = <Map<String, dynamic>>[];

    for (final ref in pointRefs) {
      // Parser le pointRef (format: "analog-value:1" ou "AV:1")
      final parsed = _parsePointRef(ref);
      if (parsed == null) {
        _logger.w('_readMultiplePointsV1: invalid pointRef format: $ref');
        continue;
      }

      // API V1 utilise camelCase (analogInput, analogValue, etc.)
      final type = BacnetObjectType.fromApiName(parsed['type'] as String);
      if (type == null) continue;
      final typeNameV1 = type.name; // camelCase: analogInput, analogValue, etc.
      final instance = parsed['instance'] as int;

      // Ajouter les propriétés essentielles
      for (final prop in ['objectName', 'presentValue', 'units', 'description', 'outOfService']) {
        propertyRefs.add({
          'type': typeNameV1,
          'instance': instance,
          'property': prop,
          'arrayIndex': -1,
        });
      }

      // Ajouter les textes pour les types binaires/multistate
      if (type.isBinary) {
        propertyRefs.add({'type': typeNameV1, 'instance': instance, 'property': 'activeText', 'arrayIndex': -1});
        propertyRefs.add({'type': typeNameV1, 'instance': instance, 'property': 'inactiveText', 'arrayIndex': -1});
      }
      if (type.isMultiState) {
        propertyRefs.add({'type': typeNameV1, 'instance': instance, 'property': 'stateText', 'arrayIndex': -1});
      }
    }

    if (propertyRefs.isEmpty) return {};

    _logger.d('_readMultiplePointsV1: propertyRefs=${propertyRefs.take(3).toList()}');

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

      _logger.d('_readMultiplePointsV1: status=${response.statusCode}, data=${response.data}');
      if (response.statusCode == 200 && response.data != null) {
        return _parseMultiplePointsFromRpm(response.data, pointRefs);
      }
    } catch (e) {
      _logger.e('_readMultiplePointsV1 error: $e');
    }

    return {};
  }

  /// Lecture batch V2 via l'API batch
  Future<Map<String, BacnetObject>> _readMultiplePointsV2(List<String> pointRefs) async {
    final batchUrl = '$baseUrl/api/rest/v2/batch';
    _logger.i('_readMultiplePointsV2: POST $batchUrl for ${pointRefs.length} points');

    // Construire les requêtes batch
    final requests = <Map<String, dynamic>>[];

    for (final ref in pointRefs) {
      final parsed = _parsePointRef(ref);
      if (parsed == null) continue;

      final typeName = parsed['type'] as String;
      final instance = parsed['instance'] as int;

      // Convertir en format kebab-case pour V2
      final typeV2 = _typeToV2Name(typeName);
      if (typeV2 == null) continue;

      requests.add({
        'id': ref,
        'method': 'GET',
        'url': '$_bacnetBasePath/objects/$typeV2/$instance',
      });
    }

    if (requests.isEmpty) {
      _logger.w('_readMultiplePointsV2: no valid requests built');
      return {};
    }

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

      _logger.d('_readMultiplePointsV2: status=${response.statusCode}, data=${response.data}');
      if (response.statusCode == 200 && response.data != null) {
        return _parseMultiplePointsFromBatchV2(response.data);
      }
    } catch (e) {
      _logger.e('_readMultiplePointsV2 error: $e');
    }

    return {};
  }

  /// Parse un pointRef en type + instance
  Map<String, dynamic>? _parsePointRef(String pointRef) {
    // Format possible: "analog-value:1", "AV:1", "analogValue:1"
    final parts = pointRef.split(':');
    if (parts.length != 2) return null;

    final typePart = parts[0].trim();
    final instance = int.tryParse(parts[1].trim());
    if (instance == null) return null;

    // Mapper le nom du type (supporte tous les formats)
    final type = BacnetObjectType.fromAnyName(typePart);
    if (type == null) {
      _logger.w('_parsePointRef: unknown type "$typePart" in "$pointRef"');
      return null;
    }

    return {
      'type': type.apiName,
      'instance': instance,
    };
  }

  /// Convertit un nom de type en format V2 (kebab-case + pluriel)
  String? _typeToV2Name(String typeName) {
    // Mapping apiName (kebab-case) vers endpoint V2 (pluriel)
    const mapping = {
      'analog-input': 'analog-inputs',
      'analog-output': 'analog-outputs',
      'analog-value': 'analog-values',
      'binary-input': 'binary-inputs',
      'binary-output': 'binary-outputs',
      'binary-value': 'binary-values',
      'multi-state-input': 'multi-state-inputs',
      'multi-state-output': 'multi-state-outputs',
      'multi-state-value': 'multi-state-values',
    };
    return mapping[typeName];
  }

  /// Parse la réponse RPM pour les super favoris (V1)
  Map<String, BacnetObject> _parseMultiplePointsFromRpm(dynamic data, List<String> originalRefs) {
    final results = <String, BacnetObject>{};
    final grouped = <String, Map<String, dynamic>>{};

    // Construire un mapping camelCase:instance -> originalRef
    // L'API V1 retourne les types en camelCase (analogInput, analogValue, etc.)
    final refMapping = <String, String>{};
    for (final ref in originalRefs) {
      final parsed = _parsePointRef(ref);
      if (parsed != null) {
        final type = BacnetObjectType.fromApiName(parsed['type'] as String);
        if (type != null) {
          final instance = parsed['instance'] as int;
          refMapping['${type.name}:$instance'] = ref; // type.name = camelCase
        }
      }
    }

    _logger.d('_parseMultiplePointsFromRpm: refMapping=$refMapping');

    // La réponse peut être une liste directement ou un wrapper
    List<dynamic> refs;
    if (data is List) {
      refs = data;
    } else if (data is Map<String, dynamic>) {
      refs = data['propertyReferences'] as List? ?? [];
    } else {
      _logger.w('_parseMultiplePointsFromRpm: unexpected data type: ${data.runtimeType}');
      return results;
    }

    _logger.d('_parseMultiplePointsFromRpm: refs.length=${refs.length}');

    // Grouper par type:instance
    for (final ref in refs) {
      if (ref is! Map<String, dynamic>) continue;

      final type = ref['type'] as String?;
      final instance = ref['instance'];
      final property = ref['property'] as String?;
      var value = ref['value'] ?? ref['message'];

      if (type == null || instance == null || property == null) continue;

      // Extraire la valeur du Map si nécessaire
      if (value is Map) {
        value = value['value'] ?? value['\$value'] ?? value.values.firstOrNull;
      }

      final key = '$type:$instance';
      grouped.putIfAbsent(key, () => {'type': type, 'instance': instance});
      grouped[key]![property] = value;
    }

    _logger.d('_parseMultiplePointsFromRpm: grouped.keys=${grouped.keys.toList()}');

    // Construire les BacnetObjects avec les clés originales
    for (final entry in grouped.entries) {
      final props = entry.value;
      // Utiliser fromAnyName car V1 retourne les types en camelCase (analogValue, etc.)
      final type = BacnetObjectType.fromAnyName(props['type'] as String? ?? '');
      if (type == null) continue; // Ignorer les types inconnus
      final instance = props['instance'] as int? ?? 0;

      // Parser stateText pour multistate
      List<String>? stateText;
      final stateTextRaw = props['stateText'];
      if (stateTextRaw is List) {
        stateText = stateTextRaw.map((e) => e?.toString() ?? '').toList();
      } else if (stateTextRaw is String) {
        stateText = stateTextRaw.split(',').map((e) => e.trim()).toList();
      }

      // Trouver la clé originale (ex: "AV:1" au lieu de "analogValue:1")
      final originalKey = refMapping[entry.key] ?? entry.key;

      // Extraire la valeur de presentValue (peut être un objet complexe)
      var presentValue = props['presentValue'];
      if (presentValue is Map) {
        presentValue = presentValue['value'] ?? presentValue['\$value'] ?? presentValue.values.firstOrNull;
      }

      // Extraire units (peut être un objet avec $value)
      var units = props['units'];
      if (units is Map) {
        units = units['value'] ?? units['\$value'] ?? units.values.firstOrNull;
      }

      results[originalKey] = BacnetObject(
        type: type,
        instance: instance,
        objectName: props['objectName']?.toString() ?? 'Point $instance',
        presentValue: _parseValue(presentValue),
        units: units?.toString(),
        description: props['description']?.toString(),
        outOfService: props['outOfService'] == true || props['outOfService'] == 'true',
        activeText: props['activeText']?.toString(),
        inactiveText: props['inactiveText']?.toString(),
        stateText: stateText,
      );
    }

    return results;
  }

  /// Parse la réponse batch V2 pour les super favoris
  Map<String, BacnetObject> _parseMultiplePointsFromBatchV2(dynamic data) {
    final results = <String, BacnetObject>{};

    List<dynamic> responses;
    if (data is List) {
      responses = data;
    } else if (data is Map<String, dynamic>) {
      responses = data['responses'] as List? ?? [];
    } else {
      _logger.w('_parseMultiplePointsFromBatchV2: unexpected data type: ${data.runtimeType}');
      return results;
    }

    _logger.d('_parseMultiplePointsFromBatchV2: responses.length=${responses.length}');

    for (final batchResponse in responses) {
      if (batchResponse is! Map<String, dynamic>) continue;

      final id = batchResponse['id'] as String?; // C'est notre pointRef original
      final body = batchResponse['body'];
      final statusCode = batchResponse['status'] as int?;

      _logger.d('_parseMultiplePointsFromBatchV2: id=$id, status=$statusCode');

      if (id == null || body == null || statusCode != 200) continue;
      if (body is! Map<String, dynamic>) continue;

      final parsed = _parsePointRef(id);
      if (parsed == null) continue;

      final type = BacnetObjectType.fromApiName(parsed['type'] as String);
      if (type == null) continue; // Ignorer les types inconnus
      final instance = parsed['instance'] as int;

      // Parser stateText
      List<String>? stateText;
      final stateTextRaw = body['state-text'];
      if (stateTextRaw is List) {
        stateText = stateTextRaw.map((e) => e?.toString() ?? '').toList();
      }

      results[id] = BacnetObject(
        type: type,
        instance: instance,
        objectName: body['object-name']?.toString() ?? 'Point $instance',
        presentValue: _parseValue(body['present-value']),
        units: _extractUnitsV2(body['units']),
        description: body['description']?.toString(),
        outOfService: body['out-of-service'] as bool?,
        activeText: body['active-text']?.toString(),
        inactiveText: body['inactive-text']?.toString(),
        stateText: stateText,
      );
    }

    return results;
  }

  /// Ferme le client
  void dispose() {
    _dio.close();
  }
}
