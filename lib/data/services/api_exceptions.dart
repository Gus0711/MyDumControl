import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

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
    return ApiException(messageForStatus(statusCode), statusCode: statusCode, url: url);
  }

  /// Technician-oriented explanation of an HTTP status returned by a
  /// controller (what it means on an ECLYPSE, and what to check).
  static String messageForStatus(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Requête refusée par l\'automate (valeur ou format invalide)';
      case 401:
        return ApiAuthException.unauthorizedMessage;
      case 403:
        return ApiAuthException.forbiddenMessage;
      case 404:
        return 'Introuvable sur l\'automate : objet inexistant, ou version d\'API '
            '(V1/V2) incorrecte pour ce modèle';
      case 405:
        return 'Opération non supportée par cet automate';
      case 408:
      case 504:
        return 'L\'automate a mis trop de temps à répondre';
      case 429:
        return 'Trop de requêtes : l\'automate limite le débit, réessayez dans un instant';
      case 500:
        return 'Erreur interne de l\'automate';
      case 502:
      case 503:
        return 'Automate occupé ou indisponible, réessayez dans un instant';
      default:
        return 'Erreur HTTP $statusCode';
    }
  }

  @override
  String toString() => statusCode != null ? '$message (HTTP $statusCode)' : message;
}

/// Authentication / authorization failure (HTTP 401 or 403).
class ApiAuthException extends ApiException {
  const ApiAuthException({super.statusCode, super.url})
      : super(statusCode == 403 ? forbiddenMessage : unauthorizedMessage);

  static const unauthorizedMessage = 'Identifiants refusés. S\'ils sont corrects, '
      'l\'automate a peut-être bloqué le compte après trop de requêtes : '
      'patientez une minute avant de réessayer';
  static const forbiddenMessage = 'Accès refusé pour ce compte (droits insuffisants)';
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

/// Human-readable explanation of any error raised while talking to a
/// controller (typed API errors, Dio errors, sockets, timeouts), for display
/// to the technician instead of raw exception dumps.
String describeError(Object error) {
  if (error is ApiException) return error.message;
  if (error is DioException) {
    final status = error.response?.statusCode;
    if (status != null && status >= 400) return ApiException.fromStatus(status).message;
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'L\'automate ne répond pas (délai de connexion dépassé) : '
            'vérifiez l\'adresse, le port et le réseau';
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'L\'automate a mis trop de temps à répondre';
      case DioExceptionType.badCertificate:
        return 'Certificat HTTPS de l\'automate refusé';
      case DioExceptionType.cancel:
        return 'Requête annulée';
      case DioExceptionType.badResponse:
        return 'Réponse invalide de l\'automate';
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        final cause = error.error;
        if (cause != null && cause is! DioException) return describeError(cause);
        return 'Automate injoignable : vérifiez l\'adresse, le port et le réseau';
    }
  }
  if (error is HandshakeException || error is TlsException) {
    return 'Échec de la connexion sécurisée (HTTPS) : vérifiez le port, '
        'ou essayez en HTTP';
  }
  if (error is SocketException) {
    return 'Automate injoignable : vérifiez l\'adresse, le port et le réseau';
  }
  if (error is TimeoutException) return 'L\'automate a mis trop de temps à répondre';
  final text = error.toString();
  return text.startsWith('Exception: ') ? text.substring('Exception: '.length) : text;
}
