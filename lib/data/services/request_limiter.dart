import 'dart:async';
import 'dart:collection';

import 'package:dio/dio.dart';

/// Caps the number of HTTP requests in flight towards one controller.
///
/// ECLYPSE controllers start refusing authentication (401) when they receive
/// bursts of requests (e.g. one GET per point in parallel): requests beyond
/// [maxConcurrent] wait in FIFO order instead of hitting the controller.
class RequestLimiter {
  RequestLimiter(this.maxConcurrent) : assert(maxConcurrent > 0);

  final int maxConcurrent;
  int _active = 0;
  final Queue<Completer<void>> _waiters = Queue();

  /// Requests currently allowed through.
  int get active => _active;

  /// Requests waiting for a slot.
  int get waiting => _waiters.length;

  Future<void> acquire() {
    if (_active < maxConcurrent) {
      _active++;
      return Future.value();
    }
    final waiter = Completer<void>();
    _waiters.add(waiter);
    return waiter.future;
  }

  void release() {
    if (_waiters.isNotEmpty) {
      // The slot goes straight to the next waiter (_active unchanged)
      _waiters.removeFirst().complete();
    } else if (_active > 0) {
      _active--;
    }
  }
}

/// Dio interceptor applying a [RequestLimiter] to every request of a client.
class RequestLimiterInterceptor extends Interceptor {
  RequestLimiterInterceptor(this.limiter);

  final RequestLimiter limiter;

  static const _slotKey = 'requestLimiterSlot';

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    await limiter.acquire();
    options.extra[_slotKey] = true;
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _release(response.requestOptions);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _release(err.requestOptions);
    handler.next(err);
  }

  void _release(RequestOptions options) {
    // Release once per request, even if several callbacks see it
    if (options.extra.remove(_slotKey) == true) limiter.release();
  }
}
