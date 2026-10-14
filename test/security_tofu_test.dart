import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myglobaldc/application/providers/connection_providers.dart';
import 'package:myglobaldc/application/providers/super_favorites_provider.dart';
import 'package:myglobaldc/data/database/app_database.dart';
import 'package:myglobaldc/data/services/api_client_factory.dart';
import 'package:myglobaldc/data/services/api_service.dart';
import 'package:myglobaldc/data/services/certificate_pinning.dart';
// ignore: depend_on_referenced_packages
import 'package:sqlite3/open.dart';

import 'security_test_certificate.dart';

/// Minimal HTTPS controller with a self-signed certificate.
class _TlsController {
  late HttpServer _server;
  int status = 200;

  String get baseUrl => 'https://127.0.0.1:${_server.port}';
  int get port => _server.port;

  Future<void> start() async {
    final context = SecurityContext()
      ..useCertificateChainBytes(utf8.encode(testCertPem))
      ..usePrivateKeyBytes(utf8.encode(testKeyPem));
    _server = await HttpServer.bindSecure(InternetAddress.loopbackIPv4, 0, context);
    _server.listen((request) async {
      request.response.statusCode = status;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode(<Object>[]));
      await request.response.close();
    }, onError: (_) {});
  }

  Future<void> stop() => _server.close(force: true);
}

Connection _connection({String? fingerprint, String apiVersion = 'V2', int port = 443}) {
  final now = DateTime(2026);
  return Connection(
    id: 1,
    name: 'c',
    host: '127.0.0.1',
    port: port,
    useHttps: true,
    username: 'admin',
    passwordKey: 'k',
    apiVersion: apiVersion,
    certificateFingerprint: fingerprint,
    connectionType: 'distech_api',
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  if (Platform.isLinux) {
    open.overrideFor(OperatingSystem.linux, () {
      try {
        return DynamicLibrary.open('libsqlite3.so');
      } catch (_) {
        return DynamicLibrary.open('libsqlite3.so.0');
      }
    });
  }
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('checkCertificate', () {
    test('no stored fingerprint: trust on first use', () {
      expect(checkCertificate(null, 'AA:BB'), CertificateCheck.trustOnFirstUse);
      expect(checkCertificate('  ', 'AA:BB'), CertificateCheck.trustOnFirstUse);
    });

    test('comparison ignores case and separators', () {
      expect(checkCertificate('aa:bb:cc', 'AA:BB:CC'), CertificateCheck.match);
      expect(checkCertificate('AABBCC', 'AA:BB:CC'), CertificateCheck.match);
      expect(checkCertificate('AA:BB:CD', 'AA:BB:CC'), CertificateCheck.mismatch);
    });

    test('fingerprint format matches openssl', () {
      final der = base64.decode(testCertPem
          .split('\n')
          .where((l) => l.isNotEmpty && !l.startsWith('-----'))
          .join());
      expect(certificateFingerprintOfDer(der), testCertFingerprint);
    });
  });

  group('TLS controller', () {
    late _TlsController controller;

    setUp(() async {
      controller = _TlsController();
      await controller.start();
    });
    tearDown(() => controller.stop());

    test('connection test reports the certificate fingerprint', () async {
      final service = ApiService();
      final result = await service.testConnection(
        host: '127.0.0.1',
        port: controller.port,
        useHttps: true,
        username: 'admin',
        password: 'pwd',
      );
      service.dispose();
      expect(result.success, isTrue);
      expect(result.apiVersion, 'V2');
      expect(result.certificateFingerprint, testCertFingerprint);
    });

    test('pinned fingerprint matching: request succeeds', () async {
      CertificateMismatchException? mismatch;
      final client = ConnectedApiClient(
        baseUrl: controller.baseUrl,
        basicAuth: 'Basic x',
        apiVersion: 'V2',
        expectedCertFingerprint: testCertFingerprint.toLowerCase(),
        onCertificateSeen: (_) {},
        onCertificateMismatch: (e) => mismatch = e,
      );
      await client.getSchedules();
      client.dispose();
      expect(mismatch, isNull);
      expect(client.lastStatusCode, 200);
      expect(client.lastError, isNull);
    });

    test('pinned fingerprint differing: request refused with typed error', () async {
      CertificateMismatchException? mismatch;
      const expected = '00:11:22';
      final client = ConnectedApiClient(
        baseUrl: controller.baseUrl,
        basicAuth: 'Basic x',
        apiVersion: 'V2',
        expectedCertFingerprint: expected,
        onCertificateSeen: (_) {},
        onCertificateMismatch: (e) => mismatch = e,
      );
      final schedules = await client.getSchedules();
      client.dispose();
      expect(schedules, isEmpty);
      expect(mismatch, isNotNull);
      expect(mismatch!.expectedFingerprint, expected);
      expect(mismatch!.receivedFingerprint, testCertFingerprint);
      expect(mismatch!.message, contains(testCertFingerprint));
      expect(client.lastError, isA<CertificateMismatchException>());
      expect(client.lastStatusCode, isNull);
    });

    test('factory pins the first certificate, then accepts only it', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final id = await db.insertConnection(ConnectionsCompanion.insert(
        name: 'c',
        host: '127.0.0.1',
        port: Value(controller.port),
        username: 'admin',
        passwordKey: 'k',
      ));
      final factory = ApiClientFactory(
        secureStorage: const FlutterSecureStorage(),
        database: db,
        connectTimeout: const Duration(seconds: 5),
      );

      // 1st connection: nothing pinned, the certificate is accepted and stored
      var connection = (await db.getConnectionById(id))!;
      expect(connection.certificateFingerprint, isNull);
      String? pinned;
      final first = factory.build(
        ApiClientFactory.configFor(connection, 'pwd'),
        onCertificatePinned: (fp) => pinned = fp,
      );
      await first.getSchedules();
      first.dispose();
      expect(first.lastStatusCode, 200);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(pinned, testCertFingerprint);
      connection = (await db.getConnectionById(id))!;
      expect(connection.certificateFingerprint, testCertFingerprint);

      // 2nd connection: same certificate accepted
      final second = factory.build(ApiClientFactory.configFor(connection, 'pwd'));
      await second.getSchedules();
      second.dispose();
      expect(second.lastStatusCode, 200);

      // Certificate "changed" (another one pinned): refused
      await db.updateCertificateFingerprint(id, 'AA:BB');
      connection = (await db.getConnectionById(id))!;
      CertificateMismatchException? mismatch;
      final third = factory.build(
        ApiClientFactory.configFor(connection, 'pwd'),
        onCertificateMismatch: (e) => mismatch = e,
      );
      await third.getSchedules();
      third.dispose();
      expect(mismatch?.receivedFingerprint, testCertFingerprint);
      expect(third.lastError, isA<CertificateMismatchException>());
    });
  });

  group('ApiClientFactory.configFor', () {
    test('defaults to API V2 and builds Basic auth', () {
      final config = ApiClientFactory.configFor(
        _connection().copyWith(apiVersion: const Value(null)),
        'pwd',
      );
      expect(config.apiVersion, 'V2');
      expect(config.baseUrl, 'https://127.0.0.1:443');
      expect(config.basicAuth, 'Basic ${base64Encode(utf8.encode('admin:pwd'))}');
      expect(config.expectedCertFingerprint, isNull);
    });

    test('cache key changes when the pinned certificate changes', () {
      final a = ApiClientFactory.configFor(_connection(fingerprint: 'AA'), 'pwd');
      final b = ApiClientFactory.configFor(_connection(fingerprint: 'BB'), 'pwd');
      final c = ApiClientFactory.configFor(_connection(fingerprint: 'AA'), 'other');
      expect(a.cacheKey, isNot(b.cacheKey));
      expect(a.cacheKey, isNot(c.cacheKey));
    });
  });

  group('connection edits', () {
    test('pinned certificate is forgotten when the endpoint changes', () {
      final c = _connection(fingerprint: 'AA');
      expect(certificateEndpointChanged(c, host: '127.0.0.1', port: 443, useHttps: true), isFalse);
      expect(certificateEndpointChanged(c, host: '10.0.0.2', port: 443, useHttps: true), isTrue);
      expect(certificateEndpointChanged(c, host: '127.0.0.1', port: 8443, useHttps: true), isTrue);
      expect(certificateEndpointChanged(c, host: '127.0.0.1', port: 443, useHttps: false), isTrue);
    });

    test('fingerprint seen by a connection test wins over the pinned one', () {
      final c = _connection(fingerprint: 'AA');
      expect(fingerprintAfterEdit(c, endpointChanged: false, testedFingerprint: 'BB'), 'BB');
      expect(fingerprintAfterEdit(c, endpointChanged: true, testedFingerprint: 'BB'), 'BB');
      expect(fingerprintAfterEdit(c, endpointChanged: false), 'AA');
      expect(fingerprintAfterEdit(c, endpointChanged: true), isNull);
    });
  });

  group('messages', () {
    test('auth failures are reported as invalid credentials', () {
      expect(
        superFavoriteFailureMessage(const ApiAuthException(statusCode: 401)),
        'Identifiants invalides (401)',
      );
      expect(const PasswordMissingException().message, contains('modifiez la connexion'));
    });
  });
}
