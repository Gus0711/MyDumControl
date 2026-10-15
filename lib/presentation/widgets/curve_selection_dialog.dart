import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/providers/multi_curve_provider.dart';
import '../../application/providers/points_provider.dart';
import '../../domain/models/multi_curve_chart.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/dc_tokens.dart';
import 'chart_chrome.dart';
import 'trend_log_viewer.dart';
import 'ui/dc_banner.dart';
import 'ui/dc_layout.dart';
import 'ui/dc_tag.dart';

/// Dialogue pour sélectionner les trend logs à afficher dans un graphique multi-courbes
class CurveSelectionDialog extends ConsumerStatefulWidget {
  /// Instances déjà sélectionnées (pour édition)
  final List<int> initialSelection;

  /// Nombre minimum de courbes (défaut: 2)
  final int minCurves;

  /// Nombre maximum de courbes (défaut: 8)
  final int maxCurves;

  const CurveSelectionDialog({
    super.key,
    this.initialSelection = const [],
    this.minCurves = 2,
    this.maxCurves = 8,
  });

  @override
  ConsumerState<CurveSelectionDialog> createState() =>
      _CurveSelectionDialogState();
}

class _CurveSelectionDialogState extends ConsumerState<CurveSelectionDialog> {
  late Set<int> _selectedInstances;
  final Map<int, String> _selectedNames = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedInstances = Set.from(widget.initialSelection);
  }

  @override
  Widget build(BuildContext context) {
    final availableTrendLogs = ref.watch(availableTrendLogsProvider);
    final pointsState = ref.watch(pointsProvider);
    final l10n = AppLocalizations.of(context)!;
    final dc = context.dc;
    final enough = _selectedInstances.length >= widget.minCurves;
    final selectedList = _selectedInstances.toList();

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 520,
          maxHeight: 640,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  DcIconBox(icon: Icons.stacked_line_chart_rounded, tone: dc.violet, size: 38),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.chartSelectCurves,
                      style: context.text.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    tooltip: l10n.cancel,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Info
              DcBanner(
                tone: dc.info,
                icon: Icons.info_outline_rounded,
                message: l10n.chartSelectCurvesHint(widget.minCurves, widget.maxCurves),
                dense: true,
              ),

              const SizedBox(height: 12),

              // Recherche + compteur de sélection
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: l10n.searchPoint,
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        isDense: true,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  DcTag(
                    l10n.chartCurvesCount(_selectedInstances.length, widget.maxCurves),
                    icon: enough ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                    tone: enough ? dc.success : dc.warning,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Liste des trend logs
              Expanded(
                child: availableTrendLogs.when(
                  data: (trendLogs) {
                    if (trendLogs.isEmpty) {
                      return ChartMessage(
                        icon: Icons.show_chart_rounded,
                        message: l10n.chartNoTrendLogAvailable,
                      );
                    }

                    // Filtrer par recherche
                    var filteredLogs = trendLogs;
                    if (_searchQuery.isNotEmpty) {
                      filteredLogs = trendLogs.where((tl) {
                        final pointName = _getPointName(tl.pointKey, pointsState);
                        return tl.pointKey.toLowerCase().contains(_searchQuery) ||
                            (pointName?.toLowerCase().contains(_searchQuery) ?? false);
                      }).toList();
                    }

                    return ListView.builder(
                      itemCount: filteredLogs.length,
                      itemBuilder: (context, index) {
                        final trendLog = filteredLogs[index];
                        final isSelected =
                            _selectedInstances.contains(trendLog.instance);
                        final colorTheme = isSelected
                            ? ChartColorTheme.fromName(getColorThemeByIndex(
                                selectedList.indexOf(trendLog.instance)))
                            : null;
                        final seriesColor =
                            colorTheme != null ? chartSeriesColor(context, colorTheme.primaryColor) : null;
                        final tone = colorTheme != null ? dc.toneOf(colorTheme.primaryColor) : null;

                        final pointName = _getPointName(trendLog.pointKey, pointsState);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Material(
                            color: isSelected ? tone!.bg : dc.surface,
                            borderRadius: BorderRadius.circular(DcRadius.md),
                            child: InkWell(
                              onTap: () => _toggleSelection(
                                trendLog.instance,
                                name: pointName ?? trendLog.pointName ?? trendLog.pointKey,
                              ),
                              borderRadius: BorderRadius.circular(DcRadius.md),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(DcRadius.md),
                                  border: Border.all(color: isSelected ? tone!.border : dc.border),
                                ),
                                child: Row(
                                  children: [
                                    // Case à cocher à la couleur de la courbe
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 160),
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        color: isSelected ? seriesColor : Colors.transparent,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: isSelected ? seriesColor! : dc.borderStrong,
                                          width: 1.6,
                                        ),
                                      ),
                                      child: isSelected
                                          ? Icon(
                                              Icons.check_rounded,
                                              size: 16,
                                              color: dc.isDark ? dc.canvas : Colors.white,
                                            )
                                          : null,
                                    ),

                                    const SizedBox(width: 12),

                                    // Info du point
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            pointName ?? trendLog.pointKey,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: context.text.titleSmall?.copyWith(
                                              color: isSelected ? tone!.fg : dc.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'TL ${trendLog.instance} · ${trendLog.pointKey}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTextStyles.monospacedValue.copyWith(
                                              fontSize: 11,
                                              color: dc.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Numéro d'ordre si sélectionné
                                    if (isSelected)
                                      DcTag(
                                        '#${selectedList.indexOf(trendLog.instance) + 1}',
                                        tone: tone,
                                        mono: true,
                                        dense: true,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const ChartMessage.loading(),
                  error: (error, _) => ChartMessage(
                    icon: Icons.error_outline_rounded,
                    tone: dc.danger,
                    message: l10n.errorWithMessage(error.toString()),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Aperçu des sélections
              if (_selectedInstances.isNotEmpty) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.chartSelectedCurves.toUpperCase(),
                        style: AppTextStyles.overline.copyWith(color: dc.textMuted),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedInstances.clear();
                        });
                      },
                      icon: const Icon(Icons.clear_all_rounded, size: 18),
                      label: Text(l10n.deselectAll),
                      style: TextButton.styleFrom(
                        foregroundColor: dc.textSecondary,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: selectedList.asMap().entries.map((entry) {
                    final index = entry.key;
                    final instance = entry.value;
                    final colorTheme =
                        ChartColorTheme.fromName(getColorThemeByIndex(index));
                    final tone = dc.toneOf(colorTheme.primaryColor);

                    return InputChip(
                      label: Text('TL $instance'),
                      backgroundColor: tone.bg,
                      side: BorderSide(color: tone.border),
                      labelStyle: AppTextStyles.monospacedValue.copyWith(
                        color: tone.fg,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      avatar: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: chartSeriesColor(context, colorTheme.primaryColor),
                          shape: BoxShape.circle,
                        ),
                      ),
                      deleteIcon: Icon(Icons.close_rounded, size: 16, color: tone.fg),
                      onDeleted: () => _toggleSelection(instance, name: null),
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],

              // Boutons d'action
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.cancel),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: enough
                        ? () => Navigator.of(context).pop(CurveSelectionResult(
                            instances: _selectedInstances.toList(),
                            names: Map.from(_selectedNames),
                          ))
                        : null,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: Text(l10n.chartValidateCount(_selectedInstances.length)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleSelection(int instance, {String? name}) {
    setState(() {
      if (_selectedInstances.contains(instance)) {
        _selectedInstances.remove(instance);
        _selectedNames.remove(instance);
      } else if (_selectedInstances.length < widget.maxCurves) {
        _selectedInstances.add(instance);
        if (name != null) {
          _selectedNames[instance] = name;
        }
      }
    });
  }

  String? _getPointName(String pointKey, PointsState pointsState) {
    // Essayer de trouver le nom du point depuis le provider
    // pointKey est au format "analog-input:101" (apiName)
    try {
      final parts = pointKey.split(':');
      if (parts.length == 2) {
        final point = pointsState.points.firstWhere(
          (p) => p.type.apiName == parts[0] && p.instance.toString() == parts[1],
        );
        return point.displayName;
      }
    } catch (_) {}
    return null;
  }
}

/// Résultat de la sélection de courbes avec les noms
class CurveSelectionResult {
  final List<int> instances;
  final Map<int, String> names;

  const CurveSelectionResult({
    required this.instances,
    required this.names,
  });
}

/// Affiche le dialogue de sélection des courbes et retourne les instances sélectionnées avec leurs noms
Future<CurveSelectionResult?> showCurveSelectionDialog(
  BuildContext context, {
  List<int> initialSelection = const [],
  int minCurves = 2,
  int maxCurves = 8,
}) async {
  return showDialog<CurveSelectionResult>(
    context: context,
    builder: (context) => CurveSelectionDialog(
      initialSelection: initialSelection,
      minCurves: minCurves,
      maxCurves: maxCurves,
    ),
  );
}
