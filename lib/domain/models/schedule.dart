/// Jours de la semaine pour les plannings
enum WeekDay {
  monday('monday', 'Lundi', 'Lun'),
  tuesday('tuesday', 'Mardi', 'Mar'),
  wednesday('wednesday', 'Mercredi', 'Mer'),
  thursday('thursday', 'Jeudi', 'Jeu'),
  friday('friday', 'Vendredi', 'Ven'),
  saturday('saturday', 'Samedi', 'Sam'),
  sunday('sunday', 'Dimanche', 'Dim');

  final String apiKey;
  final String displayName;
  final String shortName;

  const WeekDay(this.apiKey, this.displayName, this.shortName);

  /// Index 0-6 (Lundi = 0) - utilise l'index natif de l'enum
  int get dayIndex => WeekDay.values.indexOf(this);

  /// Jours ouvrés (Lun-Ven)
  static List<WeekDay> get workDays => [monday, tuesday, wednesday, thursday, friday];

  /// Week-end
  static List<WeekDay> get weekend => [saturday, sunday];
}

/// Type de valeur d'un schedule (bool ou enumerated)
enum ScheduleValueType {
  boolean,
  enumerated;

  /// Détecte le type depuis une valeur
  static ScheduleValueType fromValue(dynamic value) {
    if (value is bool) return boolean;
    if (value is int) return enumerated;
    if (value is String) {
      if (value == 'true' || value == 'false') return boolean;
      if (value == 'active' || value == 'inactive') return boolean;
    }
    return enumerated;
  }
}

/// Transition horaire dans un planning
/// Représente un changement d'état à une heure donnée
class ScheduleTransition {
  /// Heure de la transition (format HH:mm:ss.ss)
  final String time;

  /// Valeur après la transition (bool, int, ou null pour "revert to default")
  final dynamic value;

  /// Type de valeur (boolean, enumerated, null)
  final String? type;

  /// Clé unique (utilisé en V2)
  final String? key;

  ScheduleTransition({
    required this.time,
    required this.value,
    this.type,
    this.key,
  });

  /// Heure en minutes depuis minuit (pour tri et comparaison)
  int get timeInMinutes {
    final parts = time.split(':');
    if (parts.length < 2) return 0;
    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    return hours * 60 + minutes;
  }

  /// Heure formatée pour l'affichage (HH:mm)
  String get formattedTime {
    final parts = time.split(':');
    if (parts.length < 2) return time;
    return '${parts[0]}:${parts[1]}';
  }

  /// Parse depuis le format V1
  factory ScheduleTransition.fromV1(Map<String, dynamic> json) {
    return ScheduleTransition(
      time: json['time']?.toString() ?? '00:00:00.00',
      value: json['value'],
      type: json['type']?.toString(),
    );
  }

  /// Parse depuis le format V2
  factory ScheduleTransition.fromV2(String key, Map<String, dynamic> json) {
    return ScheduleTransition(
      time: json['time']?.toString() ?? '00:00:00.00',
      value: json['value'],
      key: json['key']?.toString() ?? key,
    );
  }

  /// Convertit en format V1 pour l'API
  Map<String, dynamic> toV1Json() {
    String valueType = 'null';
    dynamic valueToSend = value;

    if (value == null) {
      valueType = 'null';
    } else if (value is bool) {
      valueType = 'boolean';
    } else if (value is int) {
      valueType = 'enumerated';
    }

    return {
      'time': time,
      'value': valueToSend,
      'type': valueType,
    };
  }

  /// Convertit en format V2 pour l'API
  Map<String, dynamic> toV2Json(String keyValue) {
    return {
      'time': time,
      'value': value,
      'key': keyValue,
    };
  }

  /// Copie avec modifications
  ScheduleTransition copyWith({
    String? time,
    dynamic value,
    String? type,
    String? key,
  }) {
    return ScheduleTransition(
      time: time ?? this.time,
      value: value ?? this.value,
      type: type ?? this.type,
      key: key ?? this.key,
    );
  }

  @override
  String toString() => 'ScheduleTransition($time, $value)';
}

/// Créneau horaire avec heure de début et de fin
/// Représentation utilisateur-friendly des transitions
class TimeSlot {
  /// Heure de début (en minutes depuis minuit, ex: 480 = 08:00)
  final int startMinutes;

  /// Heure de fin (en minutes depuis minuit, ex: 1080 = 18:00)
  /// Pour "toute la journée", utiliser 1440 (24:00 = minuit suivant)
  final int endMinutes;

  /// Valeur de l'état pendant ce créneau
  final dynamic value;

  /// Indique si c'est un créneau "toute la journée"
  final bool isAllDay;

  TimeSlot({
    required this.startMinutes,
    required this.endMinutes,
    required this.value,
    this.isAllDay = false,
  });

  /// Crée un créneau "toute la journée"
  factory TimeSlot.allDay(dynamic value) {
    return TimeSlot(
      startMinutes: 0,
      endMinutes: 1440, // 24:00
      value: value,
      isAllDay: true,
    );
  }

  /// Heure de début formatée (HH:mm)
  String get formattedStart {
    final hours = startMinutes ~/ 60;
    final mins = startMinutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
  }

  /// Heure de fin formatée (HH:mm)
  String get formattedEnd {
    if (endMinutes >= 1440) return '24:00';
    final hours = endMinutes ~/ 60;
    final mins = endMinutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
  }

  /// Durée en minutes
  int get durationMinutes => endMinutes - startMinutes;

  /// Durée formatée (ex: "2h30")
  String get formattedDuration {
    final hours = durationMinutes ~/ 60;
    final mins = durationMinutes % 60;
    if (hours == 0) return '${mins}min';
    if (mins == 0) return '${hours}h';
    return '${hours}h${mins.toString().padLeft(2, '0')}';
  }

  /// Convertit en transitions pour l'API
  /// Un créneau génère 2 transitions : début avec valeur, fin avec null
  List<ScheduleTransition> toTransitions() {
    final transitions = <ScheduleTransition>[];

    // Transition de début
    transitions.add(ScheduleTransition(
      time: minutesToTimeString(startMinutes),
      value: value,
    ));

    // Transition de fin (retour à null/défaut)
    // Pour 24:00 (minuit), on utilise 23:59:59.99
    final endTime = endMinutes >= 1440
        ? '23:59:59.99'
        : minutesToTimeString(endMinutes);

    transitions.add(ScheduleTransition(
      time: endTime,
      value: null,
    ));

    return transitions;
  }

  /// Convertit des minutes en string HH:mm:ss.00
  static String minutesToTimeString(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:00.00';
  }

  /// Parse un time string en minutes
  static int timeStringToMinutes(String time) {
    final parts = time.split(':');
    if (parts.length < 2) return 0;
    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    // Gérer 23:59:59 comme "fin de journée"
    if (hours == 23 && minutes == 59) return 1440;
    return hours * 60 + minutes;
  }

  /// Copie avec modifications
  TimeSlot copyWith({
    int? startMinutes,
    int? endMinutes,
    dynamic value,
    bool? isAllDay,
  }) {
    return TimeSlot(
      startMinutes: startMinutes ?? this.startMinutes,
      endMinutes: endMinutes ?? this.endMinutes,
      value: value ?? this.value,
      isAllDay: isAllDay ?? this.isAllDay,
    );
  }

  @override
  String toString() => 'TimeSlot($formattedStart - $formattedEnd, $value)';
}

/// Utilitaires pour convertir entre TimeSlots et Transitions
class TimeSlotConverter {
  /// Convertit une liste de transitions en créneaux
  /// Les transitions sont des paires: début=valeur, fin=null
  static List<TimeSlot> transitionsToSlots(List<ScheduleTransition> transitions) {
    if (transitions.isEmpty) return [];

    final slots = <TimeSlot>[];
    final sorted = List<ScheduleTransition>.from(transitions);
    sorted.sort((a, b) => a.timeInMinutes.compareTo(b.timeInMinutes));

    int? currentStart;
    dynamic currentValue;

    for (final transition in sorted) {
      final time = transition.timeInMinutes;

      if (transition.value != null) {
        // Début d'un nouveau créneau
        // Si un créneau était en cours, le fermer ici
        if (currentStart != null && currentValue != null && time > currentStart) {
          slots.add(TimeSlot(
            startMinutes: currentStart,
            endMinutes: time,
            value: currentValue,
            isAllDay: currentStart == 0 && time >= 1439,
          ));
        }
        currentStart = time;
        currentValue = transition.value;
      } else {
        // Fin d'un créneau (value == null)
        if (currentStart != null && currentValue != null) {
          int endMinutes = time;
          if (endMinutes >= 1439) endMinutes = 1440;

          if (endMinutes > currentStart) {
            slots.add(TimeSlot(
              startMinutes: currentStart,
              endMinutes: endMinutes,
              value: currentValue,
              isAllDay: currentStart == 0 && endMinutes >= 1439,
            ));
          }
          currentStart = null;
          currentValue = null;
        }
      }
    }

    // Fermer le dernier créneau s'il est encore ouvert
    if (currentStart != null && currentValue != null) {
      slots.add(TimeSlot(
        startMinutes: currentStart,
        endMinutes: 1440,
        value: currentValue,
        isAllDay: currentStart == 0,
      ));
    }

    // Trier par heure de début
    slots.sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
    return slots;
  }

  /// Convertit une liste de créneaux en transitions
  static List<ScheduleTransition> slotsToTransitions(List<TimeSlot> slots) {
    final transitions = <ScheduleTransition>[];

    // Trier les créneaux par heure de début
    final sorted = List<TimeSlot>.from(slots);
    sorted.sort((a, b) => a.startMinutes.compareTo(b.startMinutes));

    for (final slot in sorted) {
      transitions.addAll(slot.toTransitions());
    }

    // Trier les transitions résultantes
    transitions.sort((a, b) => a.timeInMinutes.compareTo(b.timeInMinutes));

    // Fusionner les transitions à la même heure (éviter duplicate-entry)
    // Si deux transitions ont la même heure, garder celle avec une valeur non-null
    final merged = <ScheduleTransition>[];
    for (final t in transitions) {
      if (merged.isEmpty) {
        merged.add(t);
      } else {
        final last = merged.last;
        if (last.timeInMinutes == t.timeInMinutes) {
          // Même heure : garder la valeur non-null, ou la nouvelle si les deux sont non-null
          if (last.value == null && t.value != null) {
            merged.removeLast();
            merged.add(t);
          }
          // Si t.value == null et last.value != null, on garde last (ne rien faire)
          // Si les deux sont non-null, on garde last (premier arrivé)
        } else {
          merged.add(t);
        }
      }
    }

    return merged;
  }
}

/// Planning d'un jour
class DaySchedule {
  final WeekDay day;
  final List<ScheduleTransition> transitions;

  DaySchedule({
    required this.day,
    required this.transitions,
  });

  /// Transitions triées par heure
  List<ScheduleTransition> get sortedTransitions {
    final sorted = List<ScheduleTransition>.from(transitions);
    sorted.sort((a, b) => a.timeInMinutes.compareTo(b.timeInMinutes));
    return sorted;
  }

  /// Vérifie si le jour a des transitions
  bool get hasTransitions => transitions.isNotEmpty;

  /// Nombre de transitions
  int get transitionCount => transitions.length;

  /// Parse depuis le format V1 (array à l'index du jour)
  factory DaySchedule.fromV1(WeekDay day, Map<String, dynamic>? json) {
    final transitions = <ScheduleTransition>[];

    if (json != null && json['timeValues'] is List) {
      final timeValues = json['timeValues'] as List;
      for (final tv in timeValues) {
        if (tv is Map<String, dynamic>) {
          transitions.add(ScheduleTransition.fromV1(tv));
        }
      }
    }

    return DaySchedule(day: day, transitions: transitions);
  }

  /// Parse depuis le format V2 (objet avec "transitions")
  factory DaySchedule.fromV2(WeekDay day, Map<String, dynamic>? json) {
    final transitions = <ScheduleTransition>[];

    if (json != null && json['transitions'] is Map) {
      final transitionsMap = json['transitions'] as Map<String, dynamic>;
      transitionsMap.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          transitions.add(ScheduleTransition.fromV2(key, value));
        }
      });
    }

    return DaySchedule(day: day, transitions: transitions);
  }

  /// Crée un jour vide
  factory DaySchedule.empty(WeekDay day) {
    return DaySchedule(day: day, transitions: []);
  }

  /// Convertit en format V1 pour l'API
  Map<String, dynamic> toV1Json() {
    return {
      'timeValues': sortedTransitions.map((t) => t.toV1Json()).toList(),
    };
  }

  /// Convertit en format V2 pour l'API
  Map<String, dynamic> toV2Json() {
    final transitionsMap = <String, dynamic>{};
    final sorted = sortedTransitions;

    for (int i = 0; i < sorted.length; i++) {
      final key = (i + 1).toString();
      transitionsMap[key] = sorted[i].toV2Json(key);
    }

    return {'transitions': transitionsMap};
  }

  /// Copie avec modifications
  DaySchedule copyWith({
    WeekDay? day,
    List<ScheduleTransition>? transitions,
  }) {
    return DaySchedule(
      day: day ?? this.day,
      transitions: transitions ?? List.from(this.transitions),
    );
  }
}

/// Planning hebdomadaire complet
class WeeklySchedule {
  final Map<WeekDay, DaySchedule> days;

  WeeklySchedule({required this.days});

  /// Récupère le planning d'un jour
  DaySchedule getDay(WeekDay day) => days[day] ?? DaySchedule.empty(day);

  /// Liste des jours dans l'ordre
  List<DaySchedule> get daysList => WeekDay.values.map((d) => getDay(d)).toList();

  /// Parse depuis le format V1
  /// V1 retourne un array de 7 éléments (Lundi à Dimanche, index 0-6)
  factory WeeklySchedule.fromV1(Map<String, dynamic> json) {
    final days = <WeekDay, DaySchedule>{};
    final value = json['value'];

    if (value is List && value.length == 7) {
      for (int i = 0; i < 7; i++) {
        final weekDay = WeekDay.values[i];
        final dayData = value[i] as Map<String, dynamic>?;
        days[weekDay] = DaySchedule.fromV1(weekDay, dayData);
      }
    } else {
      // Créer des jours vides si pas de données
      for (final day in WeekDay.values) {
        days[day] = DaySchedule.empty(day);
      }
    }

    return WeeklySchedule(days: days);
  }

  /// Parse depuis le format V2
  /// V2 retourne un objet avec les noms des jours en anglais
  factory WeeklySchedule.fromV2(Map<String, dynamic> json) {
    final days = <WeekDay, DaySchedule>{};

    for (final day in WeekDay.values) {
      final dayData = json[day.apiKey] as Map<String, dynamic>?;
      days[day] = DaySchedule.fromV2(day, dayData);
    }

    return WeeklySchedule(days: days);
  }

  /// Crée un planning vide
  factory WeeklySchedule.empty() {
    final days = <WeekDay, DaySchedule>{};
    for (final day in WeekDay.values) {
      days[day] = DaySchedule.empty(day);
    }
    return WeeklySchedule(days: days);
  }

  /// Convertit en format V1 pour l'API
  Map<String, dynamic> toV1Json() {
    return {
      'value': WeekDay.values.map((d) => getDay(d).toV1Json()).toList(),
    };
  }

  /// Convertit en format V2 pour l'API
  Map<String, dynamic> toV2Json() {
    final result = <String, dynamic>{};
    for (final day in WeekDay.values) {
      result[day.apiKey] = getDay(day).toV2Json();
    }
    return result;
  }

  /// Copie avec modification d'un jour
  WeeklySchedule copyWithDay(WeekDay day, DaySchedule newDaySchedule) {
    final newDays = Map<WeekDay, DaySchedule>.from(days);
    newDays[day] = newDaySchedule;
    return WeeklySchedule(days: newDays);
  }

  /// Copie un jour vers d'autres jours
  WeeklySchedule copyDayTo(WeekDay source, List<WeekDay> targets) {
    final sourceDay = getDay(source);
    final newDays = Map<WeekDay, DaySchedule>.from(days);

    for (final target in targets) {
      if (target != source) {
        newDays[target] = sourceDay.copyWith(day: target);
      }
    }

    return WeeklySchedule(days: newDays);
  }
}

/// État textuel d'un schedule (ex: "Occupied", "Unoccupied")
class ScheduleStateText {
  final int index;
  final String text;

  ScheduleStateText({required this.index, required this.text});

  factory ScheduleStateText.fromJson(int index, dynamic value) {
    return ScheduleStateText(
      index: index,
      text: value?.toString() ?? 'État $index',
    );
  }
}

/// Schedule BACnet complet
class Schedule {
  final int instance;
  final String objectName;
  final String? description;
  final WeeklySchedule weeklySchedule;
  final List<ScheduleStateText> stateTexts;
  final ScheduleValueType valueType;
  final dynamic presentValue;
  final dynamic scheduleDefault;

  Schedule({
    required this.instance,
    required this.objectName,
    this.description,
    required this.weeklySchedule,
    this.stateTexts = const [],
    this.valueType = ScheduleValueType.boolean,
    this.presentValue,
    this.scheduleDefault,
  });

  /// Identifiant unique
  String get objectId => 'SCH:$instance';

  /// Récupère le texte pour une valeur donnée
  String getStateText(dynamic value) {
    if (value == null) return 'Auto';

    // Normaliser la valeur en int si possible
    int? intValue;
    if (value is int) {
      intValue = value;
    } else if (value is bool) {
      intValue = value ? 1 : 0;
    } else if (value == 'active' || value == 'true') {
      intValue = 1;
    } else if (value == 'inactive' || value == 'false') {
      intValue = 0;
    }

    if (valueType == ScheduleValueType.boolean) {
      if (intValue == 1) {
        // Chercher le texte pour l'état actif (généralement index 1)
        final activeText = stateTexts.where((s) => s.index == 1).firstOrNull;
        return activeText?.text ?? 'Actif';
      } else {
        // Chercher le texte pour l'état inactif (généralement index 0)
        final inactiveText = stateTexts.where((s) => s.index == 0).firstOrNull;
        return inactiveText?.text ?? 'Inactif';
      }
    }

    // Pour les valeurs énumérées
    if (intValue != null) {
      final stateText = stateTexts.where((s) => s.index == intValue).firstOrNull;
      return stateText?.text ?? 'État $intValue';
    }

    return value.toString();
  }

  /// Liste des valeurs possibles pour ce schedule
  List<({dynamic value, String text})> get possibleValues {
    if (valueType == ScheduleValueType.boolean) {
      return [
        (value: 1, text: getStateText(1)),
        (value: 0, text: getStateText(0)),
        (value: null, text: 'Auto'),
      ];
    }

    // Pour les énumérés, utiliser les state texts
    final values = <({dynamic value, String text})>[];
    if (stateTexts.isNotEmpty) {
      for (final state in stateTexts) {
        values.add((value: state.index, text: state.text));
      }
    } else {
      // Fallback: générer des états par défaut si pas de state-texts
      // Analyser le weeklySchedule pour trouver les valeurs utilisées
      final usedValues = <int>{};
      for (final day in weeklySchedule.days.values) {
        for (final transition in day.transitions) {
          if (transition.value is int) {
            usedValues.add(transition.value as int);
          }
        }
      }
      // Générer les états pour les valeurs trouvées
      // BACnet multistate commence à 1, pas 0
      final minVal = usedValues.isEmpty ? 1 : usedValues.reduce((a, b) => a < b ? a : b);
      final maxVal = usedValues.isEmpty ? 4 : usedValues.reduce((a, b) => a > b ? a : b);
      final startVal = minVal < 1 ? minVal : 1; // Si données utilisent 0, l'inclure
      for (int i = startVal; i <= maxVal; i++) {
        values.add((value: i, text: 'État $i'));
      }
    }
    values.add((value: null, text: 'Auto'));
    return values;
  }

  /// Copie avec modifications
  Schedule copyWith({
    int? instance,
    String? objectName,
    String? description,
    WeeklySchedule? weeklySchedule,
    List<ScheduleStateText>? stateTexts,
    ScheduleValueType? valueType,
    dynamic presentValue,
    dynamic scheduleDefault,
  }) {
    return Schedule(
      instance: instance ?? this.instance,
      objectName: objectName ?? this.objectName,
      description: description ?? this.description,
      weeklySchedule: weeklySchedule ?? this.weeklySchedule,
      stateTexts: stateTexts ?? this.stateTexts,
      valueType: valueType ?? this.valueType,
      presentValue: presentValue ?? this.presentValue,
      scheduleDefault: scheduleDefault ?? this.scheduleDefault,
    );
  }
}

/// Résumé d'un schedule (pour la liste)
class ScheduleSummary {
  final int instance;
  final String objectName;
  final String? description;
  final dynamic presentValue;
  final ScheduleValueType valueType;

  ScheduleSummary({
    required this.instance,
    required this.objectName,
    this.description,
    this.presentValue,
    this.valueType = ScheduleValueType.boolean,
  });

  String get objectId => 'SCH:$instance';

  factory ScheduleSummary.fromV1(int instance, Map<String, dynamic> json) {
    final presentValue = json['presentValue'] ?? json['present-value'];
    return ScheduleSummary(
      instance: instance,
      objectName: json['objectName']?.toString() ??
                  json['object-name']?.toString() ??
                  'Schedule $instance',
      description: json['description']?.toString(),
      presentValue: presentValue,
      valueType: ScheduleValueType.fromValue(presentValue),
    );
  }

  factory ScheduleSummary.fromV2(int instance, Map<String, dynamic> json) {
    final presentValue = json['present-value'] ?? json['presentValue'];
    return ScheduleSummary(
      instance: instance,
      objectName: json['object-name']?.toString() ??
                  json['objectName']?.toString() ??
                  'Schedule $instance',
      description: json['description']?.toString(),
      presentValue: presentValue,
      valueType: ScheduleValueType.fromValue(presentValue),
    );
  }
}

// =========================================================================
// BACnet Schedule Converters
// =========================================================================

/// Import nécessaire pour les types BACnet - à utiliser avec:
/// import 'package:my_dum_control/data/services/bacnet_service.dart';

/// Extension pour convertir les modèles Schedule vers/depuis le format BACnet natif
class BacnetScheduleConverter {
  /// Convertit un DecodedWeeklySchedule BACnet en WeeklySchedule du modèle
  static WeeklySchedule fromBacnetWeeklySchedule(
    dynamic decodedWeeklySchedule, {
    ScheduleValueType valueType = ScheduleValueType.enumerated,
  }) {
    final days = <WeekDay, DaySchedule>{};

    // decodedWeeklySchedule.days est une List<DecodedDailySchedule>
    if (decodedWeeklySchedule != null && decodedWeeklySchedule.days != null) {
      for (int i = 0; i < 7 && i < decodedWeeklySchedule.days.length; i++) {
        final weekDay = WeekDay.values[i];
        final decodedDay = decodedWeeklySchedule.days[i];

        final transitions = <ScheduleTransition>[];
        if (decodedDay.timeValues != null) {
          for (final tv in decodedDay.timeValues) {
            transitions.add(ScheduleTransition(
              time: tv.timeString,
              value: tv.value,
              type: _valueTagToTypeString(tv.valueTag),
            ));
          }
        }

        days[weekDay] = DaySchedule(day: weekDay, transitions: transitions);
      }
    }

    // Remplir les jours manquants
    for (final day in WeekDay.values) {
      days.putIfAbsent(day, () => DaySchedule.empty(day));
    }

    return WeeklySchedule(days: days);
  }

  /// Convertit le type de tag BACnet en string pour le modèle
  static String _valueTagToTypeString(int valueTag) {
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

  /// Crée un BacnetScheduleInfo depuis le modèle Schedule
  /// Note: Nécessite l'import de bacnet_service.dart pour BacnetWeeklySchedule
  static dynamic toBacnetWeeklySchedule(
    WeeklySchedule weeklySchedule, {
    bool useEnumerated = true, // true = enumerated (9), false = boolean (1)
  }) {
    // Cette méthode retourne un objet compatible avec BacnetWeeklySchedule
    // L'appelant doit créer le BacnetWeeklySchedule avec les données retournées
    return _WeeklyScheduleData(
      days: WeekDay.values.map((weekDay) {
        final daySchedule = weeklySchedule.getDay(weekDay);
        return _DailyScheduleData(
          timeValues: daySchedule.sortedTransitions.map((transition) {
            return _TimeValueData(
              time: transition.time,
              value: transition.value,
              useEnumerated: useEnumerated,
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}

/// Données internes pour la conversion (évite la dépendance circulaire)
class _WeeklyScheduleData {
  final List<_DailyScheduleData> days;
  _WeeklyScheduleData({required this.days});
}

class _DailyScheduleData {
  final List<_TimeValueData> timeValues;
  _DailyScheduleData({required this.timeValues});
}

class _TimeValueData {
  final String time;
  final dynamic value;
  final bool useEnumerated;
  _TimeValueData({required this.time, required this.value, required this.useEnumerated});
}

/// Extension sur Schedule pour la conversion BACnet
extension ScheduleBacnetExtension on Schedule {
  /// Crée un Schedule depuis un BacnetScheduleInfo
  static Schedule fromBacnetInfo(
    dynamic bacnetInfo, {
    ScheduleValueType? forceValueType,
  }) {
    // bacnetInfo est de type BacnetScheduleInfo
    final valueType = forceValueType ?? _detectValueType(bacnetInfo.presentValue);

    WeeklySchedule weeklySchedule;
    if (bacnetInfo.weeklySchedule != null) {
      weeklySchedule = BacnetScheduleConverter.fromBacnetWeeklySchedule(
        bacnetInfo.weeklySchedule,
        valueType: valueType,
      );
    } else {
      weeklySchedule = WeeklySchedule.empty();
    }

    // Parser les state texts
    final stateTexts = <ScheduleStateText>[];
    if (bacnetInfo.stateTexts != null) {
      for (int i = 0; i < bacnetInfo.stateTexts.length; i++) {
        stateTexts.add(ScheduleStateText(index: i + 1, text: bacnetInfo.stateTexts[i]));
      }
    }

    return Schedule(
      instance: bacnetInfo.instance,
      objectName: bacnetInfo.objectName,
      description: bacnetInfo.description,
      weeklySchedule: weeklySchedule,
      stateTexts: stateTexts,
      valueType: valueType,
      presentValue: bacnetInfo.presentValue,
      scheduleDefault: bacnetInfo.scheduleDefault,
    );
  }

  static ScheduleValueType _detectValueType(dynamic value) {
    if (value == null) return ScheduleValueType.enumerated;
    if (value is bool) return ScheduleValueType.boolean;
    return ScheduleValueType.enumerated;
  }
}
