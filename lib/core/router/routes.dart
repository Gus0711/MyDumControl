/// Définition des routes de l'application
class Routes {
  Routes._();

  // Routes principales
  static const String splash = '/';
  static const String connections = '/connections';
  static const String addConnection = '/connections/add';
  static const String editConnection = '/connections/edit/:id';
  static const String discoverEclypse = '/connections/discover-eclypse';
  static const String discoverBacnet = '/connections/discover-bacnet';
  static const String home = '/home';

  // Routes des fonctionnalités
  static const String points = '/points';
  static const String pointDetail = '/points/:id';
  static const String alarms = '/alarms';
  static const String schedules = '/schedules';
  static const String scheduleDetail = '/schedules/:instance';
  static const String overrides = '/overrides';
  static const String favorites = '/favorites';

  // Routes des synoptiques
  static const String synoptics = '/synoptics';
  static const String synopticCreate = '/synoptics/create';
  static const String synopticView = '/synoptics/:id';
  static const String synopticEdit = '/synoptics/:id/edit';

  // Routes des paramètres et infos
  static const String settings = '/settings';
  static const String deviceInfo = '/device-info';

  /// Génère le chemin pour éditer une connexion
  static String editConnectionPath(String id) => '/connections/edit/$id';

  /// Génère le chemin pour le détail d'un point
  static String pointDetailPath(String id) => '/points/$id';

  /// Génère le chemin pour le détail d'un schedule
  static String scheduleDetailPath(String id) => '/schedules/$id';

  /// Génère le chemin pour visualiser un synoptique
  static String synopticViewPath(int id) => '/synoptics/$id';

  /// Génère le chemin pour éditer les liaisons d'un synoptique
  static String synopticEditPath(int id) => '/synoptics/$id/edit';
}
