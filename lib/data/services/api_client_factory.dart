import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/utils/logger.dart';

import '../../core/constants/api_constants.dart';
import '../database/app_database.dart';
import 'api_service.dart';
import 'certificate_pinning.dart';

/// Default API version when a connection has none stored (V2 controllers are
/// the large majority; V1 is detected by the connection test).
const String defaultApiVersion = 'V2';

/// Everything needed to build a [ConnectedApiClient] for a connection.
class ApiClientConfig {
  final int connectionId;
  final String baseUrl;
  final String basicAuth;
  final String apiVersion;
  final bool useHttps;

  /// Certificate fingerprint stored for the connection (null = TOFU pending).
  final String? expectedCertFingerprint;

  const ApiClientConfig({
    required this.connectionId,
    required this.baseUrl,
    required this.basicAuth,
    required this.apiVersion,
    required this.useHttps,
    this.expectedCertFingerprint,
  });

  /// Identity of the config: a cached client must be rebuilt when it changes
  /// (host/port/credentials/version/pinned certificate edited).
  String get cacheKey => '$baseUrl|$apiVersion|$basicAuth|${expectedCertFingerprint ?? ''}';
}

/// Builds [ConnectedApiClient]s from stored connections, in a single place:
/// password lookup, Basic auth, default API version, timeouts and TOFU
/// certificate pinning.
class ApiClientFactory {
  final FlutterSecureStorage secureStorage;
  final AppDatabase database;

  /// Connect timeout (from the user settings).
  final Duration connectTimeout;

  ApiClientFactory({
    required this.secureStorage,
    required this.database,
    required this.connectTimeout,
  });

  /// Reads the password and computes the client config.
  /// Throws [PasswordMissingException] if no password is stored.
  Future<ApiClientConfig> resolve(Connection connection) async {
    final password = await secureStorage.read(key: connection.passwordKey);
    if (password == null) throw const PasswordMissingException();
    if (connection.apiVersion == null) {
      // Connection saved without a test: detect the API version once and
      // store it, otherwise a V1 controller would be queried with V2 paths.
      final version = await _detectApiVersion(connection, password);
      if (version != null) {
        await database.updateApiVersion(connection.id, version);
        return configFor(connection.copyWith(apiVersion: Value(version)), password);
      }
    }
    return configFor(connection, password);
  }

  Future<String?> _detectApiVersion(Connection connection, String password) async {
    try {
      final result = await ApiService().testConnection(
        host: connection.host,
        port: connection.port,
        useHttps: connection.useHttps,
        username: connection.username,
        password: password,
      );
      logger.i('ApiClientFactory: detected API ${result.apiVersion} for connection ${connection.id}');
      return result.success ? result.apiVersion : null;
    } catch (e) {
      logger.w('ApiClientFactory: API version detection failed: $e');
      return null;
    }
  }

  /// Pure config computation (no I/O).
  static ApiClientConfig configFor(Connection connection, String password) {
    final scheme = connection.useHttps ? 'https' : 'http';
    final fingerprint = connection.certificateFingerprint;
    return ApiClientConfig(
      connectionId: connection.id,
      baseUrl: '$scheme://${connection.host}:${connection.port}',
      basicAuth: 'Basic ${base64Encode(utf8.encode('${connection.username}:$password'))}',
      apiVersion: connection.apiVersion ?? defaultApiVersion,
      useHttps: connection.useHttps,
      expectedCertFingerprint:
          fingerprint == null || fingerprint.trim().isEmpty ? null : fingerprint,
    );
  }

  /// Receive/send timeouts: never shorter than the historical defaults
  /// (large reads take time), longer if the user configured a longer timeout.
  Duration get _receiveTimeout =>
      connectTimeout > ApiConstants.receiveTimeout ? connectTimeout : ApiConstants.receiveTimeout;
  Duration get _sendTimeout =>
      connectTimeout > ApiConstants.sendTimeout ? connectTimeout : ApiConstants.sendTimeout;

  /// Builds the client. With HTTPS, the first certificate seen is stored when
  /// none is pinned yet (TOFU); a different certificate is refused and
  /// reported through [onCertificateMismatch].
  ConnectedApiClient build(
    ApiClientConfig config, {
    void Function(ApiAuthException error)? onAuthError,
    void Function(CertificateMismatchException error)? onCertificateMismatch,
    void Function(String fingerprint)? onCertificatePinned,
  }) {
    var pinned = false;
    return ConnectedApiClient(
      baseUrl: config.baseUrl,
      basicAuth: config.basicAuth,
      apiVersion: config.apiVersion,
      expectedCertFingerprint: config.expectedCertFingerprint,
      onCertificateSeen: config.useHttps
          ? (fingerprint) {
              if (pinned || config.expectedCertFingerprint != null) return;
              pinned = true;
              logger.i('TOFU: pinning certificate of connection ${config.connectionId}: $fingerprint');
              database
                  .updateCertificateFingerprint(config.connectionId, fingerprint)
                  .then((_) => onCertificatePinned?.call(fingerprint))
                  .catchError((Object e) {
                logger.w('TOFU: failed to store certificate fingerprint: $e');
              });
            }
          : null,
      onAuthError: onAuthError,
      onCertificateMismatch: onCertificateMismatch,
      connectTimeout: connectTimeout,
      receiveTimeout: _receiveTimeout,
      sendTimeout: _sendTimeout,
    );
  }

  /// [resolve] + [build].
  Future<ConnectedApiClient> create(
    Connection connection, {
    void Function(ApiAuthException error)? onAuthError,
    void Function(CertificateMismatchException error)? onCertificateMismatch,
    void Function(String fingerprint)? onCertificatePinned,
  }) async {
    final config = await resolve(connection);
    return build(
      config,
      onAuthError: onAuthError,
      onCertificateMismatch: onCertificateMismatch,
      onCertificatePinned: onCertificatePinned,
    );
  }

  /// Checks a presented certificate against the one stored for [connection].
  static CertificateCheck check(Connection connection, String presentedFingerprint) =>
      checkCertificate(connection.certificateFingerprint, presentedFingerprint);
}
