/// Définition des routes de l'application
class Routes {
  Routes._();

  // Routes principales
  static const String splash = '/';
  static const String connections = '/connections';
  static const String addConnection = '/connections/add';
  static const String editConnection = '/connections/edit/:id';
  static const String home = '/home';

  // Routes des fonctionnalités
  static const String points = '/points';
  static const String pointDetail = '/points/:id';
  static const String alarms = '/alarms';
  static const String schedules = '/schedules';
  static const String scheduleDetail = '/schedules/:instance';
  static const String overrides = '/overrides';
  static const String favorites = '/favorites';
  static const String pidLoops = '/pid-loops';
  static const String pidLoopDetail = '/pid-loops/:id';

  // Routes des paramètres et infos
  static const String settings = '/settings';
  static const String deviceInfo = '/device-info';

  /// Génère le chemin pour éditer une connexion
  static String editConnectionPath(String id) => '/connections/edit/$id';

  /// Génère le chemin pour le détail d'un point
  static String pointDetailPath(String id) => '/points/$id';

  /// Génère le chemin pour le détail d'un schedule
  static String scheduleDetailPath(String id) => '/schedules/$id';

  /// Génère le chemin pour le détail d'une boucle PID
  static String pidLoopDetailPath(String id) => '/pid-loops/$id';
}
