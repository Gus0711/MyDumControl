/// Modèle pour un objet Trend Log BACnet
class TrendLog {
  final int instance;
  final String objectName;
  final String? description;

  /// Propriété log-device-object-property qui indique quel objet est tracké
  /// Format V1: "[Analog Value 454,Present Value,,]"
  final String? logDeviceObjectProperty;

  /// Type d'objet tracké (parsé depuis logDeviceObjectProperty)
  final String? trackedObjectType;

  /// Instance de l'objet tracké (parsé depuis logDeviceObjectProperty)
  final int? trackedObjectInstance;

  /// Intervalle d'enregistrement en secondes
  final int? logInterval;

  /// Taille du buffer
  final int? bufferSize;

  /// Nombre d'enregistrements actuels
  final int? recordCount;

  /// Statut d'enregistrement
  final bool? enabled;

  TrendLog({
    required this.instance,
    required this.objectName,
    this.description,
    this.logDeviceObjectProperty,
    this.trackedObjectType,
    this.trackedObjectInstance,
    this.logInterval,
    this.bufferSize,
    this.recordCount,
    this.enabled,
  });

  /// Clé pour le mapping: "objectType:objectInstance"
  String? get trackedObjectKey {
    if (trackedObjectType == null || trackedObjectInstance == null) {
      return null;
    }
    return '$trackedObjectType:$trackedObjectInstance';
  }

  /// Parse la propriété log-device-object-property
  /// Format: "[Analog Value 454,Present Value,,]" ou similaire
  factory TrendLog.fromJson(int instance, Map<String, dynamic> json) {
    String? logDeviceObjectProperty;
    String? trackedObjectType;
    int? trackedObjectInstance;

    // Extraire log-device-object-property
    final logProp = json['log-device-object-property'] ??
                    json['logDeviceObjectProperty'];

    if (logProp != null) {
      logDeviceObjectProperty = logProp.toString();

      // Parser le format "[Analog Value 454,Present Value,,]"
      final parsed = _parseLogDeviceObjectProperty(logDeviceObjectProperty);
      trackedObjectType = parsed.$1;
      trackedObjectInstance = parsed.$2;
    }

    return TrendLog(
      instance: instance,
      objectName: json['object-name']?.toString() ??
                  json['objectName']?.toString() ??
                  'Trend Log $instance',
      description: json['description']?.toString(),
      logDeviceObjectProperty: logDeviceObjectProperty,
      trackedObjectType: trackedObjectType,
      trackedObjectInstance: trackedObjectInstance,
      logInterval: _parseInt(json['log-interval'] ?? json['logInterval']),
      bufferSize: _parseInt(json['buffer-size'] ?? json['bufferSize']),
      recordCount: _parseInt(json['record-count'] ?? json['recordCount']),
      enabled: json['enable'] ?? json['enabled'],
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Parse "[Analog Value 454,Present Value,,]" -> ("analog-value", 454)
  static (String?, int?) _parseLogDeviceObjectProperty(String value) {
    // Format: "[Analog Value 454,Present Value,,]"
    // Ou: "[Binary Input 100,Present Value,,]"
    final match = RegExp(r'\[([^,]+)\s+(\d+),').firstMatch(value);

    if (match != null) {
      final objectTypeRaw = match.group(1)?.trim();
      final objectInstance = int.tryParse(match.group(2) ?? '');

      if (objectTypeRaw != null && objectInstance != null) {
        // Convertir "Analog Value" -> "analog-value" (format API)
        final objectType = objectTypeRaw.toLowerCase().replaceAll(RegExp(r'\s+'), '-');
        return (objectType, objectInstance);
      }
    }

    return (null, null);
  }
}

/// Type d'enregistrement dans un log buffer
enum TrendRecordType {
  value,      // Valeur normale
  timeChange, // Changement d'heure
  status,     // Statut du log
  error,      // Erreur/échec
}

/// Enregistrement individuel dans un trend log
class TrendLogRecord {
  final DateTime timestamp;
  final dynamic value;
  final TrendRecordType type;
  final String? status;
  final String? original;

  TrendLogRecord({
    required this.timestamp,
    required this.value,
    required this.type,
    this.status,
    this.original,
  });

  /// Parse une valeur numérique pour les graphiques
  double? get numericValue {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is bool) return value ? 1.0 : 0.0;
    if (value is String) {
      // Essayer de parser comme nombre
      final parsed = double.tryParse(value);
      if (parsed != null) return parsed;
      // Booléen textuel
      if (value.toLowerCase() == 'active' || value.toLowerCase() == 'true') {
        return 1.0;
      }
      if (value.toLowerCase() == 'inactive' || value.toLowerCase() == 'false') {
        return 0.0;
      }
    }
    return null;
  }

  /// Vérifie si c'est un enregistrement de valeur (pas erreur/status)
  bool get isValueRecord => type == TrendRecordType.value;
}

/// Résultat du parsing d'un log buffer
class TrendLogData {
  final List<TrendLogRecord> records;
  final DateTime? startTime;
  final DateTime? endTime;
  final int totalRecords;

  // Statistiques
  final double? minValue;
  final double? maxValue;
  final double? avgValue;

  TrendLogData({
    required this.records,
    this.startTime,
    this.endTime,
    required this.totalRecords,
    this.minValue,
    this.maxValue,
    this.avgValue,
  });

  factory TrendLogData.fromRecords(List<TrendLogRecord> records) {
    final valueRecords = records.where((r) => r.isValueRecord && r.numericValue != null).toList();

    double? min, max, avg;
    DateTime? start, end;

    if (valueRecords.isNotEmpty) {
      final values = valueRecords.map((r) => r.numericValue!).toList();
      min = values.reduce((a, b) => a < b ? a : b);
      max = values.reduce((a, b) => a > b ? a : b);
      avg = values.reduce((a, b) => a + b) / values.length;

      // Trier par timestamp pour trouver start/end
      final sorted = List<TrendLogRecord>.from(valueRecords)
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      start = sorted.first.timestamp;
      end = sorted.last.timestamp;
    }

    return TrendLogData(
      records: records,
      startTime: start,
      endTime: end,
      totalRecords: records.length,
      minValue: min,
      maxValue: max,
      avgValue: avg,
    );
  }

  /// Filtre les enregistrements par plage de temps
  TrendLogData filterByTimeRange(DateTime start, DateTime end) {
    final filtered = records.where((r) =>
      r.timestamp.isAfter(start) && r.timestamp.isBefore(end)
    ).toList();
    return TrendLogData.fromRecords(filtered);
  }
}

/// Parser pour le format log-buffer V1 de Distech
class TrendLogBufferParser {
  /// Parse le log buffer V1 (format texte Distech)
  /// Format: "{realValue (2), 2024-12-09T13:39:39.252+01:00, 10.0, [,,,], ...}"
  static TrendLogData parseV1(String rawData) {
    final records = <TrendLogRecord>[];

    // Nettoyer les accolades
    String dataStr = rawData.trim();
    if (dataStr.startsWith('{')) dataStr = dataStr.substring(1);
    if (dataStr.endsWith('}')) dataStr = dataStr.substring(0, dataStr.length - 1);

    if (dataStr.isEmpty) {
      return TrendLogData.fromRecords([]);
    }

    // Remplacer les virgules dans les crochets (status flags)
    const placeholder = '___COMMA___';
    dataStr = dataStr.replaceAllMapped(
      RegExp(r'\[(.*?)\]'),
      (match) => match.group(0)!.replaceAll(',', placeholder),
    );

    // Séparer par virgule
    final parts = dataStr.split(',').map((s) => s.trim()).toList();

    int i = 0;
    while (i < parts.length) {
      final current = parts[i];

      // Type 1: Valeurs (realValue, booleanValue, etc.) - 4 parties
      if (current.contains(RegExp(r'^(realValue|booleanValue|enumeratedValue|unsignedValue|integerValue)'))) {
        if (i + 3 < parts.length) {
          final timestamp = _parseTimestamp(parts[i + 1]);
          final value = _parseValue(parts[i + 2]);
          final statusFlags = parts[i + 3].replaceAll(placeholder, ',');

          if (timestamp != null) {
            records.add(TrendLogRecord(
              timestamp: timestamp,
              value: value,
              type: TrendRecordType.value,
              status: statusFlags == '[,,,]' ? 'Normal' : statusFlags,
              original: parts.sublist(i, i + 4).join(', '),
            ));
          }
        }
        i += 4;
      }
      // Type 2: Changement d'heure - 4 parties
      else if (current.startsWith('timeChange')) {
        if (i + 3 < parts.length) {
          final timestamp = _parseTimestamp(parts[i + 1]);
          if (timestamp != null) {
            records.add(TrendLogRecord(
              timestamp: timestamp,
              value: null,
              type: TrendRecordType.timeChange,
              original: parts.sublist(i, i + 4).join(', '),
            ));
          }
        }
        i += 4;
      }
      // Type 3: Status du log - 4 parties
      else if (current.startsWith('logStatus')) {
        if (i + 3 < parts.length) {
          final timestamp = _parseTimestamp(parts[i + 1]);
          if (timestamp != null) {
            records.add(TrendLogRecord(
              timestamp: timestamp,
              value: null,
              type: TrendRecordType.status,
              original: parts.sublist(i, i + 4).join(', '),
            ));
          }
        }
        i += 4;
      }
      // Type 4: Erreur - 5 parties
      else if (current.startsWith('failure')) {
        if (i + 4 < parts.length) {
          final timestamp = _parseTimestamp(parts[i + 1]);
          if (timestamp != null) {
            records.add(TrendLogRecord(
              timestamp: timestamp,
              value: null,
              type: TrendRecordType.error,
              original: parts.sublist(i, i + 5).join(', '),
            ));
          }
        }
        i += 5;
      }
      else {
        i++;
      }
    }

    return TrendLogData.fromRecords(records);
  }

  /// Parse le log buffer V2 (format JSON)
  static TrendLogData parseV2(List<dynamic> samples) {
    final records = <TrendLogRecord>[];

    for (final sample in samples) {
      if (sample is! Map<String, dynamic>) continue;

      final timestampStr = sample['timestamp']?.toString() ?? sample['t']?.toString();
      final value = sample['value'] ?? sample['v'];

      if (timestampStr != null) {
        final timestamp = _parseTimestamp(timestampStr);
        if (timestamp != null) {
          records.add(TrendLogRecord(
            timestamp: timestamp,
            value: value,
            type: TrendRecordType.value,
          ));
        }
      }
    }

    return TrendLogData.fromRecords(records);
  }

  static DateTime? _parseTimestamp(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return DateTime.parse(value.trim());
    } catch (_) {
      return null;
    }
  }

  static dynamic _parseValue(String? value) {
    if (value == null || value.isEmpty) return null;
    final trimmed = value.trim();

    // Essayer comme nombre
    final numValue = double.tryParse(trimmed);
    if (numValue != null) return numValue;

    // Booléen
    if (trimmed.toLowerCase() == 'true' || trimmed.toLowerCase() == 'active') {
      return true;
    }
    if (trimmed.toLowerCase() == 'false' || trimmed.toLowerCase() == 'inactive') {
      return false;
    }

    return trimmed;
  }
}
