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

/// The controller presented a TLS certificate whose SHA-256 fingerprint
/// differs from the one stored on first use (TOFU pinning): possible
/// man-in-the-middle, or the controller certificate was regenerated.
class CertificateMismatchException extends ApiException {
  final String expectedFingerprint;
  final String receivedFingerprint;
  final String? host;

  CertificateMismatchException({
    required this.expectedFingerprint,
    required this.receivedFingerprint,
    this.host,
    super.url,
  }) : super(
          'Le certificat de l\'automate a changé '
          '(empreinte attendue $expectedFingerprint, reçue $receivedFingerprint)',
        );
}

/// The password of a connection is missing from secure storage (connection
/// restored from an export, or storage reset): it must be entered again.
class PasswordMissingException extends ApiException {
  const PasswordMissingException()
      : super('Mot de passe à ressaisir : modifiez la connexion');
}

/// True for HTTP 2xx success codes accepted by the client (200 and 204 today).
bool isHttpOk(int? statusCode) => statusCode == 200 || statusCode == 204;
