import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../application/providers/points_provider.dart';
import '../../../application/providers/trend_log_provider.dart';
import '../../../application/providers/favorites_provider.dart';
import '../../../application/providers/active_connection_provider.dart';
import '../../../core/router/routes.dart';
import '../../../domain/models/bacnet_object.dart';
import '../../shared/utils/bacnet_type_utils.dart';
import '../../widgets/favorite_button.dart';
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
        isActive ? Icons.sync : Icons.sync_disabled,
        color: isActive ? Colors.green : null,
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
        return PopupMenuItem(
          value: option.value,
          child: Row(
            children: [
              if (isSelected)
                const Icon(Icons.check, size: 18, color: Colors.green)
              else
                const SizedBox(width: 18),
              const SizedBox(width: 8),
              Text(getAutoRefreshLabel(option.value, l10n)),
              if (option.value > 0) ...[
                const Spacer(),
                Icon(
                  Icons.timer,
                  size: 14,
                  color: Colors.grey.shade500,
                ),
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

    // Écouter les changements de favoris pour mettre à jour le tri
    ref.listen(favoritesProvider, (_, _) => _updateFavoriteIds());

    return Scaffold(
      appBar: AppBar(
        title: _showSearch ? _buildSearchField(l10n) : Text(l10n.points),
        actions: [
          // Bouton recherche
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
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
            icon: const Icon(Icons.sort),
            tooltip: l10n.sort,
            onSelected: (option) {
              ref.read(pointsProvider.notifier).setSortOption(option);
            },
            itemBuilder: (context) => PointSortOption.values.map((option) {
              final isSelected = pointsState.sortOption == option;
              return PopupMenuItem(
                value: option,
                child: Row(
                  children: [
                    if (isSelected)
                      const Icon(Icons.check, size: 18)
                    else
                      const SizedBox(width: 18),
                    const SizedBox(width: 8),
                    Text(getSortOptionDisplayName(option, l10n)),
                  ],
                ),
              );
            }).toList(),
          ),
          // Auto-refresh (seulement pour BACnet)
          if (ref.watch(activeConnectionProvider).isBacnetConnection)
            _buildAutoRefreshButton(l10n),
          // Rafraîchir (optimisé pour BACnet)
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: pointsState.isLoading
                ? null
                : () => ref.read(pointsProvider.notifier).refresh(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: _categories.map((cat) {
            final count = counts[cat] ?? 0;
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (cat == PointCategory.all)
                    const Icon(Icons.search, size: 16)
                  else
                    Text(getCategoryDisplayName(cat, l10n)),
                  if (cat == PointCategory.all)
                    const SizedBox(width: 4),
                  if (cat == PointCategory.all)
                    Text(l10n.allPoints),
                  if (count > 0 && cat != PointCategory.all) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        count.toString(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                  if (cat == PointCategory.all && count > 0) ...[
                    const SizedBox(width: 6),
                    Text(
                      '($count)',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
      ),
      body: Column(
        children: [
          // Indicateur de cache
          if (pointsState.fromCache && pointsState.isLoading)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.blue.shade50,
              child: Row(
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.loadingValuesProgress,
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                  ),
                ],
              ),
            ),

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
      decoration: InputDecoration(
        hintText: l10n.searchPoint,
        border: InputBorder.none,
      ),
      onChanged: (value) {
        ref.read(pointsProvider.notifier).setSearchQuery(value);
      },
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

    if (pointsState.isLoading && pointsState.points.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(l10n.loadingPoints),
          ],
        ),
      );
    }

    if (pointsState.error != null && pointsState.points.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                pointsState.error!,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => ref.read(pointsProvider.notifier).loadPoints(),
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
            ),
          ],
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(100),
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor.withAlpha(50),
              ),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: availableFilters.map((filter) {
                final isSelected = pointsState.subTypeFilter == filter;
                final count = counts[filter] ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      filter == SubTypeFilter.all
                          ? '${l10n.allPoints} ($count)'
                          : '${getSubTypeFilterLabel(filter, l10n)} ($count)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
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
        );
      }
    }

    if (filteredPoints.isEmpty) {
      return Column(
        children: [
          if (filterBar != null) filterBar,
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    pointsState.searchQuery.isNotEmpty
                        ? l10n.noResultsFor(pointsState.searchQuery)
                        : pointsState.subTypeFilter != SubTypeFilter.all
                            ? l10n.noPointSubType(getSubTypeFilterLabel(pointsState.subTypeFilter, l10n))
                            : l10n.noPointInCategory,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        if (filterBar != null) filterBar,
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.read(pointsProvider.notifier).refresh(),
            child: ListView.builder(
              itemCount: filteredPoints.length,
              itemBuilder: (context, index) {
                final point = filteredPoints[index];
                return _PointTile(point: point);
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Tile pour afficher un point
class _PointTile extends ConsumerWidget {
  final BacnetObject point;

  const _PointTile({required this.point});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typeColor = BacnetTypeUtils.getTypeColor(point.type);
    final valueColor = BacnetTypeUtils.getValueColor(point);

    return ListTile(
      onTap: () {
        context.push(Routes.pointDetailPath('${point.type.name}:${point.instance}'));
      },
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: typeColor.withAlpha(30),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            point.type.shortName,
            style: TextStyle(
              color: typeColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
      title: Text(
        point.objectName,
        style: const TextStyle(fontWeight: FontWeight.w500),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          Text(
            point.objectId,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontFamily: 'monospace',
            ),
          ),
          if (point.description != null && point.description!.isNotEmpty) ...[
            Text(' - ', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
            Expanded(
              child: Text(
                point.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
          ],
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bouton favori
          FavoriteButton(point: point),
          const SizedBox(width: 4),
          // Indicateur de trend log
          _TrendLogIndicator(
            pointKey: '${point.type.apiName}:${point.instance}',
          ),
          // Indicateur d'alarme
          if (point.inAlarm)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              margin: const EdgeInsets.only(left: 4),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber, size: 12, color: Colors.red.shade700),
                  const SizedBox(width: 2),
                  Text(
                    AppLocalizations.of(context)!.alarm,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ),
          // Indicateur de forçage (priority-array)
          if (point.isOverridden)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              margin: const EdgeInsets.only(left: 4),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock, size: 10, color: Colors.red.shade700),
                  if (point.overridePriority != null) ...[
                    const SizedBox(width: 2),
                    Text(
                      'P${point.overridePriority}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          // Indicateur d'entrée forcée (out-of-service)
          if (point.type.isInput && point.outOfService == true && !point.isOverridden)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              margin: const EdgeInsets.only(left: 4),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.power_settings_new, size: 10, color: Colors.orange.shade700),
                  const SizedBox(width: 2),
                  Text(
                    'OOS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(width: 8),
          // Valeur
          Container(
            constraints: const BoxConstraints(minWidth: 60),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: valueColor.withAlpha(30),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              point.presentValue != null
                  ? BacnetTypeUtils.formatValue(point)
                  : '-',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
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

    return Tooltip(
      message: l10n.trendLogAvailable,
      child: Container(
        padding: const EdgeInsets.all(4),
        child: Icon(
          Icons.show_chart,
          size: 16,
          color: Colors.blue.shade600,
        ),
      ),
    );
  }
}
