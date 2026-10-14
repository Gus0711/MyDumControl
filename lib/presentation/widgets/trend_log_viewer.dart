import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../application/providers/trend_log_provider.dart';
import '../../domain/models/trend_log.dart';
import '../../l10n/app_localizations.dart';
import 'chart_downsample.dart';

// =============================================================================
// Système de couleurs pour les graphiques
// =============================================================================

/// Thème de couleurs pour le graphique
class ChartColorTheme {
  final String name;
  final String displayName;
  final Color primaryColor;
  final Color secondaryColor;
  final Color gradientStart;
  final Color gradientEnd;
  final Color dotColor;
  final Color dotBorderColor;
  final Color tooltipBackground;
  final Color tooltipText;
  final Color gridColor;
  final Color axisColor;

  const ChartColorTheme({
    required this.name,
    required this.displayName,
    required this.primaryColor,
    required this.secondaryColor,
    required this.gradientStart,
    required this.gradientEnd,
    required this.dotColor,
    required this.dotBorderColor,
    required this.tooltipBackground,
    required this.tooltipText,
    required this.gridColor,
    required this.axisColor,
  });

  /// Palettes de couleurs prédéfinies
  static const ChartColorTheme blue = ChartColorTheme(
    name: 'blue',
    displayName: 'Bleu',
    primaryColor: Color(0xFF2196F3),
    secondaryColor: Color(0xFF64B5F6),
    gradientStart: Color(0x402196F3),
    gradientEnd: Color(0x052196F3),
    dotColor: Color(0xFF1976D2),
    dotBorderColor: Colors.white,
    tooltipBackground: Color(0xFF1565C0),
    tooltipText: Colors.white,
    gridColor: Color(0xFFE0E0E0),
    axisColor: Color(0xFF9E9E9E),
  );

  static const ChartColorTheme green = ChartColorTheme(
    name: 'green',
    displayName: 'Vert',
    primaryColor: Color(0xFF4CAF50),
    secondaryColor: Color(0xFF81C784),
    gradientStart: Color(0x404CAF50),
    gradientEnd: Color(0x054CAF50),
    dotColor: Color(0xFF388E3C),
    dotBorderColor: Colors.white,
    tooltipBackground: Color(0xFF2E7D32),
    tooltipText: Colors.white,
    gridColor: Color(0xFFE0E0E0),
    axisColor: Color(0xFF9E9E9E),
  );

  static const ChartColorTheme orange = ChartColorTheme(
    name: 'orange',
    displayName: 'Orange',
    primaryColor: Color(0xFFFF9800),
    secondaryColor: Color(0xFFFFB74D),
    gradientStart: Color(0x40FF9800),
    gradientEnd: Color(0x05FF9800),
    dotColor: Color(0xFFF57C00),
    dotBorderColor: Colors.white,
    tooltipBackground: Color(0xFFE65100),
    tooltipText: Colors.white,
    gridColor: Color(0xFFE0E0E0),
    axisColor: Color(0xFF9E9E9E),
  );

  static const ChartColorTheme purple = ChartColorTheme(
    name: 'purple',
    displayName: 'Violet',
    primaryColor: Color(0xFF9C27B0),
    secondaryColor: Color(0xFFBA68C8),
    gradientStart: Color(0x409C27B0),
    gradientEnd: Color(0x059C27B0),
    dotColor: Color(0xFF7B1FA2),
    dotBorderColor: Colors.white,
    tooltipBackground: Color(0xFF6A1B9A),
    tooltipText: Colors.white,
    gridColor: Color(0xFFE0E0E0),
    axisColor: Color(0xFF9E9E9E),
  );

  static const ChartColorTheme red = ChartColorTheme(
    name: 'red',
    displayName: 'Rouge',
    primaryColor: Color(0xFFF44336),
    secondaryColor: Color(0xFFE57373),
    gradientStart: Color(0x40F44336),
    gradientEnd: Color(0x05F44336),
    dotColor: Color(0xFFD32F2F),
    dotBorderColor: Colors.white,
    tooltipBackground: Color(0xFFC62828),
    tooltipText: Colors.white,
    gridColor: Color(0xFFE0E0E0),
    axisColor: Color(0xFF9E9E9E),
  );

  static const ChartColorTheme cyan = ChartColorTheme(
    name: 'cyan',
    displayName: 'Cyan',
    primaryColor: Color(0xFF00BCD4),
    secondaryColor: Color(0xFF4DD0E1),
    gradientStart: Color(0x4000BCD4),
    gradientEnd: Color(0x0500BCD4),
    dotColor: Color(0xFF0097A7),
    dotBorderColor: Colors.white,
    tooltipBackground: Color(0xFF00838F),
    tooltipText: Colors.white,
    gridColor: Color(0xFFE0E0E0),
    axisColor: Color(0xFF9E9E9E),
  );

  static const ChartColorTheme teal = ChartColorTheme(
    name: 'teal',
    displayName: 'Sarcelle',
    primaryColor: Color(0xFF009688),
    secondaryColor: Color(0xFF4DB6AC),
    gradientStart: Color(0x40009688),
    gradientEnd: Color(0x05009688),
    dotColor: Color(0xFF00796B),
    dotBorderColor: Colors.white,
    tooltipBackground: Color(0xFF00695C),
    tooltipText: Colors.white,
    gridColor: Color(0xFFE0E0E0),
    axisColor: Color(0xFF9E9E9E),
  );

  static const ChartColorTheme indigo = ChartColorTheme(
    name: 'indigo',
    displayName: 'Indigo',
    primaryColor: Color(0xFF3F51B5),
    secondaryColor: Color(0xFF7986CB),
    gradientStart: Color(0x403F51B5),
    gradientEnd: Color(0x053F51B5),
    dotColor: Color(0xFF303F9F),
    dotBorderColor: Colors.white,
    tooltipBackground: Color(0xFF283593),
    tooltipText: Colors.white,
    gridColor: Color(0xFFE0E0E0),
    axisColor: Color(0xFF9E9E9E),
  );

  /// Liste de toutes les palettes disponibles
  static const List<ChartColorTheme> allThemes = [
    blue,
    green,
    orange,
    purple,
    red,
    cyan,
    teal,
    indigo,
  ];

  /// Récupère un thème par son nom
  static ChartColorTheme fromName(String name) {
    return allThemes.firstWhere(
      (theme) => theme.name == name,
      orElse: () => blue,
    );
  }
}

/// Localized display name of a color theme
String chartColorThemeLabel(AppLocalizations l10n, ChartColorTheme theme) {
  switch (theme.name) {
    case 'blue':
      return l10n.trendColorBlue;
    case 'green':
      return l10n.trendColorGreen;
    case 'orange':
      return l10n.trendColorOrange;
    case 'purple':
      return l10n.trendColorPurple;
    case 'red':
      return l10n.trendColorRed;
    case 'cyan':
      return l10n.trendColorCyan;
    case 'teal':
      return l10n.trendColorTeal;
    case 'indigo':
      return l10n.trendColorIndigo;
    default:
      return theme.displayName;
  }
}

/// Localized label of a trend period
String trendPeriodLabel(AppLocalizations l10n, TrendPeriod period) {
  switch (period) {
    case TrendPeriod.hour:
      return l10n.trendPeriodHour;
    case TrendPeriod.day:
      return l10n.trendPeriodDay;
    case TrendPeriod.week:
      return l10n.trendPeriodWeek;
    case TrendPeriod.month:
      return l10n.trendPeriodMonth;
    case TrendPeriod.all:
      return l10n.trendPeriodAll;
    case TrendPeriod.custom:
      return l10n.trendPeriodCustom;
  }
}

/// Widget sélecteur de thème de couleur
class _ColorThemeSelector extends StatelessWidget {
  final ChartColorTheme selectedTheme;
  final ValueChanged<ChartColorTheme> onThemeChanged;
  final bool compact;

  const _ColorThemeSelector({
    required this.selectedTheme,
    required this.onThemeChanged,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (compact) {
      return PopupMenuButton<ChartColorTheme>(
        initialValue: selectedTheme,
        onSelected: onThemeChanged,
        tooltip: l10n.trendChangeColor,
        icon: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: selectedTheme.primaryColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(40),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        itemBuilder: (context) => ChartColorTheme.allThemes
            .map((theme) => PopupMenuItem<ChartColorTheme>(
                  value: theme,
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(chartColorThemeLabel(l10n, theme)),
                      if (theme.name == selectedTheme.name) ...[
                        const Spacer(),
                        Icon(Icons.check, color: theme.primaryColor, size: 18),
                      ],
                    ],
                  ),
                ))
            .toList(),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ChartColorTheme.allThemes.map((theme) {
          final isSelected = theme.name == selectedTheme.name;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onThemeChanged(theme),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isSelected ? 36 : 28,
                height: isSelected ? 36 : 28,
                decoration: BoxDecoration(
                  color: theme.primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: theme.primaryColor.withAlpha(100),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : null,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// =============================================================================
// Utilitaires partagés
// =============================================================================

/// Formate une valeur numérique pour l'affichage
String _formatValue(double value) {
  if (value == value.truncateToDouble()) {
    return value.toInt().toString();
  }
  return value.toStringAsFixed(2);
}

/// Données préparées pour le graphique
class _ChartData {
  final List<FlSpot> spots;
  final double minTimestamp;
  final double minY;
  final double maxY;
  final double yPadding;
  final double avgY;
  final FlSpot? minSpot; // Point avec la valeur minimale
  final FlSpot? maxSpot; // Point avec la valeur maximale
  final DateTime? minTimestampDate;
  final DateTime? maxTimestampDate;

  const _ChartData({
    required this.spots,
    required this.minTimestamp,
    required this.minY,
    required this.maxY,
    required this.yPadding,
    required this.avgY,
    this.minSpot,
    this.maxSpot,
    this.minTimestampDate,
    this.maxTimestampDate,
  });

  // Cache par identité de la liste de records (évite tri/min/max à chaque build)
  static final Expando<_ChartData> _cache = Expando<_ChartData>('chartData');

  /// Version mémoïsée de [_compute] : recalcul seulement si la liste change.
  static _ChartData? fromRecords(List<TrendLogRecord> records) {
    final cached = _cache[records];
    if (cached != null) return cached;
    final computed = _compute(records);
    if (computed != null) _cache[records] = computed;
    return computed;
  }

  /// Prépare les données pour le graphique à partir des records
  static _ChartData? _compute(List<TrendLogRecord> records) {
    final valueRecords = records
        .where((r) => r.isValueRecord && r.numericValue != null)
        .toList();

    if (valueRecords.isEmpty) return null;

    // Trier par timestamp
    valueRecords.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Créer les spots pour le graphique
    final spots = <FlSpot>[];
    final minTimestamp = valueRecords.first.timestamp.millisecondsSinceEpoch.toDouble();

    for (final record in valueRecords) {
      final x = (record.timestamp.millisecondsSinceEpoch.toDouble() - minTimestamp) / 1000 / 60;
      spots.add(FlSpot(x, record.numericValue!));
    }

    // Calculer les valeurs min/max/avg pour l'axe Y
    final values = valueRecords.map((r) => r.numericValue!).toList();
    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final avgY = values.reduce((a, b) => a + b) / values.length;
    // Protection: si min == max, utiliser 10% de la valeur absolue ou 1.0 minimum
    final range = maxY - minY;
    final yPadding = range > 0 ? range * 0.1 : (maxY.abs() * 0.1).clamp(1.0, double.infinity);

    // Trouver les spots min et max
    FlSpot? minSpot;
    FlSpot? maxSpot;
    DateTime? minTimestampDate;
    DateTime? maxTimestampDate;

    for (int i = 0; i < valueRecords.length; i++) {
      if (valueRecords[i].numericValue == minY && minSpot == null) {
        minSpot = spots[i];
        minTimestampDate = valueRecords[i].timestamp;
      }
      if (valueRecords[i].numericValue == maxY && maxSpot == null) {
        maxSpot = spots[i];
        maxTimestampDate = valueRecords[i].timestamp;
      }
    }

    return _ChartData(
      spots: spots,
      minTimestamp: minTimestamp,
      minY: minY,
      maxY: maxY,
      yPadding: yPadding,
      avgY: avgY,
      minSpot: minSpot,
      maxSpot: maxSpot,
      minTimestampDate: minTimestampDate,
      maxTimestampDate: maxTimestampDate,
    );
  }
}

/// Configuration des annotations du graphique
class ChartAnnotations {
  final bool showMinMaxMarkers;
  final bool showAverageLine;
  final bool showMinLine;
  final bool showMaxLine;
  final List<ChartThreshold> thresholds;

  const ChartAnnotations({
    this.showMinMaxMarkers = true,
    this.showAverageLine = false,
    this.showMinLine = false,
    this.showMaxLine = false,
    this.thresholds = const [],
  });

  static const ChartAnnotations none = ChartAnnotations(
    showMinMaxMarkers: false,
    showAverageLine: false,
    showMinLine: false,
    showMaxLine: false,
  );

  static const ChartAnnotations markers = ChartAnnotations(
    showMinMaxMarkers: true,
    showAverageLine: false,
    showMinLine: false,
    showMaxLine: false,
  );

  static const ChartAnnotations full = ChartAnnotations(
    showMinMaxMarkers: true,
    showAverageLine: true,
    showMinLine: true,
    showMaxLine: true,
  );

  ChartAnnotations copyWith({
    bool? showMinMaxMarkers,
    bool? showAverageLine,
    bool? showMinLine,
    bool? showMaxLine,
    List<ChartThreshold>? thresholds,
  }) {
    return ChartAnnotations(
      showMinMaxMarkers: showMinMaxMarkers ?? this.showMinMaxMarkers,
      showAverageLine: showAverageLine ?? this.showAverageLine,
      showMinLine: showMinLine ?? this.showMinLine,
      showMaxLine: showMaxLine ?? this.showMaxLine,
      thresholds: thresholds ?? this.thresholds,
    );
  }
}

/// Définition d'un seuil pour le graphique
class ChartThreshold {
  final double value;
  final String? label;
  final Color color;
  final bool isUpperBound; // true = zone au-dessus, false = zone en dessous

  const ChartThreshold({
    required this.value,
    this.label,
    required this.color,
    this.isUpperBound = true,
  });
}

/// Widget pour configurer les annotations
class _AnnotationsMenu extends StatelessWidget {
  final ChartAnnotations annotations;
  final ValueChanged<ChartAnnotations> onChanged;
  final ChartColorTheme colorTheme;

  const _AnnotationsMenu({
    required this.annotations,
    required this.onChanged,
    required this.colorTheme,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopupMenuButton<String>(
      tooltip: l10n.trendAnnotations,
      icon: Icon(
        Icons.edit_note,
        color: _hasAnyAnnotation ? colorTheme.primaryColor : null,
      ),
      onSelected: (value) {
        switch (value) {
          case 'markers':
            onChanged(annotations.copyWith(
              showMinMaxMarkers: !annotations.showMinMaxMarkers,
            ));
            break;
          case 'average':
            onChanged(annotations.copyWith(
              showAverageLine: !annotations.showAverageLine,
            ));
            break;
          case 'minLine':
            onChanged(annotations.copyWith(
              showMinLine: !annotations.showMinLine,
            ));
            break;
          case 'maxLine':
            onChanged(annotations.copyWith(
              showMaxLine: !annotations.showMaxLine,
            ));
            break;
          case 'reset':
            onChanged(ChartAnnotations.none);
            break;
        }
      },
      itemBuilder: (context) => [
        _buildMenuItem(
          'markers',
          l10n.trendMinMaxMarkers,
          Icons.push_pin,
          annotations.showMinMaxMarkers,
        ),
        _buildMenuItem(
          'average',
          l10n.trendAverageLine,
          Icons.horizontal_rule,
          annotations.showAverageLine,
        ),
        _buildMenuItem(
          'minLine',
          l10n.trendMinLine,
          Icons.arrow_downward,
          annotations.showMinLine,
        ),
        _buildMenuItem(
          'maxLine',
          l10n.trendMaxLine,
          Icons.arrow_upward,
          annotations.showMaxLine,
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'reset',
          child: Row(
            children: [
              const Icon(Icons.clear_all, size: 20),
              const SizedBox(width: 12),
              Text(l10n.trendHideAll),
            ],
          ),
        ),
      ],
    );
  }

  bool get _hasAnyAnnotation =>
      annotations.showMinMaxMarkers ||
      annotations.showAverageLine ||
      annotations.showMinLine ||
      annotations.showMaxLine;

  PopupMenuItem<String> _buildMenuItem(
    String value,
    String label,
    IconData icon,
    bool isSelected,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isSelected ? colorTheme.primaryColor : null,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          if (isSelected)
            Icon(Icons.check, size: 18, color: colorTheme.primaryColor),
        ],
      ),
    );
  }
}

// =============================================================================
// Widgets partagés
// =============================================================================

/// Sélecteur de période pour les trend logs
class _PeriodSelector extends ConsumerWidget {
  final int trendLogInstance;
  final TrendLogViewerState state;

  const _PeriodSelector({
    required this.trendLogInstance,
    required this.state,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: TrendPeriod.values
            .where((p) => p != TrendPeriod.custom)
            .map((period) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(trendPeriodLabel(AppLocalizations.of(context)!, period)),
                    selected: state.selectedPeriod == period,
                    onSelected: state.isLoading
                        ? null
                        : (selected) {
                            if (selected) {
                              ref
                                  .read(trendLogViewerProvider(trendLogInstance).notifier)
                                  .setPeriod(period);
                            }
                          },
                  ),
                ))
            .toList(),
      ),
    );
  }
}

/// Affiche les statistiques du trend log
class _StatisticsBar extends StatelessWidget {
  final TrendLogData data;
  final ChartColorTheme? colorTheme;

  const _StatisticsBar({required this.data, this.colorTheme});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final valueRecords = data.records.where((r) => r.isValueRecord).length;
    final theme = colorTheme ?? ChartColorTheme.blue;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor.withAlpha(20),
            theme.primaryColor.withAlpha(8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.primaryColor.withAlpha(30),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            label: l10n.statisticsPoints,
            value: valueRecords.toString(),
            color: theme.primaryColor,
          ),
          if (data.minValue != null)
            _StatItem(
              label: l10n.statisticsMin,
              value: _formatValue(data.minValue!),
              color: theme.primaryColor,
              icon: Icons.arrow_downward,
            ),
          if (data.maxValue != null)
            _StatItem(
              label: l10n.statisticsMax,
              value: _formatValue(data.maxValue!),
              color: theme.primaryColor,
              icon: Icons.arrow_upward,
            ),
          if (data.avgValue != null)
            _StatItem(
              label: l10n.statisticsAvg,
              value: _formatValue(data.avgValue!),
              color: theme.primaryColor,
              icon: Icons.horizontal_rule,
            ),
        ],
      ),
    );
  }
}

/// Item de statistique individuel
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final IconData? icon;

  const _StatItem({
    required this.label,
    required this.value,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final displayColor = color ?? Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: displayColor.withAlpha(200)),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: displayColor,
          ),
        ),
      ],
    );
  }
}

/// Widget d'état de chargement
class _LoadingState extends StatelessWidget {
  final String? message;

  const _LoadingState({this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget d'état d'erreur
class _ErrorState extends ConsumerWidget {
  final String error;
  final int trendLogInstance;

  const _ErrorState({required this.error, required this.trendLogInstance});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => ref
                  .read(trendLogViewerProvider(trendLogInstance).notifier)
                  .loadData(),
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.of(context)!.retry),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget d'état vide
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.show_chart, size: 48, color: isDark ? Colors.grey.shade500 : Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.trendNoDataForPeriod,
              style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tableau de données du trend log
class _DataTable extends StatelessWidget {
  final TrendLogData data;
  final String? units;
  final double? fixedHeight;

  const _DataTable({
    required this.data,
    this.units,
    this.fixedHeight,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    var valueRecords = data.records.where((r) => r.isValueRecord).toList();

    // Trier par timestamp décroissant
    valueRecords.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Limiter si hauteur fixe (mode compact)
    if (fixedHeight != null) {
      valueRecords = valueRecords.take(100).toList();
    }

    final table = DataTable(
      columnSpacing: 16,
      headingRowHeight: fixedHeight != null ? 40 : 48,
      dataRowMinHeight: fixedHeight != null ? 36 : 40,
      dataRowMaxHeight: fixedHeight != null ? 36 : 40,
      columns: [
        DataColumn(label: Text(l10n.trendDateTime)),
        DataColumn(label: Text(l10n.value), numeric: true),
        DataColumn(label: Text(l10n.status)),
      ],
      rows: valueRecords.map((record) => _buildRow(record)).toList(),
    );

    if (fixedHeight != null) {
      return SizedBox(
        height: fixedHeight,
        child: SingleChildScrollView(child: table),
      );
    }

    return SingleChildScrollView(child: table);
  }

  DataRow _buildRow(TrendLogRecord record) {
    final fontSize = fixedHeight != null ? 12.0 : 13.0;

    return DataRow(
      cells: [
        DataCell(Text(
          DateFormat('dd/MM/yyyy HH:mm:ss').format(record.timestamp),
          style: TextStyle(fontSize: fontSize),
        )),
        DataCell(Text(
          record.numericValue != null
              ? '${_formatValue(record.numericValue!)}${units != null ? ' $units' : ''}'
              : record.value?.toString() ?? '-',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: fontSize),
        )),
        DataCell(Text(
          record.status ?? 'OK',
          style: TextStyle(
            fontSize: fontSize - 1,
            color: record.status == 'Normal' || record.status == null
                ? Colors.green
                : Colors.orange,
          ),
        )),
      ],
    );
  }
}

// =============================================================================
// TrendLogViewer - Widget principal (compact, dans une Card)
// =============================================================================

/// Widget pour afficher l'historique d'un trend log avec graphique
class TrendLogViewer extends ConsumerStatefulWidget {
  final int trendLogInstance;
  final String? pointName;
  final String? units;
  final ChartColorTheme? initialColorTheme;

  const TrendLogViewer({
    super.key,
    required this.trendLogInstance,
    this.pointName,
    this.units,
    this.initialColorTheme,
  });

  @override
  ConsumerState<TrendLogViewer> createState() => _TrendLogViewerState();
}

class _TrendLogViewerState extends ConsumerState<TrendLogViewer> {
  bool _showTable = false;
  late ChartColorTheme _colorTheme;

  @override
  void initState() {
    super.initState();
    _colorTheme = widget.initialColorTheme ?? ChartColorTheme.blue;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(trendLogViewerProvider(widget.trendLogInstance).notifier).loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trendLogViewerProvider(widget.trendLogInstance));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, state),
            const SizedBox(height: 16),
            _PeriodSelector(
              trendLogInstance: widget.trendLogInstance,
              state: state,
            ),
            const SizedBox(height: 16),
            _buildContent(state),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, TrendLogViewerState state) {
    final l10n = AppLocalizations.of(context)!;
    final hasData = state.data != null && state.data!.records.isNotEmpty;

    return Row(
      children: [
        Icon(Icons.show_chart, color: _colorTheme.primaryColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            l10n.trendHistory,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        // Sélecteur de couleur compact
        _ColorThemeSelector(
          selectedTheme: _colorTheme,
          onThemeChanged: (theme) => setState(() => _colorTheme = theme),
          compact: true,
        ),
        if (hasData)
          IconButton(
            icon: const Icon(Icons.fullscreen),
            tooltip: l10n.trendFullscreen,
            onPressed: () => _openFullscreen(context, state),
          ),
        IconButton(
          icon: Icon(_showTable ? Icons.show_chart : Icons.table_chart),
          tooltip: _showTable ? l10n.trendShowChart : l10n.trendShowTable,
          onPressed: () => setState(() => _showTable = !_showTable),
        ),
        if (hasData)
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: l10n.trendExportCsv,
            onPressed: () => _exportCsv(state.data!),
          ),
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: l10n.refresh,
          onPressed: state.isLoading
              ? null
              : () => ref
                  .read(trendLogViewerProvider(widget.trendLogInstance).notifier)
                  .refresh(),
        ),
      ],
    );
  }

  Widget _buildContent(TrendLogViewerState state) {
    if (state.isLoading) {
      return _LoadingState(message: state.loadingMessage);
    }

    if (state.error != null) {
      return _ErrorState(
        error: state.error!,
        trendLogInstance: widget.trendLogInstance,
      );
    }

    if (state.data == null || state.data!.records.isEmpty) {
      return const _EmptyState();
    }

    return Column(
      children: [
        _StatisticsBar(data: state.data!, colorTheme: _colorTheme),
        const SizedBox(height: 16),
        if (_showTable)
          _DataTable(
            data: state.data!,
            units: widget.units,
            fixedHeight: 250,
          )
        else
          _buildChart(state.data!),
      ],
    );
  }

  Widget _buildChart(TrendLogData data) {
    final chartData = _ChartData.fromRecords(data.records);
    if (chartData == null) return const _EmptyState();

    return SizedBox(
      height: 200,
      child: _TrendChart(
        chartData: chartData,
        units: widget.units,
        colorTheme: _colorTheme,
        showDots: true, // decided on visible points in _TrendChart
        dateFormat: 'HH:mm',
        enableZoom: false, // Désactivé en vue compacte
        showZoomControls: false,
      ),
    );
  }

  void _openFullscreen(BuildContext context, TrendLogViewerState state) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TrendLogFullscreenView(
          trendLogInstance: widget.trendLogInstance,
          pointName: widget.pointName,
          units: widget.units,
          initialData: state.data,
          initialColorTheme: _colorTheme,
        ),
      ),
    );
  }

  Future<void> _exportCsv(TrendLogData data) async {
    final valueRecords = data.records.where((r) => r.isValueRecord).toList();
    if (valueRecords.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;

    valueRecords.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final buffer = StringBuffer();
    buffer.writeln('Timestamp,Value,Unit,Status');

    for (final record in valueRecords) {
      final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(record.timestamp);
      final value = record.numericValue?.toString() ?? record.value?.toString() ?? '';
      final unit = widget.units ?? '';
      final status = record.status ?? 'Normal';
      buffer.writeln('$timestamp,$value,$unit,$status');
    }

    try {
      final directory = await getTemporaryDirectory();
      final fileName = 'trend_${widget.trendLogInstance}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(buffer.toString());

      if (mounted) {
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: l10n.trendExportSubject(widget.pointName ?? 'Trend Log ${widget.trendLogInstance}'),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.exportError(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// =============================================================================
// TrendLogFullscreenView - Vue plein écran
// =============================================================================

/// Vue plein écran du trend log avec graphique optimisé pour mobile
class TrendLogFullscreenView extends ConsumerStatefulWidget {
  final int trendLogInstance;
  final String? pointName;
  final String? units;
  final TrendLogData? initialData;
  final ChartColorTheme? initialColorTheme;

  const TrendLogFullscreenView({
    super.key,
    required this.trendLogInstance,
    this.pointName,
    this.units,
    this.initialData,
    this.initialColorTheme,
  });

  @override
  ConsumerState<TrendLogFullscreenView> createState() => _TrendLogFullscreenViewState();
}

class _TrendLogFullscreenViewState extends ConsumerState<TrendLogFullscreenView> {
  bool _isLandscape = false;
  bool _showTable = false;
  late ChartColorTheme _colorTheme;
  ChartAnnotations _annotations = const ChartAnnotations();

  @override
  void initState() {
    super.initState();
    _colorTheme = widget.initialColorTheme ?? ChartColorTheme.blue;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialData == null) {
        ref.read(trendLogViewerProvider(widget.trendLogInstance).notifier).loadData();
      }
    });
  }

  @override
  void dispose() {
    // Restaurer l'orientation automatique
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  void _toggleOrientation() {
    setState(() => _isLandscape = !_isLandscape);

    SystemChrome.setPreferredOrientations(_isLandscape
        ? [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]
        : [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trendLogViewerProvider(widget.trendLogInstance));
    final data = state.data ?? widget.initialData;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pointName ?? l10n.trendHistory),
        actions: [
          // Menu annotations (seulement si graphique visible)
          if (!_showTable)
            _AnnotationsMenu(
              annotations: _annotations,
              onChanged: (a) => setState(() => _annotations = a),
              colorTheme: _colorTheme,
            ),
          // Sélecteur de couleur compact
          _ColorThemeSelector(
            selectedTheme: _colorTheme,
            onThemeChanged: (theme) => setState(() => _colorTheme = theme),
            compact: true,
          ),
          IconButton(
            icon: Icon(_isLandscape ? Icons.screen_lock_portrait : Icons.screen_lock_landscape),
            tooltip: _isLandscape ? l10n.trendPortraitMode : l10n.trendLandscapeMode,
            onPressed: _toggleOrientation,
          ),
          IconButton(
            icon: Icon(_showTable ? Icons.show_chart : Icons.table_chart),
            tooltip: _showTable ? l10n.trendShowChart : l10n.trendShowTable,
            onPressed: () => setState(() => _showTable = !_showTable),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.refresh,
            onPressed: state.isLoading
                ? null
                : () => ref
                    .read(trendLogViewerProvider(widget.trendLogInstance).notifier)
                    .refresh(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Sélecteur de période + couleurs en mode non compact
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: _PeriodSelector(
                      trendLogInstance: widget.trendLogInstance,
                      state: state,
                    ),
                  ),
                ],
              ),
            ),
            // Barre de couleurs en mode paysage pour plus de visibilité
            if (_isLandscape && !_showTable)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: _ColorThemeSelector(
                  selectedTheme: _colorTheme,
                  onThemeChanged: (theme) => setState(() => _colorTheme = theme),
                  compact: false,
                ),
              ),
            if (data != null && data.records.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _StatisticsBar(data: data, colorTheme: _colorTheme),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildContent(state, data),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(TrendLogViewerState state, TrendLogData? data) {
    if (state.isLoading) {
      return _LoadingState(message: state.loadingMessage);
    }

    if (state.error != null) {
      return _ErrorState(
        error: state.error!,
        trendLogInstance: widget.trendLogInstance,
      );
    }

    if (data == null || data.records.isEmpty) {
      return const _EmptyState();
    }

    if (_showTable) {
      return _DataTable(data: data, units: widget.units);
    }

    return _buildFullscreenChart(data);
  }

  Widget _buildFullscreenChart(TrendLogData data) {
    final chartData = _ChartData.fromRecords(data.records);
    if (chartData == null) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Center(
        child: Text(
          AppLocalizations.of(context)!.trendNoNumericData,
          style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
        ),
      );
    }

    return _TrendChart(
      chartData: chartData,
      units: widget.units,
      colorTheme: _colorTheme,
      showDots: true, // decided on visible points in _TrendChart
      showVerticalGrid: true,
      showAxisLabel: true,
      dateFormat: _isLandscape ? 'HH:mm' : 'dd/MM\nHH:mm',
      rotateDateLabels: !_isLandscape,
      enableZoom: true,
      showZoomControls: true,
      annotations: _annotations,
    );
  }
}

// =============================================================================
// _TrendChart - Widget graphique réutilisable avec zoom interactif
// =============================================================================

/// Widget graphique de tendance réutilisable avec zoom et pan
class _TrendChart extends StatefulWidget {
  final _ChartData chartData;
  final String? units;
  final ChartColorTheme colorTheme;
  final bool showDots;
  final bool showVerticalGrid;
  final bool showAxisLabel;
  final String dateFormat;
  final bool rotateDateLabels;
  final bool enableZoom;
  final bool showZoomControls;
  final ChartAnnotations annotations;
  final bool startYAtZero; // Forcer l'origine Y à 0

  const _TrendChart({
    required this.chartData,
    required this.colorTheme,
    this.units,
    this.showDots = true,
    this.showVerticalGrid = false,
    this.showAxisLabel = false,
    this.dateFormat = 'HH:mm',
    this.rotateDateLabels = false,
    this.enableZoom = true,
    this.showZoomControls = true,
    this.annotations = const ChartAnnotations(),
    this.startYAtZero = true, // Par défaut, origine à 0
  });

  @override
  State<_TrendChart> createState() => _TrendChartState();
}

class _TrendChartState extends State<_TrendChart> {
  // Zoom et pan state
  double _zoomLevel = 1.0;
  double _panOffsetX = 0.0;
  double _panOffsetY = 0.0;

  // Pour le gesture detector
  double _lastScale = 1.0;
  Offset _lastFocalPoint = Offset.zero;

  // Limites de zoom
  static const double _minZoom = 1.0;
  static const double _maxZoom = 10.0;

  // Valeurs de base avec protection contre les ranges nuls
  double get _baseMinX => widget.chartData.spots.isNotEmpty
      ? widget.chartData.spots.first.x
      : 0.0;

  double get _baseMaxX => widget.chartData.spots.isNotEmpty
      ? widget.chartData.spots.last.x
      : 1.0;

  double get _totalRangeX {
    final range = _baseMaxX - _baseMinX;
    return range > 0 ? range : 1.0; // Éviter division par 0
  }

  double get _baseMinY {
    if (widget.startYAtZero && widget.chartData.minY >= 0) {
      // Si origine à 0 et toutes les valeurs sont positives, commencer à 0
      return 0.0;
    }
    return widget.chartData.minY - widget.chartData.yPadding;
  }

  double get _baseMaxY => widget.chartData.maxY + widget.chartData.yPadding;

  double get _totalRangeY {
    final range = _baseMaxY - _baseMinY;
    return range > 0 ? range : 1.0; // Éviter division par 0
  }

  // Calcul des bounds visibles
  double get _visibleMinX {
    final visibleRange = _totalRangeX / _zoomLevel;
    final minX = _baseMinX + _panOffsetX;
    final maxAllowedMinX = _baseMaxX - visibleRange;
    if (maxAllowedMinX <= _baseMinX) return _baseMinX;
    return minX.clamp(_baseMinX, maxAllowedMinX);
  }

  double get _visibleMaxX {
    final visibleRange = _totalRangeX / _zoomLevel;
    return _visibleMinX + visibleRange;
  }

  double get _visibleMinY {
    final visibleRange = _totalRangeY / _zoomLevel;
    final centerY = (_baseMinY + _baseMaxY) / 2 + _panOffsetY;
    final minAllowed = _baseMinY;
    final maxAllowed = _baseMaxY - visibleRange;
    if (maxAllowed <= minAllowed) return _baseMinY;
    return (centerY - visibleRange / 2).clamp(minAllowed, maxAllowed);
  }

  double get _visibleMaxY {
    final visibleRange = _totalRangeY / _zoomLevel;
    return _visibleMinY + visibleRange;
  }

  void _resetZoom() {
    setState(() {
      _zoomLevel = 1.0;
      _panOffsetX = 0.0;
      _panOffsetY = 0.0;
    });
  }

  void _zoomIn() {
    setState(() {
      _zoomLevel = (_zoomLevel * 1.5).clamp(_minZoom, _maxZoom);
    });
  }

  void _zoomOut() {
    setState(() {
      _zoomLevel = (_zoomLevel / 1.5).clamp(_minZoom, _maxZoom);
      // Réajuster le pan si nécessaire
      _clampPanOffset();
    });
  }

  void _clampPanOffset() {
    final visibleRangeX = _totalRangeX / _zoomLevel;
    final maxPanX = _totalRangeX - visibleRangeX;
    _panOffsetX = _panOffsetX.clamp(0.0, maxPanX > 0 ? maxPanX : 0.0);

    final visibleRangeY = _totalRangeY / _zoomLevel;
    final maxPanY = (_totalRangeY - visibleRangeY) / 2;
    _panOffsetY = _panOffsetY.clamp(maxPanY > 0 ? -maxPanY : 0.0, maxPanY > 0 ? maxPanY : 0.0);
  }

  void _onScaleStart(ScaleStartDetails details) {
    _lastScale = _zoomLevel;
    _lastFocalPoint = details.localFocalPoint;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (!widget.enableZoom) return;

    setState(() {
      // Gestion du zoom (pinch)
      if (details.scale != 1.0) {
        _zoomLevel = (_lastScale * details.scale).clamp(_minZoom, _maxZoom);
      }

      // Gestion du pan (drag)
      final delta = details.localFocalPoint - _lastFocalPoint;
      _lastFocalPoint = details.localFocalPoint;

      // Sensibilité du pan ajustée au zoom (avec protection division par 0)
      final panSensitivityX = _totalRangeX / 300 / _zoomLevel;
      final panSensitivityY = _totalRangeY / 200 / _zoomLevel;

      _panOffsetX -= delta.dx * panSensitivityX;
      _panOffsetY += delta.dy * panSensitivityY;

      _clampPanOffset();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Protection: vérifier qu'on a des données valides
    if (widget.chartData.spots.isEmpty) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Center(
        child: Text(
          AppLocalizations.of(context)!.trendNoDataToDisplay,
          style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
        ),
      );
    }

    final isZoomed = _zoomLevel > 1.0;

    return Stack(
      children: [
        // Graphique avec gestion des gestes
        GestureDetector(
          onScaleStart: widget.enableZoom ? _onScaleStart : null,
          onScaleUpdate: widget.enableZoom ? _onScaleUpdate : null,
          onDoubleTap: widget.enableZoom ? _resetZoom : null,
          child: _buildChart(),
        ),

        // Contrôles de zoom
        if (widget.showZoomControls && widget.enableZoom)
          Positioned(
            right: 8,
            top: 8,
            child: _ZoomControls(
              colorTheme: widget.colorTheme,
              zoomLevel: _zoomLevel,
              isZoomed: isZoomed,
              onZoomIn: _zoomIn,
              onZoomOut: _zoomOut,
              onReset: _resetZoom,
            ),
          ),

        // Indicateur de zoom
        if (isZoomed)
          Positioned(
            left: 8,
            top: 8,
            child: _ZoomIndicator(
              zoomLevel: _zoomLevel,
              colorTheme: widget.colorTheme,
            ),
          ),
      ],
    );
  }

  // Cache des spots affichés (fenêtre + décimation)
  List<FlSpot>? _cachedSpots;
  List<FlSpot>? _cachedSource;
  double _cachedMinX = double.nan;
  double _cachedMaxX = double.nan;

  List<FlSpot> _getVisibleSpots(double fromX, double toX) {
    final source = widget.chartData.spots;
    if (_cachedSpots != null &&
        identical(_cachedSource, source) &&
        _cachedMinX == fromX &&
        _cachedMaxX == toX) {
      return _cachedSpots!;
    }
    final result = downsampleMinMax(
      visibleWindow(source, fromX, toX).where((s) => !s.x.isNaN && !s.y.isNaN).toList(),
    );
    _cachedSpots = result;
    _cachedSource = source;
    _cachedMinX = fromX;
    _cachedMaxX = toX;
    return result;
  }

  @override
  void didUpdateWidget(covariant _TrendChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Nouvelles données : on repart d'une vue complète
    if (!identical(oldWidget.chartData, widget.chartData) &&
        !identical(oldWidget.chartData.spots, widget.chartData.spots)) {
      _zoomLevel = 1.0;
      _panOffsetX = 0.0;
      _panOffsetY = 0.0;
    }
  }

  Widget _buildChart() {
    // Protection contre les valeurs invalides
    final minX = _visibleMinX;
    final maxX = _visibleMaxX;
    final minY = _visibleMinY;
    final maxY = _visibleMaxY;

    // Vérifier que les valeurs sont valides
    if (minX.isNaN || maxX.isNaN || minY.isNaN || maxY.isNaN ||
        minX.isInfinite || maxX.isInfinite || minY.isInfinite || maxY.isInfinite ||
        minX >= maxX || minY >= maxY) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Center(
        child: Text(
          AppLocalizations.of(context)!.trendInvalidData,
          style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
        ),
      );
    }

    final l10n = AppLocalizations.of(context)!;
    final yRange = maxY - minY;
    final xRange = maxX - minX;

    // Fenêtre visible (recherche dichotomique) puis décimation, mise en cache
    var visibleSpots = _getVisibleSpots(minX - xRange * 0.1, maxX + xRange * 0.1);
    if (visibleSpots.isEmpty) {
      visibleSpots = downsampleMinMax(widget.chartData.spots);
    }
    final richRendering = visibleSpots.length <= kRichRenderingMaxPoints;

    // Construire les lignes horizontales d'annotation
    final extraHorizontalLines = <HorizontalLine>[];

    if (widget.annotations.showAverageLine) {
      extraHorizontalLines.add(HorizontalLine(
        y: widget.chartData.avgY,
        color: Colors.orange.withAlpha(180),
        strokeWidth: 1.5,
        dashArray: [8, 4],
        label: HorizontalLineLabel(
          show: true,
          alignment: Alignment.topRight,
          padding: const EdgeInsets.only(right: 4, bottom: 2),
          style: TextStyle(
            color: Colors.orange.shade700,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
          labelResolver: (line) => l10n.trendAvgLineLabel(_formatValue(line.y)),
        ),
      ));
    }

    if (widget.annotations.showMinLine) {
      extraHorizontalLines.add(HorizontalLine(
        y: widget.chartData.minY,
        color: Colors.blue.withAlpha(150),
        strokeWidth: 1,
        dashArray: [6, 4],
        label: HorizontalLineLabel(
          show: true,
          alignment: Alignment.topRight,
          padding: const EdgeInsets.only(right: 4, bottom: 2),
          style: TextStyle(
            color: Colors.blue.shade700,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
          labelResolver: (line) => 'Min: ${_formatValue(line.y)}',
        ),
      ));
    }

    if (widget.annotations.showMaxLine) {
      extraHorizontalLines.add(HorizontalLine(
        y: widget.chartData.maxY,
        color: Colors.red.withAlpha(150),
        strokeWidth: 1,
        dashArray: [6, 4],
        label: HorizontalLineLabel(
          show: true,
          alignment: Alignment.bottomRight,
          padding: const EdgeInsets.only(right: 4, top: 2),
          style: TextStyle(
            color: Colors.red.shade700,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
          labelResolver: (line) => 'Max: ${_formatValue(line.y)}',
        ),
      ));
    }

    // Ajouter les seuils personnalisés
    for (final threshold in widget.annotations.thresholds) {
      extraHorizontalLines.add(HorizontalLine(
        y: threshold.value,
        color: threshold.color.withAlpha(180),
        strokeWidth: 1.5,
        dashArray: [4, 4],
        label: threshold.label != null
            ? HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                padding: const EdgeInsets.only(right: 4),
                style: TextStyle(
                  color: threshold.color,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                labelResolver: (line) => threshold.label!,
              )
            : null,
      ));
    }

    return LineChart(
      LineChartData(
        clipData: const FlClipData.all(),
        extraLinesData: ExtraLinesData(
          horizontalLines: extraHorizontalLines,
        ),
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          drawVerticalLine: widget.showVerticalGrid,
          horizontalInterval: yRange > 0 ? yRange / 4 : 1,
          getDrawingHorizontalLine: (value) => FlLine(
            color: widget.colorTheme.gridColor.withAlpha(60),
            strokeWidth: 0.5,
          ),
          getDrawingVerticalLine: (value) => FlLine(
            color: widget.colorTheme.gridColor.withAlpha(40),
            strokeWidth: 0.5,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            axisNameWidget: widget.showAxisLabel && widget.units != null
                ? Text(
                    widget.units!,
                    style: TextStyle(color: widget.colorTheme.axisColor, fontSize: 12),
                  )
                : null,
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: widget.showAxisLabel ? 60 : 50,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    _formatValue(value),
                    style: TextStyle(color: widget.colorTheme.axisColor, fontSize: 10),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: widget.rotateDateLabels ? 50 : 30,
              interval: xRange > 0 ? xRange / 6 : null,
              getTitlesWidget: (value, meta) => _buildDateLabel(value),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            left: BorderSide(color: widget.colorTheme.axisColor),
            bottom: BorderSide(color: widget.colorTheme.axisColor),
          ),
        ),
        minX: minX,
        maxX: maxX,
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: visibleSpots,
            isCurved: richRendering,
            curveSmoothness: 0.15, // Réduire pour moins d'overshoot
            preventCurveOverShooting: true, // Empêcher les dépassements
            preventCurveOvershootingThreshold: 0.0, // Strictement pas de dépassement
            color: widget.colorTheme.primaryColor,
            barWidth: 2.5,
            shadow: richRendering
                ? Shadow(
                    color: widget.colorTheme.primaryColor.withAlpha(60),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                : const Shadow(color: Colors.transparent),
            dotData: FlDotData(
              show: widget.showDots && visibleSpots.length < 50,
              getDotPainter: (spot, percent, barData, index) {
                // Marqueurs spéciaux pour min/max
                if (widget.annotations.showMinMaxMarkers) {
                  final currentSpot = visibleSpots[index];

                  // Vérifier si c'est le point min
                  if (widget.chartData.minSpot != null &&
                      currentSpot.x == widget.chartData.minSpot!.x &&
                      currentSpot.y == widget.chartData.minSpot!.y) {
                    return FlDotCirclePainter(
                      radius: 6,
                      color: Colors.blue,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    );
                  }

                  // Vérifier si c'est le point max
                  if (widget.chartData.maxSpot != null &&
                      currentSpot.x == widget.chartData.maxSpot!.x &&
                      currentSpot.y == widget.chartData.maxSpot!.y) {
                    return FlDotCirclePainter(
                      radius: 6,
                      color: Colors.red,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    );
                  }
                }

                return FlDotCirclePainter(
                  radius: 4,
                  color: widget.colorTheme.dotColor,
                  strokeWidth: 2,
                  strokeColor: widget.colorTheme.dotBorderColor,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  widget.colorTheme.gradientStart,
                  widget.colorTheme.gradientEnd,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            tooltipRoundedRadius: 12,
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            tooltipMargin: 12,
            getTooltipColor: (touchedSpot) => widget.colorTheme.tooltipBackground,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final timestamp = DateTime.fromMillisecondsSinceEpoch(
                  (widget.chartData.minTimestamp + spot.x * 60 * 1000).toInt(),
                );

                // Déterminer si c'est un point spécial (min/max)
                final isMin = widget.chartData.minSpot != null &&
                    spot.x == widget.chartData.minSpot!.x &&
                    spot.y == widget.chartData.minSpot!.y;
                final isMax = widget.chartData.maxSpot != null &&
                    spot.x == widget.chartData.maxSpot!.x &&
                    spot.y == widget.chartData.maxSpot!.y;

                // Calculer le delta par rapport à la moyenne
                final deltaFromAvg = spot.y - widget.chartData.avgY;
                final deltaSign = deltaFromAvg >= 0 ? '+' : '';
                final deltaPercent = widget.chartData.avgY != 0
                    ? (deltaFromAvg / widget.chartData.avgY * 100)
                    : 0.0;

                // Construire le texte du tooltip
                final buffer = StringBuffer();

                // Badge min/max
                if (isMin) {
                  buffer.write('▼ MIN\n');
                } else if (isMax) {
                  buffer.write('▲ MAX\n');
                }

                // Date/heure
                buffer.write(DateFormat('dd/MM/yyyy HH:mm').format(timestamp));
                buffer.write('\n');

                // Valeur principale
                buffer.write(_formatValue(spot.y));
                if (widget.units != null) {
                  buffer.write(' ${widget.units}');
                }

                // Delta par rapport à la moyenne (si annotations activées)
                if (widget.annotations.showAverageLine && !isMin && !isMax) {
                  buffer.write('\n');
                  buffer.write('$deltaSign${_formatValue(deltaFromAvg)}');
                  buffer.write(' ($deltaSign${deltaPercent.toStringAsFixed(1)}%)');
                }

                return LineTooltipItem(
                  buffer.toString(),
                  TextStyle(
                    color: widget.colorTheme.tooltipText,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                  children: isMin || isMax
                      ? [
                          TextSpan(
                            text: '',
                            style: TextStyle(
                              color: isMin ? Colors.lightBlue.shade200 : Colors.red.shade200,
                            ),
                          ),
                        ]
                      : null,
                );
              }).toList();
            },
          ),
          touchSpotThreshold: 20,
          getTouchedSpotIndicator: (barData, spotIndexes) {
            return spotIndexes.map((spotIndex) {
              final spot = barData.spots[spotIndex];

              // Couleur spéciale pour min/max
              final isMin = widget.chartData.minSpot != null &&
                  spot.x == widget.chartData.minSpot!.x &&
                  spot.y == widget.chartData.minSpot!.y;
              final isMax = widget.chartData.maxSpot != null &&
                  spot.x == widget.chartData.maxSpot!.x &&
                  spot.y == widget.chartData.maxSpot!.y;

              final indicatorColor = isMin
                  ? Colors.blue
                  : isMax
                      ? Colors.red
                      : widget.colorTheme.primaryColor;

              return TouchedSpotIndicatorData(
                FlLine(
                  color: indicatorColor.withAlpha(100),
                  strokeWidth: 2,
                  dashArray: [5, 5],
                ),
                FlDotData(
                  getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                    radius: 7,
                    color: widget.colorTheme.dotBorderColor,
                    strokeWidth: 3,
                    strokeColor: indicatorColor,
                  ),
                ),
              );
            }).toList();
          },
        ),
      ),
      duration: richRendering ? const Duration(milliseconds: 150) : Duration.zero,
      curve: Curves.easeOut,
    );
  }

  Widget _buildDateLabel(double value) {
    final timestamp = DateTime.fromMillisecondsSinceEpoch(
      (widget.chartData.minTimestamp + value * 60 * 1000).toInt(),
    );

    final label = Text(
      DateFormat(widget.dateFormat).format(timestamp),
      style: TextStyle(color: widget.colorTheme.axisColor, fontSize: 10),
      textAlign: TextAlign.center,
    );

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: widget.rotateDateLabels ? RotatedBox(quarterTurns: -1, child: label) : label,
    );
  }
}

/// Contrôles de zoom pour le graphique
class _ZoomControls extends StatelessWidget {
  final ChartColorTheme colorTheme;
  final double zoomLevel;
  final bool isZoomed;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onReset;

  const _ZoomControls({
    required this.colorTheme,
    required this.zoomLevel,
    required this.isZoomed,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(230),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ZoomButton(
            icon: Icons.add,
            onTap: zoomLevel < 10.0 ? onZoomIn : null,
            colorTheme: colorTheme,
          ),
          Container(
            height: 1,
            width: 28,
            color: Colors.grey.withAlpha(50),
          ),
          _ZoomButton(
            icon: Icons.remove,
            onTap: zoomLevel > 1.0 ? onZoomOut : null,
            colorTheme: colorTheme,
          ),
          if (isZoomed) ...[
            Container(
              height: 1,
              width: 28,
              color: Colors.grey.withAlpha(50),
            ),
            _ZoomButton(
              icon: Icons.fit_screen,
              onTap: onReset,
              colorTheme: colorTheme,
              tooltip: AppLocalizations.of(context)!.reset,
            ),
          ],
        ],
      ),
    );
  }
}

/// Bouton de zoom individuel
class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final ChartColorTheme colorTheme;
  final String? tooltip;

  const _ZoomButton({
    required this.icon,
    required this.onTap,
    required this.colorTheme,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;

    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 18,
            color: isEnabled
                ? colorTheme.primaryColor
                : Colors.grey.withAlpha(100),
          ),
        ),
      ),
    );
  }
}

/// Indicateur de niveau de zoom
class _ZoomIndicator extends StatelessWidget {
  final double zoomLevel;
  final ChartColorTheme colorTheme;

  const _ZoomIndicator({
    required this.zoomLevel,
    required this.colorTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorTheme.primaryColor.withAlpha(200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${zoomLevel.toStringAsFixed(1)}x',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// =============================================================================
// TrendLogIndicator - Indicateur compact pour la liste des points
// =============================================================================

// =============================================================================
// EmbeddedTrendChart - Widget graphique compact pour les dashboards
// =============================================================================

/// Widget graphique compact pour intégration dans les dashboards
/// Ne contient pas de Card, s'adapte à l'espace disponible
class EmbeddedTrendChart extends ConsumerWidget {
  final int trendLogInstance;
  final String? units;
  final ChartColorTheme colorTheme;

  const EmbeddedTrendChart({
    super.key,
    required this.trendLogInstance,
    this.units,
    this.colorTheme = ChartColorTheme.blue,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(trendLogViewerProvider(trendLogInstance));

    if (state.isLoading && state.data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade300, size: 32),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.loadingError,
              style: TextStyle(color: Colors.red.shade600, fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (state.data == null || state.data!.records.isEmpty) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.show_chart,
              size: 32,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.noData,
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    final chartData = _ChartData.fromRecords(state.data!.records);
    if (chartData == null) {
      return Center(child: Text(AppLocalizations.of(context)!.trendNoNumericData));
    }

    // Widget qui s'adapte à l'espace disponible
    return Padding(
      padding: const EdgeInsets.all(8),
      child: _TrendChart(
        chartData: chartData,
        units: units,
        colorTheme: colorTheme,
        showDots: true, // decided on visible points in _TrendChart
        dateFormat: 'HH:mm',
        enableZoom: false,
        showZoomControls: false,
        showVerticalGrid: false,
        showAxisLabel: false,
      ),
    );
  }
}

/// Widget compact pour afficher l'icône de trend dans la liste des points
class TrendLogIndicator extends ConsumerWidget {
  final String pointKey;
  final VoidCallback? onTap;

  const TrendLogIndicator({
    super.key,
    required this.pointKey,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mappingAsync = ref.watch(trendLogMappingProvider);

    return mappingAsync.when(
      data: (mapping) {
        if (!mapping.containsKey(pointKey)) {
          return const SizedBox.shrink();
        }

        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(
              Icons.show_chart,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
