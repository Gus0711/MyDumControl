import '../../../data/services/bacnet/bacnet_constants.dart';

/// Types d'objets BACnet
enum BacnetObjectType {
  analogInput('analog-input', 'AI', 'Entrée Analogique'),
  analogOutput('analog-output', 'AO', 'Sortie Analogique'),
  analogValue('analog-value', 'AV', 'Valeur Analogique'),
  binaryInput('binary-input', 'BI', 'Entrée Binaire'),
  binaryOutput('binary-output', 'BO', 'Sortie Binaire'),
  binaryValue('binary-value', 'BV', 'Valeur Binaire'),
  multiStateInput('multi-state-input', 'MSI', 'Entrée Multi-états'),
  multiStateOutput('multi-state-output', 'MSO', 'Sortie Multi-états'),
  multiStateValue('multi-state-value', 'MSV', 'Valeur Multi-états'),
  schedule('schedule', 'SCH', 'Horaire'),
  calendar('calendar', 'CAL', 'Calendrier'),
  trendLog('trend-log', 'TL', 'Historique'),
  notificationClass('notification-class', 'NC', 'Classe de notification'),
  device('device', 'DEV', 'Appareil');

  final String apiName;
  final String shortName;
  final String displayName;

  const BacnetObjectType(this.apiName, this.shortName, this.displayName);

  static BacnetObjectType? fromApiName(String name) {
    try {
      return BacnetObjectType.values.firstWhere((e) => e.apiName == name);
    } catch (_) {
      return null;
    }
  }

  /// Trouve le type par shortName (ex: "AV", "BI", "MSV")
  static BacnetObjectType? fromShortName(String name) {
    try {
      return BacnetObjectType.values.firstWhere(
        (e) => e.shortName.toLowerCase() == name.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Trouve le type par n'importe quel format (apiName, shortName, ou name)
  static BacnetObjectType? fromAnyName(String name) {
    // Essayer apiName d'abord (analog-value, binary-input, etc.)
    var type = fromApiName(name);
    if (type != null) return type;

    // Essayer shortName (AV, BI, etc.)
    type = fromShortName(name);
    if (type != null) return type;

    // Essayer le nom de l'enum (analogValue, binaryInput, etc.)
    try {
      return BacnetObjectType.values.firstWhere(
        (e) => e.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Vérifie si c'est un type binaire
  bool get isBinary =>
      this == BacnetObjectType.binaryInput ||
      this == BacnetObjectType.binaryOutput ||
      this == BacnetObjectType.binaryValue;

  /// Vérifie si c'est un type analogique
  bool get isAnalog =>
      this == BacnetObjectType.analogInput ||
      this == BacnetObjectType.analogOutput ||
      this == BacnetObjectType.analogValue;

  /// Vérifie si c'est un type multi-états
  bool get isMultiState =>
      this == BacnetObjectType.multiStateInput ||
      this == BacnetObjectType.multiStateOutput ||
      this == BacnetObjectType.multiStateValue;

  /// Vérifie si c'est une entrée
  bool get isInput =>
      this == BacnetObjectType.analogInput ||
      this == BacnetObjectType.binaryInput ||
      this == BacnetObjectType.multiStateInput;

  /// Vérifie si c'est une sortie
  bool get isOutput =>
      this == BacnetObjectType.analogOutput ||
      this == BacnetObjectType.binaryOutput ||
      this == BacnetObjectType.multiStateOutput;

  /// Vérifie si c'est une valeur
  bool get isValue =>
      this == BacnetObjectType.analogValue ||
      this == BacnetObjectType.binaryValue ||
      this == BacnetObjectType.multiStateValue;

  /// Vérifie si l'objet est commandable (peut avoir un priority-array)
  /// Les entrées (inputs) ne sont pas commandables via priority-array
  bool get isCommandable =>
      this == BacnetObjectType.analogOutput ||
      this == BacnetObjectType.analogValue ||
      this == BacnetObjectType.binaryOutput ||
      this == BacnetObjectType.binaryValue ||
      this == BacnetObjectType.multiStateOutput ||
      this == BacnetObjectType.multiStateValue;

  /// Vérifie si l'objet supporte l'écriture simple (sans priorité)
  /// Seules les Values supportent l'écriture simple
  bool get canWriteSimple => isValue;

  /// Vérifie si l'objet supporte le forçage (écriture avec priorité)
  /// Les Outputs et Values peuvent être forcés via priority-array
  bool get canOverride => isCommandable;

  /// Vérifie si l'objet peut être forcé via out-of-service
  /// Les entrées peuvent être forcées en mettant out-of-service à true
  bool get canForceViaOutOfService => isInput;

  /// Vérifie si l'objet peut être modifié (forcé ou écrit)
  /// Tous les types peuvent être modifiés d'une façon ou d'une autre
  bool get canBeModified => true;

  /// Vérifie si l'objet est en lecture seule (ne peut pas être modifié du tout)
  bool get isReadOnly => false;
}

/// Objet BACnet générique
class BacnetObject {
  final BacnetObjectType type;
  final int instance;
  final String objectName;
  final String? description;
  final dynamic presentValue;
  final String? units;
  final bool? outOfService;
  final String? reliability;
  final Map<String, dynamic>? rawProperties;

  /// Priority array brut (16 positions)
  final String? priorityArrayRaw;

  /// Indique si le point est forcé (position 1-15 non null)
  final bool isOverridden;

  /// Niveau de priorité du forçage (1-15, null si pas forcé)
  final int? overridePriority;

  /// Valeur du forçage
  final dynamic overrideValue;

  /// Texte affiché quand la valeur binaire est active (ex: "Marche", "ON")
  final String? activeText;

  /// Texte affiché quand la valeur binaire est inactive (ex: "Arrêt", "OFF")
  final String? inactiveText;

  /// Liste des libellés pour les valeurs multi-états (state-text)
  /// L'index 0 correspond à present-value = 1 (BACnet est indexé à partir de 1)
  final List<String>? stateText;

  /// Indique si le point est en alarme (status-flags.in-alarm)
  final bool inAlarm;

  /// Timestamp de l'alarme (event-time-stamps.to-off-normal ou to-fault)
  final DateTime? alarmTimestamp;

  /// Message d'alarme (event-message-texts)
  final String? alarmMessage;

  BacnetObject({
    required this.type,
    required this.instance,
    required this.objectName,
    this.description,
    this.presentValue,
    this.units,
    this.outOfService,
    this.reliability,
    this.rawProperties,
    this.priorityArrayRaw,
    this.isOverridden = false,
    this.overridePriority,
    this.overrideValue,
    this.activeText,
    this.inactiveText,
    this.stateText,
    this.inAlarm = false,
    this.alarmTimestamp,
    this.alarmMessage,
  });

  /// Identifiant unique de l'objet
  String get objectId => '${type.shortName}:$instance';

  /// Nom d'affichage : description si non vide, sinon objectName
  /// Permet à l'utilisateur de personnaliser l'affichage sans impacter l'intégrateur
  String get displayName =>
      (description != null && description!.isNotEmpty) ? description! : objectName;

  /// Valeur formatée pour l'affichage
  String get formattedValue {
    if (presentValue == null) return '-';

    if (type == BacnetObjectType.binaryInput ||
        type == BacnetObjectType.binaryOutput ||
        type == BacnetObjectType.binaryValue) {
      // Valeurs binaires : utiliser activeText/inactiveText si disponibles
      final isActive = _isBinaryValueActive(presentValue);

      if (isActive) {
        return activeText ?? 'Actif';
      } else {
        return inactiveText ?? 'Inactif';
      }
    }

    // Valeurs multi-états : utiliser stateText si disponible
    if (type.isMultiState) {
      return formattedMultiStateValue;
    }

    // Valeurs analogiques avec unité
    if (presentValue is num) {
      final value = presentValue as num;
      final formatted = value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
      return units != null ? '$formatted $units' : formatted;
    }

    return presentValue.toString();
  }

  /// Valeur formatée pour les multi-états (avec libellé)
  String get formattedMultiStateValue {
    if (presentValue == null) return '-';

    // Convertir la valeur en int
    final int stateIndex;
    if (presentValue is int) {
      stateIndex = presentValue;
    } else if (presentValue is num) {
      stateIndex = presentValue.toInt();
    } else {
      return presentValue.toString();
    }

    // BACnet multistate est indexé à partir de 1
    // stateText[0] = état 1, stateText[1] = état 2, etc.
    if (stateText != null && stateText!.isNotEmpty) {
      final arrayIndex = stateIndex - 1;
      if (arrayIndex >= 0 && arrayIndex < stateText!.length) {
        return stateText![arrayIndex];
      }
    }

    // Pas de libellé disponible, afficher juste la valeur
    return stateIndex.toString();
  }

  /// Libellé de l'état actuel pour les multi-états (null si pas disponible)
  String? get currentStateLabel {
    if (!type.isMultiState || presentValue == null || stateText == null) {
      return null;
    }

    final int stateIndex;
    if (presentValue is int) {
      stateIndex = presentValue;
    } else if (presentValue is num) {
      stateIndex = presentValue.toInt();
    } else {
      return null;
    }

    final arrayIndex = stateIndex - 1;
    if (arrayIndex >= 0 && arrayIndex < stateText!.length) {
      return stateText![arrayIndex];
    }
    return null;
  }

  /// Vérifie si une valeur binaire est active
  static bool _isBinaryValueActive(dynamic value) {
    if (value == null) return false;
    if (value == true) return true;
    if (value == 1) return true;
    if (value is String) {
      final lower = value.toLowerCase();
      return lower == 'active' || lower == 'true' || lower == '1' || lower == 'on';
    }
    return false;
  }

  factory BacnetObject.fromJson(BacnetObjectType type, int instance, Map<String, dynamic> json) {
    return BacnetObject(
      type: type,
      instance: instance,
      objectName: json['object-name'] ?? json['objectName'] ?? 'Sans nom',
      description: json['description'],
      presentValue: json['present-value'] ?? json['presentValue'],
      units: _parseUnits(json['units']),
      outOfService: json['out-of-service'] ?? json['outOfService'],
      reliability: json['reliability'],
      rawProperties: json,
    );
  }

  static String? _parseUnits(dynamic units) {
    if (units == null) return null;

    // Utiliser la classe BacnetUnits pour la conversion
    // Elle gère à la fois les codes numériques (62 -> °C) et les textes (DegreesCelsius -> °C)
    final result = BacnetUnits.getUnitText(units);
    if (result.isEmpty) return null;

    // Fallback sur notre table locale si BacnetUnits n'a pas trouvé
    if (result == units.toString()) {
      String unitStr;
      if (units is String) {
        unitStr = units;
      } else if (units is Map) {
        unitStr = units['value']?.toString() ?? '';
      } else {
        unitStr = units.toString();
      }
      return convertUnitSymbol(unitStr);
    }

    return result;
  }

  /// Convertit un nom d'unité BACnet en symbole court
  /// Ex: "DegreesCelsius" -> "°C", "Percent" -> "%"
  static String convertUnitSymbol(String unitName) {
    return _bacnetUnitSymbols[unitName] ?? unitName;
  }

  /// Mapping des noms enum BACnet vers les symboles courts
  static const Map<String, String> _bacnetUnitSymbols = {
    // Température
    'DegreesCelsius': '°C',
    'DegreeCelsius': '°C',
    'degreesCelsius': '°C',
    'DegreesFahrenheit': '°F',
    'DegreeFahrenheit': '°F',
    'degreesFahrenheit': '°F',
    'DegreesKelvin': 'K',
    'DeltaDegreesFahrenheit': 'Δ°F',
    'DeltaDegreesCelsius': 'Δ°C',
    'DeltaDegreesKelvin': 'ΔK',

    // Pourcentage
    'Percent': '%',
    'percent': '%',
    'PercentRelativeHumidity': '%RH',
    'percentRelativeHumidity': '%RH',

    // Pression
    'Pascals': 'Pa',
    'pascals': 'Pa',
    'Kilopascals': 'kPa',
    'kilopascals': 'kPa',
    'Bars': 'bar',
    'Millibars': 'mbar',
    'PoundsForcePerSquareInch': 'psi',
    'InchesOfWater': 'inH₂O',
    'MillimetersOfWater': 'mmH₂O',
    'CentimetersOfWater': 'cmH₂O',
    'InchesOfMercury': 'inHg',
    'MillimetersOfMercury': 'mmHg',

    // Débit volumique
    'CubicMetersPerHour': 'm³/h',
    'cubicMetersPerHour': 'm³/h',
    'CubicMetersPerMinute': 'm³/min',
    'CubicMetersPerSecond': 'm³/s',
    'CubicFeetPerMinute': 'CFM',
    'cubicFeetPerMinute': 'CFM',
    'CubicFeetPerHour': 'ft³/h',
    'CubicFeetPerSecond': 'ft³/s',
    'LitersPerSecond': 'L/s',
    'litersPerSecond': 'L/s',
    'LitersPerMinute': 'L/min',
    'litersPerMinute': 'L/min',
    'LitersPerHour': 'L/h',
    'GallonsPerMinute': 'GPM',
    'GallonsPerHour': 'GPH',

    // Puissance / Énergie
    'Watts': 'W',
    'watts': 'W',
    'Kilowatts': 'kW',
    'kilowatts': 'kW',
    'Megawatts': 'MW',
    'BtusPerHour': 'BTU/h',
    'Horsepower': 'HP',
    'TonsRefrigeration': 'TR',
    'KilowattHours': 'kWh',
    'kilowattHours': 'kWh',
    'WattHours': 'Wh',
    'MegawattHours': 'MWh',
    'Joules': 'J',
    'Kilojoules': 'kJ',
    'KilojoulesPerKilogram': 'kJ/kg',
    'JoulesPerKilogramDryAir': 'J/kg',
    'BtusPerPound': 'BTU/lb',
    'BtusPerPoundDryAir': 'BTU/lb',

    // Courant / Tension / Électrique
    'Volts': 'V',
    'volts': 'V',
    'Millivolts': 'mV',
    'Kilovolts': 'kV',
    'Amperes': 'A',
    'amperes': 'A',
    'Milliamperes': 'mA',
    'Ohms': 'Ω',
    'Kilohms': 'kΩ',
    'Megohms': 'MΩ',
    'VoltAmperes': 'VA',
    'KilovoltAmperes': 'kVA',
    'VoltAmperesReactive': 'VAR',
    'KilovoltAmperesReactive': 'kVAR',
    'PowerFactor': 'PF',
    'Hertz': 'Hz',
    'hertz': 'Hz',
    'Kilohertz': 'kHz',
    'Megahertz': 'MHz',

    // Temps
    'Seconds': 's',
    'seconds': 's',
    'Minutes': 'min',
    'minutes': 'min',
    'Hours': 'h',
    'hours': 'h',
    'Days': 'j',
    'Weeks': 'sem',
    'Months': 'mois',
    'Years': 'ans',

    // Vitesse
    'MetersPerSecond': 'm/s',
    'metersPerSecond': 'm/s',
    'MetersPerMinute': 'm/min',
    'KilometersPerHour': 'km/h',
    'FeetPerSecond': 'ft/s',
    'FeetPerMinute': 'ft/min',
    'MilesPerHour': 'mph',

    // Masse / Volume
    'Kilograms': 'kg',
    'Grams': 'g',
    'Milligrams': 'mg',
    'Pounds': 'lb',
    'Liters': 'L',
    'Milliliters': 'mL',
    'CubicMeters': 'm³',
    'CubicFeet': 'ft³',
    'Gallons': 'gal',

    // Concentration
    'PartsPerMillion': 'ppm',
    'partsPerMillion': 'ppm',
    'PartsPerBillion': 'ppb',
    'GramsPerKilogram': 'g/kg',
    'GramsPerCubicMeter': 'g/m³',
    'MilligramsPerLiter': 'mg/L',
    'MicrogramsPerCubicMeter': 'µg/m³',

    // Luminosité
    'Lux': 'lux',
    'Lumens': 'lm',
    'Candelas': 'cd',
    'FootCandles': 'fc',

    // Autres
    'RevolutionsPerMinute': 'RPM',
    'revolutionsPerMinute': 'RPM',
    'DegreesAngular': '°',
    'Radians': 'rad',
    'RadiansPerSecond': 'rad/s',
    'NoUnits': '',
    'noUnits': '',
    'No-Units': '',
  };

  /// Crée une copie avec les informations de forçage mises à jour
  BacnetObject copyWith({
    BacnetObjectType? type,
    int? instance,
    String? objectName,
    String? description,
    dynamic presentValue,
    String? units,
    bool? outOfService,
    String? reliability,
    Map<String, dynamic>? rawProperties,
    String? priorityArrayRaw,
    bool? isOverridden,
    int? overridePriority,
    dynamic overrideValue,
    String? activeText,
    String? inactiveText,
    List<String>? stateText,
    bool? inAlarm,
    DateTime? alarmTimestamp,
    String? alarmMessage,
  }) {
    return BacnetObject(
      type: type ?? this.type,
      instance: instance ?? this.instance,
      objectName: objectName ?? this.objectName,
      description: description ?? this.description,
      presentValue: presentValue ?? this.presentValue,
      units: units ?? this.units,
      outOfService: outOfService ?? this.outOfService,
      reliability: reliability ?? this.reliability,
      rawProperties: rawProperties ?? this.rawProperties,
      priorityArrayRaw: priorityArrayRaw ?? this.priorityArrayRaw,
      isOverridden: isOverridden ?? this.isOverridden,
      overridePriority: overridePriority ?? this.overridePriority,
      overrideValue: overrideValue ?? this.overrideValue,
      activeText: activeText ?? this.activeText,
      inactiveText: inactiveText ?? this.inactiveText,
      stateText: stateText ?? this.stateText,
      inAlarm: inAlarm ?? this.inAlarm,
      alarmTimestamp: alarmTimestamp ?? this.alarmTimestamp,
      alarmMessage: alarmMessage ?? this.alarmMessage,
    );
  }

  /// Parse le priority-array et retourne les infos de forçage
  /// Format V1: "{real=100.0, null=Null, null=Null, ...}"
  /// Format V2: [null, null, null, ..., valeur] (tableau JSON)
  static OverrideInfo parsePriorityArray(dynamic priorityArrayRaw) {
    if (priorityArrayRaw == null) {
      return const OverrideInfo(isOverridden: false);
    }

    // Format V2: Liste JSON
    if (priorityArrayRaw is List) {
      return _parsePriorityArrayV2(priorityArrayRaw);
    }

    // Format V1: String
    if (priorityArrayRaw is String) {
      return _parsePriorityArrayV1(priorityArrayRaw);
    }

    return const OverrideInfo(isOverridden: false);
  }

  /// Parse le format V1: "{real=100.0, null=Null, null=Null, ...}"
  static OverrideInfo _parsePriorityArrayV1(String priorityArrayRaw) {
    if (priorityArrayRaw.isEmpty) {
      return const OverrideInfo(isOverridden: false);
    }

    // Nettoyer la chaîne: enlever les accolades
    String cleaned = priorityArrayRaw;
    if (cleaned.startsWith('{')) cleaned = cleaned.substring(1);
    if (cleaned.endsWith('}')) cleaned = cleaned.substring(0, cleaned.length - 1);

    // Séparer par virgules
    final positions = cleaned.split(',');

    // Vérifier les positions 1-15 (indices 0-14)
    for (int i = 0; i < 15 && i < positions.length; i++) {
      final position = positions[i].trim();

      // Si la position ne contient pas "null=", c'est un forçage
      if (!position.toLowerCase().contains('null=')) {
        // Parser la valeur
        final value = _parseOverrideValue(position);
        return OverrideInfo(
          isOverridden: true,
          priority: i + 1, // Priorité 1-15
          value: value,
        );
      }
    }

    return const OverrideInfo(isOverridden: false);
  }

  /// Parse le format V2: [null, null, ..., valeur] (tableau JSON de 16 positions)
  static OverrideInfo _parsePriorityArrayV2(List priorityArray) {
    // Vérifier les positions 1-15 (indices 0-14)
    for (int i = 0; i < 15 && i < priorityArray.length; i++) {
      final value = priorityArray[i];

      // Si la valeur n'est pas null, c'est un forçage
      if (value != null) {
        return OverrideInfo(
          isOverridden: true,
          priority: i + 1, // Priorité 1-15
          value: value,
        );
      }
    }

    return const OverrideInfo(isOverridden: false);
  }

  /// Parse une valeur du priority-array
  /// Formats: "real=100.0", "unsigned=5", "boolean=true", "enumerated=1"
  static dynamic _parseOverrideValue(String position) {
    final parts = position.split('=');
    if (parts.length != 2) return position;

    final valueType = parts[0].trim().toLowerCase();
    final valueStr = parts[1].trim();

    switch (valueType) {
      case 'real':
        return double.tryParse(valueStr) ?? valueStr;
      case 'unsigned':
      case 'enumerated':
        return int.tryParse(valueStr) ?? valueStr;
      case 'boolean':
        return valueStr.toLowerCase() == 'true';
      default:
        return valueStr;
    }
  }
}

/// Informations sur le forçage d'un point
class OverrideInfo {
  final bool isOverridden;
  final int? priority;
  final dynamic value;

  const OverrideInfo({
    required this.isOverridden,
    this.priority,
    this.value,
  });
}

/// Informations sur l'appareil
class DeviceInfo {
  final String objectName;
  final String? modelName;
  final String? modelType;
  final String? softwareVersion;
  final String? hostId;
  final String? hostName;
  final String? vendorName;
  final String? description;
  final String? location;
  final int? deviceInstance;

  DeviceInfo({
    required this.objectName,
    this.modelName,
    this.modelType,
    this.softwareVersion,
    this.hostId,
    this.hostName,
    this.vendorName,
    this.description,
    this.location,
    this.deviceInstance,
  });

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      objectName: json['object-name'] ?? json['objectName'] ?? 'Inconnu',
      modelName: json['model-name'] ?? json['modelName'],
      vendorName: json['vendor-name'] ?? json['vendorName'],
      description: json['description'],
      location: json['location'],
      deviceInstance: json['object-identifier']?['instance'] ?? json['objectIdentifier']?['instance'],
    );
  }

  /// Crée depuis l'endpoint /api/rest/v1/info/device
  factory DeviceInfo.fromDeviceInfoJson(Map<String, dynamic> json, {String? bacnetName}) {
    return DeviceInfo(
      objectName: bacnetName ?? json['controllerName'] ?? 'Automate',
      modelName: json['modelName'],
      modelType: json['modelType'],
      softwareVersion: json['softwareVersion'],
      hostId: json['hostId'],
      hostName: json['hostName'],
      vendorName: json['vendorName'],
    );
  }
}

/// Catégories de points pour la navigation par onglets
enum PointCategory {
  inputs('Entrées', [BacnetObjectType.analogInput, BacnetObjectType.binaryInput, BacnetObjectType.multiStateInput]),
  outputs('Sorties', [BacnetObjectType.analogOutput, BacnetObjectType.binaryOutput, BacnetObjectType.multiStateOutput]),
  variables('Valeurs', [BacnetObjectType.analogValue, BacnetObjectType.binaryValue, BacnetObjectType.multiStateValue]),
  others('Autres', [BacnetObjectType.schedule, BacnetObjectType.calendar, BacnetObjectType.trendLog]),
  all('Tous', []);

  final String displayName;
  final List<BacnetObjectType> types;

  const PointCategory(this.displayName, this.types);

  /// Vérifie si un type appartient à cette catégorie
  bool containsType(BacnetObjectType type) {
    if (this == PointCategory.all) return true;
    return types.contains(type);
  }

  /// Filtre une liste de points selon cette catégorie
  List<BacnetObject> filterPoints(List<BacnetObject> points) {
    if (this == PointCategory.all) return points;
    return points.where((p) => types.contains(p.type)).toList();
  }
}

/// Options de tri pour les points
enum PointSortOption {
  nameAsc('Nom (A→Z)'),
  nameDesc('Nom (Z→A)'),
  typeAsc('Type'),
  valueAsc('Valeur ↑'),
  valueDesc('Valeur ↓'),
  favoritesFirst('Favoris d\'abord');

  final String displayName;

  const PointSortOption(this.displayName);
}

/// Filtre par sous-type pour les catégories (Entrées, Sorties, Valeurs)
enum SubTypeFilter {
  all('Tous', null),
  analog('Analog', 'analog'),
  binary('Binary', 'binary'),
  multiState('Multi', 'multiState');

  final String label;
  final String? typePrefix;

  const SubTypeFilter(this.label, this.typePrefix);

  /// Vérifie si un type BACnet correspond à ce filtre
  bool matches(BacnetObjectType type) {
    if (this == SubTypeFilter.all) return true;
    switch (this) {
      case SubTypeFilter.analog:
        return type.isAnalog;
      case SubTypeFilter.binary:
        return type.isBinary;
      case SubTypeFilter.multiState:
        return type.isMultiState;
      default:
        return true;
    }
  }
}

/// Résumé des objets disponibles sur l'automate
class ObjectsSummary {
  final int analogInputs;
  final int analogOutputs;
  final int analogValues;
  final int binaryInputs;
  final int binaryOutputs;
  final int binaryValues;
  final int multiStateInputs;
  final int multiStateOutputs;
  final int multiStateValues;
  final int schedules;

  ObjectsSummary({
    this.analogInputs = 0,
    this.analogOutputs = 0,
    this.analogValues = 0,
    this.binaryInputs = 0,
    this.binaryOutputs = 0,
    this.binaryValues = 0,
    this.multiStateInputs = 0,
    this.multiStateOutputs = 0,
    this.multiStateValues = 0,
    this.schedules = 0,
  });

  int get totalInputs => analogInputs + binaryInputs + multiStateInputs;
  int get totalOutputs => analogOutputs + binaryOutputs + multiStateOutputs;
  int get totalValues => analogValues + binaryValues + multiStateValues;
  int get total => totalInputs + totalOutputs + totalValues + schedules;
}

/// Heure de l'automate avec calcul du décalage par rapport à l'heure locale
class ControllerTime {
  /// Date et heure de l'automate
  final DateTime controllerDateTime;

  /// Date et heure locale au moment de la lecture
  final DateTime localDateTime;

  /// Décalage en secondes (positif = automate en avance, négatif = en retard)
  final int offsetSeconds;

  const ControllerTime({
    required this.controllerDateTime,
    required this.localDateTime,
    required this.offsetSeconds,
  });

  /// Crée un ControllerTime à partir de la date/heure de l'automate
  factory ControllerTime.fromDateTime(DateTime controllerDateTime) {
    final localDateTime = DateTime.now();
    final offsetSeconds = controllerDateTime.difference(localDateTime).inSeconds;
    return ControllerTime(
      controllerDateTime: controllerDateTime,
      localDateTime: localDateTime,
      offsetSeconds: offsetSeconds,
    );
  }

  /// Décalage absolu en secondes
  int get absoluteOffsetSeconds => offsetSeconds.abs();

  /// Décalage en minutes (arrondi)
  int get offsetMinutes => (offsetSeconds / 60).round();

  /// Décalage absolu en minutes
  int get absoluteOffsetMinutes => offsetMinutes.abs();

  /// Indique si le décalage est significatif (> 2 minutes)
  bool get hasSignificantOffset => absoluteOffsetMinutes > 2;

  /// Indique si le décalage est critique (> 10 minutes)
  bool get hasCriticalOffset => absoluteOffsetMinutes > 10;

  /// Heure formatée (HH:mm)
  String get formattedTime {
    final h = controllerDateTime.hour.toString().padLeft(2, '0');
    final m = controllerDateTime.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Date formatée courte (JJ/MM)
  String get formattedDateShort {
    final d = controllerDateTime.day.toString().padLeft(2, '0');
    final m = controllerDateTime.month.toString().padLeft(2, '0');
    return '$d/$m';
  }

  /// Date et heure formatées complètes
  String get formattedDateTime {
    final d = controllerDateTime.day.toString().padLeft(2, '0');
    final m = controllerDateTime.month.toString().padLeft(2, '0');
    final y = controllerDateTime.year;
    final h = controllerDateTime.hour.toString().padLeft(2, '0');
    final min = controllerDateTime.minute.toString().padLeft(2, '0');
    final s = controllerDateTime.second.toString().padLeft(2, '0');
    return '$d/$m/$y $h:$min:$s';
  }

  /// Description du décalage pour l'affichage
  String get offsetDescription {
    if (absoluteOffsetMinutes == 0) {
      return 'Synchronisé';
    }

    final absMin = absoluteOffsetMinutes;
    final direction = offsetMinutes > 0 ? 'en avance' : 'en retard';

    if (absMin < 60) {
      return '$absMin min $direction';
    }

    final hours = absMin ~/ 60;
    final mins = absMin % 60;
    if (mins == 0) {
      return '$hours h $direction';
    }
    return '$hours h $mins min $direction';
  }
}

/// Informations réseau de l'automate
/// Supporte API V1 (interface unique) et API V2 (interfaces multiples)
class NetworkInfo {
  /// Liste des interfaces réseau (V2) ou interface unique (V1)
  final List<NetworkInterfaceInfo> interfaces;

  const NetworkInfo({required this.interfaces});

  /// Crée un NetworkInfo depuis une réponse API V1
  factory NetworkInfo.fromJsonV1(Map<String, dynamic> json) {
    return NetworkInfo(
      interfaces: [
        NetworkInterfaceInfo(
          name: json['interface'] as String? ?? 'ethernet',
          displayName: 'Ethernet',
          ipAddress: json['ipAddress'] as String?,
          macAddress: json['macAddress'] as String?,
          subnetMask: json['subnetMask'] as String?,
          gateway: json['gateway'] as String?,
          enabled: true,
          dhcpEnabled: false,
        ),
      ],
    );
  }

  /// Crée un NetworkInfo depuis une réponse API V2 (liste des interfaces)
  factory NetworkInfo.fromJsonV2(Map<String, dynamic> json) {
    final interfaces = <NetworkInterfaceInfo>[];

    // Bridge (interface principale sur ECLYPSE)
    if (json.containsKey('bridge')) {
      final bridge = json['bridge'];
      if (bridge is Map<String, dynamic>) {
        interfaces.add(NetworkInterfaceInfo.fromJsonV2('bridge', 'Bridge', bridge));
      }
    }

    // Primary ethernet
    if (json.containsKey('primary')) {
      final primary = json['primary'];
      if (primary is Map<String, dynamic>) {
        interfaces.add(NetworkInterfaceInfo.fromJsonV2('primary', 'Ethernet 1', primary));
      }
    }

    // Secondary ethernet
    if (json.containsKey('secondary')) {
      final secondary = json['secondary'];
      if (secondary is Map<String, dynamic>) {
        interfaces.add(NetworkInterfaceInfo.fromJsonV2('secondary', 'Ethernet 2', secondary));
      }
    }

    // Wireless
    if (json.containsKey('wireless')) {
      final wireless = json['wireless'];
      if (wireless is Map<String, dynamic>) {
        interfaces.add(NetworkInterfaceInfo.fromJsonV2Wireless('wireless', 'Wi-Fi', wireless));
      }
    }

    return NetworkInfo(interfaces: interfaces);
  }

  /// Interface principale (bridge ou première interface active)
  NetworkInterfaceInfo? get primaryInterface {
    // Chercher d'abord le bridge
    final bridge = interfaces.where((i) => i.name == 'bridge' && i.enabled).firstOrNull;
    if (bridge != null) return bridge;

    // Sinon, la première interface active
    return interfaces.where((i) => i.enabled && i.ipAddress != null).firstOrNull;
  }

  /// Toutes les interfaces actives
  List<NetworkInterfaceInfo> get activeInterfaces =>
      interfaces.where((i) => i.enabled).toList();

  @override
  String toString() {
    return 'NetworkInfo(interfaces: ${interfaces.length})';
  }
}

/// Une interface réseau individuelle
class NetworkInterfaceInfo {
  final String name;
  final String displayName;
  final String? ipAddress;
  final String? macAddress;
  final String? subnetMask;
  final String? gateway;
  final String? dnsPrimary;
  final String? dnsSecondary;
  final bool enabled;
  final bool dhcpEnabled;

  /// Pour le Wi-Fi
  final String? ssid;
  final String? wifiMode;

  const NetworkInterfaceInfo({
    required this.name,
    required this.displayName,
    this.ipAddress,
    this.macAddress,
    this.subnetMask,
    this.gateway,
    this.dnsPrimary,
    this.dnsSecondary,
    this.enabled = true,
    this.dhcpEnabled = false,
    this.ssid,
    this.wifiMode,
  });

  /// Parse une interface depuis API V2
  factory NetworkInterfaceInfo.fromJsonV2(String name, String displayName, Map<String, dynamic> json) {
    final ipv4 = json['ipv4'] as Map<String, dynamic>?;
    final enabled = json['enabled'] as bool? ?? false;

    String? subnetMask;
    final prefixLength = ipv4?['subnet-prefix-length'];
    if (prefixLength != null) {
      subnetMask = _prefixLengthToSubnetMask(prefixLength as int);
    }

    return NetworkInterfaceInfo(
      name: name,
      displayName: displayName,
      ipAddress: ipv4?['ip-address'] as String?,
      macAddress: json['mac-address'] as String?,
      subnetMask: subnetMask,
      gateway: ipv4?['gateway'] as String?,
      dnsPrimary: ipv4?['dns-primary'] as String?,
      dnsSecondary: ipv4?['dns-secondary'] as String?,
      enabled: enabled && (ipv4?['enabled'] as bool? ?? false),
      dhcpEnabled: ipv4?['dhcp-enabled'] as bool? ?? false,
    );
  }

  /// Parse une interface Wi-Fi depuis API V2
  factory NetworkInterfaceInfo.fromJsonV2Wireless(String name, String displayName, Map<String, dynamic> json) {
    final ipv4 = json['ipv4'] as Map<String, dynamic>?;
    final enabled = json['enabled'] as bool? ?? false;

    String? subnetMask;
    final prefixLength = ipv4?['subnet-prefix-length'];
    if (prefixLength != null) {
      subnetMask = _prefixLengthToSubnetMask(prefixLength as int);
    }

    return NetworkInterfaceInfo(
      name: name,
      displayName: displayName,
      ipAddress: ipv4?['ip-address'] as String?,
      macAddress: json['mac-address'] as String?,
      subnetMask: subnetMask,
      gateway: ipv4?['gateway'] as String?,
      enabled: enabled,
      dhcpEnabled: false,
      ssid: json['ssid'] as String?,
      wifiMode: json['mode'] as String?,
    );
  }

  /// Convertit un préfixe CIDR en masque de sous-réseau
  static String _prefixLengthToSubnetMask(int prefixLength) {
    if (prefixLength <= 0 || prefixLength > 32) return '0.0.0.0';

    final mask = (0xFFFFFFFF << (32 - prefixLength)) & 0xFFFFFFFF;
    return '${(mask >> 24) & 0xFF}.${(mask >> 16) & 0xFF}.${(mask >> 8) & 0xFF}.${mask & 0xFF}';
  }

  /// Est-ce une interface Wi-Fi ?
  bool get isWireless => name == 'wireless' || ssid != null;

  @override
  String toString() {
    return 'NetworkInterfaceInfo($displayName: $ipAddress, enabled: $enabled)';
  }
}
