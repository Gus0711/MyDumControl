/// Typed errors raised (or recorded) by the Distech REST API client.
class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final String? url;

  const ApiException(this.message, {this.statusCode, this.url});

  /// Builds the right exception subtype for an HTTP status code.
  factory ApiException.fromStatus(int statusCode, {String? url}) {
    if (statusCode == 401 || statusCode == 403) {
      return ApiAuthException(statusCode: statusCode, url: url);
    }
    return ApiException('Erreur HTTP $statusCode', statusCode: statusCode, url: url);
  }

  @override
  String toString() => statusCode != null ? '$message (HTTP $statusCode)' : message;
}

/// Authentication / authorization failure (HTTP 401 or 403).
class ApiAuthException extends ApiException {
  const ApiAuthException({super.statusCode, super.url})
      : super(
          statusCode == 403
              ? 'Accès refusé pour ce compte'
              : 'Identifiants invalides ou expirés',
        );
}

/// True for HTTP 2xx success codes accepted by the client (200 and 204 today).
bool isHttpOk(int? statusCode) => statusCode == 200 || statusCode == 204;
