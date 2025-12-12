/// Constantes générales de l'application
class AppConstants {
  AppConstants._();

  // Application
  static const String appName = 'MyGlobalDC';
  static const String appVersion = '1.0.0';

  // Base de données
  static const String databaseName = 'myglobaldc.db';
  static const int databaseVersion = 1;

  // Stockage sécurisé
  static const String trustedCertificatesKey = 'trusted_certificates';
  static const String settingsKey = 'app_settings';

  // Polling
  static const Duration pointValuePollingInterval = Duration(seconds: 5);
  static const Duration alarmPollingInterval = Duration(seconds: 10);
  static const Duration connectionCheckInterval = Duration(seconds: 30);

  // Cache
  static const Duration cacheExpiration = Duration(hours: 24);

  // UI
  static const int maxRecentConnections = 5;
  static const int maxFavorites = 50;
}
