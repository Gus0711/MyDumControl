import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../application/providers/alarms_provider.dart';
import '../../../application/providers/points_provider.dart';
import '../../../core/router/routes.dart';
import '../../../domain/models/bacnet_object.dart';
import '../../../domain/models/display_preferences.dart';
import '../../shared/utils/bacnet_type_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/gradient_app_bar.dart';

/// Écran de liste des alarmes actives
class AlarmsScreen extends ConsumerStatefulWidget {
  const AlarmsScreen({super.key});

  @override
  ConsumerState<AlarmsScreen> createState() => _AlarmsScreenState();
}

class _AlarmsScreenState extends ConsumerState<AlarmsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final alarmsState = ref.watch(alarmsStateProvider);
    final filteredAlarms = ref.watch(filteredAlarmsProvider);
    final totalAlarms = ref.watch(alarmsCountProvider);
    final pointsState = ref.watch(pointsProvider);

    return Scaffold(
      appBar: GradientAppBar(
        titleWidget: _showSearch ? _buildSearchField(l10n) : Text(l10n.alarms),
        actions: [
          // Bouton recherche
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                  ref.read(alarmsStateProvider.notifier).clearSearch();
                }
              });
            },
          ),
          // Menu tri
          PopupMenuButton<AlarmSortOption>(
            icon: const Icon(Icons.sort),
            tooltip: l10n.sort,
            onSelected: (option) {
              ref.read(alarmsStateProvider.notifier).setSortOption(option);
            },
            itemBuilder: (context) => AlarmSortOption.values.map((option) {
              final isSelected = alarmsState.sortOption == option;
              return PopupMenuItem(
                value: option,
                child: Row(
                  children: [
                    if (isSelected)
                      const Icon(Icons.check, size: 18)
                    else
                      const SizedBox(width: 18),
                    const SizedBox(width: 8),
                    Text(_sortOptionLabel(l10n, option)),
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
      ),
      body: Column(
        children: [
          // Indicateur de chargement
          if (pointsState.isLoading)
            const LinearProgressIndicator(),

          // Bannière avec le nombre total d'alarmes
          if (totalAlarms > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.red.shade50,
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    l10n.alarmsCount(totalAlarms),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ),

          // Liste des alarmes
          Expanded(
            child: _buildAlarmsList(l10n, filteredAlarms, pointsState, alarmsState),
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
        hintText: l10n.searchAlarm,
        border: InputBorder.none,
      ),
      onChanged: (value) {
        ref.read(alarmsStateProvider.notifier).setSearchQuery(value);
      },
    );
  }

  Widget _buildAlarmsList(
    AppLocalizations l10n,
    List<BacnetObject> alarms,
    PointsState pointsState,
    AlarmsState alarmsState,
  ) {
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

    if (alarms.isEmpty) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              alarmsState.searchQuery.isNotEmpty
                  ? Icons.search_off
                  : Icons.check_circle_outline,
              size: 64,
              color: alarmsState.searchQuery.isNotEmpty
                  ? (isDark ? Colors.grey.shade500 : Colors.grey.shade400)
                  : Colors.green.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              alarmsState.searchQuery.isNotEmpty
                  ? l10n.noResultsFor(alarmsState.searchQuery)
                  : l10n.noAlarms,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            if (alarmsState.searchQuery.isEmpty) ...[
              const SizedBox(height: 8),
              Text(
                l10n.allEquipmentNormal,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(pointsProvider.notifier).loadPoints(forceRefresh: true),
      child: ListView.builder(
        itemCount: alarms.length,
        itemBuilder: (context, index) {
          final alarm = alarms[index];
          return _AlarmTile(alarm: alarm);
        },
      ),
    );
  }
}

/// Tile pour afficher une alarme
String _sortOptionLabel(AppLocalizations l10n, AlarmSortOption option) {
  switch (option) {
    case AlarmSortOption.nameAsc:
      return l10n.sortNameAsc;
    case AlarmSortOption.nameDesc:
      return l10n.sortNameDesc;
    case AlarmSortOption.typeAsc:
      return l10n.sortType;
    case AlarmSortOption.timestampDesc:
      return l10n.alarmsSortNewest;
    case AlarmSortOption.timestampAsc:
      return l10n.alarmsSortOldest;
  }
}

class _AlarmTile extends StatelessWidget {
  final BacnetObject alarm;

  const _AlarmTile({required this.alarm});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final typeColor = BacnetTypeUtils.getTypeColor(alarm.type);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      child: InkWell(
        onTap: () {
          context.push(Routes.pointDetailPath('${alarm.type.name}:${alarm.instance}'));
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec icône et nom
              Row(
                children: [
                  // Icône d'alarme
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.warning_amber,
                      color: Colors.red.shade700,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Nom et type
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alarm.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: typeColor.withAlpha(30),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                alarm.type.shortName,
                                style: TextStyle(
                                  color: typeColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              alarm.objectId,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Valeur actuelle
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      alarm.activeText ?? BacnetTypeUtils.formatValue(alarm),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, color: isDark ? Colors.grey.shade500 : Colors.grey.shade400, size: 20),
                ],
              ),

              // Description si présente
              if (alarm.description != null && alarm.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  alarm.description!,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // Timestamp de l'alarme si disponible
              if (alarm.alarmTimestamp != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: isDark ? Colors.grey.shade400 : Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      _formatTimestamp(AppLocalizations.of(context)!, alarm.alarmTimestamp!),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(AppLocalizations l10n, DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    String dateStr = DisplayPreferences.formatDateTime(timestamp);

    // Ajouter une indication relative
    if (diff.inMinutes < 60) {
      dateStr += ' (${l10n.agoMinutes(diff.inMinutes)})';
    } else if (diff.inHours < 24) {
      dateStr += ' (${l10n.agoHours(diff.inHours)})';
    } else if (diff.inDays < 7) {
      dateStr += ' (${l10n.agoDays(diff.inDays)})';
    }

    return dateStr;
  }
}
