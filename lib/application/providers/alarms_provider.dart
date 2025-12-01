import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/bacnet_object.dart';
import 'points_provider.dart';

/// Options de tri pour les alarmes
enum AlarmSortOption {
  nameAsc('Nom (A→Z)'),
  nameDesc('Nom (Z→A)'),
  typeAsc('Type'),
  timestampDesc('Plus récentes'),
  timestampAsc('Plus anciennes');

  final String displayName;

  const AlarmSortOption(this.displayName);
}

/// Provider qui filtre les points en alarme depuis le pointsProvider
final alarmsProvider = Provider<List<BacnetObject>>((ref) {
  final pointsState = ref.watch(pointsProvider);
  return pointsState.points.where((p) => p.inAlarm).toList();
});

/// Provider pour le nombre d'alarmes actives
final alarmsCountProvider = Provider<int>((ref) {
  return ref.watch(alarmsProvider).length;
});

/// Provider pour vérifier s'il y a des alarmes
final hasAlarmsProvider = Provider<bool>((ref) {
  return ref.watch(alarmsCountProvider) > 0;
});

/// État des alarmes avec recherche et tri
class AlarmsState {
  final String searchQuery;
  final AlarmSortOption sortOption;

  const AlarmsState({
    this.searchQuery = '',
    this.sortOption = AlarmSortOption.nameAsc,
  });

  AlarmsState copyWith({
    String? searchQuery,
    AlarmSortOption? sortOption,
  }) {
    return AlarmsState(
      searchQuery: searchQuery ?? this.searchQuery,
      sortOption: sortOption ?? this.sortOption,
    );
  }
}

/// Notifier pour gérer l'état de filtrage/tri des alarmes
class AlarmsNotifier extends StateNotifier<AlarmsState> {
  AlarmsNotifier() : super(const AlarmsState());

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setSortOption(AlarmSortOption option) {
    state = state.copyWith(sortOption: option);
  }

  void clearSearch() {
    state = state.copyWith(searchQuery: '');
  }
}

/// Provider pour l'état de filtrage/tri
final alarmsStateProvider = StateNotifierProvider<AlarmsNotifier, AlarmsState>((ref) {
  return AlarmsNotifier();
});

/// Provider pour les alarmes filtrées et triées
final filteredAlarmsProvider = Provider<List<BacnetObject>>((ref) {
  final alarms = ref.watch(alarmsProvider);
  final state = ref.watch(alarmsStateProvider);

  var result = alarms.toList();

  // Filtrer par recherche
  if (state.searchQuery.isNotEmpty) {
    final query = state.searchQuery.toLowerCase();
    result = result.where((p) {
      return p.objectName.toLowerCase().contains(query) ||
          (p.description?.toLowerCase().contains(query) ?? false) ||
          p.objectId.toLowerCase().contains(query) ||
          (p.activeText?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  // Trier
  switch (state.sortOption) {
    case AlarmSortOption.nameAsc:
      result.sort((a, b) => a.objectName.toLowerCase().compareTo(b.objectName.toLowerCase()));
      break;
    case AlarmSortOption.nameDesc:
      result.sort((a, b) => b.objectName.toLowerCase().compareTo(a.objectName.toLowerCase()));
      break;
    case AlarmSortOption.typeAsc:
      result.sort((a, b) {
        final typeCompare = a.type.index.compareTo(b.type.index);
        if (typeCompare != 0) return typeCompare;
        return a.objectName.compareTo(b.objectName);
      });
      break;
    case AlarmSortOption.timestampDesc:
      result.sort((a, b) {
        if (a.alarmTimestamp == null && b.alarmTimestamp == null) return 0;
        if (a.alarmTimestamp == null) return 1;
        if (b.alarmTimestamp == null) return -1;
        return b.alarmTimestamp!.compareTo(a.alarmTimestamp!);
      });
      break;
    case AlarmSortOption.timestampAsc:
      result.sort((a, b) {
        if (a.alarmTimestamp == null && b.alarmTimestamp == null) return 0;
        if (a.alarmTimestamp == null) return 1;
        if (b.alarmTimestamp == null) return -1;
        return a.alarmTimestamp!.compareTo(b.alarmTimestamp!);
      });
      break;
  }

  return result;
});
