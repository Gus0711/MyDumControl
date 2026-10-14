import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'routes.dart';
import 'page_transitions.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/connections/connections_list_screen.dart';
import '../../presentation/screens/connections/add_connection_screen.dart';
import '../../presentation/screens/connections/discover_eclypse_screen.dart';
import '../../presentation/screens/connections/discover_bacnet_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/device_info/device_info_screen.dart';
import '../../presentation/screens/points/points_screen.dart';
import '../../presentation/screens/points/point_detail_screen.dart';
import '../../presentation/screens/overrides/overrides_screen.dart';
import '../../presentation/screens/favorites/favorites_screen.dart';
import '../../presentation/screens/schedules/schedules_list_screen.dart';
import '../../presentation/screens/schedules/schedule_detail_screen.dart';
import '../../presentation/screens/alarms/alarms_screen.dart';
import '../../presentation/screens/synoptics/synoptics_list_screen.dart';
import '../../presentation/screens/synoptics/synoptic_viewer_screen.dart';
import '../../presentation/screens/synoptics/synoptic_editor_screen.dart';
import '../../presentation/screens/synoptics/envysion_viewer_screen.dart';
import '../../presentation/screens/dashboard/dashboard_list_screen.dart';
import '../../presentation/screens/dashboard/dashboard_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';

/// Configuration du router de l'application
class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: Routes.splash,
    debugLogDiagnostics: kDebugMode,
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
          // Decouverte ECLYPSE (mDNS)
          GoRoute(
            path: 'discover-eclypse',
            name: 'discoverEclypse',
            builder: (context, state) => const DiscoverEclypseScreen(),
          ),
          // Decouverte BACnet
          GoRoute(
            path: 'discover-bacnet',
            name: 'discoverBacnet',
            builder: (context, state) => const DiscoverBacnetScreen(),
          ),
        ],
      ),

      // Home (Dashboard)
      GoRoute(
        path: Routes.home,
        name: 'home',
        pageBuilder: (context, state) {
          // Récupérer le connectionId depuis les query params
          final connectionIdStr = state.uri.queryParameters['connectionId'];
          final connectionId = connectionIdStr != null ? int.tryParse(connectionIdStr) : null;
          return PageTransitions.sharedAxisTransition(
            context: context,
            state: state,
            child: HomeScreen(connectionId: connectionId),
          );
        },
      ),

      // Points BACnet
      GoRoute(
        path: Routes.points,
        name: 'points',
        pageBuilder: (context, state) => PageTransitions.slideTransition(
          context: context,
          state: state,
          child: const PointsScreen(),
        ),
        routes: [
          // Détail d'un point
          GoRoute(
            path: ':id',
            name: 'pointDetail',
            pageBuilder: (context, state) {
              final id = state.pathParameters['id']!;
              return PageTransitions.scaleTransition(
                context: context,
                state: state,
                child: PointDetailScreen(pointId: id),
              );
            },
          ),
        ],
      ),

      // Alarmes
      GoRoute(
        path: Routes.alarms,
        name: 'alarms',
        pageBuilder: (context, state) => PageTransitions.slideTransition(
          context: context,
          state: state,
          child: const AlarmsScreen(),
        ),
      ),

      // Schedules (Plannings)
      GoRoute(
        path: Routes.schedules,
        name: 'schedules',
        pageBuilder: (context, state) => PageTransitions.slideTransition(
          context: context,
          state: state,
          child: const SchedulesListScreen(),
        ),
        routes: [
          // Détail d'un schedule
          GoRoute(
            path: ':instance',
            name: 'scheduleDetail',
            pageBuilder: (context, state) {
              final instanceStr = state.pathParameters['instance']!;
              final instance = int.tryParse(instanceStr) ?? 0;
              return PageTransitions.scaleTransition(
                context: context,
                state: state,
                child: ScheduleDetailScreen(instance: instance),
              );
            },
          ),
        ],
      ),

      // Overrides - Liste des points forcés
      GoRoute(
        path: Routes.overrides,
        name: 'overrides',
        pageBuilder: (context, state) => PageTransitions.slideTransition(
          context: context,
          state: state,
          child: const OverridesScreen(),
        ),
      ),

      // Favoris
      GoRoute(
        path: Routes.favorites,
        name: 'favorites',
        pageBuilder: (context, state) => PageTransitions.slideTransition(
          context: context,
          state: state,
          child: const FavoritesScreen(),
        ),
      ),

      // Synoptiques
      GoRoute(
        path: Routes.synoptics,
        name: 'synoptics',
        pageBuilder: (context, state) => PageTransitions.slideTransition(
          context: context,
          state: state,
          child: const SynopticsListScreen(),
        ),
        routes: [
          // Visualiser un synoptique
          GoRoute(
            path: ':id',
            name: 'synopticView',
            pageBuilder: (context, state) {
              final idStr = state.pathParameters['id']!;
              final id = int.tryParse(idStr) ?? 0;
              return PageTransitions.scaleTransition(
                context: context,
                state: state,
                child: SynopticViewerScreen(synopticId: id),
              );
            },
            routes: [
              // Éditer les liaisons d'un synoptique
              GoRoute(
                path: 'edit',
                name: 'synopticEdit',
                pageBuilder: (context, state) {
                  final idStr = state.pathParameters['id']!;
                  final id = int.tryParse(idStr) ?? 0;
                  return PageTransitions.fadeTransition(
                    context: context,
                    state: state,
                    child: SynopticEditorScreen(synopticId: id),
                  );
                },
              ),
            ],
          ),
        ],
      ),

      // Envysion Viewer (synoptique integre via WebView)
      GoRoute(
        path: Routes.envysionViewer,
        name: 'envysionViewer',
        pageBuilder: (context, state) {
          final connectionIdStr = state.pathParameters['connectionId']!;
          final connectionId = int.tryParse(connectionIdStr) ?? 0;
          return PageTransitions.slideTransition(
            context: context,
            state: state,
            child: EnvysionViewerScreen(connectionId: connectionId),
          );
        },
      ),

      // Dashboards
      GoRoute(
        path: Routes.dashboards,
        name: 'dashboards',
        pageBuilder: (context, state) => PageTransitions.slideTransition(
          context: context,
          state: state,
          child: const DashboardListScreen(),
        ),
        routes: [
          // Vue d'un dashboard
          GoRoute(
            path: ':id',
            name: 'dashboardView',
            pageBuilder: (context, state) {
              final idStr = state.pathParameters['id']!;
              final id = int.tryParse(idStr) ?? 0;
              return PageTransitions.scaleTransition(
                context: context,
                state: state,
                child: DashboardScreen(dashboardId: id),
              );
            },
          ),
        ],
      ),

      // Paramètres
      GoRoute(
        path: Routes.settings,
        name: 'settings',
        pageBuilder: (context, state) => PageTransitions.slideTransition(
          context: context,
          state: state,
          child: const SettingsScreen(),
        ),
      ),

      // Info sur l'appareil
      GoRoute(
        path: Routes.deviceInfo,
        name: 'deviceInfo',
        pageBuilder: (context, state) => PageTransitions.slideTransition(
          context: context,
          state: state,
          child: const DeviceInfoScreen(),
        ),
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
