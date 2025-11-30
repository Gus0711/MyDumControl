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
  });

  /// Identifiant unique de l'objet
  String get objectId => '${type.shortName}:$instance';

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

    // Valeurs analogiques avec unité
    if (presentValue is num) {
      final value = presentValue as num;
      final formatted = value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
      return units != null ? '$formatted $units' : formatted;
    }

    return presentValue.toString();
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
    if (units is String) return units;
    if (units is Map) return units['value']?.toString();
    return units.toString();
  }

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
