import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../application/providers/points_provider.dart';
import '../../../application/providers/trend_log_provider.dart';
import '../../../application/providers/favorites_provider.dart';
import '../../../core/router/routes.dart';
import '../../../domain/models/bacnet_object.dart';
import '../../shared/utils/bacnet_type_utils.dart';
import '../../widgets/favorite_button.dart';

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
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
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
    final pointsState = ref.watch(pointsProvider);
    final counts = pointsState.pointCountByCategory;

    // Écouter les changements de favoris pour mettre à jour le tri
    ref.listen(favoritesProvider, (_, _) => _updateFavoriteIds());

    return Scaffold(
      appBar: AppBar(
        title: _showSearch ? _buildSearchField() : const Text('Points'),
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
            tooltip: 'Trier',
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
                    Text(option.displayName),
                  ],
                ),
              );
            }).toList(),
          ),
          // Rafraîchir
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: pointsState.isLoading
                ? null
                : () => ref.read(pointsProvider.notifier).loadPoints(forceRefresh: true),
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
                    Text(cat.displayName),
                  if (cat == PointCategory.all)
                    const SizedBox(width: 4),
                  if (cat == PointCategory.all)
                    const Text('Tous'),
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
                    'Chargement des valeurs en cours...',
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

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      decoration: const InputDecoration(
        hintText: 'Rechercher un point...',
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pointsState = ref.watch(pointsProvider);

    if (pointsState.isLoading && pointsState.points.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement des points...'),
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
              label: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    final filteredPoints = pointsState.getFilteredAndSortedPoints(category: category);

    if (filteredPoints.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              pointsState.searchQuery.isNotEmpty
                  ? 'Aucun résultat pour "${pointsState.searchQuery}"'
                  : 'Aucun point dans cette catégorie',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(pointsProvider.notifier).loadPoints(),
      child: ListView.builder(
        itemCount: filteredPoints.length,
        itemBuilder: (context, index) {
          final point = filteredPoints[index];
          return _PointTile(point: point);
        },
      ),
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
    final hasTrendLog = ref.watch(hasTrendLogProvider(pointKey));

    if (!hasTrendLog) return const SizedBox.shrink();

    return Tooltip(
      message: 'Trend log disponible',
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
