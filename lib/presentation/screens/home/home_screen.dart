import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mydumcontrol/l10n/app_localizations.dart';
import '../../../application/providers/active_connection_provider.dart';
import '../../../application/providers/points_provider.dart';
import '../../../application/providers/favorites_provider.dart';
import '../../../application/providers/alarms_provider.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/bacnet_object.dart';
import '../../widgets/connection_loading_overlay.dart';

/// Écran principal - Menu de navigation vers les fonctionnalités
class HomeScreen extends ConsumerStatefulWidget {
  final int? connectionId;

  const HomeScreen({super.key, this.connectionId});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _pointsLoadTriggered = false;
  bool _initialLoadComplete = false;

  @override
  void initState() {
    super.initState();
    if (widget.connectionId != null) {
      // Reset le flag de chargement initial quand on démarre une nouvelle connexion
      _initialLoadComplete = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(activeConnectionProvider.notifier).connect(widget.connectionId!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Écouter l'état de connexion pour charger les points automatiquement
    ref.listen<ActiveConnectionState>(activeConnectionProvider, (previous, next) {
      // Quand la connexion devient active, charger les points
      if (next.isConnected && !_pointsLoadTriggered) {
        _pointsLoadTriggered = true;
        final pointsState = ref.read(pointsProvider);
        if (pointsState.points.isEmpty && !pointsState.isLoading) {
          ref.read(pointsProvider.notifier).loadPoints();
        }
      }
      // Reset si déconnecté
      if (!next.isConnected) {
        _pointsLoadTriggered = false;
        _initialLoadComplete = false;
      }
    });

    // Écouter aussi le chargement des points pour fermer l'overlay
    final pointsState = ref.watch(pointsProvider);
    final connectionState = ref.watch(activeConnectionProvider);

    // Marquer le chargement initial comme terminé quand connexion ET points sont chargés
    if (!_initialLoadComplete &&
        connectionState.isConnected &&
        !connectionState.isLoading &&
        connectionState.objectsSummary != null &&
        !pointsState.isLoading &&
        pointsState.points.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _initialLoadComplete = true;
          });
        }
      });
    }

    // Charger les points si déjà connecté au premier build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final connState = ref.read(activeConnectionProvider);
      final ptsState = ref.read(pointsProvider);
      if (connState.isConnected && ptsState.points.isEmpty && !ptsState.isLoading && !_pointsLoadTriggered) {
        _pointsLoadTriggered = true;
        ref.read(pointsProvider.notifier).loadPoints();
      }
    });
    final l10n = AppLocalizations.of(context)!;

    // Nom de l'automate (ou placeholder pendant le chargement)
    String deviceName = connectionState.connection?.name ?? l10n.home;
    if (connectionState.deviceInfo?.objectName != null) {
      deviceName = connectionState.deviceInfo!.objectName;
    }

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                deviceName,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (connectionState.isLoading)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            // Affichage de l'heure de l'automate
            if (connectionState.controllerTime != null)
              _ControllerTimeDisplay(controllerTime: connectionState.controllerTime!),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: connectionState.isLoading
                ? null
                : () => ref.read(activeConnectionProvider.notifier).refresh(),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'settings':
                  context.push(Routes.settings);
                  break;
                case 'disconnect':
                  ref.read(activeConnectionProvider.notifier).disconnect();
                  context.go(Routes.connections);
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    const Icon(Icons.settings, size: 20),
                    const SizedBox(width: 12),
                    Text(l10n.settings),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'disconnect',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20, color: Colors.red.shade400),
                    const SizedBox(width: 12),
                    Text(l10n.disconnect, style: TextStyle(color: Colors.red.shade400)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      drawer: _buildDrawer(context, l10n, connectionState),
      body: _buildBody(context, l10n, connectionState),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n, ActiveConnectionState state) {
    // Afficher l'overlay de chargement pendant tout le processus de connexion initial
    // L'overlay reste visible tant que le chargement initial n'est pas terminé
    final ptsState = ref.watch(pointsProvider);
    final isLoadingPoints = ptsState.isLoading || (ptsState.points.isEmpty && state.isConnected);
    final showLoadingOverlay = !_initialLoadComplete && (state.isConnecting || state.isLoading || isLoadingPoints);

    if (showLoadingOverlay) {
      int step = 0;
      String message = 'Connexion en cours';

      if (state.isConnecting) {
        step = 0;
        message = 'Connexion en cours';
      } else if (state.isLoadingDeviceInfo) {
        step = 1;
        message = 'Authentification';
      } else if (state.isLoadingSummary) {
        step = 2;
        message = 'Récupération des données';
      } else if (isLoadingPoints) {
        step = 3;
        message = 'Chargement des points';
      }

      return ConnectionLoadingOverlay(
        message: message,
        subMessage: state.connection?.name ?? 'Automate',
        currentStep: step,
        totalSteps: 4,
      );
    }

    if (state.error != null && !state.isConnected) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(state.error!, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go(Routes.connections),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Retour aux connexions'),
            ),
          ],
        ),
      );
    }

    // Grille de menu style MyDC Control
    return _buildMenuGrid(context, l10n, state);
  }

  Widget _buildMenuGrid(BuildContext context, AppLocalizations l10n, ActiveConnectionState state) {
    final summary = state.objectsSummary;
    final pointsState = ref.watch(pointsProvider);
    final overrideCount = pointsState.overriddenCount;
    final hasOverrides = pointsState.hasOverrides;

    // Compter les favoris
    final favoritesAsync = ref.watch(favoritesProvider);
    final favoritesCount = favoritesAsync.maybeWhen(
      data: (favorites) => favorites.length,
      orElse: () => 0,
    );

    // Compter les alarmes actives
    final alarmsCount = ref.watch(alarmsCountProvider);
    final hasAlarms = alarmsCount > 0;

    // Menu items inspirés de MyDC Control
    final menuItems = [
      _MenuItem(
        icon: Icons.list_alt,
        title: l10n.points,
        color: Colors.blue.shade700,
        route: Routes.points,
      ),
      _MenuItem(
        icon: Icons.calendar_month,
        title: l10n.schedules,
        color: Colors.blue.shade600,
        route: Routes.schedules,
        badge: summary?.schedules.toString(),
      ),
      _MenuItem(
        icon: Icons.notifications_active,
        title: l10n.alarms,
        // Rouge si alarmes présentes, bleu sinon
        color: hasAlarms ? Colors.red.shade600 : Colors.blue.shade700,
        route: Routes.alarms,
        badge: hasAlarms ? alarmsCount.toString() : null,
      ),
      _MenuItem(
        icon: Icons.lock,
        title: l10n.overrides,
        // Bleu si aucun forçage, violet si au moins 1 forçage
        color: hasOverrides ? Colors.purple.shade600 : Colors.blue.shade600,
        route: Routes.overrides,
        badge: hasOverrides ? overrideCount.toString() : null,
      ),
      _MenuItem(
        icon: Icons.star,
        title: 'Favoris',
        // Jaune/ambre si favoris présents, bleu sinon
        color: favoritesCount > 0 ? Colors.amber.shade600 : Colors.blue.shade600,
        route: Routes.favorites,
        badge: favoritesCount > 0 ? favoritesCount.toString() : null,
      ),
      _MenuItem(
        icon: Icons.show_chart,
        title: 'Boucles PID',
        color: Colors.blueGrey.shade600,
        route: Routes.pidLoops,
      ),
      _MenuItem(
        icon: Icons.settings,
        title: l10n.settings,
        color: Colors.blueGrey.shade500,
        route: Routes.settings,
      ),
      _MenuItem(
        icon: Icons.info,
        title: l10n.deviceInfo,
        color: Colors.blue.shade600,
        route: Routes.deviceInfo,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Adapter le nombre de colonnes selon la largeur
        int crossAxisCount = 2;
        if (constraints.maxWidth > 600) crossAxisCount = 3;
        if (constraints.maxWidth > 900) crossAxisCount = 4;

        return GridView.builder(
          padding: const EdgeInsets.all(24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
            childAspectRatio: 1.0,
          ),
          itemCount: menuItems.length,
          itemBuilder: (context, index) {
            final item = menuItems[index];
            return _buildMenuTile(context, item);
          },
        );
      },
    );
  }

  Widget _buildMenuTile(BuildContext context, _MenuItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(item.route),
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  item.icon,
                  size: 56,
                  color: item.color,
                ),
                if (item.badge != null && item.badge != '0')
                  Positioned(
                    top: -4,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        item.badge!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AppLocalizations l10n, ActiveConnectionState state) {
    final device = state.deviceInfo;
    final connection = state.connection;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.settings_remote, size: 48, color: Colors.white),
                const SizedBox(height: 8),
                Text(
                  device?.objectName ?? connection?.name ?? 'ECLYPSE Controller',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  connection != null ? '${connection.host}:${connection.port}' : '',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
                ),
              ],
            ),
          ),
          _buildDrawerItem(context, icon: Icons.home, title: l10n.home, route: Routes.home, isSelected: true),
          _buildDrawerItem(context, icon: Icons.list_alt, title: l10n.points, route: Routes.points),
          _buildDrawerItem(context, icon: Icons.calendar_month, title: l10n.schedules, route: Routes.schedules),
          _buildDrawerItem(context, icon: Icons.notifications_active, title: l10n.alarms, route: Routes.alarms),
          _buildDrawerItem(context, icon: Icons.settings_backup_restore, title: l10n.overrides, route: Routes.overrides),
          _buildDrawerItem(context, icon: Icons.star, title: 'Favoris', route: Routes.favorites),
          _buildDrawerItem(context, icon: Icons.show_chart, title: 'Boucles PID', route: Routes.pidLoops),
          const Divider(),
          _buildDrawerItem(context, icon: Icons.info_outline, title: l10n.deviceInfo, route: Routes.deviceInfo),
          _buildDrawerItem(context, icon: Icons.settings, title: l10n.settings, route: Routes.settings),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(l10n.disconnect, style: const TextStyle(color: Colors.red)),
            onTap: () {
              ref.read(activeConnectionProvider.notifier).disconnect();
              Navigator.pop(context);
              context.go(Routes.connections);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
    bool isSelected = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppColors.primary : null),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.primary : null,
        ),
      ),
      selected: isSelected,
      onTap: () {
        Navigator.pop(context);
        if (!isSelected) {
          context.push(route);
        }
      },
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final Color color;
  final String route;
  final String? badge;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.color,
    required this.route,
    this.badge,
  });
}

/// Widget d'affichage de l'heure de l'automate avec indicateur de décalage
class _ControllerTimeDisplay extends StatelessWidget {
  final ControllerTime controllerTime;

  const _ControllerTimeDisplay({required this.controllerTime});

  @override
  Widget build(BuildContext context) {
    // Couleur selon le décalage
    Color timeColor;
    Color? iconColor;
    IconData? warningIcon;

    if (controllerTime.hasCriticalOffset) {
      // Décalage critique (> 10 min) : rouge
      timeColor = Colors.red.shade300;
      iconColor = Colors.red.shade300;
      warningIcon = Icons.error;
    } else if (controllerTime.hasSignificantOffset) {
      // Décalage significatif (> 2 min) : orange
      timeColor = Colors.orange.shade300;
      iconColor = Colors.orange.shade300;
      warningIcon = Icons.warning_amber;
    } else {
      // OK : couleur normale
      timeColor = Colors.white70;
    }

    return Tooltip(
      message: _buildTooltipMessage(),
      child: InkWell(
        onTap: () => _showTimeDialog(context),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          margin: const EdgeInsets.only(left: 8),
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                warningIcon ?? Icons.access_time,
                size: 14,
                color: iconColor ?? Colors.white54,
              ),
              const SizedBox(width: 4),
              Text(
                controllerTime.formattedTime,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: timeColor,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildTooltipMessage() {
    final buffer = StringBuffer();
    buffer.writeln('Heure automate: ${controllerTime.formattedDateTime}');
    buffer.write('Décalage: ${controllerTime.offsetDescription}');
    return buffer.toString();
  }

  void _showTimeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              controllerTime.hasCriticalOffset
                  ? Icons.error
                  : controllerTime.hasSignificantOffset
                      ? Icons.warning_amber
                      : Icons.access_time,
              color: controllerTime.hasCriticalOffset
                  ? Colors.red
                  : controllerTime.hasSignificantOffset
                      ? Colors.orange
                      : Colors.blue,
            ),
            const SizedBox(width: 8),
            const Text('Heure de l\'automate'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Date/Heure automate', controllerTime.formattedDateTime),
            _buildInfoRow('Heure locale', _formatLocalTime()),
            const Divider(),
            _buildInfoRow(
              'Décalage',
              controllerTime.offsetDescription,
              valueColor: controllerTime.hasCriticalOffset
                  ? Colors.red
                  : controllerTime.hasSignificantOffset
                      ? Colors.orange
                      : Colors.green,
            ),
            if (controllerTime.hasSignificantOffset) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: controllerTime.hasCriticalOffset
                      ? Colors.red.shade50
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: controllerTime.hasCriticalOffset
                        ? Colors.red.shade200
                        : Colors.orange.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: controllerTime.hasCriticalOffset
                          ? Colors.red.shade700
                          : Colors.orange.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'L\'heure de l\'automate est décalée. '
                        'Les plannings peuvent ne pas s\'exécuter aux moments attendus.',
                        style: TextStyle(
                          fontSize: 13,
                          color: controllerTime.hasCriticalOffset
                              ? Colors.red.shade800
                              : Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  String _formatLocalTime() {
    final now = DateTime.now();
    final d = now.day.toString().padLeft(2, '0');
    final m = now.month.toString().padLeft(2, '0');
    final y = now.year;
    final h = now.hour.toString().padLeft(2, '0');
    final min = now.minute.toString().padLeft(2, '0');
    final s = now.second.toString().padLeft(2, '0');
    return '$d/$m/$y $h:$min:$s';
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
