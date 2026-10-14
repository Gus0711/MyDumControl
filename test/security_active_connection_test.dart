import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myglobaldc/application/providers/active_connection_provider.dart';
import 'package:myglobaldc/application/providers/api_provider.dart';
import 'package:myglobaldc/application/providers/database_provider.dart';
import 'package:myglobaldc/data/database/app_database.dart';
import 'package:myglobaldc/data/services/api_service.dart';
// ignore: depend_on_referenced_packages
import 'package:sqlite3/open.dart';

import 'security_test_certificate.dart';

/// HTTPS controller (self-signed) answering every request with [status].
class _TlsController {
  late HttpServer _server;
  int status = 200;
  /// Optional per-path status (overrides [status]).
  int Function(String path)? statusFor;
  int get port => _server.port;

  Future<void> start() async {
    final context = SecurityContext()
      ..useCertificateChainBytes(utf8.encode(testCertPem))
      ..usePrivateKeyBytes(utf8.encode(testKeyPem));
    _server = await HttpServer.bindSecure(InternetAddress.loopbackIPv4, 0, context);
    _server.listen((request) async {
      request.response.statusCode = statusFor?.call(request.uri.path) ?? status;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode(<String, Object>{}));
      await request.response.close();
    }, onError: (_) {});
  }

  Future<void> stop() => _server.close(force: true);
}

Future<void> _waitFor(bool Function() condition) async {
  for (var i = 0; i < 100 && !condition(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
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

  late _TlsController controller;
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() async {
    // The test binding fakes every HttpClient (HTTP 400): use real sockets
    HttpOverrides.global = null;
    controller = _TlsController();
    await controller.start();
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      connectionTimeoutProvider.overrideWithValue(const Duration(seconds: 5)),
    ]);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
    await controller.stop();
  });

  Future<int> addConnection({String? fingerprint, bool withPassword = true}) async {
    FlutterSecureStorage.setMockInitialValues(withPassword ? {'k': 'pwd'} : {});
    return db.insertConnection(ConnectionsCompanion.insert(
      name: 'c',
      host: '127.0.0.1',
      port: Value(controller.port),
      username: 'admin',
      passwordKey: 'k',
      apiVersion: const Value('V2'),
      certificateFingerprint: Value(fingerprint),
    ));
  }

  test('changed certificate: typed failure, then trust and reconnect', () async {
    final id = await addConnection(fingerprint: 'AA:BB');
    final notifier = container.read(activeConnectionProvider.notifier);

    await notifier.connect(id);
    await _waitFor(() => container.read(activeConnectionProvider).failure != null);

    var state = container.read(activeConnectionProvider);
    expect(state.isConnected, isFalse);
    expect(state.failure, isA<CertificateMismatchException>());
    expect(state.error, contains(testCertFingerprint));

    expect(await notifier.trustNewCertificate(), isTrue);
    state = container.read(activeConnectionProvider);
    expect(state.isConnected, isTrue);
    expect((await db.getConnectionById(id))!.certificateFingerprint, testCertFingerprint);
  });

  test('first connection pins the certificate (TOFU)', () async {
    final id = await addConnection();
    await container.read(activeConnectionProvider.notifier).connect(id);
    await _waitFor(() => !container.read(activeConnectionProvider).isLoadingDeviceInfo);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(container.read(activeConnectionProvider).isConnected, isTrue);
    expect((await db.getConnectionById(id))!.certificateFingerprint, testCertFingerprint);
  });

  test('401 during initial load: invalid credentials failure', () async {
    controller.status = 401;
    final id = await addConnection(fingerprint: testCertFingerprint);
    await container.read(activeConnectionProvider.notifier).connect(id);
    await _waitFor(() => container.read(activeConnectionProvider).failure != null);

    final state = container.read(activeConnectionProvider);
    expect(state.isConnected, isFalse);
    expect(state.failure, isA<ApiAuthException>());
  });

  test('401 on annex requests only: connection kept with a warning', () async {
    controller.statusFor = (path) => path.contains('/bacnet/local/objects') ? 200 : 401;
    final id = await addConnection(fingerprint: testCertFingerprint);
    await container.read(activeConnectionProvider.notifier).connect(id);
    await _waitFor(() {
      final s = container.read(activeConnectionProvider);
      return !s.isLoadingDeviceInfo && !s.isLoadingSummary;
    });
    await Future<void>.delayed(const Duration(milliseconds: 100));

    final state = container.read(activeConnectionProvider);
    expect(state.isConnected, isTrue);
    expect(state.failure, isNull);
    expect(state.authWarning, isNotNull);
  });

  test('401 on the objects list: invalid credentials failure', () async {
    controller.statusFor = (path) => path.contains('/bacnet/local/objects') ? 401 : 200;
    final id = await addConnection(fingerprint: testCertFingerprint);
    await container.read(activeConnectionProvider.notifier).connect(id);
    await _waitFor(() => container.read(activeConnectionProvider).failure != null);

    final state = container.read(activeConnectionProvider);
    expect(state.isConnected, isFalse);
    expect(state.failure, isA<ApiAuthException>());
  });

  test('missing password: typed failure', () async {
    final id = await addConnection(withPassword: false);
    expect(await container.read(activeConnectionProvider.notifier).connect(id), isFalse);
    final state = container.read(activeConnectionProvider);
    expect(state.failure, isA<PasswordMissingException>());
    expect(state.error, contains('modifiez la connexion'));
  });
}
