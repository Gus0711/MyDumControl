import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:myglobaldc/data/services/eclypse_probe.dart';

/// 401 of a legacy ECLYPSE (nginx + Jetty), identical for V1 and V2
/// controllers (captured on 192.168.1.7, V1 only, and 192.168.1.6).
const _jetty401 = ProbeHttpResponse(
  statusCode: 401,
  headers: {
    'server': 'nginx',
    'content-type': 'text/html;charset=ISO-8859-1',
    'www-authenticate': 'basic realm="Radius"',
  },
  body: '<html><body><h2>HTTP ERROR 401</h2><i><small>Powered by Jetty://</small></i></body></html>',
);

/// 401 of a new generation ECLYPSE (Karaf), captured on 192.168.1.49.
const _karaf401 = ProbeHttpResponse(
  statusCode: 401,
  headers: {
    'content-type': 'application/json',
    'www-authenticate': 'basic realm="karaf", bearer realm="karaf"',
  },
  body: '{"error":{"type":"HttpErrorStatus","message":"Unauthorized"}}',
);

void main() {
  group('EclypseProbe.apiVersionFromResponse', () {
    test('2xx on the V2 route means V2', () {
      expect(EclypseProbe.apiVersionFromResponse(const ProbeHttpResponse(statusCode: 200)), 'V2');
      expect(EclypseProbe.apiVersionFromResponse(const ProbeHttpResponse(statusCode: 204)), 'V2');
    });

    test('404 on the V2 route means V1', () {
      expect(EclypseProbe.apiVersionFromResponse(const ProbeHttpResponse(statusCode: 404)), 'V1');
    });

    test('401/403 from the Karaf stack means the V2 route exists', () {
      expect(EclypseProbe.apiVersionFromResponse(_karaf401), 'V2');
      expect(
        EclypseProbe.apiVersionFromResponse(ProbeHttpResponse(
          statusCode: 403,
          headers: _karaf401.headers,
          body: _karaf401.body,
        )),
        'V2',
      );
      // JSON error without WWW-Authenticate header
      expect(
        EclypseProbe.apiVersionFromResponse(const ProbeHttpResponse(
          statusCode: 401,
          headers: {'content-type': 'application/json'},
          body: '{"error":{"type":"HttpErrorStatus","message":"Unauthorized"}}',
        )),
        'V2',
      );
    });

    test('401 from the Jetty "Radius" stack is undetermined', () {
      // A V1-only controller answers 401 to V2 routes without credentials
      expect(EclypseProbe.apiVersionFromResponse(_jetty401), isNull);
      expect(EclypseProbe.serverStackOf(_jetty401), 'jetty');
      expect(EclypseProbe.serverStackOf(_karaf401), 'karaf');
    });

    test('other statuses are undetermined', () {
      for (final status in [301, 302, 400, 500, 503]) {
        expect(EclypseProbe.apiVersionFromResponse(ProbeHttpResponse(statusCode: status)), isNull,
            reason: 'status $status');
      }
    });
  });

  group('EclypseProbe.probe (injected getter)', () {
    test('queries the V2 platform route on the given scheme/port', () async {
      final uris = <Uri>[];
      final probe = EclypseProbe(httpGet: (uri, timeout) async {
        uris.add(uri);
        return _karaf401;
      });

      final result = await probe.probe(host: '192.168.1.49', port: 443, useHttps: true);

      expect(uris.single.toString(), 'https://192.168.1.49/api/rest/v2/services/platform');
      expect(result.reachable, isTrue);
      expect(result.statusCode, 401);
      expect(result.apiVersion, 'V2');
      expect(result.serverStack, 'karaf');
    });

    test('a failure gives an unreachable result instead of throwing', () async {
      final probe = EclypseProbe(httpGet: (uri, timeout) async => throw const SocketException('refused'));
      final result = await probe.probe(host: '10.0.0.1', port: 80, useHttps: false);
      expect(result.reachable, isFalse);
      expect(result.apiVersion, isNull);
      expect(result.error, contains('refused'));
    });

    test('a getter that hangs is cut by the timeout', () async {
      final probe = EclypseProbe(
        timeout: const Duration(milliseconds: 50),
        httpGet: (uri, timeout) => Completer<ProbeHttpResponse>().future,
      );
      final result = await probe.probe(host: '10.0.0.1', port: 443, useHttps: true);
      expect(result.reachable, isFalse);
    });
  });

  group('EclypseProbe.defaultHttpGet (local fake server)', () {
    late HttpServer server;
    final requests = <HttpRequest>[];
    var status = 404;
    var authHeader = '';

    setUp(() async {
      requests.clear();
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) {
        requests.add(request);
        request.response.statusCode = status;
        if (authHeader.isNotEmpty) {
          request.response.headers.set(HttpHeaders.wwwAuthenticateHeader, authHeader);
        }
        request.response.write('{"error":{"type":"HttpErrorStatus","message":"x"}}');
        request.response.close();
      });
    });

    tearDown(() => server.close(force: true));

    test('404 -> V1, without credentials', () async {
      status = 404;
      authHeader = '';
      final result = await EclypseProbe().probe(host: '127.0.0.1', port: server.port, useHttps: false);

      expect(result.reachable, isTrue);
      expect(result.statusCode, 404);
      expect(result.apiVersion, 'V1');
      expect(requests.single.method, 'GET');
      expect(requests.single.uri.path, EclypseProbe.v2ProbePath);
      expect(requests.single.headers.value(HttpHeaders.authorizationHeader), isNull);
    });

    test('401 Radius -> undetermined, 401 karaf -> V2', () async {
      status = 401;
      authHeader = 'basic realm="Radius"';
      final radius = await EclypseProbe().probe(host: '127.0.0.1', port: server.port, useHttps: false);
      expect(radius.reachable, isTrue);
      expect(radius.apiVersion, isNull);

      authHeader = 'basic realm="karaf", bearer realm="karaf"';
      final karaf = await EclypseProbe().probe(host: '127.0.0.1', port: server.port, useHttps: false);
      expect(karaf.apiVersion, 'V2');
    });

    test('closed port -> unreachable', () async {
      final port = server.port;
      await server.close(force: true);
      final result = await EclypseProbe(timeout: const Duration(seconds: 2))
          .probe(host: '127.0.0.1', port: port, useHttps: false);
      expect(result.reachable, isFalse);
    });
  });

  group('BoundedTaskRunner', () {
    test('never runs more than maxConcurrent tasks and runs them all', () async {
      final runner = BoundedTaskRunner(maxConcurrent: 4);
      final completers = List.generate(10, (_) => Completer<void>());
      var running = 0;
      var maxRunning = 0;
      var done = 0;

      for (var i = 0; i < completers.length; i++) {
        final c = completers[i];
        runner.add(() async {
          running++;
          if (running > maxRunning) maxRunning = running;
          await c.future;
          running--;
          done++;
          if (i == 3) throw StateError('a failing probe must not block the queue');
        });
      }

      await Future<void>.delayed(Duration.zero);
      expect(runner.running, 4);
      expect(runner.pending, 6);

      for (final c in completers) {
        c.complete();
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);
      }

      expect(done, 10);
      expect(maxRunning, 4);
      expect(runner.running, 0);
      expect(runner.pending, 0);
    });

    test('clear drops tasks not yet started', () async {
      final runner = BoundedTaskRunner(maxConcurrent: 1);
      final gate = Completer<void>();
      var started = 0;
      runner.add(() async {
        started++;
        await gate.future;
      });
      runner.add(() async => started++);
      runner.clear();
      gate.complete();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(started, 1);
    });
  });
}
