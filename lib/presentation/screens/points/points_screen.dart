import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../application/providers/points_provider.dart';
import '../../../core/router/routes.dart';
import '../../../domain/models/bacnet_object.dart';

/// Écran de liste des points BACnet
class PointsScreen extends ConsumerStatefulWidget {
  const PointsScreen({super.key});

  @override
  ConsumerState<PointsScreen> createState() => _PointsScreenState();
}

class _PointsScreenState extends ConsumerState<PointsScreen> {
  final _searchController = TextEditingController();
  bool _isSearchVisible = false;

  @override
  void initState() {
    super.initState();
    // Charger les points au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pointsProvider.notifier).loadPoints();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pointsProvider);

    return Scaffold(
      appBar: AppBar(
        title: _isSearchVisible
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Rechercher un point...',
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  ref.read(pointsProvider.notifier).setSearchQuery(value);
                },
              )
            : const Text('Points'),
        actions: [
          IconButton(
            icon: Icon(_isSearchVisible ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearchVisible = !_isSearchVisible;
                if (!_isSearchVisible) {
                  _searchController.clear();
                  ref.read(pointsProvider.notifier).setSearchQuery('');
                }
              });
            },
          ),
          PopupMenuButton<BacnetObjectType?>(
            icon: Badge(
              isLabelVisible: state.filterType != null,
              child: const Icon(Icons.filter_list),
            ),
            onSelected: (type) {
              ref.read(pointsProvider.notifier).setFilterType(type);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('Tous les types'),
              ),
              const PopupMenuDivider(),
              ...BacnetObjectType.values.where((t) => _isPointType(t)).map(
                    (type) => PopupMenuItem(
                      value: type,
                      child: Row(
                        children: [
                          Icon(
                            _getTypeIcon(type),
                            size: 20,
                            color: _getTypeColor(type),
                          ),
                          const SizedBox(width: 8),
                          Text(type.displayName),
                          if (state.filterType == type) ...[
                            const Spacer(),
                            const Icon(Icons.check, size: 18),
                          ],
                        ],
                      ),
                    ),
                  ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: state.isLoading
                ? null
                : () => ref.read(pointsProvider.notifier).refresh(),
          ),
        ],
      ),
      body: _buildBody(context, state),
    );
  }

  Widget _buildBody(BuildContext context, PointsState state) {
    if (state.isLoading && state.points.isEmpty) {
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

    if (state.error != null && state.points.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(state.error!),
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

    final filteredPoints = state.filteredPoints;

    if (filteredPoints.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              state.searchQuery.isNotEmpty || state.filterType != null
                  ? 'Aucun point trouvé'
                  : 'Aucun point disponible',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    // Grouper par type
    final pointsByType = state.pointsByType;

    return RefreshIndicator(
      onRefresh: () => ref.read(pointsProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: pointsByType.length,
        itemBuilder: (context, index) {
          final type = pointsByType.keys.elementAt(index);
          final points = pointsByType[type]!;

          return _buildTypeSection(context, type, points, state.isLoading);
        },
      ),
    );
  }

  Widget _buildTypeSection(
    BuildContext context,
    BacnetObjectType type,
    List<BacnetObject> points,
    bool isLoading,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête du type
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              Icon(_getTypeIcon(type), color: _getTypeColor(type), size: 20),
              const SizedBox(width: 8),
              Text(
                type.displayName,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getTypeColor(type).withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${points.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _getTypeColor(type),
                  ),
                ),
              ),
              if (isLoading) ...[
                const SizedBox(width: 8),
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
        ),
        // Liste des points
        ...points.map((point) => _buildPointTile(context, point)),
      ],
    );
  }

  Widget _buildPointTile(BuildContext context, BacnetObject point) {
    final valueColor = _getValueColor(point);

    return ListTile(
      onTap: () => context.push(Routes.pointDetailPath('${point.type.name}:${point.instance}')),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _getTypeColor(point.type).withAlpha(30),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          _getTypeIcon(point.type),
          color: _getTypeColor(point.type),
          size: 20,
        ),
      ),
      title: Text(
        point.objectName,
        style: const TextStyle(fontWeight: FontWeight.w500),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: point.description != null
          ? Text(
              point.description!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Indicateur de forçage (override via priority-array)
          if (point.isOverridden)
            Tooltip(
              message: 'Forcé à priorité ${point.overridePriority}',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red.shade300, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock, size: 10, color: Colors.red.shade700),
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
                ),
              ),
            ),
          // Indicateur d'entrée forcée (out-of-service pour les inputs)
          if (point.type.isInput && point.outOfService == true)
            Tooltip(
              message: 'Entrée forcée (out-of-service)',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.orange.shade300, width: 1),
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
            )
          // Indicateur out of service pour les non-entrées
          else if (point.outOfService == true)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'OOS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade800,
                ),
              ),
            ),
          // Valeur
          Container(
            constraints: const BoxConstraints(minWidth: 60),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: valueColor.withAlpha(30),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _formatValue(point),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, color: Colors.grey.shade400),
        ],
      ),
    );
  }

  String _formatValue(BacnetObject point) {
    final value = point.presentValue;
    if (value == null) return '---';

    if (point.type.isBinary) {
      // Utiliser activeText/inactiveText si disponibles
      final isActive = _isBinaryActive(value);
      if (isActive) {
        return point.activeText ?? 'ON';
      } else {
        return point.inactiveText ?? 'OFF';
      }
    }

    if (value is num) {
      final formatted = value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1);
      if (point.units != null && point.units!.isNotEmpty) {
        return '$formatted ${point.units}';
      }
      return formatted;
    }

    return value.toString();
  }

  bool _isBinaryActive(dynamic value) {
    if (value == null) return false;
    if (value == true) return true;
    if (value == 1) return true;
    if (value is String) {
      final lower = value.toLowerCase();
      return lower == 'active' || lower == 'true' || lower == '1' || lower == 'on';
    }
    return false;
  }

  Color _getValueColor(BacnetObject point) {
    if (point.outOfService == true) return Colors.orange;

    final value = point.presentValue;
    if (value == null) return Colors.grey;

    if (point.type.isBinary) {
      return _isBinaryActive(value) ? Colors.green : Colors.grey;
    }

    return Colors.blue;
  }

  bool _isPointType(BacnetObjectType type) {
    return [
      BacnetObjectType.analogInput,
      BacnetObjectType.analogOutput,
      BacnetObjectType.analogValue,
      BacnetObjectType.binaryInput,
      BacnetObjectType.binaryOutput,
      BacnetObjectType.binaryValue,
      BacnetObjectType.multiStateInput,
      BacnetObjectType.multiStateOutput,
      BacnetObjectType.multiStateValue,
    ].contains(type);
  }

  IconData _getTypeIcon(BacnetObjectType type) {
    switch (type) {
      case BacnetObjectType.analogInput:
        return Icons.input;
      case BacnetObjectType.analogOutput:
        return Icons.output;
      case BacnetObjectType.analogValue:
        return Icons.speed;
      case BacnetObjectType.binaryInput:
        return Icons.toggle_off;
      case BacnetObjectType.binaryOutput:
        return Icons.toggle_on;
      case BacnetObjectType.binaryValue:
        return Icons.radio_button_checked;
      case BacnetObjectType.multiStateInput:
        return Icons.list;
      case BacnetObjectType.multiStateOutput:
        return Icons.list_alt;
      case BacnetObjectType.multiStateValue:
        return Icons.format_list_numbered;
      default:
        return Icons.device_unknown;
    }
  }

  Color _getTypeColor(BacnetObjectType type) {
    switch (type) {
      case BacnetObjectType.analogInput:
      case BacnetObjectType.binaryInput:
      case BacnetObjectType.multiStateInput:
        return Colors.blue;
      case BacnetObjectType.analogOutput:
      case BacnetObjectType.binaryOutput:
      case BacnetObjectType.multiStateOutput:
        return Colors.orange;
      case BacnetObjectType.analogValue:
      case BacnetObjectType.binaryValue:
      case BacnetObjectType.multiStateValue:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
