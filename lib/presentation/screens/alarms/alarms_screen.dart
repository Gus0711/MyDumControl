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
import '../../widgets/point_widgets.dart';
import '../../widgets/ui/ui.dart';

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
        titleWidget: _showSearch ? _buildSearchField(l10n) : null,
        title: _showSearch ? null : l10n.alarms,
        subtitle: _showSearch || pointsState.points.isEmpty ? null : l10n.alarmsCount(totalAlarms),
        actions: [
          // Bouton recherche
          IconButton(
            icon: Icon(_showSearch ? Icons.close_rounded : Icons.search_rounded),
            tooltip: l10n.search,
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
            icon: const Icon(Icons.sort_rounded),
            tooltip: l10n.sort,
            onSelected: (option) {
              ref.read(alarmsStateProvider.notifier).setSortOption(option);
            },
            itemBuilder: (context) => AlarmSortOption.values.map((option) {
              final isSelected = alarmsState.sortOption == option;
              return dcMenuItem(
                context,
                option,
                isSelected ? Icons.check_rounded : Icons.sort_rounded,
                _sortOptionLabel(l10n, option),
              );
            }).toList(),
          ),
          // Rafraîchir
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: l10n.refresh,
            onPressed: pointsState.isLoading
                ? null
                : () => ref.read(pointsProvider.notifier).loadPoints(forceRefresh: true),
          ),
        ],
      ),
      body: Column(
        children: [
          // Indicateur de chargement
          if (pointsState.isLoading) const LinearProgressIndicator(),

          // Liste des alarmes
          Expanded(
            child: _buildAlarmsList(l10n, filteredAlarms, pointsState, alarmsState, totalAlarms),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(AppLocalizations l10n) {
    return TextField(
      controller: _searchController,
      autofocus: true,
      style: const TextStyle(color: Colors.white),
      cursorColor: Colors.white,
      decoration: InputDecoration(
        hintText: l10n.searchAlarm,
        hintStyle: const TextStyle(color: Color(0xFF9FB2CC)),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        filled: false,
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
    int totalAlarms,
  ) {
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

    if (alarms.isEmpty) {
      if (alarmsState.searchQuery.isNotEmpty) {
        return DcEmptyState(
          icon: Icons.search_off_rounded,
          title: l10n.noResultsFor(alarmsState.searchQuery),
        );
      }
      return DcEmptyState(
        icon: Icons.verified_rounded,
        tone: dc.success,
        title: l10n.noAlarms,
        message: l10n.allEquipmentNormal,
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(pointsProvider.notifier).loadPoints(forceRefresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: alarms.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            // Bandeau récapitulatif
            return DcContent(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: DcBanner(
                tone: dc.danger,
                icon: Icons.notifications_active_rounded,
                title: l10n.alarmsCount(totalAlarms),
              ),
            );
          }
          final alarm = alarms[index - 1];
          return DcContent(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            child: _AlarmTile(alarm: alarm),
          );
        },
      ),
    );
  }
}

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

/// Carte d'une alarme : liseré rouge, type, nom, valeur, horodatage.
class _AlarmTile extends StatelessWidget {
  final BacnetObject alarm;

  const _AlarmTile({required this.alarm});

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final l10n = AppLocalizations.of(context)!;
    final hasDescription = alarm.description != null && alarm.description!.isNotEmpty;

    return DcCard(
      accentColor: dc.danger.fg,
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      onTap: () {
        context.push(Routes.pointDetailPath('${alarm.type.name}:${alarm.instance}'));
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PointTypeBadge(type: alarm.type),
              const SizedBox(width: 12),
              // Nom et identifiant
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alarm.displayName,
                      style: context.text.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasDescription ? '${alarm.objectId} · ${alarm.objectName}' : alarm.objectId,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.monospacedValue.copyWith(
                        fontSize: 11.5,
                        color: dc.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Valeur actuelle
              PointValueChip(
                point: alarm,
                text: alarm.activeText ?? BacnetTypeUtils.formatValue(alarm),
                // Point en alarme : la valeur est un défaut, quel que soit son état binaire
                tone: context.dc.danger,
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: dc.textMuted, size: 20),
            ],
          ),

          // Message / horodatage de l'alarme
          if ((alarm.alarmMessage?.isNotEmpty ?? false) || alarm.alarmTimestamp != null) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                DcTag(l10n.alarm, icon: Icons.notifications_active_rounded, tone: dc.danger, dense: true),
                if (alarm.alarmTimestamp != null)
                  DcTag(
                    _formatTimestamp(l10n, alarm.alarmTimestamp!),
                    icon: Icons.schedule_rounded,
                    mono: true,
                    dense: true,
                  ),
                if (alarm.alarmMessage?.isNotEmpty ?? false)
                  Text(
                    alarm.alarmMessage!,
                    style: context.text.bodySmall?.copyWith(color: dc.textSecondary),
                  ),
              ],
            ),
          ],
        ],
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
