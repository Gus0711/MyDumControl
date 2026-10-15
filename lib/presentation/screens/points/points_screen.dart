import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../application/providers/points_provider.dart';
import '../../../application/providers/trend_log_provider.dart';
import '../../../application/providers/favorites_provider.dart';
import '../../../application/providers/active_connection_provider.dart';
import '../../../application/providers/bacnet_provider.dart';
import '../../../application/providers/settings_provider.dart';
import '../../../core/router/routes.dart';
import '../../../domain/models/bacnet_object.dart';
import '../../widgets/favorite_button.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../widgets/point_widgets.dart';
import '../../widgets/ui/ui.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';

/// Helper pour obtenir le nom localisé d'une catégorie
String getCategoryDisplayName(PointCategory category, AppLocalizations l10n) {
  switch (category) {
    case PointCategory.inputs:
      return l10n.categoryInputs;
    case PointCategory.outputs:
      return l10n.categoryOutputs;
    case PointCategory.variables:
      return l10n.categoryVariables;
    case PointCategory.others:
      return l10n.categoryOthers;
    case PointCategory.all:
      return l10n.categoryAll;
  }
}

/// Helper pour obtenir le nom localisé d'une option de tri
String getSortOptionDisplayName(PointSortOption option, AppLocalizations l10n) {
  switch (option) {
    case PointSortOption.nameAsc:
      return l10n.sortNameAsc;
    case PointSortOption.nameDesc:
      return l10n.sortNameDesc;
    case PointSortOption.typeAsc:
      return l10n.sortType;
    case PointSortOption.valueAsc:
      return l10n.sortValueAsc;
    case PointSortOption.valueDesc:
      return l10n.sortValueDesc;
    case PointSortOption.favoritesFirst:
      return l10n.sortFavoritesFirst;
  }
}

/// Helper pour obtenir le nom localisé d'un filtre de sous-type
String getSubTypeFilterLabel(SubTypeFilter filter, AppLocalizations l10n) {
  switch (filter) {
    case SubTypeFilter.all:
      return l10n.subTypeAll;
    case SubTypeFilter.analog:
      return l10n.subTypeAnalog;
    case SubTypeFilter.binary:
      return l10n.subTypeBinary;
    case SubTypeFilter.multiState:
      return l10n.subTypeMulti;
  }
}

/// Helper pour obtenir le label localisé de l'auto-refresh
String getAutoRefreshLabel(int value, AppLocalizations l10n) {
  if (value == 0) return l10n.autoRefreshOff;
  if (value == 60) return l10n.autoRefreshMinute;
  return l10n.autoRefreshSeconds(value);
}

/// Écran de liste des points BACnet avec navigation par catégories (TabBar)
class PointsScreen extends ConsumerStatefulWidget {
  const PointsScreen({super.key});

  @override
  ConsumerState<PointsScreen> createState() => _PointsScreenState();
}

class _PointsScreenState extends ConsumerState<PointsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;
  Timer? _autoRefreshTimer;

  /// Manual refresh in progress (API refreshes do not set isLoading)
  bool _isRefreshing = false;

  Future<void> _manualRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      await ref.read(pointsProvider.notifier).refresh();
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  /// Les catégories dans l'ordre des onglets
  static const _categories = [
    PointCategory.inputs,
    PointCategory.outputs,
    PointCategory.variables,
    PointCategory.others,
    PointCategory.all,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabController.addListener(_onTabChanged);

    // Charger les points au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pointsState = ref.read(pointsProvider);
      if (pointsState.points.isEmpty && !pointsState.isLoading) {
        ref.read(pointsProvider.notifier).loadPoints();
      }
      // Mettre à jour les favoris pour le tri
      _updateFavoriteIds();
      // Intervalle initial = réglage persistant, si l'utilisateur n'en a pas choisi un
      final configured = ref.read(settingsProvider).refreshIntervalSeconds;
      if (ref.read(autoRefreshIntervalProvider) == 0 && configured > 0) {
        ref.read(autoRefreshIntervalProvider.notifier).state = configured;
      }
      // Démarrer l'auto-refresh si configuré
      _setupAutoRefresh();
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _setupAutoRefresh() {
    final interval = ref.read(autoRefreshIntervalProvider);
    _autoRefreshTimer?.cancel();

    if (interval > 0) {
      _autoRefreshTimer = Timer.periodic(
        Duration(seconds: interval),
        (_) => _doAutoRefresh(),
      );
    }
  }

  void _doAutoRefresh() {
    if (!mounted) return;
    // Connexion fermée : plus rien à rafraîchir
    if (!ref.read(activeConnectionProvider).isConnected) return;
    // Écran recouvert (détail/édition d'un point) : on ne rafraîchit pas
    if (ModalRoute.of(context)?.isCurrent == false) return;
    final pointsState = ref.read(pointsProvider);
    if (!pointsState.isLoading) {
      ref.read(pointsProvider.notifier).refresh();
    }
  }

  Widget _buildAutoRefreshButton(AppLocalizations l10n) {
    final currentInterval = ref.watch(autoRefreshIntervalProvider);
    final isActive = currentInterval > 0;

    return PopupMenuButton<int>(
      icon: Icon(
        isActive ? Icons.sync_rounded : Icons.sync_disabled_rounded,
        color: isActive ? AppColors.success : null,
      ),
      tooltip: isActive
          ? l10n.autoRefreshLabel(getAutoRefreshLabel(currentInterval, l10n))
          : l10n.autoRefreshDisabled,
      onSelected: (interval) {
        ref.read(autoRefreshIntervalProvider.notifier).state = interval;
        _setupAutoRefresh();
      },
      itemBuilder: (context) => autoRefreshOptions.map((option) {
        final isSelected = currentInterval == option.value;
        final dc = context.dc;
        return PopupMenuItem(
          value: option.value,
          height: 42,
          child: Row(
            children: [
              if (isSelected)
                Icon(Icons.check_rounded, size: 18, color: dc.accent)
              else
                const SizedBox(width: 18),
              const SizedBox(width: 10),
              Text(
                getAutoRefreshLabel(option.value, l10n),
                style: TextStyle(fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400),
              ),
              if (option.value > 0) ...[
                const Spacer(),
                Icon(Icons.timer_outlined, size: 14, color: dc.textMuted),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      final category = _categories[_tabController.index];
      ref.read(pointsProvider.notifier).setCategory(category);
    }
  }

  void _updateFavoriteIds() {
    final favoritesAsync = ref.read(favoritesProvider);
    favoritesAsync.whenData((favorites) {
      final ids = favorites.map((f) => f.pointRef).toSet();
      ref.read(pointsProvider.notifier).updateFavoriteIds(ids);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pointsState = ref.watch(pointsProvider);
    final counts = pointsState.pointCountByCategory;
    final isBacnet = ref.watch(activeConnectionProvider.select((s) => s.isBacnetConnection));

    // Écouter les changements de favoris pour mettre à jour le tri
    ref.listen(favoritesProvider, (_, _) => _updateFavoriteIds());
    // Rebuild the values when the display settings change
    ref.watch(settingsProvider.select((s) => (s.decimalPlaces, s.temperatureUnit)));

    // Le réglage d'intervalle change : l'appliquer au timer
    ref.listen(settingsProvider.select((s) => s.refreshIntervalSeconds), (_, next) {
      ref.read(autoRefreshIntervalProvider.notifier).state = next;
      _setupAutoRefresh();
    });

    final total = pointsState.points.length;

    return Scaffold(
      appBar: GradientAppBar(
        title: _showSearch ? null : l10n.points,
        subtitle: _showSearch || total == 0 ? null : '$total ${l10n.points.toLowerCase()}',
        titleWidget: _showSearch ? _buildSearchField(l10n) : null,
        actions: [
          // Bouton recherche
          IconButton(
            icon: Icon(_showSearch ? Icons.close_rounded : Icons.search_rounded),
            tooltip: _showSearch ? l10n.close : l10n.search,
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                  ref.read(pointsProvider.notifier).setSearchQuery('');
                }
              });
            },
          ),
          // Menu tri
          PopupMenuButton<PointSortOption>(
            icon: const Icon(Icons.sort_rounded),
            tooltip: l10n.sort,
            onSelected: (option) {
              ref.read(pointsProvider.notifier).setSortOption(option);
            },
            itemBuilder: (context) => PointSortOption.values.map((option) {
              final isSelected = pointsState.sortOption == option;
              return PopupMenuItem(
                value: option,
                height: 42,
                child: Row(
                  children: [
                    if (isSelected)
                      Icon(Icons.check_rounded, size: 18, color: context.dc.accent)
                    else
                      const SizedBox(width: 18),
                    const SizedBox(width: 10),
                    Text(
                      getSortOptionDisplayName(option, l10n),
                      style: TextStyle(fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          // Auto-refresh (seulement pour BACnet)
          if (isBacnet) _buildAutoRefreshButton(l10n),
          // Rafraîchir (optimisé pour BACnet)
          IconButton(
            tooltip: l10n.refresh,
            icon: _isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.refresh_rounded),
            onPressed: pointsState.isLoading || _isRefreshing ? null : _manualRefresh,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorWeight: 2.5,
          tabs: _categories.map((cat) {
            final count = counts[cat] ?? 0;
            return Tab(
              height: 44,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (cat == PointCategory.all) ...[
                    const Icon(Icons.search_rounded, size: 16),
                    const SizedBox(width: 6),
                    Text(l10n.allPoints),
                  ] else
                    Text(getCategoryDisplayName(cat, l10n)),
                  if (count > 0) ...[
                    const SizedBox(width: 8),
                    _TabCount(count: count),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
      ),
      body: Column(
        children: [
          // Warning port BACnet non standard
          if (isBacnet) _BacnetPortWarningBanner(),

          // Indicateur de cache
          if (pointsState.fromCache && pointsState.isLoading) _CacheLoadingStrip(label: l10n.loadingValuesProgress),

          // Contenu par onglet
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _categories.map((category) {
                return _PointsCategoryTab(category: category);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(AppLocalizations l10n) {
    return TextField(
      controller: _searchController,
      autofocus: true,
      cursorColor: AppColors.brandSky,
      style: context.text.bodyLarge?.copyWith(color: Colors.white),
      decoration: InputDecoration(
        hintText: l10n.searchPoint,
        hintStyle: context.text.bodyLarge?.copyWith(color: const Color(0xFF8DA2BF)),
        filled: false,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        isDense: true,
      ),
      onChanged: (value) {
        ref.read(pointsProvider.notifier).setSearchQuery(value);
      },
    );
  }
}

/// Compteur d'un onglet (sur la barre bleu nuit).
class _TabCount extends StatelessWidget {
  final int count;

  const _TabCount({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(DcRadius.sm),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text(
        '$count',
        style: AppTextStyles.monospacedValue.copyWith(fontSize: 11, color: const Color(0xFFD5E2F3)),
      ),
    );
  }
}

/// Bandeau fin « chargement des valeurs » (données affichées depuis le cache).
class _CacheLoadingStrip extends StatelessWidget {
  final String label;

  const _CacheLoadingStrip({required this.label});

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: dc.accentTone.bg,
        border: Border(bottom: BorderSide(color: dc.accentTone.border)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            child: Row(
              children: [
                Icon(Icons.history_rounded, size: 15, color: dc.accentTone.fg),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(label, style: context.text.bodySmall?.copyWith(color: dc.accentTone.fg)),
                ),
              ],
            ),
          ),
          LinearProgressIndicator(minHeight: 2, backgroundColor: dc.accentTone.bg),
        ],
      ),
    );
  }
}

/// Tab pour afficher les points d'une catégorie
class _PointsCategoryTab extends ConsumerWidget {
  final PointCategory category;

  const _PointsCategoryTab({required this.category});

  /// Vérifie si cette catégorie supporte les filtres de sous-type
  bool get _supportsSubTypeFilter =>
      category == PointCategory.inputs ||
      category == PointCategory.outputs ||
      category == PointCategory.variables;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final pointsState = ref.watch(pointsProvider);
    final dc = context.dc;

    if (pointsState.isLoading && pointsState.points.isEmpty) {
      return DcLoading(message: l10n.loadingPoints);
    }

    if (pointsState.error != null && pointsState.points.isEmpty) {
      return DcEmptyState.error(
        context,
        title: l10n.error,
        message: pointsState.error!,
        action: FilledButton.icon(
          onPressed: () => ref.read(pointsProvider.notifier).loadPoints(),
          icon: const Icon(Icons.refresh_rounded),
          label: Text(l10n.retry),
        ),
      );
    }

    final filteredPoints = pointsState.getFilteredAndSortedPoints(category: category);

    // Construire la barre de filtres si applicable
    Widget? filterBar;
    if (_supportsSubTypeFilter && pointsState.points.isNotEmpty) {
      final availableFilters = pointsState.getAvailableSubTypes(category);
      // N'afficher les filtres que s'il y a plus d'un type disponible
      if (availableFilters.length > 2) {
        final counts = pointsState.getSubTypeCountsForCategory(category);
        filterBar = Container(
          decoration: BoxDecoration(
            color: dc.surface,
            border: Border(bottom: BorderSide(color: dc.border)),
          ),
          child: DcContent(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: availableFilters.map((filter) {
                  final isSelected = pointsState.subTypeFilter == filter;
                  final count = counts[filter] ?? 0;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            filter == SubTypeFilter.all ? l10n.allPoints : getSubTypeFilterLabel(filter, l10n),
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected ? dc.accentTone.fg : dc.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$count',
                            style: AppTextStyles.monospacedValue.copyWith(
                              fontSize: 11,
                              color: isSelected ? dc.accentTone.fg : dc.textMuted,
                            ),
                          ),
                        ],
                      ),
                      selected: isSelected,
                      side: BorderSide(color: isSelected ? dc.accentTone.border : dc.border),
                      onSelected: (_) {
                        ref.read(pointsProvider.notifier).setSubTypeFilter(filter);
                      },
                      showCheckmark: false,
                      visualDensity: VisualDensity.compact,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      }
    }

    if (filteredPoints.isEmpty) {
      return Column(
        children: [
          ?filterBar,
          Expanded(
            child: DcEmptyState(
              icon: pointsState.searchQuery.isNotEmpty ? Icons.search_off_rounded : Icons.inbox_outlined,
              title: pointsState.searchQuery.isNotEmpty
                  ? l10n.noResultsFor(pointsState.searchQuery)
                  : pointsState.subTypeFilter != SubTypeFilter.all
                      ? l10n.noPointSubType(getSubTypeFilterLabel(pointsState.subTypeFilter, l10n))
                      : l10n.noPointInCategory,
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        ?filterBar,
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.read(pointsProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(0, 12, 0, 24),
              itemCount: filteredPoints.length,
              itemBuilder: (context, index) {
                final point = filteredPoints[index];
                return DcContent(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                  child: _PointTile(key: ValueKey(point.objectId), point: point),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Ligne d'un point : type, nom, identifiant, états, favori, valeur.
class _PointTile extends ConsumerWidget {
  final BacnetObject point;

  const _PointTile({super.key, required this.point});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dc = context.dc;
    final hasDescription = point.description != null && point.description!.isNotEmpty;
    final flagged = point.inAlarm
        ? dc.danger.fg
        : (point.isOverridden || (point.type.isInput && point.outOfService == true))
            ? dc.overrideTone.fg
            : null;

    return DcCard(
      onTap: () {
        context.push(Routes.pointDetailPath('${point.type.name}:${point.instance}'));
      },
      radius: DcRadius.md,
      accentColor: flagged,
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      child: Row(
        children: [
          PointTypeBadge(type: point.type, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Tooltip(
                  message: point.displayName,
                  waitDuration: const Duration(milliseconds: 500),
                  child: Text(
                    point.displayName,
                    style: context.text.bodyLarge?.copyWith(fontWeight: FontWeight.w500, height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 3),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      point.objectId,
                      style: AppTextStyles.monospacedValue.copyWith(fontSize: 11.5, color: dc.textMuted),
                    ),
                    // Si description existe, afficher le nom technique pour référence
                    if (hasDescription)
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 260),
                        child: Text(
                          point.objectName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.bodySmall?.copyWith(color: dc.textMuted),
                        ),
                      ),
                    if (PointStatusTags.hasAny(point)) PointStatusTags(point: point),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Indicateur de trend log
          _TrendLogIndicator(pointKey: '${point.type.apiName}:${point.instance}'),
          // Bouton favori
          FavoriteButton(point: point),
          const SizedBox(width: 8),
          // Valeur
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: PointValueChip(point: point, minWidth: 72),
          ),
          const SizedBox(width: 2),
          Icon(Icons.chevron_right_rounded, color: dc.textMuted, size: 20),
        ],
      ),
    );
  }
}

/// Indicateur de trend log
class _TrendLogIndicator extends ConsumerWidget {
  final String pointKey;

  const _TrendLogIndicator({required this.pointKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final hasTrendLog = ref.watch(hasTrendLogProvider(pointKey));

    if (!hasTrendLog) return const SizedBox.shrink();

    final tone = context.dc.violet;

    return Tooltip(
      message: l10n.trendLogAvailable,
      child: Container(
        padding: const EdgeInsets.all(4),
        margin: const EdgeInsets.only(right: 2),
        decoration: BoxDecoration(
          color: tone.bg,
          borderRadius: BorderRadius.circular(DcRadius.sm),
          border: Border.all(color: tone.border),
        ),
        child: Icon(Icons.show_chart_rounded, size: 16, color: tone.fg),
      ),
    );
  }
}

/// Banner d'avertissement pour le port BACnet non standard
class _BacnetPortWarningBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final portInfo = ref.watch(bacnetPortInfoProvider);

    // Ne rien afficher si le port standard est utilisé
    if (portInfo.isUsingStandardPort || portInfo.actualPort == null) {
      return const SizedBox.shrink();
    }

    final dc = context.dc;
    return DcContent(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: DcBanner(
        tone: dc.warning,
        icon: Icons.warning_amber_rounded,
        message: l10n.bacnetPortWarning(portInfo.actualPort!, portInfo.standardPort),
        dense: true,
        action: IconButton(
          icon: Icon(Icons.info_outline_rounded, size: 18, color: dc.warning.fg),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          onPressed: () => _showPortInfoDialog(context, l10n, portInfo),
        ),
      ),
    );
  }

  void _showPortInfoDialog(BuildContext context, AppLocalizations l10n, BacnetPortInfo portInfo) {
    showDialog(
      context: context,
      builder: (context) {
        final dc = context.dc;
        return AlertDialog(
          icon: Icon(Icons.warning_amber_rounded, color: dc.warning.fg),
          title: Text(l10n.bacnetPortConflict),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.bacnetPortConflictDetail(portInfo.standardPort, portInfo.actualPort!)),
                const SizedBox(height: 16),
                Text(
                  l10n.bacnetPortConflictSolution,
                  style: context.text.titleSmall?.copyWith(color: dc.textPrimary),
                ),
                const SizedBox(height: 8),
                Text('•  ${l10n.bacnetPortSolution1}'),
                const SizedBox(height: 4),
                Text('•  ${l10n.bacnetPortSolution2}'),
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.understood),
            ),
          ],
        );
      },
    );
  }
}
