/// Utilitaires de validation
class Validators {
  Validators._();

  /// Valide une adresse IP v4
  static bool isValidIPv4(String value) {
    final regex = RegExp(
      r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
    );
    return regex.hasMatch(value);
  }

  /// Valide un nom de domaine
  static bool isValidHostname(String value) {
    final regex = RegExp(
      r'^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
    );
    return regex.hasMatch(value);
  }

  /// Valide un hôte (IP ou nom de domaine)
  static bool isValidHost(String value) {
    return isValidIPv4(value) || isValidHostname(value);
  }

  /// Valide un numéro de port
  static bool isValidPort(int port) {
    return port >= 1 && port <= 65535;
  }

  /// Valide un numéro de port (depuis une chaîne)
  static bool isValidPortString(String value) {
    final port = int.tryParse(value);
    if (port == null) return false;
    return isValidPort(port);
  }

  /// Valide qu'une chaîne n'est pas vide
  static bool isNotEmpty(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  /// Valide une URL
  static bool isValidUrl(String value) {
    try {
      final uri = Uri.parse(value);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (_) {
      return false;
    }
  }

  /// Valide un nom d'utilisateur (pas de caractères spéciaux dangereux)
  static bool isValidUsername(String value) {
    final regex = RegExp(r'^[a-zA-Z0-9_.-]+$');
    return value.isNotEmpty && regex.hasMatch(value);
  }
}
