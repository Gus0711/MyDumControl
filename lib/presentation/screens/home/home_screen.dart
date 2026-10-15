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
import '../../widgets/ui/ui.dart';

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
          dcSnackBar(next.authWarning!, color: AppSnackColors.warning, icon: Icons.lock_outline_rounded),
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
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        titleWidget: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(deviceName, overflow: TextOverflow.ellipsis),
                  if (connectionState.connection != null)
                    Text(
                      connectionState.connection!.host,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.monospacedValue.copyWith(
                        fontSize: 11,
                        color: const Color(0xFF9FB2CC),
                      ),
                    ),
                ],
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
            icon: const Icon(Icons.refresh_rounded),
            tooltip: l10n.refresh,
            onPressed: connectionState.isLoading
                ? null
                : () => ref.read(activeConnectionProvider.notifier).refresh(),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
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
              dcMenuItem(context, 'settings', Icons.settings_outlined, l10n.settings),
              dcMenuItem(context, 'disconnect', Icons.logout_rounded, l10n.disconnect, danger: true),
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
      action = FilledButton.icon(
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
        action = FilledButton.icon(
          onPressed: () => context.push(Routes.editConnectionPath(connectionId.toString())),
          icon: const Icon(Icons.edit),
          label: Text(l10n.editConnection),
        );
      }
    }

    return DcEmptyState(
      icon: icon,
      tone: failure is CertificateMismatchException ? context.dc.warning : context.dc.danger,
      title: failure is CertificateMismatchException
          ? l10n.certificateChangedTitle
          : (state.connection?.name ?? l10n.error),
      message: message,
      action: action,
      secondaryAction: OutlinedButton.icon(
        onPressed: () => context.go(Routes.connections),
        icon: const Icon(Icons.arrow_back_rounded),
        label: Text(l10n.backToConnections),
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
        icon: Icon(Icons.warning_amber_rounded, color: context.dc.warning.fg),
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
    final dc = context.dc;
    final summary = state.objectsSummary;
    final pointsState = ref.watch(pointsProvider);
    final overrideCount = pointsState.overriddenCount;
    final hasOverrides = pointsState.hasOverrides;
    final pointsCount = pointsState.points.isNotEmpty ? pointsState.points.length : (summary?.total ?? 0);

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

    // Modules - ordre: Favoris, Points, Dashboard, Horaires, Alarmes, Forçages, Synoptique, Informations
    final menuItems = [
      _MenuItem(
        icon: Icons.star_rounded,
        title: l10n.favorites,
        description: l10n.homeFavoritesDesc,
        color: AppColors.multiStateOutput,
        route: Routes.favorites,
        badge: favoritesCount > 0 ? favoritesCount.toString() : null,
      ),
      _MenuItem(
        icon: Icons.format_list_bulleted_rounded,
        title: l10n.points,
        description: l10n.homePointsDesc,
        color: AppColors.brandSky,
        route: Routes.points,
        badge: pointsCount > 0 ? pointsCount.toString() : null,
      ),
      _MenuItem(
        icon: Icons.insights_rounded,
        title: l10n.dashboards,
        description: l10n.homeDashboardDesc,
        color: AppColors.brandViolet,
        route: Routes.dashboards,
      ),
      _MenuItem(
        icon: Icons.calendar_month_rounded,
        title: l10n.schedules,
        description: l10n.homeSchedulesDesc,
        color: AppColors.multiStateValue,
        route: Routes.schedules,
        badge: (summary?.schedules ?? 0) > 0 ? summary!.schedules.toString() : null,
      ),
      _MenuItem(
        icon: Icons.notifications_active_rounded,
        title: l10n.alarms,
        description: l10n.homeAlarmsDesc,
        color: AppColors.alarmCritical,
        route: Routes.alarms,
        badge: hasAlarms ? alarmsCount.toString() : null,
        badgeTone: dc.danger,
      ),
      _MenuItem(
        icon: Icons.back_hand_rounded,
        title: l10n.overrides,
        description: l10n.homeOverridesDesc,
        color: AppColors.overrideActive,
        route: Routes.overrides,
        badge: hasOverrides ? overrideCount.toString() : null,
        badgeTone: dc.overrideTone,
      ),
      _MenuItem(
        icon: hasEnvysion ? Icons.open_in_new_rounded : Icons.schema_rounded,
        title: hasEnvysion ? l10n.synopticEnvysion : l10n.homeSynoptic,
        description: hasEnvysion ? l10n.homeEnvysionDesc : l10n.homeSynopticDesc,
        color: AppColors.analogValue,
        route: hasEnvysion ? null : Routes.synoptics,
        onTap: hasEnvysion ? _openEnvysionInBrowser : null,
      ),
      _MenuItem(
        icon: Icons.info_outline_rounded,
        title: l10n.deviceInfo,
        description: l10n.homeDeviceInfoDesc,
        color: AppColors.disconnected,
        route: Routes.deviceInfo,
      ),
    ];

    final kpis = [
      _Kpi(
        label: l10n.points,
        value: pointsCount > 0 ? '$pointsCount' : '—',
        icon: Icons.format_list_bulleted_rounded,
        tone: dc.accentTone,
        route: Routes.points,
      ),
      _Kpi(
        label: hasAlarms ? l10n.activeAlarms : l10n.homeNoAlarm,
        value: '$alarmsCount',
        icon: hasAlarms ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
        tone: hasAlarms ? dc.danger : dc.success,
        route: Routes.alarms,
      ),
      _Kpi(
        label: hasOverrides ? l10n.overrides : l10n.homeNoOverride,
        value: '$overrideCount',
        icon: Icons.back_hand_rounded,
        tone: hasOverrides ? dc.overrideTone : dc.success,
        route: Routes.overrides,
      ),
      _Kpi(
        label: l10n.favorites,
        value: '$favoritesCount',
        icon: Icons.star_rounded,
        tone: favoritesCount > 0 ? dc.toneOf(AppColors.multiStateOutput) : dc.neutral,
        route: Routes.favorites,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.clamp(0.0, DcSpace.contentMaxWidth) - 40;
        final kpiColumns = width >= 860 ? 4 : 2;
        final moduleColumns = width >= 1000 ? 4 : (width >= 640 ? 3 : (width >= 380 ? 2 : 1));
        const spacing = 14.0;
        final kpiWidth = (width - spacing * (kpiColumns - 1)) / kpiColumns;
        final moduleWidth = (width - spacing * (moduleColumns - 1)) / moduleColumns;

        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: DcContent(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DeviceHeader(state: state),
                const SizedBox(height: spacing),
                Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (final k in kpis)
                      SizedBox(
                        width: kpiWidth,
                        child: DcKpi(
                          label: k.label,
                          value: k.value,
                          icon: k.icon,
                          tone: k.tone,
                          onTap: () => context.push(k.route),
                        ),
                      ),
                  ],
                ),
                DcSectionHeader(
                  l10n.homeModulesTitle,
                  padding: const EdgeInsets.fromLTRB(2, 28, 0, 12),
                ),
                Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (var i = 0; i < menuItems.length; i++)
                      SizedBox(
                        width: moduleWidth,
                        child: _AnimatedMenuTile(item: menuItems[i], index: i),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawer(BuildContext context, AppLocalizations l10n, ActiveConnectionState state) {
    final device = state.deviceInfo;
    final connection = state.connection;
    final hasEnvysion = connection?.designerUrl != null && connection!.designerUrl!.isNotEmpty;

    return Drawer(
      width: 300,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 24, 20, 20),
            decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
            child: Row(
              children: [
                Image.asset('assets/images/logov2_no_back.png', width: 48, height: 48, fit: BoxFit.contain),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device?.objectName ?? connection?.name ?? 'ECLYPSE Controller',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.titleMedium?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        connection != null ? '${connection.host}:${connection.port}' : '',
                        style: AppTextStyles.monospacedValue.copyWith(
                          color: const Color(0xFF9FB2CC),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1.5, decoration: const BoxDecoration(gradient: AppColors.brandLine)),
          const SizedBox(height: 8),
          _buildDrawerItem(context, icon: Icons.space_dashboard_rounded, title: l10n.home, route: Routes.home, isSelected: true),
          _buildDrawerItem(context, icon: Icons.star_rounded, title: l10n.favorites, route: Routes.favorites),
          _buildDrawerItem(context, icon: Icons.format_list_bulleted_rounded, title: l10n.points, route: Routes.points),
          _buildDrawerItem(context, icon: Icons.insights_rounded, title: l10n.dashboards, route: Routes.dashboards),
          _buildDrawerItem(context, icon: Icons.calendar_month_rounded, title: l10n.schedules, route: Routes.schedules),
          _buildDrawerItem(context, icon: Icons.notifications_active_rounded, title: l10n.alarms, route: Routes.alarms),
          _buildDrawerItem(context, icon: Icons.back_hand_rounded, title: l10n.overrides, route: Routes.overrides),
          _buildDrawerItem(
            context,
            icon: hasEnvysion ? Icons.open_in_new_rounded : Icons.schema_rounded,
            title: hasEnvysion ? l10n.synopticEnvysion : l10n.homeSynoptic,
            route: hasEnvysion ? null : Routes.synoptics,
            onTap: hasEnvysion ? _openEnvysionInBrowser : null,
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16), child: Divider()),
          _buildDrawerItem(context, icon: Icons.info_outline_rounded, title: l10n.deviceInfo, route: Routes.deviceInfo),
          _buildDrawerItem(context, icon: Icons.settings_outlined, title: l10n.settings, route: Routes.settings),
          const Padding(padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16), child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ListTile(
              leading: Icon(Icons.logout_rounded, color: context.dc.danger.fg),
              title: Text(l10n.disconnect, style: TextStyle(color: context.dc.danger.fg)),
              onTap: () {
                ref.read(activeConnectionProvider.notifier).disconnect();
                ref.read(autoRefreshIntervalProvider.notifier).state = 0;
                Navigator.pop(context);
                context.go(Routes.connections);
              },
            ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
      child: ListTile(
        leading: Icon(icon, size: 21),
        title: Text(
          title,
          style: TextStyle(fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500),
        ),
        selected: isSelected,
        dense: true,
        visualDensity: const VisualDensity(vertical: 0.5),
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
      ),
    );
  }
}

class _Kpi {
  final String label;
  final String value;
  final IconData icon;
  final DcTone tone;
  final String route;

  const _Kpi({
    required this.label,
    required this.value,
    required this.icon,
    required this.tone,
    required this.route,
  });
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final String? route;
  final String? badge;
  final DcTone? badgeTone;
  final VoidCallback? onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    this.route,
    this.badge,
    this.badgeTone,
    this.onTap,
  });
}

/// En-tête de l'automate connecté : identité, état et caractéristiques.
class _DeviceHeader extends StatelessWidget {
  final ActiveConnectionState state;

  const _DeviceHeader({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dc = context.dc;
    final device = state.deviceInfo;
    final connection = state.connection;
    final isBacnet = state.isBacnetConnection;
    final name = device?.objectName ?? connection?.name ?? '';
    final model = device?.modelName ?? connection?.modelName;
    final firmware = device?.softwareVersion;
    final apiVersion = connection?.apiVersion;
    final description = (device?.description?.trim().isNotEmpty ?? false)
        ? device!.description!.trim()
        : (device?.location?.trim().isNotEmpty ?? false)
            ? device!.location!.trim()
            : null;

    return DcCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DcIconBox(
            icon: isBacnet ? Icons.lan_outlined : Icons.memory_rounded,
            tone: isBacnet ? dc.violet : dc.accentTone,
            size: 56,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.headlineSmall,
                      ),
                    ),
                    const SizedBox(width: 12),
                    DcStatusDot(color: dc.success.fg),
                    const SizedBox(width: 6),
                    Text(l10n.connected, style: context.text.labelMedium?.copyWith(color: dc.success.fg)),
                  ],
                ),
                if (description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodyMedium?.copyWith(color: dc.textSecondary),
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (connection != null)
                      DcTag('${connection.host}:${connection.port}', icon: Icons.lan_rounded, mono: true),
                    if (model != null) DcTag(model, icon: Icons.memory_rounded),
                    if (firmware != null) DcTag('FW $firmware', mono: true),
                    if (isBacnet)
                      DcTag(
                        state.bacnetDeviceId != null ? 'BACnet · ${state.bacnetDeviceId}' : 'BACnet/IP',
                        tone: dc.violet,
                      )
                    else if (apiVersion != null)
                      DcTag('API $apiVersion', tone: dc.accentTone),
                    if (state.deviceInfoFromCache || state.summaryFromCache)
                      DcTag(l10n.homeFromCache, icon: Icons.history_rounded, tone: dc.warning),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tuile de module (Points, Horaires…) avec apparition en cascade.
class _AnimatedMenuTile extends StatefulWidget {
  final _MenuItem item;
  final int index;

  const _AnimatedMenuTile({required this.item, required this.index});

  @override
  State<_AnimatedMenuTile> createState() => _AnimatedMenuTileState();
}

class _AnimatedMenuTileState extends State<_AnimatedMenuTile> with SingleTickerProviderStateMixin {
  late final AnimationController _entryController = AnimationController(
    duration: const Duration(milliseconds: 420),
    vsync: this,
  );
  late final Animation<double> _entry = CurvedAnimation(
    parent: _entryController,
    curve: Curves.easeOutCubic,
  );
  bool _hover = false;

  @override
  void initState() {
    super.initState();
    // Délai décalé selon l'index pour effet cascade
    Future.delayed(Duration(milliseconds: 40 * widget.index), () {
      if (mounted) _entryController.forward();
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  void _onTap() {
    HapticFeedback.lightImpact();
    if (widget.item.onTap != null) {
      widget.item.onTap!();
    } else if (widget.item.route != null) {
      context.push(widget.item.route!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final dc = context.dc;
    final tone = dc.toneOf(item.color);
    final radius = BorderRadius.circular(DcRadius.lg);

    return AnimatedBuilder(
      animation: _entry,
      builder: (context, child) => Opacity(
        opacity: _entry.value,
        child: Transform.translate(offset: Offset(0, 12 * (1 - _entry.value)), child: child),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hover ? -2 : 0, 0),
        decoration: BoxDecoration(
          color: dc.surface,
          borderRadius: radius,
          border: Border.all(color: _hover ? tone.border : dc.border),
          boxShadow: _hover ? dc.raisedShadow : dc.cardShadow,
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _onTap,
            onHover: (h) => setState(() => _hover = h),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DcIconBox(icon: item.icon, tone: tone, size: 44),
                      const Spacer(),
                      if (item.badge != null && item.badge != '0')
                        DcTag(item.badge!, tone: item.badgeTone ?? dc.neutral, solid: item.badgeTone != null),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.titleMedium,
                        ),
                      ),
                      AnimatedSlide(
                        duration: const Duration(milliseconds: 160),
                        offset: Offset(_hover ? 0.15 : 0, 0),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: _hover ? tone.fg : dc.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall?.copyWith(color: dc.textSecondary, height: 1.35),
                  ),
                ],
              ),
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
    final hasOffset = controllerTime.hasSignificantOffset;
    final critical = controllerTime.hasCriticalOffset;

    // Couleurs selon le décalage (sur la barre bleu nuit)
    final Color accent = critical
        ? const Color(0xFFFF6B70)
        : hasOffset
            ? const Color(0xFFF7B13D)
            : const Color(0xFF9FB2CC);
    final IconData icon = critical
        ? Icons.error_rounded
        : hasOffset
            ? Icons.warning_amber_rounded
            : Icons.schedule_rounded;

    Widget content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: hasOffset ? accent.withValues(alpha: 0.16) : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(DcRadius.md),
        border: Border.all(color: hasOffset ? accent.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: accent),
          const SizedBox(width: 6),
          Text(
            '${controllerTime.formattedDateShort} ${controllerTime.formattedTime}',
            style: AppTextStyles.monospacedValue.copyWith(
              fontSize: 12.5,
              fontWeight: hasOffset ? FontWeight.w600 : FontWeight.w500,
              color: hasOffset ? accent : const Color(0xFFD5E2F3),
            ),
          ),
        ],
      ),
    );

    // Pulsation si décalage
    if (hasOffset && _pulseAnimation != null) {
      content = AnimatedBuilder(
        animation: _pulseAnimation!,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DcRadius.md),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: _pulseAnimation!.value * 0.45),
                  blurRadius: 12,
                  spreadRadius: 1,
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
        borderRadius: BorderRadius.circular(DcRadius.md),
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
        builder: (context, setDialogState) {
          final dc = context.dc;
          final offsetTone = controllerTime.hasCriticalOffset
              ? dc.danger
              : controllerTime.hasSignificantOffset
                  ? dc.warning
                  : dc.success;
          return AlertDialog(
            icon: Icon(
              controllerTime.hasCriticalOffset
                  ? Icons.error_rounded
                  : controllerTime.hasSignificantOffset
                      ? Icons.warning_amber_rounded
                      : Icons.schedule_rounded,
              color: controllerTime.hasSignificantOffset ? offsetTone.fg : dc.accent,
            ),
            title: Text(l10n.homeControllerTimeTitle),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DcInfoRow(label: l10n.homeControllerDateTime, value: controllerTime.formattedDateTime, mono: true),
                  DcInfoRow(label: l10n.homeLocalTime, value: _formatLocalTime(), mono: true),
                  const Divider(height: 16),
                  DcInfoRow(
                    label: l10n.homeTimeOffset,
                    value: controllerTime.offsetDescription,
                    valueColor: offsetTone.fg,
                  ),
                  if (controllerTime.hasSignificantOffset) ...[
                    const SizedBox(height: 12),
                    DcBanner(
                      tone: offsetTone,
                      icon: Icons.info_outline_rounded,
                      message: l10n.homeTimeOffsetWarning,
                    ),
                  ],
                  // Message de résultat de synchronisation
                  if (syncResult != null) ...[
                    const SizedBox(height: 12),
                    DcBanner(
                      tone: syncSuccess ? dc.success : dc.danger,
                      icon: syncSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
                      message: syncResult!,
                    ),
                  ],
                  // Info si V2 (pas de sync disponible)
                  if (!widget.canSync && controllerTime.hasSignificantOffset) ...[
                    const SizedBox(height: 12),
                    DcBanner(
                      tone: dc.info,
                      icon: Icons.info_outline_rounded,
                      message: l10n.homeSyncV2Info,
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSyncing ? null : () => Navigator.pop(dialogContext),
                child: Text(l10n.close),
              ),
              // Bouton Synchroniser (uniquement si API V1 et décalage)
              if (widget.canSync && controllerTime.hasSignificantOffset)
                FilledButton.icon(
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
                              syncResult = success ? l10n.homeSyncSuccess : l10n.homeSyncFailed;
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
                      : const Icon(Icons.sync_rounded),
                  label: Text(isSyncing ? l10n.homeSyncing : l10n.homeSync),
                ),
            ],
          );
        },
      ),
    );
  }

  String _formatLocalTime() => DisplayPreferences.formatDateTime(DateTime.now(), withSeconds: true);
}
