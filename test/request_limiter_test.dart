import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myglobaldc/data/services/request_limiter.dart';

void main() {
  test('never lets more than maxConcurrent through, FIFO order', () async {
    final limiter = RequestLimiter(2);
    final order = <int>[];
    var inFlight = 0;
    var peak = 0;

    Future<void> job(int i) async {
      await limiter.acquire();
      inFlight++;
      peak = inFlight > peak ? inFlight : peak;
      order.add(i);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      inFlight--;
      limiter.release();
    }

    await Future.wait([for (var i = 0; i < 6; i++) job(i)]);
    expect(peak, 2);
    expect(order, [0, 1, 2, 3, 4, 5]);
    expect(limiter.active, 0);
    expect(limiter.waiting, 0);
  });

  test('a failed request frees its slot', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    var concurrent = 0;
    var peak = 0;
    server.listen((request) async {
      concurrent++;
      peak = concurrent > peak ? concurrent : peak;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      concurrent--;
      request.response.statusCode = request.uri.path == '/fail' ? 404 : 200;
      await request.response.close();
    });
    addTearDown(() => server.close(force: true));

    final limiter = RequestLimiter(3);
    final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:${server.port}'))
      ..interceptors.add(RequestLimiterInterceptor(limiter));

    final results = await Future.wait([
      for (var i = 0; i < 10; i++)
        dio.get(i.isEven ? '/fail' : '/ok').then((r) => r.statusCode, onError: (_) => -1),
    ]);
    expect(results.where((s) => s == -1), hasLength(5)); // 404 -> DioException
    expect(peak, lessThanOrEqualTo(3));
    expect(limiter.active, 0);
  });
}
