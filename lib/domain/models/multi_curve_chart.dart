import 'package:fl_chart/fl_chart.dart';
import 'trend_log.dart';

/// Configuration d'une courbe individuelle dans un graphique multi-courbes
class CurveConfig {
  final int trendLogInstance;
  final String? pointName;
  final String? units;
  final String colorThemeName;
  final bool isVisible;

  const CurveConfig({
    required this.trendLogInstance,
    this.pointName,
    this.units,
    this.colorThemeName = 'blue',
    this.isVisible = true,
  });

  CurveConfig copyWith({
    int? trendLogInstance,
    String? pointName,
    String? units,
    String? colorThemeName,
    bool? isVisible,
  }) {
    return CurveConfig(
      trendLogInstance: trendLogInstance ?? this.trendLogInstance,
      pointName: pointName ?? this.pointName,
      units: units ?? this.units,
      colorThemeName: colorThemeName ?? this.colorThemeName,
      isVisible: isVisible ?? this.isVisible,
    );
  }

  Map<String, dynamic> toJson() => {
        'trendLogInstance': trendLogInstance,
        'pointName': pointName,
        'units': units,
        'colorThemeName': colorThemeName,
        'isVisible': isVisible,
      };

  factory CurveConfig.fromJson(Map<String, dynamic> json) {
    return CurveConfig(
      trendLogInstance: json['trendLogInstance'] as int,
      pointName: json['pointName'] as String?,
      units: json['units'] as String?,
      colorThemeName: json['colorThemeName'] as String? ?? 'blue',
      isVisible: json['isVisible'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CurveConfig &&
        other.trendLogInstance == trendLogInstance &&
        other.pointName == pointName &&
        other.units == units &&
        other.colorThemeName == colorThemeName &&
        other.isVisible == isVisible;
  }

  @override
  int get hashCode => Object.hash(
        trendLogInstance,
        pointName,
        units,
        colorThemeName,
        isVisible,
      );
}

/// Configuration complète d'un graphique multi-courbes
class MultiCurveChartConfig {
  final String id;
  final String name;
  final List<CurveConfig> curves;
  final DateTime? startTime;
  final DateTime? endTime;

  const MultiCurveChartConfig({
    required this.id,
    required this.name,
    required this.curves,
    this.startTime,
    this.endTime,
  });

  MultiCurveChartConfig copyWith({
    String? id,
    String? name,
    List<CurveConfig>? curves,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return MultiCurveChartConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      curves: curves ?? this.curves,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'curves': curves.map((c) => c.toJson()).toList(),
        'startTime': startTime?.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
      };

  factory MultiCurveChartConfig.fromJson(Map<String, dynamic> json) {
    return MultiCurveChartConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      curves: (json['curves'] as List<dynamic>)
          .map((c) => CurveConfig.fromJson(c as Map<String, dynamic>))
          .toList(),
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'] as String)
          : null,
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
    );
  }
}

/// Données d'une courbe individuelle prête pour l'affichage
class CurveData {
  final int trendLogInstance;
  final String name;
  final String? units;
  final List<FlSpot> spots;
  final String colorThemeName;
  final double minValue;
  final double maxValue;
  final double avgValue;
  final bool isVisible;
  final FlSpot? minSpot;
  final FlSpot? maxSpot;

  const CurveData({
    required this.trendLogInstance,
    required this.name,
    this.units,
    required this.spots,
    required this.colorThemeName,
    required this.minValue,
    required this.maxValue,
    required this.avgValue,
    this.isVisible = true,
    this.minSpot,
    this.maxSpot,
  });

  CurveData copyWith({
    int? trendLogInstance,
    String? name,
    String? units,
    List<FlSpot>? spots,
    String? colorThemeName,
    double? minValue,
    double? maxValue,
    double? avgValue,
    bool? isVisible,
    FlSpot? minSpot,
    FlSpot? maxSpot,
  }) {
    return CurveData(
      trendLogInstance: trendLogInstance ?? this.trendLogInstance,
      name: name ?? this.name,
      units: units ?? this.units,
      spots: spots ?? this.spots,
      colorThemeName: colorThemeName ?? this.colorThemeName,
      minValue: minValue ?? this.minValue,
      maxValue: maxValue ?? this.maxValue,
      avgValue: avgValue ?? this.avgValue,
      isVisible: isVisible ?? this.isVisible,
      minSpot: minSpot ?? this.minSpot,
      maxSpot: maxSpot ?? this.maxSpot,
    );
  }

  /// Crée CurveData à partir de TrendLogData
  static CurveData? fromTrendLogData({
    required int trendLogInstance,
    required String name,
    String? units,
    required TrendLogData data,
    required String colorThemeName,
    required double minTimestamp,
    bool isVisible = true,
  }) {
    final valueRecords = data.records
        .where((r) => r.isValueRecord && r.numericValue != null)
        .toList();

    if (valueRecords.isEmpty) return null;

    // Trier par timestamp
    valueRecords.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Créer les spots pour le graphique (X = minutes depuis minTimestamp)
    final spots = <FlSpot>[];
    for (final record in valueRecords) {
      final x = (record.timestamp.millisecondsSinceEpoch - minTimestamp) / 1000 / 60;
      spots.add(FlSpot(x, record.numericValue!));
    }

    // Calculer min/max/avg
    final values = valueRecords.map((r) => r.numericValue!).toList();
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final avgValue = values.reduce((a, b) => a + b) / values.length;

    // Trouver les spots min et max
    FlSpot? minSpot;
    FlSpot? maxSpot;

    for (int i = 0; i < valueRecords.length; i++) {
      if (valueRecords[i].numericValue == minValue && minSpot == null) {
        minSpot = spots[i];
      }
      if (valueRecords[i].numericValue == maxValue && maxSpot == null) {
        maxSpot = spots[i];
      }
    }

    return CurveData(
      trendLogInstance: trendLogInstance,
      name: name,
      units: units,
      spots: spots,
      colorThemeName: colorThemeName,
      minValue: minValue,
      maxValue: maxValue,
      avgValue: avgValue,
      isVisible: isVisible,
      minSpot: minSpot,
      maxSpot: maxSpot,
    );
  }
}

/// Données agrégées de toutes les courbes pour le graphique multi-courbes
class MultiCurveData {
  final List<CurveData> curves;
  final double minTimestamp;
  final double maxTimestamp;
  final double globalMinY;
  final double globalMaxY;
  final double yPadding;

  const MultiCurveData({
    required this.curves,
    required this.minTimestamp,
    required this.maxTimestamp,
    required this.globalMinY,
    required this.globalMaxY,
    required this.yPadding,
  });

  /// Crée MultiCurveData à partir d'une liste de TrendLogData
  static MultiCurveData? fromTrendLogDataList({
    required List<({int instance, String name, String? units, TrendLogData data, String colorTheme})> dataList,
    required Map<int, bool> visibility,
  }) {
    if (dataList.isEmpty) return null;

    // Trouver le timestamp minimum global pour synchroniser les axes X
    double? globalMinTimestamp;
    double? globalMaxTimestamp;

    for (final item in dataList) {
      final valueRecords = item.data.records
          .where((r) => r.isValueRecord && r.numericValue != null)
          .toList();

      if (valueRecords.isEmpty) continue;

      for (final record in valueRecords) {
        final ts = record.timestamp.millisecondsSinceEpoch.toDouble();
        if (globalMinTimestamp == null || ts < globalMinTimestamp) {
          globalMinTimestamp = ts;
        }
        if (globalMaxTimestamp == null || ts > globalMaxTimestamp) {
          globalMaxTimestamp = ts;
        }
      }
    }

    if (globalMinTimestamp == null || globalMaxTimestamp == null) return null;

    // Créer les CurveData avec le timestamp minimum commun
    final curves = <CurveData>[];
    double? globalMinY;
    double? globalMaxY;

    for (final item in dataList) {
      final curveData = CurveData.fromTrendLogData(
        trendLogInstance: item.instance,
        name: item.name,
        units: item.units,
        data: item.data,
        colorThemeName: item.colorTheme,
        minTimestamp: globalMinTimestamp,
        isVisible: visibility[item.instance] ?? true,
      );

      if (curveData != null) {
        curves.add(curveData);

        // Mettre à jour les min/max globaux
        if (globalMinY == null || curveData.minValue < globalMinY) {
          globalMinY = curveData.minValue;
        }
        if (globalMaxY == null || curveData.maxValue > globalMaxY) {
          globalMaxY = curveData.maxValue;
        }
      }
    }

    if (curves.isEmpty || globalMinY == null || globalMaxY == null) return null;

    // Calculer le padding Y
    final range = globalMaxY - globalMinY;
    final yPadding = range > 0 ? range * 0.1 : (globalMaxY.abs() * 0.1).clamp(1.0, double.infinity);

    return MultiCurveData(
      curves: curves,
      minTimestamp: globalMinTimestamp,
      maxTimestamp: globalMaxTimestamp,
      globalMinY: globalMinY,
      globalMaxY: globalMaxY,
      yPadding: yPadding,
    );
  }

  /// Retourne les courbes visibles uniquement
  List<CurveData> get visibleCurves => curves.where((c) => c.isVisible).toList();

  /// Met à jour la visibilité d'une courbe
  MultiCurveData toggleCurveVisibility(int trendLogInstance) {
    final newCurves = curves.map((c) {
      if (c.trendLogInstance == trendLogInstance) {
        return c.copyWith(isVisible: !c.isVisible);
      }
      return c;
    }).toList();

    return MultiCurveData(
      curves: newCurves,
      minTimestamp: minTimestamp,
      maxTimestamp: maxTimestamp,
      globalMinY: globalMinY,
      globalMaxY: globalMaxY,
      yPadding: yPadding,
    );
  }
}

/// Liste des thèmes de couleurs disponibles pour les courbes
const List<String> curveColorThemes = [
  'blue',
  'green',
  'orange',
  'purple',
  'red',
  'cyan',
  'teal',
  'indigo',
];

/// Retourne le thème de couleur par index (boucle sur les 8 thèmes)
String getColorThemeByIndex(int index) {
  return curveColorThemes[index % curveColorThemes.length];
}
