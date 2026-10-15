import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import '../../core/utils/logger.dart';
import '../../core/constants/api_constants.dart';
import '../../domain/models/bacnet_object.dart';
import '../../domain/models/schedule.dart';
import 'api_exceptions.dart';
import 'api_type_names.dart';
import 'certificate_pinning.dart';
import 'request_limiter.dart';

export 'api_exceptions.dart';

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

  /// [timeout] defaults to [ApiConstants.testConnectionTimeout].
  ApiService({Duration? timeout}) {
    final t = timeout ?? ApiConstants.testConnectionTimeout;
    _dio = Dio(BaseOptions(
      connectTimeout: t,
      receiveTimeout: t,
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

  /// Calcule l'empreinte SHA-256 d'un certificat
  String _calculateFingerprint(X509Certificate cert) => certificateFingerprintOf(cert);

  /// SHA-256 fingerprint of a certificate (DER), formatted as `AA:BB:...`.
  /// Shared with [ConnectedApiClient] so both use the same format.
  static String certificateFingerprintOf(X509Certificate cert) =>
      certificateFingerprintOfDer(cert.der);

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

    // Ne jamais réutiliser l'empreinte d'un test précédent (autre hôte)
    _lastCertificateFingerprint = null;

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
      logger.w('testConnection: V2 probe failed: $e');
      // Hôte injoignable : inutile d'attendre un second timeout en V1
      if (e is DioException &&
          (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.connectionError)) {
        return ConnectionTestResult(
          success: false,
          errorMessage: _formatError(e),
          certificateFingerprint: _lastCertificateFingerprint,
        );
      }
      // Sinon on essaie V1
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
  String _formatError(dynamic error) => describeError(error as Object);

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

  /// Expected SHA-256 certificate fingerprint (`AA:BB:...`, see
  /// [ApiService.certificateFingerprintOf]). When null (default), every
  /// certificate is accepted, as before. TOFU wiring is done by the callers.
  final String? expectedCertFingerprint;

  /// Called with the SHA-256 fingerprint of each self-signed / untrusted
  /// certificate presented by the controller.
  final void Function(String fingerprint)? onCertificateSeen;

  /// Called whenever the controller answers 401/403 (bad or expired
  /// credentials, insufficient rights). Public methods keep their historical
  /// contract (empty list / null / false on failure); use this callback or
  /// [lastError] to tell an auth failure apart from "no data".
  final void Function(ApiAuthException error)? onAuthError;

  /// Called when the presented certificate does not match
  /// [expectedCertFingerprint] (the TLS handshake is then refused).
  final void Function(CertificateMismatchException error)? onCertificateMismatch;

  CertificateMismatchException? _certificateMismatch;

  /// Set once the controller presented a certificate that does not match
  /// [expectedCertFingerprint].
  CertificateMismatchException? get certificateMismatch => _certificateMismatch;

  ApiException? _lastError;
  int? _lastStatusCode;

  /// Last HTTP failure seen by this client (sticky until [clearLastError]).
  ApiException? get lastError => _lastError;

  /// Status code of the last HTTP response received.
  int? get lastStatusCode => _lastStatusCode;

  /// True if the last recorded failure is an authentication failure.
  bool get hasAuthError => _lastError is ApiAuthException;

  /// Clears [lastError] (call it before an operation to check its outcome).
  void clearLastError() {
    _lastError = null;
    _recentAuthErrors.clear();
  }

  /// Auth failures recorded since the last [clearLastError] (newest last).
  /// Kept separately from [lastError] so that a failure on a parallel annex
  /// request (device info, time...) is not mistaken for a failure of the
  /// call being checked, and vice versa.
  final List<ApiAuthException> _recentAuthErrors = [];
  static const _maxRecentAuthErrors = 32;

  /// URL fragments of the requests that read BACnet objects (points,
  /// schedules): the objects path, plus the V2 batch endpoint.
  List<String> get _objectsUrlFragments => [
        '$_bacnetBasePath/objects',
        if (apiVersion == 'V2') ApiConstants.v2Batch,
      ];

  /// The failure that prevented reading BACnet objects (points, schedules)
  /// since the last [clearLastError]: a certificate mismatch, or a 401/403
  /// on an objects request. Auth failures on other endpoints are ignored.
  ApiException? objectsAccessFailure() {
    if (_certificateMismatch != null) return _certificateMismatch;
    final fragments = _objectsUrlFragments;
    for (final error in _recentAuthErrors.reversed) {
      final url = error.url ?? '';
      if (fragments.any(url.contains)) return error;
    }
    return null;
  }

  /// Requests in flight, used to deduplicate identical concurrent reads.
  final Map<String, Future<dynamic>> _inFlight = {};

  ConnectedApiClient({
    required this.baseUrl,
    required this.basicAuth,
    required this.apiVersion,
    this.expectedCertFingerprint,
    this.onCertificateSeen,
    this.onAuthError,
    this.onCertificateMismatch,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
  }) : _dio = Dio(BaseOptions(
          connectTimeout: connectTimeout ?? ApiConstants.connectTimeout,
          receiveTimeout: receiveTimeout ?? ApiConstants.receiveTimeout,
          sendTimeout: sendTimeout ?? ApiConstants.sendTimeout,
          validateStatus: (status) => status != null && status < 500,
        )) {
    // Configurer pour les certificats auto-signés
    (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback = (cert, host, port) {
        if (expectedCertFingerprint == null && onCertificateSeen == null) {
          return true;
        }
        final fingerprint = ApiService.certificateFingerprintOf(cert);
        onCertificateSeen?.call(fingerprint);
        final expected = expectedCertFingerprint;
        if (checkCertificate(expected, fingerprint) != CertificateCheck.mismatch) {
          return true;
        }
        logger.e('ConnectedApiClient: certificate fingerprint mismatch for $host');
        final mismatch = CertificateMismatchException(
          expectedFingerprint: expected!,
          receivedFingerprint: fingerprint,
          host: host,
        );
        _certificateMismatch = mismatch;
        _lastError = mismatch;
        onCertificateMismatch?.call(mismatch);
        return false;
      };
      return client;
    };
    // Limiter en premier : les requêtes en attente n'ont pas encore été émises
    _dio.interceptors.add(RequestLimiterInterceptor(RequestLimiter(ApiConstants.maxConcurrentRequests)));
    _dio.interceptors.add(InterceptorsWrapper(
      onResponse: (response, handler) {
        _recordStatus(response.statusCode, response.requestOptions.uri.toString());
        handler.next(response);
      },
      onError: (error, handler) {
        final status = error.response?.statusCode;
        if (status != null) {
          _recordStatus(status, error.requestOptions.uri.toString());
        } else if (_certificateMismatch != null) {
          _lastError = _certificateMismatch;
        } else {
          _lastError = ApiException(
            error.message ?? 'Erreur réseau (${error.type.name})',
            url: error.requestOptions.uri.toString(),
          );
        }
        handler.next(error);
      },
    ));
    logger.i('ConnectedApiClient créé: baseUrl=$baseUrl, apiVersion=$apiVersion');
  }

  void _recordStatus(int? statusCode, String url) {
    _lastStatusCode = statusCode;
    if (statusCode == null || statusCode < 400) return;
    final error = ApiException.fromStatus(statusCode, url: url);
    _lastError = error;
    if (error is ApiAuthException) {
      _recentAuthErrors.add(error);
      if (_recentAuthErrors.length > _maxRecentAuthErrors) _recentAuthErrors.removeAt(0);
      logger.w('ConnectedApiClient: authentication failure ($statusCode) on $url');
      onAuthError?.call(error);
    }
  }

  /// Throws [ApiAuthException] for 401/403 responses (for methods whose
  /// callers already handle exceptions).
  void _throwIfAuthError(Response response) {
    final status = response.statusCode;
    if (status == 401 || status == 403) {
      throw ApiAuthException(statusCode: status, url: response.requestOptions.uri.toString());
    }
  }

  /// Runs [action] once for concurrent calls sharing the same [key].
  Future<T> _dedup<T>(String key, Future<T> Function() action) {
    final existing = _inFlight[key];
    if (existing != null) return existing as Future<T>;
    // Block body on purpose: returning the removed Future from whenComplete
    // would make the future wait for itself (deadlock).
    final future = action().whenComplete(() {
      _inFlight.remove(key);
    });
    _inFlight[key] = future;
    return future;
  }

  /// Chemin de base pour l'API BACnet
  String get _bacnetBasePath =>
      apiVersion == 'V2' ? ApiConstants.v2BacnetLocal : ApiConstants.v1BacnetLocal;

  /// Options HTTP avec authentification
  Options get _authOptions => Options(headers: {'Authorization': basicAuth});

  /// Options HTTP avec authentification pour un corps JSON
  Options get _jsonOptions => Options(headers: {
        'Authorization': basicAuth,
        'Content-Type': 'application/json',
      });

  /// POST JSON authentifié
  Future<Response> _postJson(String url, Object? body, {Options? options}) {
    return _dio.post(url, data: body, options: options ?? _jsonOptions);
  }

  /// Extracts the property references of a read-property-multiple response
  /// (either a bare List or `{propertyReferences: [...]}`).
  static List<dynamic> _extractRpmRefs(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      final refs = data['propertyReferences'] ?? data['property-references'];
      if (refs is List) return refs;
    }
    return const [];
  }

  /// Récupère les informations de l'appareil
  Future<DeviceInfo> getDeviceInfo() async {
    // Pour V1, utiliser read-property-multiple pour récupérer toutes les propriétés en une requête
    if (apiVersion == 'V1') {
      return await _getDeviceInfoV1();
    }

    // V2: méthode standard
    final url = '$baseUrl$_bacnetBasePath/objects/device';
    logger.i('getDeviceInfo: GET $url');

    try {
      final response = await _dio.get(url, options: _authOptions);
      logger.i('getDeviceInfo: status=${response.statusCode}');
      logger.d(() => 'getDeviceInfo: data=${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is List && data.isNotEmpty) {
          final firstItem = data.first;
          if (firstItem is int) {
            final detailUrl = '$baseUrl$_bacnetBasePath/objects/device/$firstItem';
            logger.i('getDeviceInfo: fetching details from $detailUrl');
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
      logger.e('getDeviceInfo error: $e');
    }

    throw Exception('Impossible de récupérer les informations de l\'appareil');
  }

  /// Récupère les infos du device pour V1 depuis /info/device et /bacnet/local
  Future<DeviceInfo> _getDeviceInfoV1() async {
    String? bacnetName;

    // 1. Récupérer le nom BACnet depuis /bacnet/local
    try {
      final localUrl = '$baseUrl$_bacnetBasePath';
      logger.i('_getDeviceInfoV1: GET $localUrl');
      final localResponse = await _dio.get(localUrl, options: _authOptions);
      if (localResponse.statusCode == 200 && localResponse.data is Map<String, dynamic>) {
        bacnetName = (localResponse.data as Map<String, dynamic>)['name'] as String?;
      }
    } catch (e) {
      logger.w('_getDeviceInfoV1: /bacnet/local error: $e');
    }

    // 2. Récupérer les infos détaillées depuis /info/device
    try {
      final infoUrl = '$baseUrl/api/rest/v1/info/device';
      logger.i('_getDeviceInfoV1: GET $infoUrl');
      final infoResponse = await _dio.get(infoUrl, options: _authOptions);
      logger.d(() => '_getDeviceInfoV1: /info/device response=${infoResponse.data}');

      if (infoResponse.statusCode == 200 && infoResponse.data is Map<String, dynamic>) {
        final data = infoResponse.data as Map<String, dynamic>;
        return DeviceInfo.fromDeviceInfoJson(data, bacnetName: bacnetName);
      }
    } catch (e) {
      logger.w('_getDeviceInfoV1: /info/device error: $e');
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
    logger.i('_getControllerTimeV2: GET $url');

    try {
      final response = await _dio.get(url, options: _authOptions);
      logger.d(() => '_getControllerTimeV2: response=${response.data}');

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
      logger.w('_getControllerTimeV2: error: $e');
    }

    // Essayer l'endpoint alternatif
    try {
      final altUrl = '$baseUrl/api/rest/v2/services/platform/time/date-time';
      logger.i('_getControllerTimeV2: trying alternate GET $altUrl');
      final response = await _dio.get(altUrl, options: _authOptions);

      if (response.statusCode == 200 && response.data != null) {
        final dateTimeStr = response.data.toString();
        final controllerDateTime = DateTime.tryParse(dateTimeStr);
        if (controllerDateTime != null) {
          return ControllerTime.fromDateTime(controllerDateTime);
        }
      }
    } catch (e) {
      logger.w('_getControllerTimeV2: alternate endpoint error: $e');
    }

    throw Exception('Impossible de récupérer l\'heure de l\'automate');
  }

  /// Récupère l'heure de l'automate via API V1 (BACnet Device object)
  Future<ControllerTime> _getControllerTimeV1() async {
    final rpmUrl = '$baseUrl$_bacnetBasePath/objects/read-property-multiple';
    logger.i('_getControllerTimeV1: POST $rpmUrl');

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
        options: _jsonOptions,
      );

      logger.d(() => '_getControllerTimeV1: response=${response.data}');

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

        logger.i('_getControllerTimeV1: localDate=$localDate, localTime=$localTime');

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
      logger.w('_getControllerTimeV1: error: $e');
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
    logger.i('_setControllerTimeV1: POST $url');

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

    logger.d(() => '_setControllerTimeV1: body=$body');

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

      logger.i('_setControllerTimeV1: response status=${response.statusCode}');

      // Succès si status 200 ou 204
      if (response.statusCode == 200 || response.statusCode == 204) {
        logger.i('_setControllerTimeV1: Heure mise à jour avec succès');
        return true;
      }

      logger.w('_setControllerTimeV1: Échec, status=${response.statusCode}');
      return false;
    } catch (e) {
      logger.e('_setControllerTimeV1: Erreur: $e');
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
    logger.i('_getNetworkInfoV1: GET $url');

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

      logger.i('_getNetworkInfoV1: status=${response.statusCode}');
      logger.d(() => '_getNetworkInfoV1: data=${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          return NetworkInfo.fromJsonV1(data);
        }
      }

      return null;
    } catch (e) {
      logger.w('_getNetworkInfoV1: Erreur: $e');
      return null;
    }
  }

  /// Récupère les infos réseau pour API V2
  /// Récupère toutes les interfaces : bridge, primary, secondary, wireless
  Future<NetworkInfo?> _getNetworkInfoV2() async {
    final url = '$baseUrl/api/rest/v2/services/platform/network/interfaces';
    logger.i('_getNetworkInfoV2: GET $url');

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

      logger.i('_getNetworkInfoV2: status=${response.statusCode}');
      logger.d(() => '_getNetworkInfoV2: data=${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          return NetworkInfo.fromJsonV2(data);
        }
      }

      return null;
    } catch (e) {
      logger.w('_getNetworkInfoV2: Erreur: $e');
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
      logger.w('_parseBacnetDateTime: error parsing $dateStr $timeStr: $e');
      return null;
    }
  }

  /// Récupère le résumé des objets disponibles
  Future<ObjectsSummary> getObjectsSummary() async {
    final url = '$baseUrl$_bacnetBasePath/objects';
    logger.i('getObjectsSummary: GET $url');

    try {
      final response = await _dio.get(url, options: _authOptions);
      logger.i('getObjectsSummary: status=${response.statusCode}');
      logger.d(() => 'getObjectsSummary: data=${response.data}');
      _throwIfAuthError(response);

      if (response.statusCode == 200 && response.data != null) {
        // Vérifier que la réponse est bien du JSON
        if (response.data is! Map<String, dynamic>) {
          logger.w('getObjectsSummary: réponse non-JSON: ${response.data.runtimeType}');
          throw Exception('Réponse non-JSON reçue');
        }
        final data = response.data as Map<String, dynamic>;
        logger.i('getObjectsSummary: keys=${data.keys.toList()}');

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
      logger.e('getObjectsSummary error: $e');
      rethrow;
    }

    throw Exception('Impossible de récupérer la liste des objets');
  }

  /// Parse le résumé des objets pour V1 via read-property-multiple (1 seule requête!)
  Future<ObjectsSummary> _getObjectsSummaryV1(Map<String, dynamic> data) async {
    logger.i('_getObjectsSummaryV1: using read-property-multiple');

    // Utiliser read-property-multiple avec instance=-1 pour récupérer TOUS les objets de chaque type
    final rpmUrl = '$baseUrl$_bacnetBasePath/objects/read-property-multiple';

    // Liste des types à compter avec instance=-1 (tous les objets du type)
    final propertyRefs = <Map<String, dynamic>>[];
    for (final type in _summaryTypes) {
      propertyRefs.add({
        'type': ApiTypeNames.v1Name(type),
        'instance': -1,  // -1 = tous les instances
        'property': 'objectName',
        'arrayIndex': -1,
      });
    }

    final body = {
      'encode': 'text',
      'propertyReferences': propertyRefs,
    };

    logger.i('_getObjectsSummaryV1: POST $rpmUrl with ${propertyRefs.length} types');

    Response response;
    try {
      response = await _postJson(rpmUrl, body);
    } catch (e) {
      logger.w('_getObjectsSummaryV1: read-property-multiple failed: $e');
      // Fallback: compter depuis la liste des types
      return _getObjectsSummaryV1Fallback(data);
    }

    logger.d(() => '_getObjectsSummaryV1: response status=${response.statusCode}');
    logger.d(() => '_getObjectsSummaryV1: response data=${response.data}');
    // A 401/403 here is not fatal: the objects list was readable (limited
    // account), the per-type fallback below counts what is allowed.

    if (response.statusCode == 200 && response.data != null) {
      return parseObjectsSummaryFromRpm(response.data);
    }

    // Statut inattendu : ne pas renvoyer un résumé vide (il écraserait le cache)
    logger.w('_getObjectsSummaryV1: RPM status=${response.statusCode}, using fallback');
    return _getObjectsSummaryV1Fallback(data);
  }

  /// Types d'objets importants à compter
  static const _summaryTypes = [
    ...ApiTypeNames.pointTypes,
    BacnetObjectType.schedule,
  ];

  /// Builds an [ObjectsSummary] from per-type counts.
  static ObjectsSummary _summaryFromCounts(Map<BacnetObjectType, int> counts) {
    return ObjectsSummary(
      analogInputs: counts[BacnetObjectType.analogInput] ?? 0,
      analogOutputs: counts[BacnetObjectType.analogOutput] ?? 0,
      analogValues: counts[BacnetObjectType.analogValue] ?? 0,
      binaryInputs: counts[BacnetObjectType.binaryInput] ?? 0,
      binaryOutputs: counts[BacnetObjectType.binaryOutput] ?? 0,
      binaryValues: counts[BacnetObjectType.binaryValue] ?? 0,
      multiStateInputs: counts[BacnetObjectType.multiStateInput] ?? 0,
      multiStateOutputs: counts[BacnetObjectType.multiStateOutput] ?? 0,
      multiStateValues: counts[BacnetObjectType.multiStateValue] ?? 0,
      schedules: counts[BacnetObjectType.schedule] ?? 0,
    );
  }

  /// Parse la réponse read-property-multiple pour compter les objets.
  /// Type names are matched case-insensitively (`multistateValue` and
  /// `multiStateValue` are both accepted).
  static ObjectsSummary parseObjectsSummaryFromRpm(dynamic data) {
    // Compter les objets par type (chaque entrée avec instance différent = 1 objet)
    final instancesByType = <BacnetObjectType, Set<int>>{};

    for (final ref in _extractRpmRefs(data)) {
      if (ref is! Map) continue;
      final type = ApiTypeNames.fromV1Name(ref['type']?.toString() ?? '');
      final rawInstance = ref['instance'];
      final instance = rawInstance is int ? rawInstance : int.tryParse('$rawInstance');
      if (type == null || !_summaryTypes.contains(type)) continue;
      if (instance == null || instance == -1) continue;
      instancesByType.putIfAbsent(type, () => <int>{}).add(instance);
    }

    final counts = instancesByType.map((type, set) => MapEntry(type, set.length));
    logger.i(() => 'parseObjectsSummaryFromRpm: ${counts.entries.map((e) => '${e.key.name}=${e.value}').join(', ')}');
    return _summaryFromCounts(counts);
  }

  /// Fallback: compter les objets via requêtes individuelles (si RPM échoue)
  Future<ObjectsSummary> _getObjectsSummaryV1Fallback(Map<String, dynamic> data) async {
    logger.i('_getObjectsSummaryV1Fallback: using individual requests');
    final objectTypes = data['bacnetObjectTypes'] as List? ?? [];
    final counts = <BacnetObjectType, int>{};

    // Traiter par lots de 4
    final typesToCount = <(BacnetObjectType, String)>[];
    for (final typeInfo in objectTypes) {
      if (typeInfo is! Map<String, dynamic>) continue;
      final type = ApiTypeNames.fromV1Name(typeInfo['name'] as String? ?? '');
      final href = typeInfo['href'] as String?;
      if (href != null && type != null && _summaryTypes.contains(type)) {
        typesToCount.add((type, href));
      }
    }

    var failures = 0;
    ApiException? fallbackError;
    const batchSize = 4;
    for (var i = 0; i < typesToCount.length; i += batchSize) {
      final batch = typesToCount.skip(i).take(batchSize);
      await Future.wait(batch.map((t) async {
        try {
          final response = await _dio.get('$baseUrl${t.$2}', options: _authOptions);
          if (response.statusCode == 200 && response.data is List) {
            counts[t.$1] = (response.data as List).length;
          } else {
            failures++;
            final status = response.statusCode;
            if (status != null && status >= 400) {
              fallbackError = ApiException.fromStatus(status, url: response.requestOptions.uri.toString());
            }
          }
        } catch (e) {
          failures++;
        }
      }));
    }

    // Tout a échoué : lever une erreur plutôt qu'un résumé vide qui écraserait le cache.
    // Uses this call's own error (not [lastError], shared with parallel requests).
    if (typesToCount.isNotEmpty && failures == typesToCount.length) {
      throw fallbackError ?? const ApiException('Impossible de compter les objets');
    }

    return _summaryFromCounts(counts);
  }

  int _countObjects(Map<String, dynamic> data, String key1, String key2) {
    final value = data[key1] ?? data[key2];
    if (value is List) return value.length;
    if (value is Map) return value.length;  // V2 format: {instance: {...}, ...}
    if (value is int) return value;
    return 0;
  }

  /// URL path segment of an object type for the current API version
  /// (V1: `analog-value`, V2: `analog-values`).
  String _typePath(BacnetObjectType type) =>
      apiVersion == 'V2' ? ApiTypeNames.v2Path(type) : ApiTypeNames.v1Path(type);

  /// Récupère tous les objets d'un type donné.
  /// Lève une [ApiException] si la liste ne peut pas être lue.
  Future<List<BacnetObject>> getObjectsByType(BacnetObjectType type) async {
    final url = '$baseUrl$_bacnetBasePath/objects/${_typePath(type)}';
    final response = await _dio.get(url, options: _authOptions);
    _throwIfAuthError(response);

    if (response.statusCode != 200 || response.data == null) {
      throw ApiException.fromStatus(response.statusCode ?? 0, url: url);
    }

    final data = response.data;
    final objects = <BacnetObject>[];
    final instancesToFetch = <int>[];

    if (data is List) {
      // Liste d'IDs, de liens {href, name} (V1) ou d'objets complets
      for (var i = 0; i < data.length; i++) {
        final item = data[i];
        if (item is int) {
          instancesToFetch.add(item);
        } else if (item is Map<String, dynamic>) {
          final hasProperties = item.containsKey('object-name') || item.containsKey('objectName');
          final hrefInstance = _instanceFromHref(item['href']);
          if (!hasProperties && hrefInstance != null) {
            instancesToFetch.add(hrefInstance);
            continue;
          }
          final instance = item['object-identifier']?['instance'] ??
                          item['objectIdentifier']?['instance'] ?? hrefInstance ?? i + 1;
          objects.add(BacnetObject.fromJson(type, instance, item));
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

    // Récupérer les détails par lots (requêtes indépendantes)
    const batchSize = 8;
    for (var i = 0; i < instancesToFetch.length; i += batchSize) {
      final batch = instancesToFetch.skip(i).take(batchSize);
      final details = await Future.wait(batch.map((instance) => getObjectDetails(type, instance)));
      objects.addAll(details.whereType<BacnetObject>());
    }

    return objects;
  }

  /// Extracts the trailing instance number of a V1 href (`.../analog-value/12`).
  static int? _instanceFromHref(dynamic href) {
    if (href is! String) return null;
    final match = RegExp(r'/(\d+)/?$').firstMatch(href);
    return match != null ? int.tryParse(match.group(1)!) : null;
  }

  /// Récupère les détails d'un objet spécifique
  Future<BacnetObject?> getObjectDetails(BacnetObjectType type, int instance) async {
    try {
      final response = await _dio.get(
        '$baseUrl$_bacnetBasePath/objects/${_typePath(type)}/$instance',
        options: _authOptions,
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return BacnetObject.fromJson(type, instance, response.data as Map<String, dynamic>);
      }
    } catch (e) {
      // Ignorer les erreurs pour les objets individuels
      logger.d(() => 'getObjectDetails ${type.apiName}:$instance error: $e');
    }
    return null;
  }

  /// Récupère tous les objets avec leurs valeurs actuelles.
  /// Lève la dernière erreur si aucun type n'a pu être lu.
  Future<List<BacnetObject>> getAllObjects() async {
    final objects = <BacnetObject>[];
    Object? lastError;
    var failures = 0;

    // Requêtes indépendantes : les lancer en parallèle
    final results = await Future.wait(ApiTypeNames.pointTypes.map((type) async {
      try {
        return await getObjectsByType(type);
      } on ApiAuthException {
        rethrow;
      } catch (e) {
        // Continuer même si un type échoue
        failures++;
        lastError = e;
        return <BacnetObject>[];
      }
    }));
    for (final typeObjects in results) {
      objects.addAll(typeObjects);
    }

    if (failures == ApiTypeNames.pointTypes.length && lastError != null) {
      throw lastError!;
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
    logger.i('_getAllPointsV1Optimized: fetching all points with read-property-multiple');

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

    logger.i('_getAllPointsV1Optimized: requesting ${propertyRefs.length} property references');

    // Faire la requête read-property-multiple
    final rpmUrl = '$baseUrl$_bacnetBasePath/objects/read-property-multiple';

    try {
      final rpmResponse = await _dio.post(
        rpmUrl,
        data: {
          'encode': 'text',
          'propertyReferences': propertyRefs,
        },
        options: _jsonOptions,
      );

      logger.d(() => '_getAllPointsV1Optimized: response status=${rpmResponse.statusCode}');
      _throwIfAuthError(rpmResponse);

      if (rpmResponse.statusCode == 200 && rpmResponse.data != null) {
        return _parsePointsFromRpm(rpmResponse.data);
      }
      logger.w('_getAllPointsV1Optimized: RPM status=${rpmResponse.statusCode}');
    } on ApiAuthException {
      rethrow;
    } catch (e) {
      logger.e('_getAllPointsV1Optimized: read-property-multiple failed: $e');
    }

    // En cas d'échec, on fallback sur la méthode classique
    logger.i('_getAllPointsV1Optimized: falling back to getAllObjects()');
    return getAllObjects();
  }

  /// Récupère tous les points V2 via batch API
  Future<List<BacnetObject>> _getAllPointsV2Optimized() async {
    logger.i('_getAllPointsV2Optimized: fetching all points with batch API');

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

    final batchUrl = '$baseUrl${ApiConstants.v2Batch}';
    logger.i('_getAllPointsV2Optimized: POST $batchUrl with ${requests.length} requests');

    try {
      final response = await _dio.post(
        batchUrl,
        data: {'requests': requests},
        options: _jsonOptions,
      );

      logger.d(() => '_getAllPointsV2Optimized: response status=${response.statusCode}');
      _throwIfAuthError(response);

      if (response.statusCode == 200 && response.data != null) {
        return _parsePointsFromBatchV2(response.data);
      }
      logger.w('_getAllPointsV2Optimized: batch status=${response.statusCode}');
    } on ApiAuthException {
      rethrow;
    } catch (e) {
      logger.e('_getAllPointsV2Optimized: batch API failed: $e');
    }

    // En cas d'échec, fallback sur la méthode classique
    logger.i('_getAllPointsV2Optimized: falling back to getAllObjects()');
    return getAllObjects();
  }

  /// Parse la réponse batch V2 pour construire les objets BACnet
  List<BacnetObject> _parsePointsFromBatchV2(dynamic data) {
    logger.d(() => '_parsePointsFromBatchV2: data type=${data.runtimeType}');

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
        logger.d(() => '_parsePointsFromBatchV2: extracted ${responses.length} responses from wrapper');
      } else {
        logger.w('_parsePointsFromBatchV2: no responses key found, keys=${data.keys.toList()}');
        return results;
      }
    } else {
      logger.w('_parsePointsFromBatchV2: expected List or Map, got ${data.runtimeType}');
      return results;
    }

    for (final batchResponse in responses) {
      if (batchResponse is! Map<String, dynamic>) continue;

      final id = batchResponse['id'] as String?;
      final body = batchResponse['body'];
      final status = batchResponse['status'];

      if (id == null || body == null) continue;

      // Statut par sous-requête : un type en échec est signalé, pas ignoré en silence
      if (status is int && status != 200) {
        logger.w('_parsePointsFromBatchV2: sub-request "$id" failed with status $status');
        _recordStatus(status, id);
        continue;
      }

      // Mapper l'ID (type kebab-case) vers BacnetObjectType
      final objectType = ApiTypeNames.fromV2Path(id);
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
            // priority-array brut non conservé (non utilisé, coûteux sur de gros volumes)
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

    logger.i('_parsePointsFromBatchV2: parsed ${results.length} objects');

    // Log des points forcés pour debug
    final overriddenCount = results.where((p) => p.isOverridden).length;
    if (overriddenCount > 0) {
      logger.i('_parsePointsFromBatchV2: $overriddenCount points are overridden');
    }

    return results;
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
      logger.w('_parseAlarmTimestamp: failed to parse: $e');
      return null;
    }
  }

  /// Parse la réponse read-property-multiple pour construire les objets BACnet
  List<BacnetObject> _parsePointsFromRpm(dynamic data) {
    logger.d(() => '_parsePointsFromRpm: data type=${data.runtimeType}');

    final objects = <String, Map<String, dynamic>>{};

    List refs;
    if (data is List) {
      refs = data;
    } else if (data is Map<String, dynamic>) {
      refs = data['propertyReferences'] as List? ?? [];
      logger.d(() => '_parsePointsFromRpm: found ${refs.length} propertyReferences');
    } else {
      logger.w('_parsePointsFromRpm: unexpected data format');
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

    logger.d(() => '_parsePointsFromRpm: grouped into ${objects.length} objects');

    // Convertir en liste de BacnetObject
    final result = <BacnetObject>[];
    for (final entry in objects.entries) {
      final props = entry.value;
      final typeName = props['type'] as String;
      final instance = props['instance'] as int;

      // Mapper le nom de type camelCase vers BacnetObjectType
      final objectType = ApiTypeNames.fromV1Name(typeName);

      if (objectType != null) {
        // Parser le priority-array pour détecter les forçages
        // Le format peut être String (V1) ou List (V2)
        final priorityArrayData = props['priorityArray'];
        final priorityArrayRaw = priorityArrayData is String ? priorityArrayData : null;
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

    logger.i('_parsePointsFromRpm: parsed ${result.length} objects');

    // Log des points forcés pour debug
    final overriddenCount = result.where((p) => p.isOverridden).length;
    if (overriddenCount > 0) {
      logger.i('_parsePointsFromRpm: $overriddenCount points are overridden');
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

  dynamic _parseValue(dynamic value) => _parseValueStatic(value);

  static dynamic _parseValueStatic(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    if (value is bool) return value;
    if (value is String) {
      // Essayer de parser comme nombre ('1'/'0' restent numériques : l'UI
      // interprète les binaires via BacnetObject)
      final numValue = num.tryParse(value);
      if (numValue != null) return numValue;
      // Essayer comme booléen
      if (value.toLowerCase() == 'true' || value == 'active') return true;
      if (value.toLowerCase() == 'false' || value == 'inactive') return false;
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
  ///
  /// [wasOutOfService]: the input was already out-of-service (already forced)
  /// before this call. On failure, out-of-service is then left as is: the
  /// compensation only releases what this call has set.
  Future<bool> forceInput(
    BacnetObjectType type,
    int instance,
    dynamic value, {
    bool wasOutOfService = false,
  }) async {
    if (apiVersion == 'V2') {
      return _forceInputV2(type, instance, value, wasOutOfService: wasOutOfService);
    }
    return _forceInputV1(type, instance, value, wasOutOfService: wasOutOfService);
  }

  /// True if a failed write may nevertheless have been applied by the
  /// controller (request sent, answer not received in time).
  static bool _mayHaveBeenApplied(Object error) =>
      error is DioException && error.type == DioExceptionType.receiveTimeout;

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
    final typeName = ApiTypeNames.v1Name(type);

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

    logger.i('_writePropertyV1: POST $url property=$property, value=$value');

    try {
      final response = await _dio.post(
        url,
        data: body,
        options: _jsonOptions,
      );

      logger.i('_writePropertyV1: status=${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      logger.e('_writePropertyV1 error: $e');
      return false;
    }
  }

  /// Écrit une propriété quelconque sur un objet (V2)
  /// Utilise write-property-multiple avec property-references (format V2)
  Future<bool> _writePropertyV2(BacnetObjectType type, int instance, String property, dynamic value) async {
    final url = '$baseUrl$_bacnetBasePath/objects/write-property-multiple';
    final typeName = ApiTypeNames.v1Name(type);

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

    logger.i('_writePropertyV2: POST $url property=$property, value=$value');

    try {
      final response = await _dio.post(
        url,
        data: body,
        options: _jsonOptions,
      );

      logger.i('_writePropertyV2: status=${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      logger.e('_writePropertyV2 error: $e');
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
    final typeName = ApiTypeNames.v1Name(type);

    // Formater la valeur pour l'API - toujours en String
    final formattedValue = formatValueForWriteV1(type, value);

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

    logger.i('_writeValueV1: POST $url with priority=$priority, value=$formattedValue');

    try {
      final response = await _dio.post(
        url,
        data: body,
        options: _jsonOptions,
      );

      logger.i('_writeValueV1: status=${response.statusCode}');
      logger.d(() => '_writeValueV1: response=${response.data}');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      logger.e('_writeValueV1 error: $e');
      return false;
    }
  }

  /// Libération V1 via write-property-multiple avec "Null"
  Future<bool> _releaseOverrideV1(BacnetObjectType type, int instance, {int priority = 8}) async {
    final url = '$baseUrl$_bacnetBasePath/objects/write-property-multiple';
    final typeName = ApiTypeNames.v1Name(type);

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

    logger.i('_releaseOverrideV1: POST $url with priority=$priority, value=Null');

    try {
      final response = await _dio.post(
        url,
        data: body,
        options: _jsonOptions,
      );

      logger.i('_releaseOverrideV1: status=${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      logger.e('_releaseOverrideV1 error: $e');
      return false;
    }
  }

  /// Formate une valeur pour l'écriture V1 - TOUJOURS en String
  static String formatValueForWriteV1(BacnetObjectType type, dynamic value) {
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
    final typeName = ApiTypeNames.v1Name(type);

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

    logger.i('_emergencyReleaseV1: releasing all priorities for $typeName:$instance');

    try {
      final response = await _dio.post(
        url,
        data: body,
        options: _jsonOptions,
      );

      logger.i('_emergencyReleaseV1: status=${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      logger.e('_emergencyReleaseV1 error: $e');
      return false;
    }
  }

  /// Force une entrée V1 : out-of-service=true et present-value dans UN SEUL
  /// write-property-multiple (les deux références sont appliquées ensemble).
  /// En cas d'échec, tente de remettre out-of-service à false pour ne pas
  /// laisser un capteur gelé à une valeur obsolète.
  Future<bool> _forceInputV1(
    BacnetObjectType type,
    int instance,
    dynamic value, {
    bool wasOutOfService = false,
  }) async {
    final url = '$baseUrl$_bacnetBasePath/objects/write-property-multiple';
    final body = buildForceInputV1Body(type, instance, value);

    logger.i('_forceInputV1: out-of-service=true + present-value for ${ApiTypeNames.v1Name(type)}:$instance');

    int? status;
    var mayHaveBeenApplied = false;
    try {
      final response = await _postJson(url, body);
      status = response.statusCode;
      logger.i('_forceInputV1: status=$status');
      if (isHttpOk(status)) return true;
    } catch (e) {
      logger.e('_forceInputV1 error: $e');
      mayHaveBeenApplied = _mayHaveBeenApplied(e);
    }

    // Pas de compensation si : 401/403 (rien n'a été écrit), entrée déjà
    // forcée avant l'appel, ou timeout de réponse (forçage peut-être appliqué)
    if (status != 401 && status != 403 && !wasOutOfService && !mayHaveBeenApplied) {
      logger.w('_forceInputV1: failed, releasing out-of-service (compensation)');
      await _releaseInputV1(type, instance);
    }
    return false;
  }

  /// Corps write-property-multiple V1 du forçage d'une entrée (testable).
  static Map<String, dynamic> buildForceInputV1Body(BacnetObjectType type, int instance, dynamic value) {
    final typeName = ApiTypeNames.v1Name(type);
    return {
      'encode': 'text',
      'propertyReferences': [
        {
          'type': typeName,
          'instance': instance,
          'property': 'outOfService',
          'value': 'true',
        },
        {
          'type': typeName,
          'instance': instance,
          'property': 'presentValue',
          'value': formatValueForWriteV1(type, value),
        },
      ],
    };
  }

  /// Libère une entrée forcée V1 en remettant out-of-service à false
  Future<bool> _releaseInputV1(BacnetObjectType type, int instance) async {
    final url = '$baseUrl$_bacnetBasePath/objects/write-property-multiple';
    final typeName = ApiTypeNames.v1Name(type);

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

    logger.i('_releaseInputV1: Setting out-of-service=false for $typeName:$instance');

    try {
      final response = await _dio.post(
        url,
        data: body,
        options: _jsonOptions,
      );

      logger.i('_releaseInputV1: status=${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      logger.e('_releaseInputV1 error: $e');
      return false;
    }
  }

  // ============ Méthodes V2 ============

  /// Écriture simple V2 via set-value
  Future<bool> _writeValueV2(BacnetObjectType type, int instance, dynamic value) async {
    final typePath = ApiTypeNames.v2Path(type);
    final url = '$baseUrl$_bacnetBasePath/objects/$typePath/$instance/set-value';

    final formattedValue = _formatValueForWrite(type, value);

    logger.i('_writeValueV2: POST $url with value=$formattedValue');

    try {
      final response = await _dio.post(
        url,
        data: {'value': formattedValue},
        options: _jsonOptions,
      );

      logger.i('_writeValueV2: status=${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      logger.e('_writeValueV2 error: $e');
      return false;
    }
  }

  /// Forçage V2 via set-value-at
  Future<bool> _writeOverrideV2(BacnetObjectType type, int instance, dynamic value, {int priority = 8}) async {
    final typePath = ApiTypeNames.v2Path(type);
    final url = '$baseUrl$_bacnetBasePath/objects/$typePath/$instance/set-value-at';

    final formattedValue = _formatValueForWrite(type, value);

    logger.i('_writeOverrideV2: POST $url with value=$formattedValue, priority=$priority');

    try {
      final response = await _dio.post(
        url,
        data: {
          'value': formattedValue,
          'priority': priority,
        },
        options: _jsonOptions,
      );

      logger.i('_writeOverrideV2: status=${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      logger.e('_writeOverrideV2 error: $e');
      return false;
    }
  }

  /// Libération V2 via set-value-at avec null
  Future<bool> _releaseOverrideV2(BacnetObjectType type, int instance, {int priority = 8}) async {
    final typePath = ApiTypeNames.v2Path(type);
    final url = '$baseUrl$_bacnetBasePath/objects/$typePath/$instance/set-value-at';

    logger.i('_releaseOverrideV2: POST $url with value=null, priority=$priority');

    try {
      final response = await _dio.post(
        url,
        data: {
          'value': null,
          'priority': priority,
        },
        options: _jsonOptions,
      );

      logger.i('_releaseOverrideV2: status=${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      logger.e('_releaseOverrideV2 error: $e');
      return false;
    }
  }

  /// Libération d'urgence V2 via emergency-auto
  Future<bool> _emergencyReleaseV2(BacnetObjectType type, int instance) async {
    final typePath = ApiTypeNames.v2Path(type);
    final url = '$baseUrl$_bacnetBasePath/objects/$typePath/$instance/emergency-auto';

    logger.i('_emergencyReleaseV2: POST $url');

    try {
      final response = await _dio.post(
        url,
        data: {},
        options: _jsonOptions,
      );

      logger.i('_emergencyReleaseV2: status=${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      logger.e('_emergencyReleaseV2 error: $e');
      return false;
    }
  }

  /// Force une entrée V2 en mettant out-of-service à true puis en écrivant present-value.
  /// Si l'écriture de present-value échoue, out-of-service est remis à false
  /// (compensation) pour ne pas laisser l'entrée gelée.
  Future<bool> _forceInputV2(
    BacnetObjectType type,
    int instance,
    dynamic value, {
    bool wasOutOfService = false,
  }) async {
    final typePath = ApiTypeNames.v2Path(type);
    final formattedValue = _formatValueForWrite(type, value);

    // Étape 1: Mettre out-of-service à true via POST sur la propriété
    final oosUrl = '$baseUrl$_bacnetBasePath/objects/$typePath/$instance/out-of-service';
    logger.i('_forceInputV2: Setting out-of-service=true for $typePath/$instance');

    try {
      final oosResponse = await _postJson(oosUrl, {'\$value': true});
      if (!isHttpOk(oosResponse.statusCode)) {
        logger.e('_forceInputV2: Failed to set out-of-service, status=${oosResponse.statusCode}');
        return false;
      }
    } catch (e) {
      logger.e('_forceInputV2: out-of-service error: $e');
      return false;
    }

    // Étape 2: Écrire present-value via POST sur la propriété
    final pvUrl = '$baseUrl$_bacnetBasePath/objects/$typePath/$instance/present-value';
    logger.i('_forceInputV2: Writing present-value=$formattedValue for $typePath/$instance');

    try {
      final pvResponse = await _postJson(pvUrl, {'\$value': formattedValue});
      logger.i('_forceInputV2: status=${pvResponse.statusCode}');
      if (isHttpOk(pvResponse.statusCode)) return true;
    } catch (e) {
      logger.e('_forceInputV2: present-value error: $e');
      if (_mayHaveBeenApplied(e)) {
        logger.w('_forceInputV2: response timeout, value may be applied: no compensation');
        return false;
      }
    }

    // Already forced before this call: keep it forced (previous value)
    if (wasOutOfService) {
      logger.w('_forceInputV2: present-value write failed, input was already out-of-service: no compensation');
      return false;
    }

    // Compensation : ne pas laisser l'entrée hors service à une valeur obsolète
    logger.w('_forceInputV2: present-value write failed, releasing out-of-service (compensation)');
    final released = await _releaseInputV2(type, instance);
    if (!released) {
      logger.e('_forceInputV2: compensation failed, $typePath/$instance may stay out-of-service');
    }
    return false;
  }

  /// Libère une entrée forcée V2 en remettant out-of-service à false
  Future<bool> _releaseInputV2(BacnetObjectType type, int instance) async {
    final typePath = ApiTypeNames.v2Path(type);
    final url = '$baseUrl$_bacnetBasePath/objects/$typePath/$instance/out-of-service';

    logger.i('_releaseInputV2: Setting out-of-service=false for $typePath/$instance');

    try {
      final response = await _dio.post(
        url,
        data: {'\$value': false},
        options: _jsonOptions,
      );

      logger.i('_releaseInputV2: status=${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      logger.e('_releaseInputV2 error: $e');
      return false;
    }
  }

  // ============ Helpers ============

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
    logger.i('_getTrendLogsV1: fetching trend-logs');

    final url = '$baseUrl$_bacnetBasePath/objects/trendLog';

    try {
      final response = await _dio.get(url, options: _authOptions);
      logger.d(() => '_getTrendLogsV1: status=${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final trendLogs = <Map<String, dynamic>>[];

        if (data is List) {
          logger.d(() => '_getTrendLogsV1: data is List with ${data.length} items');
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

        logger.i(() => '_getTrendLogsV1: parsed ${trendLogs.length} trend-logs: ${trendLogs.map((t) => t['instance']).toList()}');
        return trendLogs;
      }
    } catch (e) {
      logger.e('_getTrendLogsV1 error: $e');
    }

    return [];
  }

  /// Récupère les trend-logs V2
  Future<List<Map<String, dynamic>>> _getTrendLogsV2() async {
    logger.i('_getTrendLogsV2: fetching trend-logs');

    try {
      final data = await _fetchTrendLogsRawV2();
      if (data == null) return [];
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
    } catch (e) {
      logger.e('_getTrendLogsV2 error: $e');
    }

    return [];
  }

  /// Short-lived cache of the V2 trend-logs collection, shared by
  /// [getTrendLogs] and [getTrendLogMapping] (avoids a duplicate GET).
  static const _trendLogsCacheTtl = Duration(seconds: 30);
  dynamic _trendLogsRawV2;
  DateTime? _trendLogsRawV2At;

  /// GET /objects/trend-logs (V2), deduplicated and cached for a few seconds.
  /// Returns null if the collection could not be read.
  Future<dynamic> _fetchTrendLogsRawV2() {
    final cachedAt = _trendLogsRawV2At;
    if (_trendLogsRawV2 != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < _trendLogsCacheTtl) {
      return Future.value(_trendLogsRawV2);
    }
    return _dedup('GET trend-logs', () async {
      final url = '$baseUrl$_bacnetBasePath/objects/trend-logs';
      final response = await _dio.get(url, options: _authOptions);
      logger.d(() => '_fetchTrendLogsRawV2: status=${response.statusCode}');
      if (response.statusCode != 200 || response.data == null) return null;
      _trendLogsRawV2 = response.data;
      _trendLogsRawV2At = DateTime.now();
      return response.data;
    });
  }

  /// Récupère le mapping trend-log -> objet tracké.
  /// Retourne une Map dont la clé est "objectType:objectInstance" (ex. `analog-value:12`)
  /// et la valeur l'instance du trend-log. Les appels concurrents sont dédupliqués.
  Future<Map<String, int>> getTrendLogMapping() {
    return _dedup('trendLogMapping', () {
      if (apiVersion == 'V2') {
        return _getTrendLogMappingV2();
      }
      return _getTrendLogMappingV1();
    });
  }

  /// Récupère le mapping V1 via read-property-multiple.
  /// Essaie d'abord une seule requête (instance=-1 = tous les trend-logs), puis
  /// l'ancienne méthode (liste puis RPM) si elle ne donne rien.
  Future<Map<String, int>> _getTrendLogMappingV1() async {
    logger.i('_getTrendLogMappingV1: loading trend log mapping');

    final rpmUrl = '$baseUrl$_bacnetBasePath/objects/read-property-multiple';

    // 1 requête : tous les trend-logs d'un coup
    try {
      final response = await _postJson(rpmUrl, {
        'encode': 'text',
        'propertyReferences': [
          {
            'type': ApiTypeNames.v1Name(BacnetObjectType.trendLog),
            'instance': -1,
            'property': 'logDeviceObjectProperty',
            'arrayIndex': -1,
          },
        ],
      });
      if (response.statusCode == 200 && response.data != null) {
        final mapping = parseTrendLogMappingV1(response.data);
        if (mapping.isNotEmpty) {
          logger.i('_getTrendLogMappingV1: found ${mapping.length} mappings (single request)');
          return mapping;
        }
      }
    } catch (e) {
      logger.w('_getTrendLogMappingV1: wildcard RPM failed: $e');
    }

    // Repli : récupérer la liste des trend-logs puis leurs propriétés
    final trendLogs = await _getTrendLogsV1();
    logger.i('_getTrendLogMappingV1: got ${trendLogs.length} trend-logs');
    if (trendLogs.isEmpty) {
      logger.w('_getTrendLogMappingV1: no trend-logs found, returning empty mapping');
      return {};
    }

    final propertyRefs = trendLogs.map((tl) => {
      'type': ApiTypeNames.v1Name(BacnetObjectType.trendLog),
      'instance': tl['instance'],
      'property': 'logDeviceObjectProperty',
      'arrayIndex': -1,
    }).toList();

    logger.d(() => '_getTrendLogMappingV1: requesting ${propertyRefs.length} properties');

    var mapping = <String, int>{};
    try {
      final response = await _postJson(rpmUrl, {
        'encode': 'text',
        'propertyReferences': propertyRefs,
      });

      logger.d(() => '_getTrendLogMappingV1: status=${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        mapping = parseTrendLogMappingV1(response.data);
      }
    } catch (e) {
      logger.e('_getTrendLogMappingV1 error: $e');
    }

    logger.i('_getTrendLogMappingV1: found ${mapping.length} mappings');
    return mapping;
  }

  /// Parse une réponse RPM `logDeviceObjectProperty` (V1) en mapping
  /// `objectType:objectInstance` -> instance du trend-log.
  static Map<String, int> parseTrendLogMappingV1(dynamic data) {
    final mapping = <String, int>{};
    for (final ref in _extractRpmRefs(data)) {
      if (ref is! Map) continue;

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
          final trendLogInstance = instance is int ? instance : int.tryParse(instance.toString());
          if (trendLogInstance == null) continue;
          mapping['$objectType:$objectInstance'] = trendLogInstance;
        }
      }
    }
    return mapping;
  }

  /// Récupère le mapping V2 (réutilise la collection trend-logs mise en cache)
  Future<Map<String, int>> _getTrendLogMappingV2() async {
    logger.i('_getTrendLogMappingV2: loading trend log mapping');

    var mapping = <String, int>{};
    try {
      final data = await _fetchTrendLogsRawV2();
      if (data is Map<String, dynamic>) {
        mapping = parseTrendLogMappingV2(data);
      }
    } catch (e) {
      logger.e('_getTrendLogMappingV2 error: $e');
    }

    logger.i('_getTrendLogMappingV2: found ${mapping.length} mappings');
    return mapping;
  }

  /// Parse la collection trend-logs V2 (`{instance: {source-reference: ...}}`).
  static Map<String, int> parseTrendLogMappingV2(Map<String, dynamic> data) {
    final mapping = <String, int>{};
    data.forEach((key, value) {
      final instance = int.tryParse(key);
      if (instance == null || value is! Map<String, dynamic>) return;

      // En V2, la propriété s'appelle 'source-reference'
      final logProp = value['source-reference'];
      if (logProp is! Map<String, dynamic>) return;

      // Format V2: {object-identifier: {object-type: "AnalogValue", object-instance: 17}}
      final objectId = logProp['object-identifier'];
      if (objectId is! Map<String, dynamic>) return;

      final rawType = objectId['object-type']?.toString();
      final objectInstance = objectId['object-instance'];
      if (rawType == null || objectInstance is! int) return;

      // Convertir PascalCase en kebab-case (AnalogValue -> analog-value)
      final objectType = rawType
          .replaceAllMapped(RegExp(r'([A-Z])'), (m) => '-${m.group(1)!.toLowerCase()}')
          .replaceFirst('-', ''); // Enlever le tiret initial
      mapping['$objectType:$objectInstance'] = instance;
    });
    return mapping;
  }

  /// Récupère le log buffer d'un trend-log spécifique (V1)
  /// Si allData=true, récupère tout l'historique sans limite de temps
  /// Retourne une chaîne (JSON ré-encodé ou texte V1) : préférer
  /// [getTrendLogBufferData] qui évite de ré-encoder de gros volumes.
  Future<String?> getTrendLogBuffer(int trendLogInstance, {bool allData = false}) async {
    final data = await getTrendLogBufferData(trendLogInstance, allData: allData);
    if (data == null) return null;
    if (data is String) return data;
    return jsonEncode(data);
  }

  /// Comme [getTrendLogBuffer], mais retourne les données telles que décodées
  /// par Dio : `List`/`Map` (JSON V1 /trend ou V2 get-table, à passer
  /// directement à `TrendLogBufferParser.parseV2`) ou `String` (texte du
  /// logBuffer V1, pour `TrendLogBufferParser.parseV1`). Pas de ré-encodage JSON.
  Future<Object?> getTrendLogBufferData(int trendLogInstance, {bool allData = false}) {
    return _dedup('trendBuffer:$trendLogInstance:$allData', () {
      if (apiVersion == 'V2') {
        return _getTrendLogBufferV2(trendLogInstance, allData: allData);
      }
      return _getTrendLogBufferV1(trendLogInstance, allData: allData);
    });
  }

  /// Récupère le log buffer V1 via l'endpoint /trend
  /// Utilise les paramètres start/stop pour la plage de temps et limit pour le nombre de records
  /// Si allData=true, ne met pas de limite de temps (récupère tout)
  /// Doc: https://wiki.distech-controls.com/RestAPI/Protocols/BACnet/Local/Objects/ObjectType/ObjectInstance/Trend/GET-trend
  Future<Object?> _getTrendLogBufferV1(int trendLogInstance, {int? maxRecords, bool allData = false}) async {
    logger.i('_getTrendLogBufferV1: fetching trend data for trend-log $trendLogInstance, allData=$allData');

    // D'abord, récupérer les infos du trend-log pour trouver l'objet source
    String? sourceObjectType;
    String? sourceObjectInstance;

    // Méthode 1: Essayer de récupérer les infos du trend-log directement
    try {
      final infoUrl = '$baseUrl$_bacnetBasePath/objects/trendLog/$trendLogInstance';
      logger.d(() => '_getTrendLogBufferV1: fetching trend-log info from $infoUrl');
      final infoResponse = await _dio.get(infoUrl, options: _authOptions);

      if (infoResponse.statusCode == 200 && infoResponse.data is Map<String, dynamic>) {
        final data = infoResponse.data as Map<String, dynamic>;
        logger.d(() => '_getTrendLogBufferV1: trend-log response keys: ${data.keys.toList()}');

        final recordCount = data['record-count'] ?? data['recordCount'];
        final bufferSize = data['buffer-size'] ?? data['bufferSize'];
        final logInterval = data['log-interval'] ?? data['logInterval'];
        final logProp = data['log-device-object-property']?.toString() ?? data['logDeviceObjectProperty']?.toString();
        logger.i('_getTrendLogBufferV1: trend-log info: recordCount=$recordCount, bufferSize=$bufferSize, logInterval=$logInterval, logProp=$logProp');

        // Parser l'objet source depuis log-device-object-property
        // Format: "[Analog Input 101,Present Value,,]"
        if (logProp != null && logProp != 'null') {
          final match = RegExp(r'\[([^,]+)\s+(\d+),').firstMatch(logProp);
          if (match != null) {
            sourceObjectType = match.group(1)?.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '-');
            sourceObjectInstance = match.group(2);
            logger.i('_getTrendLogBufferV1: source object from logProp: $sourceObjectType/$sourceObjectInstance');
          }
        }
      }
    } catch (e) {
      logger.w('_getTrendLogBufferV1: failed to get trend-log info: $e');
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

        logger.i('_getTrendLogBufferV1: deduced source object from instance: $sourceObjectType/$sourceObjectInstance (prefix=$prefix)');
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
        logger.i('_getTrendLogBufferV1: fetching ALL data from /trend endpoint');
      } else {
        // Limiter aux 30 derniers jours
        final start = now.subtract(const Duration(days: 30));
        final startMs = start.millisecondsSinceEpoch;
        final stopMs = now.millisecondsSinceEpoch;
        trendUrl = '$baseUrl$_bacnetBasePath/objects/$sourceObjectType/$sourceObjectInstance/trend'
            '?dataOnly=true&iso8601=true&start=$startMs&stop=$stopMs&limit=$limit';
        logger.i('_getTrendLogBufferV1: fetching 30 days from /trend endpoint');
        logger.d(() => '_getTrendLogBufferV1: time range: ${start.toIso8601String()} -> ${now.toIso8601String()}');
      }

      logger.i('_getTrendLogBufferV1: URL=$trendUrl');

      try {
        final response = await _dio.get(
          trendUrl,
          options: Options(
            headers: {'Authorization': basicAuth},
            receiveTimeout: ApiConstants.longReceiveTimeout,
            sendTimeout: ApiConstants.longSendTimeout,
          ),
        );

        logger.i('_getTrendLogBufferV1: /trend response status=${response.statusCode}, dataType=${response.data?.runtimeType}');

        if (response.statusCode == 200 && response.data != null) {
          // La réponse est une liste JSON de records
          if (response.data is List) {
            final records = response.data as List;
            logger.i('_getTrendLogBufferV1: got ${records.length} records from /trend endpoint');

            // Log le premier record pour debug
            if (records.isNotEmpty) {
              logger.d(() => '_getTrendLogBufferV1: first record: ${records.first}');
            }

            // Données déjà décodées par Dio : pas de ré-encodage
            return records;
          } else if (response.data is Map) {
            // Parfois la réponse est dans un wrapper
            logger.d(() => '_getTrendLogBufferV1: response is Map with keys: ${(response.data as Map).keys}');
            return response.data as Map;
          } else {
            logger.w('_getTrendLogBufferV1: unexpected response type: ${response.data.runtimeType}');
          }
        } else {
          logger.w('_getTrendLogBufferV1: /trend returned status=${response.statusCode}');
        }
      } catch (e, st) {
        logger.e('_getTrendLogBufferV1: /trend endpoint failed: $e');
        logger.d(() => '_getTrendLogBufferV1: stacktrace: $st');
      }
    } else {
      logger.w('_getTrendLogBufferV1: source object not found (type=$sourceObjectType, instance=$sourceObjectInstance)');
    }

    // Fallback: essayer le logBuffer directement (moins fiable)
    logger.w('_getTrendLogBufferV1: falling back to logBuffer property');
    final logBufferUrl = '$baseUrl$_bacnetBasePath/objects/trendLog/$trendLogInstance/properties/logBuffer';

    try {
      final response = await _dio.get(
        logBufferUrl,
        options: Options(
          headers: {'Authorization': basicAuth},
          receiveTimeout: ApiConstants.longReceiveTimeout,
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
          logger.i('_getTrendLogBufferV1: got ${value.length} chars from logBuffer');
          return value;
        }
      }
    } catch (e) {
      logger.e('_getTrendLogBufferV1: logBuffer fallback failed: $e');
    }

    logger.e('_getTrendLogBufferV1: all attempts failed for trend-log $trendLogInstance');
    return null;
  }

  /// Récupère le log buffer V2 via l'API history
  /// Si allData=true, récupère tout l'historique (depuis 10 ans)
  Future<Object?> _getTrendLogBufferV2(int trendLogInstance, {bool allData = false}) async {
    logger.i('_getTrendLogBufferV2: fetching history for trend-log $trendLogInstance, allData=$allData');

    // D'abord récupérer le nom de l'historique depuis le trend-log
    String? historyName;
    // Réutiliser la collection trend-logs récemment lue si elle contient le nom
    final cached = _trendLogsRawV2;
    if (cached is Map && cached['$trendLogInstance'] is Map) {
      historyName = (cached['$trendLogInstance'] as Map)['history']?.toString();
    }
    if (historyName == null || historyName.isEmpty) {
      try {
        final trendLogUrl = '$baseUrl$_bacnetBasePath/objects/trend-logs/$trendLogInstance';
        final trendLogResponse = await _dio.get(trendLogUrl, options: _authOptions);
        if (trendLogResponse.statusCode == 200 && trendLogResponse.data is Map<String, dynamic>) {
          historyName = trendLogResponse.data['history']?.toString();
          logger.d(() => '_getTrendLogBufferV2: got history name: $historyName');
        }
      } catch (e) {
        logger.w('_getTrendLogBufferV2: failed to get history name: $e');
      }
    }

    if (historyName == null || historyName.isEmpty) {
      logger.w('_getTrendLogBufferV2: no history name found for trend-log $trendLogInstance');
      return null;
    }

    // En V2, utiliser l'API history avec get-table (données brutes, pas d'agrégation)
    // get-history fait de l'agrégation automatique, get-table retourne les données brutes
    final url = '$baseUrl${ApiConstants.v2BacnetHistories}/get-table';

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

    logger.i('_getTrendLogBufferV2: ${allData ? "fetching ALL data" : "fetching 30 days"}');

    final requestData = {
      'history': historyName,
      'time-range': timeRange,
      'limit': 0, // 0 = pas de limite, retourne toutes les données
    };
    logger.d(() => '_getTrendLogBufferV2: POST $url');
    logger.d(() => '_getTrendLogBufferV2: body=$requestData');

    try {
      // get-table avec limit=0 sur une longue période : timeout long (comme en V1)
      final response = await _postJson(
        url,
        requestData,
        options: _jsonOptions.copyWith(
          receiveTimeout: ApiConstants.longReceiveTimeout,
          sendTimeout: ApiConstants.longSendTimeout,
        ),
      );

      logger.d(() => '_getTrendLogBufferV2: status=${response.statusCode}, response=${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        // Format V2: {columns: [...], rows: [...]} déjà décodé par Dio
        if (response.data is Map || response.data is List) {
          return response.data as Object;
        }
        return response.data.toString();
      }
    } catch (e) {
      logger.e('_getTrendLogBufferV2 error: $e');
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
    logger.i('_getSchedulesV1: fetching schedules');

    // D'abord récupérer la liste des instances
    final listUrl = '$baseUrl$_bacnetBasePath/objects/schedule';

    try {
      final listResponse = await _dio.get(listUrl, options: _authOptions);
      logger.d(() => '_getSchedulesV1: list status=${listResponse.statusCode}');

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

      logger.i('_getSchedulesV1: found ${instances.length} schedules: $instances');

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
          options: _jsonOptions,
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
      logger.e('_getSchedulesV1 error: $e');
      return [];
    }
  }

  /// Récupère les schedules V2
  Future<List<ScheduleSummary>> _getSchedulesV2() async {
    logger.i('_getSchedulesV2: fetching schedules');

    final url = '$baseUrl$_bacnetBasePath/objects/schedules';

    try {
      final response = await _dio.get(url, options: _authOptions);
      logger.d(() => '_getSchedulesV2: status=${response.statusCode}');
      logger.d(() => '_getSchedulesV2: response type=${response.data.runtimeType}');
      logger.d(() => '_getSchedulesV2: response data=${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        final schedules = <ScheduleSummary>[];

        if (response.data is Map<String, dynamic>) {
          final data = response.data as Map<String, dynamic>;
          logger.d(() => '_getSchedulesV2: data keys=${data.keys.toList()}');
          data.forEach((key, value) {
            final instance = int.tryParse(key);
            logger.d(() => '_getSchedulesV2: key=$key, instance=$instance, value type=${value.runtimeType}');
            if (instance != null && value is Map<String, dynamic>) {
              schedules.add(ScheduleSummary.fromV2(instance, value));
            }
          });
        }

        logger.i('_getSchedulesV2: found ${schedules.length} schedules');
        return schedules;
      }
    } catch (e) {
      logger.e('_getSchedulesV2 error: $e');
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
    logger.i('_getScheduleDetailV1: fetching schedule $instance');

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

      final weeklyUrl = '$baseUrl$_bacnetBasePath/objects/schedule/$instance/properties/weekly-schedule';

      // Trois requêtes indépendantes : en parallèle (1 aller-retour au lieu de 3)
      final results = await Future.wait<Object?>([
        _postJson(rpmUrl, {'encode': 'text', 'propertyReferences': propertyRefs}),
        _dio.get(weeklyUrl, options: _authOptions),
        _getScheduleStateTextsV1(instance),
      ]);
      final rpmResponse = results[0] as Response;
      final weeklyResponse = results[1] as Response;
      final stateTexts = results[2] as List<ScheduleStateText>;

      // Planning illisible : planning vide affiché en lecture seule
      // (weeklyScheduleReadable=false), jamais sauvegardé sur l'automate
      final weeklySchedule = parseWeeklyScheduleResponse(
        weeklyResponse.statusCode,
        weeklyResponse.data,
        WeeklySchedule.fromV1,
      );
      if (weeklySchedule == null) {
        logger.e('_getScheduleDetailV1: weekly-schedule unreadable '
            '(status=${weeklyResponse.statusCode}), schedule $instance read-only');
      }

      String objectName = 'Schedule $instance';
      String? description;
      dynamic presentValue;
      dynamic scheduleDefault;

      if (rpmResponse.statusCode == 200 && rpmResponse.data != null) {
        for (final ref in _extractRpmRefs(rpmResponse.data)) {
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

      // Déterminer le type de valeur
      final valueType = ScheduleValueType.fromValue(presentValue);

      return Schedule(
        instance: instance,
        objectName: objectName,
        description: description,
        // Unreadable: empty placeholder, flagged read-only (never saved)
        weeklySchedule: weeklySchedule ?? WeeklySchedule.empty(),
        weeklyScheduleReadable: weeklySchedule != null,
        stateTexts: stateTexts,
        valueType: valueType,
        presentValue: presentValue,
        scheduleDefault: scheduleDefault,
      );
    } catch (e) {
      logger.e('_getScheduleDetailV1 error: $e');
      return null;
    }
  }

  /// Parses a weekly-schedule GET response. Returns null (never an empty
  /// planning) when the response is not a 200 with a JSON object body.
  static WeeklySchedule? parseWeeklyScheduleResponse(
    int? statusCode,
    dynamic data,
    WeeklySchedule Function(Map<String, dynamic>) parse,
  ) {
    if (statusCode != 200 || data is! Map<String, dynamic>) return null;
    try {
      return parse(data);
    } catch (e) {
      logger.e('parseWeeklyScheduleResponse: invalid weekly-schedule: $e');
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

      logger.d(() => '_getScheduleStateTextsV1: response=${response.data}');

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
      logger.w('_getScheduleStateTextsV1: error fetching state texts: $e');
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
            logger.d(() => '_parseScheduleStateTextV1: parsed state $index = "$displayLabel"');
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
    logger.i('_getScheduleDetailV2: fetching schedule $instance');

    try {
      // Récupérer les propriétés principales (sans $select qui cause des problèmes)
      // et le weekly-schedule en parallèle (requêtes indépendantes)
      final url = '$baseUrl$_bacnetBasePath/objects/schedules/$instance';
      final weeklyUrl = '$baseUrl$_bacnetBasePath/objects/schedules/$instance/weekly-schedule';
      final responses = await Future.wait([
        _dio.get(url, options: _authOptions),
        _dio.get(weeklyUrl, options: _authOptions),
      ]);
      final response = responses[0];
      final weeklyResponse = responses[1];

      if (response.statusCode != 200 || response.data is! Map<String, dynamic>) {
        return null;
      }

      // Planning illisible : planning vide en lecture seule (jamais sauvegardé)
      final weeklySchedule = parseWeeklyScheduleResponse(
        weeklyResponse.statusCode,
        weeklyResponse.data,
        WeeklySchedule.fromV2,
      );
      if (weeklySchedule == null) {
        logger.e('_getScheduleDetailV2: weekly-schedule unreadable '
            '(status=${weeklyResponse.statusCode}), schedule $instance read-only');
      }

      final data = response.data as Map<String, dynamic>;
      logger.d(() => '_getScheduleDetailV2: data keys=${data.keys.toList()}');

      final objectName = data['object-name']?.toString() ?? 'Schedule $instance';
      final description = data['description']?.toString();
      final presentValue = data['present-value'];
      final scheduleDefault = data['schedule-default'];

      // Parser les state-texts (V2 utilise 'schedule-state-text')
      final stateTexts = <ScheduleStateText>[];
      final stateTextData = data['schedule-state-text'];
      logger.d(() => '_getScheduleDetailV2: schedule-state-text=$stateTextData');

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

      logger.d(() => '_getScheduleDetailV2: parsed stateTexts=${stateTexts.length}');

      // Valeurs par défaut si vide
      if (stateTexts.isEmpty) {
        stateTexts.add(ScheduleStateText(index: 0, text: 'Inoccupé'));
        stateTexts.add(ScheduleStateText(index: 1, text: 'Occupé'));
      }

      return Schedule(
        instance: instance,
        objectName: objectName,
        description: description,
        // Unreadable: empty placeholder, flagged read-only (never saved)
        weeklySchedule: weeklySchedule ?? WeeklySchedule.empty(),
        weeklyScheduleReadable: weeklySchedule != null,
        stateTexts: stateTexts,
        valueType: ScheduleValueType.fromValue(presentValue),
        presentValue: presentValue,
        scheduleDefault: scheduleDefault,
      );
    } catch (e) {
      logger.e('_getScheduleDetailV2 error: $e');
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
    logger.i('_writeWeeklyScheduleV1: writing schedule $instance');

    final url = '$baseUrl$_bacnetBasePath/objects/schedule/$instance/properties/weekly-schedule';
    final body = weeklySchedule.toV1Json();

    logger.d(() => '_writeWeeklyScheduleV1: body=$body');

    try {
      final response = await _dio.post(
        url,
        data: body,
        options: _jsonOptions,
      );

      logger.i('_writeWeeklyScheduleV1: status=${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      logger.e('_writeWeeklyScheduleV1 error: $e');
      return false;
    }
  }

  /// Écrit le weekly-schedule V2
  Future<bool> _writeWeeklyScheduleV2(int instance, WeeklySchedule weeklySchedule) async {
    logger.i('_writeWeeklyScheduleV2: writing schedule $instance');

    final url = '$baseUrl$_bacnetBasePath/objects/schedules/$instance/weekly-schedule';
    final body = weeklySchedule.toV2Json();

    logger.d(() => '_writeWeeklyScheduleV2: url=$url');
    logger.d(() => '_writeWeeklyScheduleV2: body=$body');

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

      logger.i('_writeWeeklyScheduleV2: status=${response.statusCode}');

      if (response.statusCode == 400) {
        logger.e('_writeWeeklyScheduleV2: 400 Bad Request - response=${response.data}');
        return false;
      }

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      if (e is DioException) {
        logger.e('_writeWeeklyScheduleV2 DioException: ${e.message}');
        logger.e('_writeWeeklyScheduleV2 response: ${e.response?.data}');
      } else {
        logger.e('_writeWeeklyScheduleV2 error: $e');
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

    logger.i('readMultiplePoints: reading ${pointRefs.length} points');

    if (apiVersion == 'V2') {
      return _readMultiplePointsV2(pointRefs);
    } else {
      return _readMultiplePointsV1(pointRefs);
    }
  }

  /// Static (rarely changing) V1 properties of the super-favorites, cached
  /// per object so that periodic refreshes only read presentValue/outOfService.
  static const _staticPropsTtl = Duration(minutes: 10);
  static const _staticPropNamesV1 = [
    'objectName', 'units', 'description', 'activeText', 'inactiveText', 'stateText',
  ];
  final Map<String, ({DateTime at, Map<String, dynamic> props})> _staticPropsCache = {};

  /// Forces the next [readMultiplePoints] to re-read names, units and texts.
  void invalidateStaticPropertiesCache() => _staticPropsCache.clear();

  /// Lecture batch V1 via read-property-multiple
  Future<Map<String, BacnetObject>> _readMultiplePointsV1(List<String> pointRefs) async {
    final rpmUrl = '$baseUrl$_bacnetBasePath/objects/read-property-multiple';
    logger.i('_readMultiplePointsV1: POST $rpmUrl for ${pointRefs.length} points');

    // Construire les propertyReferences pour chaque point
    final propertyRefs = <Map<String, dynamic>>[];
    final now = DateTime.now();
    final cachedKeys = <String>{};

    for (final ref in pointRefs) {
      // Parser le pointRef (format: "analog-value:1" ou "AV:1")
      final parsed = _parsePointRef(ref);
      if (parsed == null) {
        logger.w('_readMultiplePointsV1: invalid pointRef format: $ref');
        continue;
      }

      final type = BacnetObjectType.fromApiName(parsed['type'] as String);
      if (type == null) continue;
      // API V1 : camelCase avec "multistate" en minuscules (multistateValue)
      final typeNameV1 = ApiTypeNames.v1Name(type);
      final instance = parsed['instance'] as int;

      final key = ApiTypeNames.objectKey(type, instance);
      final cached = _staticPropsCache[key];
      final hasFreshStatic = cached != null && now.difference(cached.at) < _staticPropsTtl;

      final props = <String>['presentValue', 'outOfService'];
      if (hasFreshStatic) {
        cachedKeys.add(key);
      } else {
        props.addAll(['objectName', 'units', 'description']);
        // Ajouter les textes pour les types binaires/multistate
        if (type.isBinary) props.addAll(['activeText', 'inactiveText']);
        if (type.isMultiState) props.add('stateText');
      }

      for (final prop in props) {
        propertyRefs.add({
          'type': typeNameV1,
          'instance': instance,
          'property': prop,
          'arrayIndex': -1,
        });
      }
    }

    if (propertyRefs.isEmpty) return {};

    logger.d(() => '_readMultiplePointsV1: ${propertyRefs.length} refs (${cachedKeys.length} points with cached static props)');

    try {
      final response = await _postJson(rpmUrl, {
        'encode': 'text',
        'propertyReferences': propertyRefs,
      });

      logger.d(() => '_readMultiplePointsV1: status=${response.statusCode}, data=${response.data}');
      if (response.statusCode == 200 && response.data != null) {
        final grouped = groupRpmPropertiesByObject(response.data);
        for (final entry in grouped.entries) {
          if (cachedKeys.contains(entry.key)) {
            // Compléter avec les propriétés statiques en cache
            final cached = _staticPropsCache[entry.key]!;
            entry.value.addAll({...cached.props, ...entry.value});
          } else if (entry.value['objectName'] != null) {
            _staticPropsCache[entry.key] = (
              at: now,
              props: {
                for (final name in _staticPropNamesV1)
                  if (entry.value.containsKey(name)) name: entry.value[name],
              },
            );
          }
        }
        return buildMultiplePointsFromGrouped(grouped, pointRefs);
      }
    } catch (e) {
      logger.e('_readMultiplePointsV1 error: $e');
    }

    return {};
  }

  /// True once the controller rejected `$select` in batch sub-requests.
  bool _v2SelectUnsupported = false;

  /// Properties needed to display a super-favorite (V2 `$select`).
  static const _favoriteSelectV2 =
      'object-name,present-value,units,description,out-of-service,active-text,inactive-text,state-text';

  /// Lecture batch V2 via l'API batch
  Future<Map<String, BacnetObject>> _readMultiplePointsV2(List<String> pointRefs) async {
    final useSelect = !_v2SelectUnsupported;
    final result = await _readMultiplePointsV2Batch(pointRefs, useSelect: useSelect);
    if (result != null) return result;
    if (useSelect) {
      // $select refusé par ce firmware : relire sans et ne plus l'utiliser
      logger.w('_readMultiplePointsV2: \$select rejected, retrying without it');
      _v2SelectUnsupported = true;
      return await _readMultiplePointsV2Batch(pointRefs, useSelect: false) ?? {};
    }
    return {};
  }

  /// Returns null when every sub-request failed with a 4xx (other than
  /// 401/403), which is how a `$select` rejection shows up.
  Future<Map<String, BacnetObject>?> _readMultiplePointsV2Batch(
    List<String> pointRefs, {
    required bool useSelect,
  }) async {
    final batchUrl = '$baseUrl${ApiConstants.v2Batch}';
    logger.i('_readMultiplePointsV2: POST $batchUrl for ${pointRefs.length} points (select=$useSelect)');

    // Construire les requêtes batch
    final requests = <Map<String, dynamic>>[];

    for (final ref in pointRefs) {
      final parsed = _parsePointRef(ref);
      if (parsed == null) continue;

      final type = BacnetObjectType.fromApiName(parsed['type'] as String);
      if (type == null || !ApiTypeNames.pointTypes.contains(type)) continue;
      final instance = parsed['instance'] as int;

      final select = useSelect ? '?\$select=$_favoriteSelectV2' : '';
      requests.add({
        'id': ref,
        'method': 'GET',
        'url': '$_bacnetBasePath/objects/${ApiTypeNames.v2Path(type)}/$instance$select',
      });
    }

    if (requests.isEmpty) {
      logger.w('_readMultiplePointsV2: no valid requests built');
      return {};
    }

    try {
      final response = await _postJson(batchUrl, {'requests': requests});

      logger.d(() => '_readMultiplePointsV2: status=${response.statusCode}, data=${response.data}');
      if (response.statusCode == 200 && response.data != null) {
        if (useSelect && _allSubRequestsRejected(response.data)) return null;
        return _parseMultiplePointsFromBatchV2(response.data);
      }
    } catch (e) {
      logger.e('_readMultiplePointsV2 error: $e');
    }

    return {};
  }

  /// True if the batch contains responses and all of them are 4xx (not auth).
  static bool _allSubRequestsRejected(dynamic data) {
    final responses = data is List ? data : (data is Map ? data['responses'] : null);
    if (responses is! List || responses.isEmpty) return false;
    return responses.every((r) {
      final status = r is Map ? r['status'] : null;
      return status is int && status >= 400 && status < 500 && status != 401 && status != 403;
    });
  }

  /// Parse un pointRef en type + instance
  static Map<String, dynamic>? _parsePointRef(String pointRef) {
    // Format possible: "analog-value:1", "AV:1", "analogValue:1"
    final parts = pointRef.split(':');
    if (parts.length != 2) return null;

    final typePart = parts[0].trim();
    final instance = int.tryParse(parts[1].trim());
    if (instance == null) return null;

    // Mapper le nom du type (supporte tous les formats, y compris "multistateValue")
    final type = BacnetObjectType.fromAnyName(typePart) ?? ApiTypeNames.fromV1Name(typePart);
    if (type == null) {
      logger.w('_parsePointRef: unknown type "$typePart" in "$pointRef"');
      return null;
    }

    return {
      'type': type.apiName,
      'instance': instance,
    };
  }

  /// Groups a V1 read-property-multiple response by object. Keys are
  /// normalized `apiName:instance` (e.g. `multi-state-value:3`) whatever the
  /// casing returned by the controller (`multistateValue` / `multiStateValue`).
  static Map<String, Map<String, dynamic>> groupRpmPropertiesByObject(dynamic data) {
    final grouped = <String, Map<String, dynamic>>{};

    for (final ref in _extractRpmRefs(data)) {
      if (ref is! Map) continue;

      final typeName = ref['type']?.toString();
      final rawInstance = ref['instance'];
      final property = ref['property']?.toString();
      var value = ref['value'] ?? ref['message'];

      if (typeName == null || rawInstance == null || property == null) continue;
      final instance = rawInstance is int ? rawInstance : int.tryParse('$rawInstance');
      if (instance == null || instance == -1) continue;

      final type = ApiTypeNames.fromV1Name(typeName) ?? BacnetObjectType.fromAnyName(typeName);
      if (type == null) continue; // Ignorer les types inconnus

      // Extraire la valeur du Map si nécessaire
      if (value is Map) {
        value = value['value'] ?? value['\$value'] ?? value.values.firstOrNull;
      }

      final key = ApiTypeNames.objectKey(type, instance);
      grouped.putIfAbsent(key, () => {'type': type, 'instance': instance})[property] = value;
    }

    return grouped;
  }

  /// Builds the super-favorites map (keyed by the original pointRefs) from
  /// [groupRpmPropertiesByObject] output.
  static Map<String, BacnetObject> buildMultiplePointsFromGrouped(
    Map<String, Map<String, dynamic>> grouped,
    List<String> originalRefs,
  ) {
    // Mapping clé normalisée -> pointRef original (ex: "AV:1")
    final refMapping = <String, String>{};
    for (final ref in originalRefs) {
      final parsed = _parsePointRef(ref);
      if (parsed != null) {
        refMapping['${parsed['type']}:${parsed['instance']}'] = ref;
      }
    }

    final results = <String, BacnetObject>{};
    for (final entry in grouped.entries) {
      final props = entry.value;
      final type = props['type'] as BacnetObjectType;
      final instance = props['instance'] as int;

      // Parser stateText pour multistate
      List<String>? stateText;
      final stateTextRaw = props['stateText'];
      if (stateTextRaw is List) {
        stateText = stateTextRaw.map((e) => e?.toString() ?? '').toList();
      } else if (stateTextRaw is String) {
        stateText = stateTextRaw.split(',').map((e) => e.trim()).toList();
      }

      // Trouver la clé originale (ex: "AV:1" au lieu de "analog-value:1")
      final originalKey = refMapping[entry.key] ?? entry.key;

      final presentValue = props['presentValue'];
      final units = props['units'];

      results[originalKey] = BacnetObject(
        type: type,
        instance: instance,
        objectName: props['objectName']?.toString() ?? 'Point $instance',
        presentValue: _parseValueStatic(presentValue),
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
      logger.w('_parseMultiplePointsFromBatchV2: unexpected data type: ${data.runtimeType}');
      return results;
    }

    logger.d(() => '_parseMultiplePointsFromBatchV2: responses.length=${responses.length}');

    for (final batchResponse in responses) {
      if (batchResponse is! Map<String, dynamic>) continue;

      final id = batchResponse['id'] as String?; // C'est notre pointRef original
      final body = batchResponse['body'];
      final statusCode = batchResponse['status'] as int?;

      logger.d(() => '_parseMultiplePointsFromBatchV2: id=$id, status=$statusCode');

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
