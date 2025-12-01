import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'routes.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/connections/connections_list_screen.dart';
import '../../presentation/screens/connections/add_connection_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/device_info/device_info_screen.dart';
import '../../presentation/screens/points/points_screen.dart';
import '../../presentation/screens/points/point_detail_screen.dart';
import '../../presentation/screens/overrides/overrides_screen.dart';
import '../../presentation/screens/favorites/favorites_screen.dart';
import '../../presentation/screens/schedules/schedules_list_screen.dart';
import '../../presentation/screens/schedules/schedule_detail_screen.dart';
import '../../presentation/screens/alarms/alarms_screen.dart';

/// Configuration du router de l'application
class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: Routes.splash,
    debugLogDiagnostics: true,
    routes: [
      // Splash screen
      GoRoute(
        path: Routes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Liste des connexions
      GoRoute(
        path: Routes.connections,
        name: 'connections',
        builder: (context, state) => const ConnectionsListScreen(),
        routes: [
          // Ajouter une connexion
          GoRoute(
            path: 'add',
            name: 'addConnection',
            builder: (context, state) => const AddConnectionScreen(),
          ),
          // Modifier une connexion
          GoRoute(
            path: 'edit/:id',
            name: 'editConnection',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return AddConnectionScreen(connectionId: id);
            },
          ),
        ],
      ),

      // Home (Dashboard)
      GoRoute(
        path: Routes.home,
        name: 'home',
        builder: (context, state) {
          // Récupérer le connectionId depuis les query params
          final connectionIdStr = state.uri.queryParameters['connectionId'];
          final connectionId = connectionIdStr != null ? int.tryParse(connectionIdStr) : null;
          return HomeScreen(connectionId: connectionId);
        },
      ),

      // Points BACnet
      GoRoute(
        path: Routes.points,
        name: 'points',
        builder: (context, state) => const PointsScreen(),
        routes: [
          // Détail d'un point
          GoRoute(
            path: ':id',
            name: 'pointDetail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return PointDetailScreen(pointId: id);
            },
          ),
        ],
      ),

      // Alarmes
      GoRoute(
        path: Routes.alarms,
        name: 'alarms',
        builder: (context, state) => const AlarmsScreen(),
      ),

      // Schedules (Plannings)
      GoRoute(
        path: Routes.schedules,
        name: 'schedules',
        builder: (context, state) => const SchedulesListScreen(),
        routes: [
          // Détail d'un schedule
          GoRoute(
            path: ':instance',
            name: 'scheduleDetail',
            builder: (context, state) {
              final instanceStr = state.pathParameters['instance']!;
              final instance = int.tryParse(instanceStr) ?? 0;
              return ScheduleDetailScreen(instance: instance);
            },
          ),
        ],
      ),

      // Overrides - Liste des points forcés
      GoRoute(
        path: Routes.overrides,
        name: 'overrides',
        builder: (context, state) => const OverridesScreen(),
      ),

      // Favoris
      GoRoute(
        path: Routes.favorites,
        name: 'favorites',
        builder: (context, state) => const FavoritesScreen(),
      ),

      // Boucles PID - À implémenter
      GoRoute(
        path: Routes.pidLoops,
        name: 'pidLoops',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Boucles PID - À implémenter')),
        ),
      ),

      // Paramètres - À implémenter
      GoRoute(
        path: Routes.settings,
        name: 'settings',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Paramètres - À implémenter')),
        ),
      ),

      // Info sur l'appareil
      GoRoute(
        path: Routes.deviceInfo,
        name: 'deviceInfo',
        builder: (context, state) => const DeviceInfoScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page non trouvée: ${state.uri.path}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(Routes.connections),
              child: const Text('Retour aux connexions'),
            ),
          ],
        ),
      ),
    ),
  );
}
