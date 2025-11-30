/// Exceptions personnalisées de l'application

/// Exception de base
abstract class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, {this.code});

  @override
  String toString() => 'AppException: $message${code != null ? ' (code: $code)' : ''}';
}

/// Exception serveur (erreurs HTTP)
class ServerException extends AppException {
  final int? statusCode;

  const ServerException(super.message, {this.statusCode, super.code});

  @override
  String toString() =>
      'ServerException: $message${statusCode != null ? ' (HTTP $statusCode)' : ''}';
}

/// Exception de connexion réseau
class ConnectionException extends AppException {
  const ConnectionException(super.message, {super.code});
}

/// Exception de timeout
class TimeoutException extends AppException {
  const TimeoutException([String message = 'La requête a expiré']) : super(message);
}

/// Exception d'authentification
class AuthenticationException extends AppException {
  const AuthenticationException([String message = 'Échec de l\'authentification'])
      : super(message);
}

/// Exception de certificat
class CertificateException extends AppException {
  final String? fingerprint;

  const CertificateException(super.message, {this.fingerprint, super.code});
}

/// Exception de cache/base de données locale
class CacheException extends AppException {
  const CacheException(super.message, {super.code});
}

/// Exception de détection de version API
class ApiVersionDetectionException extends AppException {
  const ApiVersionDetectionException(
      [String message = 'Impossible de détecter la version de l\'API'])
      : super(message);
}

/// Exception de validation
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  const ValidationException(super.message, {this.fieldErrors, super.code});
}

/// Exception de point non trouvé
class PointNotFoundException extends AppException {
  final String pointId;

  const PointNotFoundException(this.pointId)
      : super('Point non trouvé: $pointId');
}

/// Exception d'opération non supportée
class UnsupportedOperationException extends AppException {
  const UnsupportedOperationException(super.message, {super.code});
}
