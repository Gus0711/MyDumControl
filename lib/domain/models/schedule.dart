import 'display_preferences.dart';

/// Sentinel pour distinguer "paramètre non fourni" de "null" dans copyWith
const Object _unset = Object();

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
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (DisplayPreferences.use24HourFormat || hour == null || minute == null) {
      return '${parts[0]}:${parts[1]}';
    }
    return DisplayPreferences.formatHourMinute(hour, minute);
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

  /// Types de valeur BACnet connus (ceux qui peuvent être réécrits tels quels)
  static const knownValueTypes = {'boolean', 'unsigned', 'signed', 'real', 'enumerated'};

  /// Type d'origine de la transition s'il est connu (sinon null)
  String? get knownType => (value != null && knownValueTypes.contains(type)) ? type : null;

  /// Convertit en format V1 pour l'API
  /// [fallbackType] : type à utiliser pour une transition sans type connu
  /// (nouvelle transition créée dans l'éditeur), en général le type des
  /// autres transitions du planning.
  Map<String, dynamic> toV1Json({String? fallbackType}) {
    if (value == null) {
      return {'time': time, 'value': null, 'type': 'null'};
    }

    String valueType;
    final resolved = knownType ?? (knownValueTypes.contains(fallbackType) ? fallbackType : null);
    if (resolved != null) {
      valueType = resolved;
    } else if (value is bool) {
      valueType = 'boolean';
    } else if (value is double) {
      valueType = 'real';
    } else {
      valueType = 'enumerated';
    }

    return {
      'time': time,
      'value': normalizeValueForType(value, valueType),
      'type': valueType,
    };
  }

  /// Convertit une valeur au type Dart attendu par un type BACnet
  /// (ex: 1 -> true pour boolean, true -> 1 pour unsigned/enumerated)
  static dynamic normalizeValueForType(dynamic value, String type) {
    if (value == null) return null;
    switch (type) {
      case 'boolean':
        if (value is bool) return value;
        if (value is num) return value != 0;
        if (value is String) return value == 'true' || value == 'active' || value == '1';
        return value;
      case 'unsigned':
      case 'signed':
      case 'enumerated':
        if (value is int) return value;
        if (value is bool) return value ? 1 : 0;
        if (value is double) return value.round();
        if (value is String) return int.tryParse(value) ?? value;
        return value;
      case 'real':
        if (value is double) return value;
        if (value is num) return value.toDouble();
        if (value is bool) return value ? 1.0 : 0.0;
        if (value is String) return double.tryParse(value) ?? value;
        return value;
      default:
        return value;
    }
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
    Object? value = _unset,
    String? type,
    String? key,
  }) {
    return ScheduleTransition(
      time: time ?? this.time,
      value: identical(value, _unset) ? this.value : value,
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
  String get formattedStart =>
      DisplayPreferences.formatHourMinute(startMinutes ~/ 60, startMinutes % 60);

  /// Heure de fin formatée (HH:mm)
  String get formattedEnd {
    if (endMinutes >= 1440) return DisplayPreferences.formatHourMinute(24, 0);
    return DisplayPreferences.formatHourMinute(endMinutes ~/ 60, endMinutes % 60);
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
    Object? value = _unset,
    bool? isAllDay,
  }) {
    return TimeSlot(
      startMinutes: startMinutes ?? this.startMinutes,
      endMinutes: endMinutes ?? this.endMinutes,
      value: identical(value, _unset) ? this.value : value,
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
  Map<String, dynamic> toV1Json({String? fallbackType}) {
    return {
      'timeValues': sortedTransitions.map((t) => t.toV1Json(fallbackType: fallbackType)).toList(),
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

  /// Type de valeur d'origine du planning : celui de la première transition
  /// non nulle dont le type est connu (lu sur l'automate). Null si inconnu.
  String? get dominantValueType {
    for (final day in WeekDay.values) {
      for (final t in getDay(day).transitions) {
        final type = t.knownType;
        if (type != null) return type;
      }
    }
    return null;
  }

  /// Convertit en format V1 pour l'API
  /// Les nouvelles transitions (sans type) prennent le type des transitions
  /// existantes, pour ne pas mélanger les types dans un même planning.
  Map<String, dynamic> toV1Json({String? fallbackType}) {
    final fallback = dominantValueType ?? fallbackType;
    return {
      'value': WeekDay.values.map((d) => getDay(d).toV1Json(fallbackType: fallback)).toList(),
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
    Object? description = _unset,
    WeeklySchedule? weeklySchedule,
    List<ScheduleStateText>? stateTexts,
    ScheduleValueType? valueType,
    Object? presentValue = _unset,
    Object? scheduleDefault = _unset,
  }) {
    return Schedule(
      instance: instance ?? this.instance,
      objectName: objectName ?? this.objectName,
      description: identical(description, _unset) ? this.description : description as String?,
      weeklySchedule: weeklySchedule ?? this.weeklySchedule,
      stateTexts: stateTexts ?? this.stateTexts,
      valueType: valueType ?? this.valueType,
      presentValue: identical(presentValue, _unset) ? this.presentValue : presentValue,
      scheduleDefault: identical(scheduleDefault, _unset) ? this.scheduleDefault : scheduleDefault,
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
