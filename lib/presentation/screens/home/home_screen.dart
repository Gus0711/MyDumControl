import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:myglobaldc/l10n/app_localizations.dart';
import '../../../application/providers/active_connection_provider.dart';
import '../../../application/providers/points_provider.dart';
import '../../../application/providers/favorites_provider.dart';
import '../../../application/providers/alarms_provider.dart';
import '../../../application/providers/settings_provider.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/api_exceptions.dart';
import '../../../domain/models/bacnet_object.dart';
import '../../../domain/models/display_preferences.dart';
import '../../widgets/skeleton_loading.dart';
import '../../widgets/gradient_app_bar.dart';

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

  /// True once a points load has finished (even with 0 point or an error),
  /// so an empty controller does not keep the loading skeleton forever.
  bool _pointsLoadFinished = false;

  /// Ouvre le synoptique Envysion dans le navigateur externe
  Future<void> _openEnvysionInBrowser() async {
    final state = ref.read(activeConnectionProvider);
    if (state.connection == null) return;
    final conn = state.connection!;
    final protocol = conn.useHttps ? 'https' : 'http';
    final host = conn.host;
    final port = conn.port;
    final designerPath = conn.designerUrl ?? '';

    String urlStr = '$protocol://$host';
    if ((protocol == 'https' && port != 443) || (protocol == 'http' && port != 80)) {
      urlStr += ':$port';
    }
    urlStr += designerPath;

    final uri = Uri.parse(urlStr);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

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
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.connectionId != null &&
        widget.connectionId != oldWidget.connectionId) {
      _initialLoadComplete = false;
      _pointsLoadTriggered = false;
      _pointsLoadFinished = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(activeConnectionProvider.notifier).connect(widget.connectionId!);
        }
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
      // Avertissement d'autorisation non bloquant (HTTP 403)
      if (next.authWarning != null && next.authWarning != previous?.authWarning) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.authWarning!), backgroundColor: Colors.orange.shade800),
        );
      }
      // Reset si déconnecté
      if (!next.isConnected) {
        _pointsLoadTriggered = false;
        _initialLoadComplete = false;
        _pointsLoadFinished = false;
      }
    });

    // Détecter la fin d'un chargement de points (même vide ou en erreur)
    ref.listen<PointsState>(pointsProvider, (previous, next) {
      if (previous != null && previous.isLoading && !next.isLoading) {
        if (!_pointsLoadFinished && mounted) {
          setState(() => _pointsLoadFinished = true);
        }
      }
    });

    // Écouter aussi le chargement des points pour fermer l'overlay
    final pointsState = ref.watch(pointsProvider);
    final connectionState = ref.watch(activeConnectionProvider);
    // Rebuild the controller clock when the 12/24 h setting changes
    ref.watch(settingsProvider.select((s) => s.use24HourFormat));

    // Marquer le chargement initial comme terminé quand connexion ET points sont chargés
    if (!_initialLoadComplete &&
        connectionState.isConnected &&
        !connectionState.isLoading &&
        connectionState.objectsSummary != null &&
        !pointsState.isLoading &&
        (pointsState.points.isNotEmpty ||
            _pointsLoadFinished ||
            pointsState.error != null)) {
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
      appBar: GradientAppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        titleWidget: Row(
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
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
              ),
            // Affichage de l'heure de l'automate
            if (connectionState.controllerTime != null)
              _ControllerTimeDisplay(
                controllerTime: connectionState.controllerTime!,
                canSync: connectionState.client?.canSetControllerTime ?? false,
                onSyncTime: () async {
                  final client = connectionState.client;
                  if (client == null || !client.canSetControllerTime) return false;
                  try {
                    final success = await client.setControllerTime(DateTime.now());
                    if (success) {
                      // Rafraîchir pour récupérer la nouvelle heure
                      ref.read(activeConnectionProvider.notifier).refresh();
                    }
                    return success;
                  } catch (e) {
                    return false;
                  }
                },
              ),
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
                  ref.read(autoRefreshIntervalProvider.notifier).state = 0;
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
    final isLoadingPoints = ptsState.isLoading ||
        (ptsState.points.isEmpty &&
            state.isConnected &&
            !_pointsLoadFinished &&
            ptsState.error == null);
    final showLoadingOverlay = !_initialLoadComplete && (state.isConnecting || state.isLoading || isLoadingPoints);

    if (showLoadingOverlay) {
      // Déterminer le message de statut
      String statusMessage = l10n.connecting;
      if (state.isConnecting) {
        statusMessage = l10n.connecting;
      } else if (state.isLoadingDeviceInfo) {
        statusMessage = l10n.homeAuthenticating;
      } else if (state.isLoadingSummary) {
        statusMessage = l10n.homeFetchingData;
      } else if (isLoadingPoints) {
        statusMessage = l10n.loadingPoints;
      }

      // Skeleton loading avec message de statut
      return DashboardSkeletonGrid(
        itemCount: 8,
        statusMessage: statusMessage,
        deviceName: state.connection?.name,
      );
    }

    if (state.error != null && !state.isConnected) {
      return _buildConnectionError(context, l10n, state);
    }

    // Grille de menu style MyDC Control avec fond dégradé
    return _buildMenuGrid(context, l10n, state);
  }

  /// Connection failure view, with the action matching the typed cause.
  Widget _buildConnectionError(BuildContext context, AppLocalizations l10n, ActiveConnectionState state) {
    final failure = state.failure;
    final connectionId = state.connection?.id;
    String message = state.error!;
    IconData icon = Icons.error_outline;
    Widget? action;

    if (failure is CertificateMismatchException) {
      icon = Icons.gpp_maybe_outlined;
      action = ElevatedButton.icon(
        onPressed: () => _confirmTrustNewCertificate(context, l10n, failure),
        icon: const Icon(Icons.verified_user_outlined),
        label: Text(l10n.trustNewCertificate),
      );
    } else if (failure is ApiAuthException || failure is PasswordMissingException) {
      icon = Icons.lock_outline;
      if (failure is ApiAuthException) {
        message = l10n.invalidCredentialsMessage('${failure.statusCode ?? '401/403'}');
      }
      if (connectionId != null) {
        action = ElevatedButton.icon(
          onPressed: () => context.push(Routes.editConnectionPath(connectionId.toString())),
          icon: const Icon(Icons.edit),
          label: Text(l10n.editConnection),
        );
      }
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            if (failure is CertificateMismatchException) ...[
              Text(
                l10n.certificateChangedTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
            ],
            SelectableText(message, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            if (action != null) ...[
              action,
              const SizedBox(height: 12),
            ],
            OutlinedButton.icon(
              onPressed: () => context.go(Routes.connections),
              icon: const Icon(Icons.arrow_back),
              label: Text(l10n.backToConnections),
            ),
          ],
        ),
      ),
    );
  }

  /// Asks the user to confirm before trusting a changed certificate.
  Future<void> _confirmTrustNewCertificate(
    BuildContext context,
    AppLocalizations l10n,
    CertificateMismatchException failure,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
        title: Text(l10n.certificateChangedTitle),
        content: SingleChildScrollView(
          child: SelectableText(
            l10n.trustNewCertificateMessage(failure.expectedFingerprint, failure.receivedFingerprint),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.trust),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _initialLoadComplete = false;
      _pointsLoadTriggered = false;
      _pointsLoadFinished = false;
    });
    await ref.read(activeConnectionProvider.notifier).trustNewCertificate();
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

    // Verifier si Envysion est configure pour cette connexion
    final hasEnvysion = state.connection?.designerUrl != null &&
        state.connection!.designerUrl!.isNotEmpty;

    // Menu items - ordre: Favoris, Points, Dashboard, Horaires, Alarmes, Forçages, Synoptique, Informations
    final menuItems = [
      _MenuItem(
        icon: Icons.star,
        title: l10n.favorites,
        // Jaune/ambre si favoris présents, bleu sinon
        color: favoritesCount > 0 ? Colors.amber.shade600 : Colors.blue.shade600,
        route: Routes.favorites,
        badge: favoritesCount > 0 ? favoritesCount.toString() : null,
      ),
      _MenuItem(
        icon: Icons.list_alt,
        title: l10n.points,
        color: Colors.blue.shade700,
        route: Routes.points,
      ),
      _MenuItem(
        icon: Icons.bar_chart,
        title: l10n.dashboard,
        color: Colors.indigo.shade600,
        route: Routes.dashboards,
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
        icon: hasEnvysion ? Icons.web : Icons.dashboard,
        title: hasEnvysion ? l10n.synopticEnvysion : l10n.homeSynoptic,
        color: Colors.teal.shade600,
        route: hasEnvysion ? null : Routes.synoptics,
        onTap: hasEnvysion ? _openEnvysionInBrowser : null,
      ),
      _MenuItem(
        icon: Icons.info,
        title: l10n.deviceInfo,
        color: Colors.blue.shade600,
        route: Routes.deviceInfo,
      ),
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF111318),
                  const Color(0xFF151922),
                  const Color(0xFF111318),
                ]
              : [
                  const Color(0xFFF5F7FA),
                  const Color(0xFFE8ECF2),
                  const Color(0xFFF0F4F8),
                ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Adapter le nombre de colonnes selon la largeur
          int crossAxisCount = 2;
          if (constraints.maxWidth > 600) crossAxisCount = 3;
          if (constraints.maxWidth > 900) crossAxisCount = 4;

          // Calculer si on a besoin de scroll ou pas
          final padding = 24.0;
          final spacing = 24.0;
          final availableWidth = constraints.maxWidth - (padding * 2);
          final availableHeight = constraints.maxHeight - (padding * 2);
          final rows = (menuItems.length / crossAxisCount).ceil();

          // Taille de carte pour tenir sans scroll
          final maxCardWidth = (availableWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;
          final maxCardHeight = (availableHeight - (spacing * (rows - 1))) / rows;
          final cardSize = maxCardWidth < maxCardHeight ? maxCardWidth : maxCardHeight;

          // Si tout tient, utiliser une grille non-scrollable
          final totalHeight = (cardSize * rows) + (spacing * (rows - 1)) + (padding * 2);
          final needsScroll = totalHeight > constraints.maxHeight;

          if (!needsScroll && constraints.maxHeight > 400) {
            // Grille centrée sans scroll
            return Padding(
              padding: EdgeInsets.all(padding),
              child: Center(
                child: Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  alignment: WrapAlignment.center,
                  children: menuItems.asMap().entries.map((entry) {
                    return SizedBox(
                      width: cardSize.clamp(120.0, 180.0),
                      height: cardSize.clamp(120.0, 180.0),
                      child: _buildMenuTile(context, entry.value, entry.key),
                    );
                  }).toList(),
                ),
              ),
            );
          }

          // Sinon, grille scrollable (mobile)
          return GridView.builder(
            padding: EdgeInsets.all(padding),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: 1.0,
            ),
            itemCount: menuItems.length,
            itemBuilder: (context, index) {
              final item = menuItems[index];
              return _buildMenuTile(context, item, index);
            },
          );
        },
      ),
    );
  }

  Widget _buildMenuTile(BuildContext context, _MenuItem item, int index) {
    return _AnimatedMenuTile(item: item, index: index);
  }

  Widget _buildDrawer(BuildContext context, AppLocalizations l10n, ActiveConnectionState state) {
    final device = state.deviceInfo;
    final connection = state.connection;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A1A2E),
                  Color(0xFF16213E),
                  Color(0xFF0F3460),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/logov2_no_back.png',
                    width: 56,
                    height: 56,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 12),
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
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
                ),
              ],
            ),
          ),
          _buildDrawerItem(context, icon: Icons.home, title: l10n.home, route: Routes.home, isSelected: true),
          _buildDrawerItem(context, icon: Icons.star, title: l10n.favorites, route: Routes.favorites),
          _buildDrawerItem(context, icon: Icons.list_alt, title: l10n.points, route: Routes.points),
          _buildDrawerItem(context, icon: Icons.bar_chart, title: l10n.dashboard, route: Routes.dashboards),
          _buildDrawerItem(context, icon: Icons.calendar_month, title: l10n.schedules, route: Routes.schedules),
          _buildDrawerItem(context, icon: Icons.notifications_active, title: l10n.alarms, route: Routes.alarms),
          _buildDrawerItem(context, icon: Icons.lock, title: l10n.overrides, route: Routes.overrides),
          _buildDrawerItem(
            context,
            icon: connection?.designerUrl != null && connection!.designerUrl!.isNotEmpty
                ? Icons.web
                : Icons.dashboard,
            title: connection?.designerUrl != null && connection!.designerUrl!.isNotEmpty
                ? l10n.synopticEnvysion
                : l10n.homeSynoptic,
            route: connection?.designerUrl != null && connection!.designerUrl!.isNotEmpty
                ? null
                : Routes.synoptics,
            onTap: connection?.designerUrl != null && connection!.designerUrl!.isNotEmpty
                ? _openEnvysionInBrowser
                : null,
          ),
          const Divider(),
          _buildDrawerItem(context, icon: Icons.info_outline, title: l10n.deviceInfo, route: Routes.deviceInfo),
          _buildDrawerItem(context, icon: Icons.settings, title: l10n.settings, route: Routes.settings),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(l10n.disconnect, style: const TextStyle(color: Colors.red)),
            onTap: () {
              ref.read(activeConnectionProvider.notifier).disconnect();
              ref.read(autoRefreshIntervalProvider.notifier).state = 0;
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
    String? route,
    VoidCallback? onTap,
    bool isSelected = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Couleur visible en dark et light mode pour l'élément sélectionné
    final selectedColor = isDark ? Colors.blue.shade300 : AppColors.primary;

    return ListTile(
      leading: Icon(icon, color: isSelected ? selectedColor : null),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? selectedColor : null,
        ),
      ),
      selected: isSelected,
      onTap: () {
        Navigator.pop(context);
        if (!isSelected) {
          if (onTap != null) {
            onTap();
          } else if (route != null) {
            context.push(route);
          }
        }
      },
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final Color color;
  final String? route;
  final String? badge;
  final VoidCallback? onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.color,
    this.route,
    this.badge,
    this.onTap,
  });
}

/// Widget de tuile de menu style MyDumControl avec animation pop-in
class _AnimatedMenuTile extends StatefulWidget {
  final _MenuItem item;
  final int index;

  const _AnimatedMenuTile({required this.item, required this.index});

  @override
  State<_AnimatedMenuTile> createState() => _AnimatedMenuTileState();
}

class _AnimatedMenuTileState extends State<_AnimatedMenuTile>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late Animation<double> _entryScaleAnimation;
  late Animation<double> _opacityAnimation;

  late AnimationController _tapController;
  late Animation<double> _tapAnimation;

  @override
  void initState() {
    super.initState();

    // Animation d'entrée (pop-in)
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _entryScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const ElasticOutCurve(0.8),
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // Animation de tap (bounce)
    _tapController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _tapAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.85), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.05), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 0.95), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(
      parent: _tapController,
      curve: Curves.easeOut,
    ));

    // Délai décalé selon l'index pour effet cascade
    Future.delayed(Duration(milliseconds: 50 * widget.index), () {
      if (mounted) {
        _entryController.forward();
      }
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    _tapController.dispose();
    super.dispose();
  }

  void _onTap() {
    // Haptic feedback léger
    HapticFeedback.lightImpact();

    _tapController.forward(from: 0).then((_) {
      if (mounted) {
        // Utiliser le callback personnalisé si fourni, sinon naviguer vers la route
        if (widget.item.onTap != null) {
          widget.item.onTap!();
        } else if (widget.item.route != null) {
          context.push(widget.item.route!);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    // Couleur plus foncée pour le dégradé
    final darkerColor = HSLColor.fromColor(item.color)
        .withLightness((HSLColor.fromColor(item.color).lightness * 0.4).clamp(0.05, 0.3))
        .withSaturation((HSLColor.fromColor(item.color).saturation * 0.8).clamp(0.0, 1.0))
        .toColor();

    return AnimatedBuilder(
      animation: Listenable.merge([_entryController, _tapController]),
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _entryScaleAnimation.value * _tapAnimation.value,
            child: child,
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  item.color.withValues(alpha: 0.85),
                  darkerColor,
                ],
              ),
            ),
            child: Stack(
              children: [
                // Icône centrée avec cercle
                Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Cercle de l'icône
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: item.color,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          item.icon,
                          size: 24,
                          color: Colors.white,
                        ),
                      ),
                      // Badge rouge
                      if (item.badge != null && item.badge != '0')
                        Positioned(
                          top: -4,
                          right: -4,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFE53935),
                            ),
                            child: Center(
                              child: Text(
                                item.badge!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Titre en bas à gauche
                Positioned(
                  bottom: 14,
                  left: 14,
                  right: 14,
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget d'affichage de l'heure de l'automate avec indicateur de décalage
class _ControllerTimeDisplay extends StatefulWidget {
  final ControllerTime controllerTime;
  final bool canSync;
  final Future<bool> Function()? onSyncTime;

  const _ControllerTimeDisplay({
    required this.controllerTime,
    this.canSync = false,
    this.onSyncTime,
  });

  @override
  State<_ControllerTimeDisplay> createState() => _ControllerTimeDisplayState();
}

class _ControllerTimeDisplayState extends State<_ControllerTimeDisplay>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
  }

  @override
  void didUpdateWidget(_ControllerTimeDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reconfigurer l'animation si le statut de décalage change
    final hadOffset = oldWidget.controllerTime.hasSignificantOffset;
    final hasOffset = widget.controllerTime.hasSignificantOffset;
    if (hadOffset != hasOffset) {
      _setupAnimation();
    }
  }

  void _setupAnimation() {
    if (widget.controllerTime.hasSignificantOffset) {
      _pulseController?.dispose();
      _pulseController = AnimationController(
        duration: const Duration(milliseconds: 1500),
        vsync: this,
      );
      _pulseAnimation = Tween<double>(begin: 1.0, end: 0.4).animate(
        CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut),
      );
      _pulseController!.repeat(reverse: true);
    } else {
      _pulseController?.dispose();
      _pulseController = null;
      _pulseAnimation = null;
    }
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    super.dispose();
  }

  ControllerTime get controllerTime => widget.controllerTime;

  @override
  Widget build(BuildContext context) {
    // Couleurs et styles selon le décalage
    Color textColor;
    Color backgroundColor;
    Color borderColor;
    Color iconColor;
    IconData icon;

    if (controllerTime.hasCriticalOffset) {
      // Décalage critique (> 10 min) : rouge vif
      textColor = Colors.white;
      backgroundColor = Colors.red.shade700;
      borderColor = Colors.red.shade300;
      iconColor = Colors.white;
      icon = Icons.error;
    } else if (controllerTime.hasSignificantOffset) {
      // Décalage significatif (> 2 min) : orange
      textColor = Colors.white;
      backgroundColor = Colors.orange.shade700;
      borderColor = Colors.orange.shade300;
      iconColor = Colors.white;
      icon = Icons.warning_amber;
    } else {
      // OK : couleur normale
      textColor = Colors.white70;
      backgroundColor = Colors.black12;
      borderColor = Colors.transparent;
      iconColor = Colors.white54;
      icon = Icons.access_time;
    }

    final hasOffset = controllerTime.hasSignificantOffset;

    Widget content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: hasOffset
            ? Border.all(color: borderColor, width: 2)
            : null,
        boxShadow: hasOffset
            ? [
                BoxShadow(
                  color: backgroundColor.withValues(alpha: 0.6),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: hasOffset ? 18 : 14,
            color: iconColor,
          ),
          const SizedBox(width: 6),
          Text(
            '${controllerTime.formattedDateShort} ${controllerTime.formattedTime}',
            style: TextStyle(
              fontSize: hasOffset ? 14 : 13,
              fontWeight: hasOffset ? FontWeight.bold : FontWeight.w500,
              color: textColor,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );

    // Ajouter l'animation de pulsation si décalage
    if (hasOffset && _pulseAnimation != null) {
      content = AnimatedBuilder(
        animation: _pulseAnimation!,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: (controllerTime.hasCriticalOffset
                          ? Colors.red
                          : Colors.orange)
                      .withValues(alpha: _pulseAnimation!.value * 0.8),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: child,
          );
        },
        child: content,
      );
    }

    return Tooltip(
      message: _buildTooltipMessage(AppLocalizations.of(context)!),
      child: InkWell(
        onTap: () => _showTimeDialog(context),
        borderRadius: BorderRadius.circular(8),
        child: content,
      ),
    );
  }

  String _buildTooltipMessage(AppLocalizations l10n) {
    final buffer = StringBuffer();
    buffer.writeln(l10n.homeControllerTimeTooltip(controllerTime.formattedDateTime));
    buffer.write(l10n.homeTimeOffsetTooltip(controllerTime.offsetDescription));
    return buffer.toString();
  }

  void _showTimeDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    bool isSyncing = false;
    String? syncResult;
    bool syncSuccess = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
              Text(l10n.homeControllerTimeTitle),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow(l10n.homeControllerDateTime, controllerTime.formattedDateTime),
              _buildInfoRow(l10n.homeLocalTime, _formatLocalTime()),
              const Divider(),
              _buildInfoRow(
                l10n.homeTimeOffset,
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
                          l10n.homeTimeOffsetWarning,
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
              // Message de résultat de synchronisation
              if (syncResult != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: syncSuccess
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        syncSuccess
                            ? Icons.check_circle
                            : Icons.error,
                        size: 18,
                        color: syncSuccess
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          syncResult!,
                          style: TextStyle(
                            fontSize: 13,
                            color: syncSuccess
                                ? Colors.green.shade800
                                : Colors.red.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // Info si V2 (pas de sync disponible)
              if (!widget.canSync && controllerTime.hasSignificantOffset) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, size: 18, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.homeSyncV2Info,
                          style: TextStyle(fontSize: 12, color: Colors.blue.shade800),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            // Bouton Synchroniser (uniquement si API V1 et décalage)
            if (widget.canSync && controllerTime.hasSignificantOffset)
              TextButton.icon(
                onPressed: isSyncing
                    ? null
                    : () async {
                        setDialogState(() {
                          isSyncing = true;
                          syncResult = null;
                        });

                        try {
                          final success = await widget.onSyncTime?.call() ?? false;
                          if (!dialogContext.mounted) return;
                          setDialogState(() {
                            isSyncing = false;
                            syncSuccess = success;
                            syncResult = success
                                ? l10n.homeSyncSuccess
                                : l10n.homeSyncFailed;
                          });

                          // Fermer la popup après succès
                          if (success && dialogContext.mounted) {
                            await Future.delayed(const Duration(milliseconds: 1500));
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                          }
                        } catch (e) {
                          if (!dialogContext.mounted) return;
                          setDialogState(() {
                            isSyncing = false;
                            syncSuccess = false;
                            syncResult = l10n.errorWithMessage('$e');
                          });
                        }
                      },
                icon: isSyncing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync),
                label: Text(isSyncing ? l10n.homeSyncing : l10n.homeSync),
              ),
            TextButton(
              onPressed: isSyncing ? null : () => Navigator.pop(dialogContext),
              child: Text(l10n.close),
            ),
          ],
        ),
      ),
    );
  }

  String _formatLocalTime() => DisplayPreferences.formatDateTime(DateTime.now(), withSeconds: true);

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
