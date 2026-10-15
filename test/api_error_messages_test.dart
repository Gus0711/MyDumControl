import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myglobaldc/data/services/api_exceptions.dart';

void main() {
  DioException withStatus(int status) {
    final options = RequestOptions(path: '/api/rest/v2/services/platform');
    return DioException.badResponse(
      statusCode: status,
      requestOptions: options,
      response: Response(requestOptions: options, statusCode: status),
    );
  }

  test('404 points to a wrong API version or a missing object', () {
    expect(describeError(withStatus(404)), contains('version d\'API'));
    expect(ApiException.fromStatus(404).message, contains('V1/V2'));
  });

  test('401 mentions the temporary lockout', () {
    expect(describeError(withStatus(401)), contains('bloqué le compte'));
    expect(ApiException.fromStatus(401), isA<ApiAuthException>());
    expect(ApiException.fromStatus(403).message, contains('droits insuffisants'));
  });

  test('network failures are explained without raw dumps', () {
    final options = RequestOptions(path: '/');
    expect(
      describeError(DioException.connectionTimeout(timeout: const Duration(seconds: 1), requestOptions: options)),
      contains('ne répond pas'),
    );
    expect(
      describeError(DioException.connectionError(
        requestOptions: options,
        reason: 'refused',
        error: const SocketException('Connection refused'),
      )),
      contains('injoignable'),
    );
    expect(describeError(const HandshakeException('bad')), contains('HTTPS'));
    expect(describeError(Exception('Impossible de lire')), 'Impossible de lire');
  });

  test('unknown statuses keep the code', () {
    expect(ApiException.fromStatus(418).message, 'Erreur HTTP 418');
  });
}
