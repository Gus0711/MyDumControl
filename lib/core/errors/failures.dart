import 'package:equatable/equatable.dart';

/// Classe de base pour les échecs (Failures)
/// Utilisée avec le pattern Either pour la gestion des erreurs
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

/// Échec serveur
class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure([String message = 'Erreur serveur', this.statusCode]) : super(message);

  @override
  List<Object?> get props => [message, statusCode];
}

/// Échec de connexion réseau
class ConnectionFailure extends Failure {
  const ConnectionFailure([String message = 'Erreur de connexion']) : super(message);
}

/// Échec de timeout
class TimeoutFailure extends Failure {
  const TimeoutFailure([String message = 'La requête a expiré']) : super(message);
}

/// Échec d'authentification
class AuthenticationFailure extends Failure {
  const AuthenticationFailure([String message = 'Échec de l\'authentification'])
      : super(message);
}

/// Échec de certificat
class CertificateFailure extends Failure {
  final String? fingerprint;

  const CertificateFailure([String message = 'Certificat non valide', this.fingerprint])
      : super(message);

  @override
  List<Object?> get props => [message, fingerprint];
}

/// Échec de cache
class CacheFailure extends Failure {
  const CacheFailure([String message = 'Erreur de cache']) : super(message);
}

/// Échec de détection de version API
class ApiVersionDetectionFailure extends Failure {
  const ApiVersionDetectionFailure(
      [String message = 'Impossible de détecter la version de l\'API'])
      : super(message);
}

/// Échec de validation
class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;

  const ValidationFailure([String message = 'Erreur de validation', this.fieldErrors])
      : super(message);

  @override
  List<Object?> get props => [message, fieldErrors];
}

/// Échec inconnu
class UnknownFailure extends Failure {
  const UnknownFailure([String message = 'Erreur inconnue']) : super(message);
}

/// Échec hors ligne
class OfflineFailure extends Failure {
  const OfflineFailure([String message = 'Aucune connexion internet']) : super(message);
}
