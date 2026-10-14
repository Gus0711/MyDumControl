import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/providers/multi_curve_provider.dart';
import '../../application/providers/points_provider.dart';
import '../../domain/models/multi_curve_chart.dart';
import '../../l10n/app_localizations.dart';
import 'trend_log_viewer.dart';

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

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 500,
          maxHeight: 600,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.multiline_chart,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.chartSelectCurves,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 18, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.chartSelectCurvesHint(widget.minCurves, widget.maxCurves),
                        style: const TextStyle(fontSize: 13, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Compteur de sélection
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _selectedInstances.length >= widget.minCurves
                      ? Colors.green.withAlpha(20)
                      : Colors.orange.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _selectedInstances.length >= widget.minCurves
                        ? Colors.green.withAlpha(50)
                        : Colors.orange.withAlpha(50),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.chartCurvesCount(_selectedInstances.length, widget.maxCurves),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _selectedInstances.length >= widget.minCurves
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                      ),
                    ),
                    if (_selectedInstances.isNotEmpty)
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedInstances.clear();
                          });
                        },
                        icon: const Icon(Icons.clear_all, size: 18),
                        label: Text(l10n.deselectAll),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey.shade600,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Recherche
              TextField(
                decoration: InputDecoration(
                  hintText: l10n.searchPoint,
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  isDense: true,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),

              const SizedBox(height: 16),

              // Liste des trend logs
              Expanded(
                child: availableTrendLogs.when(
                  data: (trendLogs) {
                    if (trendLogs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.show_chart, size: 48, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              l10n.chartNoTrendLogAvailable,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
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
                                _selectedInstances.toList().indexOf(trendLog.instance)))
                            : null;

                        final pointName = _getPointName(trendLog.pointKey, pointsState);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          elevation: isSelected ? 2 : 0,
                          color: isSelected
                              ? colorTheme!.primaryColor.withAlpha(15)
                              : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isSelected
                                  ? colorTheme!.primaryColor.withAlpha(50)
                                  : Colors.grey.withAlpha(30),
                            ),
                          ),
                          child: InkWell(
                            onTap: () => _toggleSelection(
                              trendLog.instance,
                              name: pointName ?? trendLog.pointName ?? trendLog.pointKey,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  // Checkbox avec couleur
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? colorTheme!.primaryColor
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isSelected
                                            ? colorTheme!.primaryColor
                                            : Colors.grey.shade400,
                                        width: 2,
                                      ),
                                    ),
                                    child: isSelected
                                        ? const Icon(
                                            Icons.check,
                                            size: 16,
                                            color: Colors.white,
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
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: isSelected
                                                ? colorTheme!.primaryColor
                                                : null,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Trend Log: ${trendLog.instance} • Point: ${trendLog.pointKey}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Badge couleur si sélectionné
                                  if (isSelected)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: colorTheme!.primaryColor,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '#${_selectedInstances.toList().indexOf(trendLog.instance) + 1}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline,
                            size: 48, color: Colors.red.shade300),
                        const SizedBox(height: 16),
                        Text(
                          l10n.errorWithMessage(error.toString()),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.red.shade600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Aperçu des sélections
              if (_selectedInstances.isNotEmpty) ...[
                Text(
                  l10n.chartSelectedCurves,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedInstances.toList().asMap().entries.map((entry) {
                    final index = entry.key;
                    final instance = entry.value;
                    final colorTheme =
                        ChartColorTheme.fromName(getColorThemeByIndex(index));

                    return Chip(
                      label: Text('TL $instance'),
                      backgroundColor: colorTheme.primaryColor.withAlpha(30),
                      side: BorderSide(color: colorTheme.primaryColor.withAlpha(50)),
                      labelStyle: TextStyle(
                        color: colorTheme.primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      deleteIcon: Icon(
                        Icons.close,
                        size: 16,
                        color: colorTheme.primaryColor,
                      ),
                      onDeleted: () => _toggleSelection(instance, name: null),
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
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _selectedInstances.length >= widget.minCurves
                        ? () => Navigator.of(context).pop(CurveSelectionResult(
                            instances: _selectedInstances.toList(),
                            names: Map.from(_selectedNames),
                          ))
                        : null,
                    icon: const Icon(Icons.check),
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
