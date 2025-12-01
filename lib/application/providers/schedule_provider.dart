import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../domain/models/schedule.dart';
import 'active_connection_provider.dart';

final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

/// Provider pour récupérer la liste des schedules
final schedulesListProvider = FutureProvider<List<ScheduleSummary>>((ref) async {
  final state = ref.watch(activeConnectionProvider);
  if (!state.isConnected) {
    _logger.w('schedulesListProvider: not connected');
    return [];
  }

  _logger.i('schedulesListProvider: loading schedules');
  final schedules = await state.client!.getSchedules();
  _logger.i('schedulesListProvider: loaded ${schedules.length} schedules');
  return schedules;
});

/// Provider pour récupérer un schedule détaillé avec son planning
final scheduleDetailProvider = FutureProvider.family<Schedule?, int>((ref, instance) async {
  final state = ref.watch(activeConnectionProvider);
  if (!state.isConnected) {
    _logger.w('scheduleDetailProvider: not connected');
    return null;
  }

  _logger.i('scheduleDetailProvider: loading schedule $instance');
  final schedule = await state.client!.getScheduleDetail(instance);

  if (schedule != null) {
    _logger.i('scheduleDetailProvider: loaded ${schedule.objectName}');
    _logger.d('scheduleDetailProvider: valueType=${schedule.valueType}, stateTexts=${schedule.stateTexts.length}');

    // Log des transitions pour debug
    for (final day in WeekDay.values) {
      final daySchedule = schedule.weeklySchedule.getDay(day);
      if (daySchedule.hasTransitions) {
        _logger.d('scheduleDetailProvider: ${day.shortName}: ${daySchedule.transitionCount} transitions');
      }
    }
  }

  return schedule;
});

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

  /// Charge un schedule pour édition
  Future<void> loadSchedule(int instance) async {
    final connectionState = _ref.read(activeConnectionProvider);
    if (!connectionState.isConnected) return;

    final schedule = await connectionState.client!.getScheduleDetail(instance);
    if (schedule != null) {
      state = ScheduleEditState(
        originalSchedule: schedule,
        editedSchedule: schedule,
        selectedDay: WeekDay.monday,
      );
      _logger.i('ScheduleEditNotifier: loaded schedule ${schedule.objectName}');
    }
  }

  /// Active/désactive le mode édition
  void setEditing(bool editing) {
    state = state.copyWith(isEditing: editing, clearError: true, clearSuccess: true);
  }

  /// Sélectionne un jour
  void selectDay(WeekDay day) {
    state = state.copyWith(selectedDay: day);
  }

  /// Copie un jour dans le presse-papier
  void copyDay(WeekDay day) {
    state = state.copyWith(clipboardSourceDay: day);
    _logger.i('ScheduleEditNotifier: copied ${day.displayName} to clipboard');
  }

  /// Colle le jour du presse-papier sur un autre jour
  void pasteDay(WeekDay targetDay) {
    if (state.clipboardSourceDay == null || state.editedSchedule == null) return;

    final sourceDay = state.clipboardSourceDay!;
    if (sourceDay == targetDay) return;

    final newWeeklySchedule = state.editedSchedule!.weeklySchedule.copyDayTo(sourceDay, [targetDay]);
    final newSchedule = state.editedSchedule!.copyWith(weeklySchedule: newWeeklySchedule);

    state = state.copyWith(
      editedSchedule: newSchedule,
      hasChanges: true,
    );

    _logger.i('ScheduleEditNotifier: pasted ${sourceDay.displayName} to ${targetDay.displayName}');
  }

  /// Colle le jour sur tous les jours ouvrés
  void pasteDayToWorkDays() {
    if (state.clipboardSourceDay == null || state.editedSchedule == null) return;

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

    _logger.i('ScheduleEditNotifier: pasted ${sourceDay.displayName} to work days');
  }

  /// Colle le jour sur tous les jours
  void pasteDayToAllDays() {
    if (state.clipboardSourceDay == null || state.editedSchedule == null) return;

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

    _logger.i('ScheduleEditNotifier: pasted ${sourceDay.displayName} to all days');
  }

  /// Efface le presse-papier
  void clearClipboard() {
    state = state.copyWith(clearClipboard: true);
  }

  /// Efface un jour (supprime toutes ses transitions)
  void clearDay(WeekDay day) {
    if (state.editedSchedule == null) return;

    final newWeeklySchedule = state.editedSchedule!.weeklySchedule.copyWithDay(
      day,
      DaySchedule.empty(day),
    );
    final newSchedule = state.editedSchedule!.copyWith(weeklySchedule: newWeeklySchedule);

    state = state.copyWith(
      editedSchedule: newSchedule,
      hasChanges: true,
    );

    _logger.i('ScheduleEditNotifier: cleared ${day.displayName}');
  }

  /// Ajoute une transition à un jour
  void addTransition(WeekDay day, ScheduleTransition transition) {
    if (state.editedSchedule == null) return;

    final currentDay = state.editedSchedule!.weeklySchedule.getDay(day);
    final newTransitions = List<ScheduleTransition>.from(currentDay.transitions)..add(transition);

    final newDaySchedule = currentDay.copyWith(transitions: newTransitions);
    final newWeeklySchedule = state.editedSchedule!.weeklySchedule.copyWithDay(day, newDaySchedule);
    final newSchedule = state.editedSchedule!.copyWith(weeklySchedule: newWeeklySchedule);

    state = state.copyWith(
      editedSchedule: newSchedule,
      hasChanges: true,
    );

    _logger.i('ScheduleEditNotifier: added transition at ${transition.formattedTime} to ${day.displayName}');
  }

  /// Ajoute un créneau en ajustant les créneaux existants pour éviter les chevauchements
  /// Si le nouveau créneau chevauche un existant, l'existant est ajusté (raccourci ou supprimé)
  void addTimeSlot(WeekDay day, TimeSlot newSlot) {
    if (state.editedSchedule == null) return;

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
        _logger.d('Slot ${existing.formattedStart}-${existing.formattedEnd} supprimé (couvert par le nouveau)');
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
          _logger.d('Slot ajusté: ${existing.formattedStart}-${existing.formattedEnd} → ${existing.formattedStart}-${newSlot.formattedStart}');
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
          _logger.d('Slot coupé en deux: ${existing.formattedStart}-${newSlot.formattedStart} et ${newSlot.formattedEnd}-${existing.formattedEnd}');
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
        _logger.d('Slot ajusté: ${existing.formattedStart}-${existing.formattedEnd} → ${newSlot.formattedEnd}-${existing.formattedEnd}');
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

    _logger.i('ScheduleEditNotifier: added slot ${newSlot.formattedStart}-${newSlot.formattedEnd} to ${day.displayName}');
  }

  /// Met à jour un créneau existant
  void updateTimeSlot(WeekDay day, TimeSlot oldSlot, TimeSlot newSlot) {
    if (state.editedSchedule == null) return;

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

    _logger.i('ScheduleEditNotifier: updated slot on ${day.displayName}');
  }

  /// Supprime un créneau
  void removeTimeSlot(WeekDay day, TimeSlot slot) {
    if (state.editedSchedule == null) return;

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

    _logger.i('ScheduleEditNotifier: removed slot ${slot.formattedStart}-${slot.formattedEnd} from ${day.displayName}');
  }

  /// Modifie une transition existante
  void updateTransition(WeekDay day, int index, ScheduleTransition newTransition) {
    if (state.editedSchedule == null) return;

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

    _logger.i('ScheduleEditNotifier: updated transition $index on ${day.displayName}');
  }

  /// Supprime une transition
  void removeTransition(WeekDay day, int index) {
    if (state.editedSchedule == null) return;

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

    _logger.i('ScheduleEditNotifier: removed transition $index from ${day.displayName}');
  }

  /// Annule les modifications
  void revert() {
    if (state.originalSchedule == null) return;

    state = state.copyWith(
      editedSchedule: state.originalSchedule,
      hasChanges: false,
      clearClipboard: true,
      clearError: true,
      clearSuccess: true,
    );

    _logger.i('ScheduleEditNotifier: reverted changes');
  }

  /// Sauvegarde les modifications sur l'automate
  Future<bool> save() async {
    if (state.editedSchedule == null || !state.hasChanges) return false;

    final connectionState = _ref.read(activeConnectionProvider);
    if (!connectionState.isConnected) {
      state = state.copyWith(error: 'Non connecté');
      return false;
    }

    state = state.copyWith(isSaving: true, clearError: true, clearSuccess: true);

    try {
      final success = await connectionState.client!.writeWeeklySchedule(
        state.editedSchedule!.instance,
        state.editedSchedule!.weeklySchedule,
      );

      if (success) {
        // Mettre à jour l'original avec les nouvelles valeurs
        state = state.copyWith(
          originalSchedule: state.editedSchedule,
          hasChanges: false,
          isSaving: false,
          successMessage: 'Planning sauvegardé',
        );

        // Invalider le provider de détail pour forcer le rechargement
        _ref.invalidate(scheduleDetailProvider(state.editedSchedule!.instance));

        _logger.i('ScheduleEditNotifier: saved successfully');
        return true;
      } else {
        state = state.copyWith(
          isSaving: false,
          error: 'Échec de la sauvegarde',
        );
        _logger.e('ScheduleEditNotifier: save failed');
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: 'Erreur: $e',
      );
      _logger.e('ScheduleEditNotifier: save error: $e');
      return false;
    }
  }

  /// Reset complet
  void reset() {
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

/// Provider pour l'édition d'un schedule
final scheduleEditProvider = StateNotifierProvider<ScheduleEditNotifier, ScheduleEditState>((ref) {
  return ScheduleEditNotifier(ref);
});
