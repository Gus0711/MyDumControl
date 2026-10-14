import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/logger.dart';
import '../../domain/models/schedule.dart';
import '../../data/services/api_service.dart';
import '../../data/services/bacnet_service.dart';
import 'active_connection_provider.dart';
import 'bacnet_provider.dart';

/// Ne surveille que les champs de la connexion active utiles aux schedules,
/// pour ne pas relancer les lectures à chaque mise à jour de deviceInfo,
/// objectsSummary, controllerTime, etc.
void _watchScheduleConnectionKey(Ref ref) {
  ref.watch(activeConnectionProvider.select((s) => (
        s.connection?.id,
        s.isConnected,
        s.isBacnetConnection,
        s.client,
      )));
}

/// Provider pour récupérer la liste des schedules
/// Supporte les connexions API (V1/V2) et BACnet natives
final schedulesListProvider = FutureProvider<List<ScheduleSummary>>((ref) async {
  _watchScheduleConnectionKey(ref);
  final state = ref.read(activeConnectionProvider);
  if (!state.isConnected) {
    logger.w('schedulesListProvider: not connected');
    return [];
  }

  logger.i('schedulesListProvider: loading schedules (isBacnet=${state.isBacnetConnection}, hasClient=${state.client != null})');

  // ========================================
  // CONNEXION BACNET NATIVE
  // ========================================
  if (state.isBacnetConnection) {
    logger.i('schedulesListProvider: using BACnet native mode');
    final bacnetConnection = ref.read(activeBacnetConnectionProvider);
    if (bacnetConnection == null) {
      logger.e('schedulesListProvider: no active BACnet connection');
      return [];
    }

    final bacnetService = ref.read(bacnetServiceProvider);

    try {
      final scheduleInfos = await bacnetService.discoverSchedules(
        host: bacnetConnection.host,
        port: bacnetConnection.port,
        deviceId: bacnetConnection.deviceId ?? 0,
      );

      // Convertir BacnetScheduleInfo en ScheduleSummary
      final summaries = scheduleInfos.map((info) => ScheduleSummary(
        instance: info.instance,
        objectName: info.objectName,
        description: info.description,
        presentValue: info.presentValue,
        valueType: _detectValueType(info.presentValue),
      )).toList();

      logger.i('schedulesListProvider: loaded ${summaries.length} schedules via BACnet');
      return summaries;
    } catch (e) {
      // Remonter l'erreur (AsyncError) pour que l'écran affiche une erreur
      // avec "Réessayer" plutôt que "aucun planning"
      logger.e('schedulesListProvider: BACnet error: $e');
      rethrow;
    }
  }

  // ========================================
  // CONNEXION API DISTECH
  // ========================================
  final client = state.client!;
  client.clearLastError();
  final schedules = await client.getSchedules();
  // An empty list caused by a 401/403 must not look like "no schedule"
  throwIfAuthFailed(isEmpty: schedules.isEmpty, client: client);
  logger.i('schedulesListProvider: loaded ${schedules.length} schedules via API');
  return schedules;
});

/// Throws the client's auth error when an empty API result (empty list /
/// null) was caused by invalid credentials, so the screen shows an error
/// (AsyncError) instead of "no data".
@visibleForTesting
void throwIfAuthFailed({required bool isEmpty, required ConnectedApiClient client}) {
  if (!isEmpty || !client.hasAuthError) return;
  final error = client.lastError;
  throw error ?? const ApiAuthException();
}

/// Schedules just written by [ScheduleEditNotifier.save], keyed by
/// (connection id, instance). Consumed once by [scheduleDetailProvider] so the
/// detail screen shows the saved version without re-reading the controller.
final _savedScheduleCacheProvider = Provider<Map<(int?, int), Schedule>>((ref) => {});

/// Détecte le type de valeur depuis la presentValue
ScheduleValueType _detectValueType(dynamic value) {
  if (value == null) return ScheduleValueType.enumerated;
  if (value is bool) return ScheduleValueType.boolean;
  // Les valeurs double/real sont traitées comme enumerated pour l'instant
  return ScheduleValueType.enumerated;
}

/// Détecte le type de valeur depuis les transitions décodées (plus précis)
/// Analyse toutes les valeurs pour déterminer si c'est boolean ou enum
ScheduleValueType _detectValueTypeFromWeeklySchedule(DecodedWeeklySchedule? weeklySchedule) {
  if (weeklySchedule == null) return ScheduleValueType.enumerated;

  // Collecter toutes les valeurs uniques
  final uniqueValues = <int>{};
  int? firstTag;

  for (final day in weeklySchedule.days) {
    for (final tv in day.timeValues) {
      firstTag ??= tv.valueTag;

      // valueTag: 1 = boolean, 2 = unsigned, 9 = enumerated
      if (tv.valueTag == 1) {
        // Tag boolean explicite
        return ScheduleValueType.boolean;
      } else if (tv.valueTag == 9) {
        // Tag enumerated explicite
        return ScheduleValueType.enumerated;
      } else if (tv.valueTag == 2 && tv.value is int) {
        // Unsigned - collecter les valeurs pour analyse
        uniqueValues.add(tv.value as int);
      }
    }
  }

  // Analyser les valeurs unsigned collectées
  if (uniqueValues.isNotEmpty) {
    // Si toutes les valeurs sont 0 ou 1 uniquement -> boolean
    // Si une valeur > 1 existe -> enumerated
    final maxValue = uniqueValues.reduce((a, b) => a > b ? a : b);
    logger.d('_detectValueTypeFromWeeklySchedule: uniqueValues=$uniqueValues');
    if (maxValue > 1) {
      logger.d('_detectValueTypeFromWeeklySchedule: maxValue=$maxValue -> enumerated');
      return ScheduleValueType.enumerated;
    } else {
      logger.d('_detectValueTypeFromWeeklySchedule: values=$uniqueValues -> boolean');
      return ScheduleValueType.boolean;
    }
  }

  return ScheduleValueType.enumerated;
}

/// Provider pour récupérer un schedule détaillé avec son planning
/// Supporte les connexions API (V1/V2) et BACnet natives
/// Source unique de lecture : ScheduleEditNotifier.loadSchedule lit aussi ce
/// provider, ce qui évite une double lecture à l'ouverture de l'écran.
final scheduleDetailProvider = FutureProvider.family<Schedule?, int>((ref, instance) async {
  _watchScheduleConnectionKey(ref);
  final connectionId = ref.read(activeConnectionProvider).connection?.id;
  final saved = ref.read(_savedScheduleCacheProvider).remove((connectionId, instance));
  if (saved != null) return saved;
  return _fetchSchedule(ref, instance);
});

/// Lit un schedule complet (BACnet natif ou API). Lève en cas d'erreur réseau.
Future<Schedule?> _fetchSchedule(Ref ref, int instance) async {
  final state = ref.read(activeConnectionProvider);
  if (!state.isConnected) {
    logger.w('scheduleDetailProvider: not connected');
    return null;
  }

  logger.i('scheduleDetailProvider: loading schedule $instance (isBacnet=${state.isBacnetConnection})');

  // ========================================
  // CONNEXION BACNET NATIVE
  // ========================================
  if (state.isBacnetConnection) {
    final bacnetConnection = ref.read(activeBacnetConnectionProvider);
    if (bacnetConnection == null) {
      logger.e('scheduleDetailProvider: no active BACnet connection');
      return null;
    }

    final bacnetService = ref.read(bacnetServiceProvider);

    try {
      final scheduleInfo = await bacnetService.readScheduleFull(
        host: bacnetConnection.host,
        port: bacnetConnection.port,
        scheduleInstance: instance,
        deviceId: bacnetConnection.deviceId,
      );

      if (scheduleInfo == null) {
        logger.e('scheduleDetailProvider: failed to read schedule $instance via BACnet');
        return null;
      }

      // Convertir BacnetScheduleInfo en Schedule
      final schedule = _convertBacnetScheduleInfoToSchedule(scheduleInfo);

      logger.i('scheduleDetailProvider: loaded ${schedule.objectName} via BACnet');
      _logScheduleDetails(schedule);

      return schedule;
    } catch (e) {
      // Remonter l'erreur (AsyncError) : un timeout ne doit pas ressembler
      // à "planning introuvable"
      logger.e('scheduleDetailProvider: BACnet error: $e');
      rethrow;
    }
  }

  // ========================================
  // CONNEXION API DISTECH
  // ========================================
  final client = state.client!;
  client.clearLastError();
  final schedule = await client.getScheduleDetail(instance);
  throwIfAuthFailed(isEmpty: schedule == null, client: client);

  if (schedule != null) {
    logger.i('scheduleDetailProvider: loaded ${schedule.objectName} via API');
    _logScheduleDetails(schedule);
  }

  return schedule;
}

/// Convertit un BacnetScheduleInfo en Schedule
Schedule _convertBacnetScheduleInfoToSchedule(BacnetScheduleInfo info) {
  // Déterminer le type de valeur - priorité au weekly-schedule car plus précis
  ScheduleValueType valueType;
  if (info.weeklySchedule != null) {
    valueType = _detectValueTypeFromWeeklySchedule(info.weeklySchedule);
  } else {
    valueType = _detectValueType(info.presentValue);
  }
  logger.d('_convertBacnetScheduleInfoToSchedule: detected valueType=$valueType');

  // Convertir le weekly schedule
  WeeklySchedule weeklySchedule;
  if (info.weeklySchedule != null) {
    weeklySchedule = _convertDecodedWeeklySchedule(info.weeklySchedule!);
  } else {
    weeklySchedule = WeeklySchedule.empty();
  }

  // Convertir les state texts
  final stateTexts = bacnetStateTextsToScheduleStateTexts(info.stateTexts, valueType);

  return Schedule(
    instance: info.instance,
    objectName: info.objectName,
    description: info.description,
    weeklySchedule: weeklySchedule,
    stateTexts: stateTexts,
    valueType: valueType,
    presentValue: info.presentValue,
    scheduleDefault: info.scheduleDefault,
  );
}

/// Convertit la propriété BACnet state-text en ScheduleStateText.
/// BACnet (ASHRAE 135, multi-state) : state-text[0] correspond à la valeur 1,
/// donc pour un schedule énuméré l'index = i + 1. Pour un booléen, on garde
/// 0 = inactif / 1 = actif.
@visibleForTesting
List<ScheduleStateText> bacnetStateTextsToScheduleStateTexts(
  List<String>? texts,
  ScheduleValueType valueType,
) {
  if (texts == null) return const [];
  final offset = valueType == ScheduleValueType.enumerated ? 1 : 0;
  return [
    for (int i = 0; i < texts.length; i++) ScheduleStateText(index: i + offset, text: texts[i]),
  ];
}

/// Convertit un DecodedWeeklySchedule en WeeklySchedule
WeeklySchedule _convertDecodedWeeklySchedule(DecodedWeeklySchedule decoded) {
  final days = <WeekDay, DaySchedule>{};

  for (int i = 0; i < 7 && i < decoded.days.length; i++) {
    final weekDay = WeekDay.values[i];
    final decodedDay = decoded.days[i];

    final transitions = <ScheduleTransition>[];
    for (final tv in decodedDay.timeValues) {
      // Conserver l'heure complète "HH:mm:ss.cc" (l'affichage n'utilise que
      // HH:mm via formattedTime) pour ne pas perdre les secondes à la réécriture
      transitions.add(ScheduleTransition(
        time: tv.timeString,
        value: tv.value,
        type: _valueTagToTypeString(tv.valueTag),
      ));
    }

    days[weekDay] = DaySchedule(day: weekDay, transitions: transitions);
  }

  // Remplir les jours manquants
  for (final day in WeekDay.values) {
    days.putIfAbsent(day, () => DaySchedule.empty(day));
  }

  return WeeklySchedule(days: days);
}

/// Convertit le type de tag BACnet en string
String _valueTagToTypeString(int valueTag) {
  switch (valueTag) {
    case 0: return 'null';
    case 1: return 'boolean';
    case 2: return 'unsigned';
    case 3: return 'signed';
    case 4: return 'real';
    case 9: return 'enumerated';
    default: return 'unknown';
  }
}

/// Log les détails d'un schedule pour debug
void _logScheduleDetails(Schedule schedule) {
  logger.d('scheduleDetailProvider: valueType=${schedule.valueType}, stateTexts=${schedule.stateTexts.length}');

  for (final day in WeekDay.values) {
    final daySchedule = schedule.weeklySchedule.getDay(day);
    if (daySchedule.hasTransitions) {
      logger.d('scheduleDetailProvider: ${day.shortName}: ${daySchedule.transitionCount} transitions');
    }
  }
}

/// État pour l'édition d'un schedule
class ScheduleEditState {
  final Schedule? originalSchedule;
  final Schedule? editedSchedule;
  final bool isEditing;
  final bool hasChanges;
  final bool isSaving;
  final String? error;
  final String? successMessage;
  final WeekDay? selectedDay;
  final WeekDay? clipboardSourceDay;

  const ScheduleEditState({
    this.originalSchedule,
    this.editedSchedule,
    this.isEditing = false,
    this.hasChanges = false,
    this.isSaving = false,
    this.error,
    this.successMessage,
    this.selectedDay,
    this.clipboardSourceDay,
  });

  /// Vérifie si un schedule est chargé
  bool get isLoaded => editedSchedule != null;

  /// Récupère le planning du jour sélectionné
  DaySchedule? get selectedDaySchedule {
    if (editedSchedule == null || selectedDay == null) return null;
    return editedSchedule!.weeklySchedule.getDay(selectedDay!);
  }

  ScheduleEditState copyWith({
    Schedule? originalSchedule,
    Schedule? editedSchedule,
    bool? isEditing,
    bool? hasChanges,
    bool? isSaving,
    String? error,
    String? successMessage,
    WeekDay? selectedDay,
    WeekDay? clipboardSourceDay,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearClipboard = false,
    bool clearSelectedDay = false,
  }) {
    return ScheduleEditState(
      originalSchedule: originalSchedule ?? this.originalSchedule,
      editedSchedule: editedSchedule ?? this.editedSchedule,
      isEditing: isEditing ?? this.isEditing,
      hasChanges: hasChanges ?? this.hasChanges,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      selectedDay: clearSelectedDay ? null : (selectedDay ?? this.selectedDay),
      clipboardSourceDay: clearClipboard ? null : (clipboardSourceDay ?? this.clipboardSourceDay),
    );
  }
}

/// Notifier pour l'édition d'un schedule
class ScheduleEditNotifier extends StateNotifier<ScheduleEditState> {
  final Ref _ref;

  ScheduleEditNotifier(this._ref) : super(const ScheduleEditState());

  /// Jeton de la dernière demande de chargement : une réponse tardive d'un
  /// chargement précédent (autre planning) est ignorée.
  int _loadToken = 0;

  /// Dernière instance demandée (pour récupérer le planning si le premier
  /// chargement a échoué puis que l'écran a relu le détail avec succès)
  int? _lastInstance;

  /// Édition possible : un planning est chargé et aucune sauvegarde en cours
  bool get _canEdit => state.editedSchedule != null && !state.isSaving;

  /// Charge un schedule pour édition
  /// Supporte les connexions API (V1/V2) et BACnet natives
  /// Lit [scheduleDetailProvider] (lecture partagée avec l'écran, pas de
  /// double requête). L'état est réinitialisé immédiatement : en cas d'échec,
  /// aucun planning précédent (périmé ou d'une autre instance) ne reste chargé.
  Future<void> loadSchedule(int instance) async {
    final token = ++_loadToken;
    _lastInstance = instance;
    state = const ScheduleEditState();

    Schedule? schedule;
    try {
      schedule = await _ref.read(scheduleDetailProvider(instance).future);
    } catch (e) {
      if (!mounted || token != _loadToken) return;
      logger.e('ScheduleEditNotifier.loadSchedule: error: $e');
      state = ScheduleEditState(error: 'Erreur de chargement du planning: $e');
      return;
    }

    if (!mounted || token != _loadToken) return;

    if (schedule == null) {
      logger.w('ScheduleEditNotifier.loadSchedule: schedule $instance not available');
      return;
    }

    state = ScheduleEditState(
      originalSchedule: schedule,
      editedSchedule: schedule,
      selectedDay: WeekDay.monday,
    );
    logger.i('ScheduleEditNotifier: loaded schedule ${schedule.objectName}');
  }

  /// Starts editing [schedule] (already read by [scheduleDetailProvider])
  /// without any controller access. Cancels a pending [loadSchedule].
  void loadFrom(Schedule schedule) {
    _loadToken++;
    _lastInstance = schedule.instance;
    state = ScheduleEditState(
      originalSchedule: schedule,
      editedSchedule: schedule,
      selectedDay: WeekDay.monday,
    );
  }

  /// Active/désactive le mode édition
  void setEditing(bool editing) {
    // Rien de chargé (échec précédent, puis "Réessayer" sur l'écran) :
    // reprendre le planning déjà lu par scheduleDetailProvider s'il existe
    if (editing && state.editedSchedule == null && _lastInstance != null) {
      final schedule = _ref.read(scheduleDetailProvider(_lastInstance!)).valueOrNull;
      if (schedule != null) {
        state = ScheduleEditState(
          originalSchedule: schedule,
          editedSchedule: schedule,
          selectedDay: WeekDay.monday,
        );
      }
    }
    state = state.copyWith(isEditing: editing, clearError: true, clearSuccess: true);
  }

  /// Sélectionne un jour
  void selectDay(WeekDay day) {
    state = state.copyWith(selectedDay: day);
  }

  /// Copie un jour dans le presse-papier
  void copyDay(WeekDay day) {
    state = state.copyWith(clipboardSourceDay: day);
    logger.i('ScheduleEditNotifier: copied ${day.displayName} to clipboard');
  }

  /// Colle le jour du presse-papier sur un autre jour
  void pasteDay(WeekDay targetDay) {
    if (state.clipboardSourceDay == null || !_canEdit) return;

    final sourceDay = state.clipboardSourceDay!;
    if (sourceDay == targetDay) return;

    final newWeeklySchedule = state.editedSchedule!.weeklySchedule.copyDayTo(sourceDay, [targetDay]);
    final newSchedule = state.editedSchedule!.copyWith(weeklySchedule: newWeeklySchedule);

    state = state.copyWith(
      editedSchedule: newSchedule,
      hasChanges: true,
    );

    logger.i('ScheduleEditNotifier: pasted ${sourceDay.displayName} to ${targetDay.displayName}');
  }

  /// Colle le jour sur tous les jours ouvrés
  void pasteDayToWorkDays() {
    if (state.clipboardSourceDay == null || !_canEdit) return;

    final sourceDay = state.clipboardSourceDay!;
    final newWeeklySchedule = state.editedSchedule!.weeklySchedule.copyDayTo(
      sourceDay,
      WeekDay.workDays.where((d) => d != sourceDay).toList(),
    );
    final newSchedule = state.editedSchedule!.copyWith(weeklySchedule: newWeeklySchedule);

    state = state.copyWith(
      editedSchedule: newSchedule,
      hasChanges: true,
    );

    logger.i('ScheduleEditNotifier: pasted ${sourceDay.displayName} to work days');
  }

  /// Colle le jour sur tous les jours
  void pasteDayToAllDays() {
    if (state.clipboardSourceDay == null || !_canEdit) return;

    final sourceDay = state.clipboardSourceDay!;
    final newWeeklySchedule = state.editedSchedule!.weeklySchedule.copyDayTo(
      sourceDay,
      WeekDay.values.where((d) => d != sourceDay).toList(),
    );
    final newSchedule = state.editedSchedule!.copyWith(weeklySchedule: newWeeklySchedule);

    state = state.copyWith(
      editedSchedule: newSchedule,
      hasChanges: true,
    );

    logger.i('ScheduleEditNotifier: pasted ${sourceDay.displayName} to all days');
  }

  /// Efface le presse-papier
  void clearClipboard() {
    state = state.copyWith(clearClipboard: true);
  }

  /// Efface un jour (supprime toutes ses transitions)
  void clearDay(WeekDay day) {
    if (!_canEdit) return;

    final newWeeklySchedule = state.editedSchedule!.weeklySchedule.copyWithDay(
      day,
      DaySchedule.empty(day),
    );
    final newSchedule = state.editedSchedule!.copyWith(weeklySchedule: newWeeklySchedule);

    state = state.copyWith(
      editedSchedule: newSchedule,
      hasChanges: true,
    );

    logger.i('ScheduleEditNotifier: cleared ${day.displayName}');
  }

  /// Ajoute une transition à un jour
  void addTransition(WeekDay day, ScheduleTransition transition) {
    if (!_canEdit) return;

    final currentDay = state.editedSchedule!.weeklySchedule.getDay(day);
    final newTransitions = List<ScheduleTransition>.from(currentDay.transitions)..add(transition);

    final newDaySchedule = currentDay.copyWith(transitions: newTransitions);
    final newWeeklySchedule = state.editedSchedule!.weeklySchedule.copyWithDay(day, newDaySchedule);
    final newSchedule = state.editedSchedule!.copyWith(weeklySchedule: newWeeklySchedule);

    state = state.copyWith(
      editedSchedule: newSchedule,
      hasChanges: true,
    );

    logger.i('ScheduleEditNotifier: added transition at ${transition.formattedTime} to ${day.displayName}');
  }

  /// Ajoute un créneau en ajustant les créneaux existants pour éviter les chevauchements
  /// Si le nouveau créneau chevauche un existant, l'existant est ajusté (raccourci ou supprimé)
  void addTimeSlot(WeekDay day, TimeSlot newSlot) {
    if (!_canEdit) return;

    final currentDay = state.editedSchedule!.weeklySchedule.getDay(day);

    // Convertir les transitions actuelles en créneaux
    var existingSlots = TimeSlotConverter.transitionsToSlots(currentDay.sortedTransitions);

    // Ajuster les créneaux existants qui chevauchent le nouveau
    final adjustedSlots = <TimeSlot>[];

    for (final existing in existingSlots) {
      // Pas de chevauchement : le créneau existant est avant ou après le nouveau
      if (existing.endMinutes <= newSlot.startMinutes || existing.startMinutes >= newSlot.endMinutes) {
        adjustedSlots.add(existing);
        continue;
      }

      // Chevauchement détecté - ajuster le créneau existant

      // Cas 1: Le nouveau créneau couvre entièrement l'existant → supprimer l'existant
      if (newSlot.startMinutes <= existing.startMinutes && newSlot.endMinutes >= existing.endMinutes) {
        logger.d('Slot ${existing.formattedStart}-${existing.formattedEnd} supprimé (couvert par le nouveau)');
        continue; // Ne pas ajouter ce créneau
      }

      // Cas 2: Le nouveau créneau commence pendant l'existant → raccourcir la fin de l'existant
      if (newSlot.startMinutes > existing.startMinutes && newSlot.startMinutes < existing.endMinutes) {
        if (newSlot.endMinutes >= existing.endMinutes) {
          // Le nouveau déborde à droite : raccourcir l'existant
          adjustedSlots.add(TimeSlot(
            startMinutes: existing.startMinutes,
            endMinutes: newSlot.startMinutes,
            value: existing.value,
          ));
          logger.d('Slot ajusté: ${existing.formattedStart}-${existing.formattedEnd} → ${existing.formattedStart}-${newSlot.formattedStart}');
        } else {
          // Le nouveau est au milieu : couper l'existant en deux
          adjustedSlots.add(TimeSlot(
            startMinutes: existing.startMinutes,
            endMinutes: newSlot.startMinutes,
            value: existing.value,
          ));
          adjustedSlots.add(TimeSlot(
            startMinutes: newSlot.endMinutes,
            endMinutes: existing.endMinutes,
            value: existing.value,
          ));
          logger.d('Slot coupé en deux: ${existing.formattedStart}-${newSlot.formattedStart} et ${newSlot.formattedEnd}-${existing.formattedEnd}');
        }
        continue;
      }

      // Cas 3: Le nouveau créneau finit pendant l'existant → décaler le début de l'existant
      if (newSlot.endMinutes > existing.startMinutes && newSlot.endMinutes < existing.endMinutes) {
        adjustedSlots.add(TimeSlot(
          startMinutes: newSlot.endMinutes,
          endMinutes: existing.endMinutes,
          value: existing.value,
        ));
        logger.d('Slot ajusté: ${existing.formattedStart}-${existing.formattedEnd} → ${newSlot.formattedEnd}-${existing.formattedEnd}');
        continue;
      }

      // Par défaut, garder l'existant (ne devrait pas arriver)
      adjustedSlots.add(existing);
    }

    // Ajouter le nouveau créneau
    adjustedSlots.add(newSlot);

    // Reconvertir en transitions
    final newTransitions = TimeSlotConverter.slotsToTransitions(adjustedSlots);

    final newDaySchedule = currentDay.copyWith(transitions: newTransitions);
    final newWeeklySchedule = state.editedSchedule!.weeklySchedule.copyWithDay(day, newDaySchedule);
    final newSchedule = state.editedSchedule!.copyWith(weeklySchedule: newWeeklySchedule);

    state = state.copyWith(
      editedSchedule: newSchedule,
      hasChanges: true,
    );

    logger.i('ScheduleEditNotifier: added slot ${newSlot.formattedStart}-${newSlot.formattedEnd} to ${day.displayName}');
  }

  /// Met à jour un créneau existant
  void updateTimeSlot(WeekDay day, TimeSlot oldSlot, TimeSlot newSlot) {
    if (!_canEdit) return;

    final currentDay = state.editedSchedule!.weeklySchedule.getDay(day);

    // Convertir en créneaux et supprimer l'ancien
    var slots = TimeSlotConverter.transitionsToSlots(currentDay.sortedTransitions);
    slots = slots.where((s) =>
      !(s.startMinutes == oldSlot.startMinutes &&
        s.endMinutes == oldSlot.endMinutes &&
        s.value == oldSlot.value)
    ).toList();

    // Reconvertir en transitions
    final transitions = TimeSlotConverter.slotsToTransitions(slots);
    final tempDaySchedule = currentDay.copyWith(transitions: transitions);
    final tempWeeklySchedule = state.editedSchedule!.weeklySchedule.copyWithDay(day, tempDaySchedule);
    final tempSchedule = state.editedSchedule!.copyWith(weeklySchedule: tempWeeklySchedule);

    // Mettre à jour l'état temporairement
    state = state.copyWith(editedSchedule: tempSchedule);

    // Ajouter le nouveau créneau (qui gérera les chevauchements)
    addTimeSlot(day, newSlot);

    logger.i('ScheduleEditNotifier: updated slot on ${day.displayName}');
  }

  /// Supprime un créneau
  void removeTimeSlot(WeekDay day, TimeSlot slot) {
    if (!_canEdit) return;

    final currentDay = state.editedSchedule!.weeklySchedule.getDay(day);

    // Convertir en créneaux et supprimer celui qui correspond
    var slots = TimeSlotConverter.transitionsToSlots(currentDay.sortedTransitions);
    slots = slots.where((s) =>
      !(s.startMinutes == slot.startMinutes &&
        s.endMinutes == slot.endMinutes &&
        s.value == slot.value)
    ).toList();

    // Reconvertir en transitions
    final newTransitions = TimeSlotConverter.slotsToTransitions(slots);

    final newDaySchedule = currentDay.copyWith(transitions: newTransitions);
    final newWeeklySchedule = state.editedSchedule!.weeklySchedule.copyWithDay(day, newDaySchedule);
    final newSchedule = state.editedSchedule!.copyWith(weeklySchedule: newWeeklySchedule);

    state = state.copyWith(
      editedSchedule: newSchedule,
      hasChanges: true,
    );

    logger.i('ScheduleEditNotifier: removed slot ${slot.formattedStart}-${slot.formattedEnd} from ${day.displayName}');
  }

  /// Modifie une transition existante
  void updateTransition(WeekDay day, int index, ScheduleTransition newTransition) {
    if (!_canEdit) return;

    final currentDay = state.editedSchedule!.weeklySchedule.getDay(day);
    if (index < 0 || index >= currentDay.transitions.length) return;

    final newTransitions = List<ScheduleTransition>.from(currentDay.transitions);
    newTransitions[index] = newTransition;

    final newDaySchedule = currentDay.copyWith(transitions: newTransitions);
    final newWeeklySchedule = state.editedSchedule!.weeklySchedule.copyWithDay(day, newDaySchedule);
    final newSchedule = state.editedSchedule!.copyWith(weeklySchedule: newWeeklySchedule);

    state = state.copyWith(
      editedSchedule: newSchedule,
      hasChanges: true,
    );

    logger.i('ScheduleEditNotifier: updated transition $index on ${day.displayName}');
  }

  /// Supprime une transition
  void removeTransition(WeekDay day, int index) {
    if (!_canEdit) return;

    final currentDay = state.editedSchedule!.weeklySchedule.getDay(day);
    if (index < 0 || index >= currentDay.transitions.length) return;

    final newTransitions = List<ScheduleTransition>.from(currentDay.transitions)..removeAt(index);

    final newDaySchedule = currentDay.copyWith(transitions: newTransitions);
    final newWeeklySchedule = state.editedSchedule!.weeklySchedule.copyWithDay(day, newDaySchedule);
    final newSchedule = state.editedSchedule!.copyWith(weeklySchedule: newWeeklySchedule);

    state = state.copyWith(
      editedSchedule: newSchedule,
      hasChanges: true,
    );

    logger.i('ScheduleEditNotifier: removed transition $index from ${day.displayName}');
  }

  /// Annule les modifications
  void revert() {
    if (state.originalSchedule == null || state.isSaving) return;

    state = state.copyWith(
      editedSchedule: state.originalSchedule,
      hasChanges: false,
      clearClipboard: true,
      clearError: true,
      clearSuccess: true,
    );

    logger.i('ScheduleEditNotifier: reverted changes');
  }

  /// Sauvegarde les modifications sur l'automate
  /// Supporte les connexions API (V1/V2) et BACnet natives
  Future<bool> save() async {
    if (state.editedSchedule == null || !state.hasChanges || state.isSaving) return false;

    final connectionState = _ref.read(activeConnectionProvider);
    if (!connectionState.isConnected) {
      state = state.copyWith(error: 'Non connecté');
      return false;
    }

    // Version effectivement envoyée (les éditions sont bloquées pendant isSaving)
    final toWrite = state.editedSchedule!;
    state = state.copyWith(isSaving: true, clearError: true, clearSuccess: true);

    try {
      bool success;

      // ========================================
      // CONNEXION BACNET NATIVE
      // ========================================
      if (connectionState.isBacnetConnection) {
        final bacnetConnection = _ref.read(activeBacnetConnectionProvider);
        if (bacnetConnection == null) {
          state = state.copyWith(isSaving: false, error: 'Connexion BACnet non active');
          return false;
        }

        final bacnetService = _ref.read(bacnetServiceProvider);

        // Convertir le WeeklySchedule en BacnetWeeklySchedule en conservant
        // le type de données d'origine du planning (unsigned/real/...)
        final bacnetWeeklySchedule = convertToBacnetWeeklySchedule(
          toWrite.weeklySchedule,
          toWrite.valueType,
          fallbackType: state.originalSchedule?.weeklySchedule.dominantValueType,
        );

        success = await bacnetService.writeWeeklySchedule(
          host: bacnetConnection.host,
          port: bacnetConnection.port,
          scheduleInstance: toWrite.instance,
          weeklySchedule: bacnetWeeklySchedule,
          deviceId: bacnetConnection.deviceId,
        );
      }
      // ========================================
      // CONNEXION API DISTECH
      // ========================================
      else {
        success = await connectionState.client!.writeWeeklySchedule(
          toWrite.instance,
          toWrite.weeklySchedule,
        );
      }

      if (!mounted) return success;

      if (success) {
        // Mettre à jour l'original avec la version réellement envoyée
        state = state.copyWith(
          originalSchedule: toWrite,
          hasChanges: !identical(state.editedSchedule, toWrite),
          isSaving: false,
          successMessage: 'Planning sauvegardé',
        );

        // Update the detail cache with the written version (no re-read of
        // the controller): the next evaluation consumes this entry. The
        // refresh button still re-reads the controller.
        _ref.read(_savedScheduleCacheProvider)[
            (connectionState.connection?.id, toWrite.instance)] = toWrite;
        _ref.invalidate(scheduleDetailProvider(toWrite.instance));

        logger.i('ScheduleEditNotifier: saved successfully');
        return true;
      } else {
        state = state.copyWith(
          isSaving: false,
          error: 'Échec de la sauvegarde',
        );
        logger.e('ScheduleEditNotifier: save failed');
        return false;
      }
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        isSaving: false,
        error: 'Erreur: $e',
      );
      logger.e('ScheduleEditNotifier: save error: $e');
      return false;
    }
  }

  /// Reset complet
  void reset() {
    _loadToken++; // ignorer un chargement en cours
    _lastInstance = null;
    state = const ScheduleEditState();
  }

  /// Efface le message d'erreur
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Efface le message de succès
  void clearSuccess() {
    state = state.copyWith(clearSuccess: true);
  }
}

/// Convertit un type de valeur ("unsigned", "real"...) en tag BACnet
ScheduleValueTag? _scheduleValueTagFromType(String? type) {
  switch (type) {
    case 'boolean': return ScheduleValueTag.boolean;
    case 'unsigned': return ScheduleValueTag.unsigned;
    case 'signed': return ScheduleValueTag.signed;
    case 'real': return ScheduleValueTag.real;
    case 'enumerated': return ScheduleValueTag.enumerated;
    default: return null;
  }
}

/// Convertit un WeeklySchedule en BacnetWeeklySchedule pour l'écriture BACnet.
///
/// Le tag de chaque valeur conserve le type d'origine du planning :
/// 1. type de la transition (lu sur l'automate) ;
/// 2. sinon type dominant du planning édité, puis [fallbackType] (planning
///    d'origine) — cas des nouvelles transitions créées dans l'éditeur ;
/// 3. sinon boolean/enumerated selon [valueType].
/// Une valeur null (retour au défaut) est toujours encodée en tag Null.
@visibleForTesting
BacnetWeeklySchedule convertToBacnetWeeklySchedule(
  WeeklySchedule weeklySchedule,
  ScheduleValueType valueType, {
  String? fallbackType,
}) {
  final scheduleTag = _scheduleValueTagFromType(weeklySchedule.dominantValueType) ??
      _scheduleValueTagFromType(fallbackType) ??
      (valueType == ScheduleValueType.boolean ? ScheduleValueTag.boolean : ScheduleValueTag.enumerated);

  final days = <BacnetDailySchedule>[];

  for (final weekDay in WeekDay.values) {
    final daySchedule = weeklySchedule.getDay(weekDay);
    final timeValues = <BacnetTimeValue>[];

    for (final transition in daySchedule.sortedTransitions) {
      if (transition.value == null) {
        timeValues.add(BacnetTimeValue.fromTimeString(
          transition.time,
          null,
          valueTag: ScheduleValueTag.nullValue,
        ));
        continue;
      }

      final tag = _scheduleValueTagFromType(transition.knownType) ?? scheduleTag;
      timeValues.add(BacnetTimeValue.fromTimeString(
        transition.time,
        ScheduleTransition.normalizeValueForType(transition.value, tag.name),
        valueTag: tag,
      ));
    }

    days.add(BacnetDailySchedule(timeValues: timeValues));
  }

  return BacnetWeeklySchedule(days: days);
}

/// Provider pour l'édition d'un schedule
final scheduleEditProvider = StateNotifierProvider<ScheduleEditNotifier, ScheduleEditState>((ref) {
  return ScheduleEditNotifier(ref);
});
