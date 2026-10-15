import 'package:flutter/material.dart';

import '../../core/theme/app_text_styles.dart';
import '../../core/theme/dc_tokens.dart';

/// Habillage commun des graphiques (courbes de tendance, multi-courbes) :
/// couleurs d'axes et de grille, infobulles, sélecteur segmenté, blocs de
/// statistiques et messages d'état compacts.

/// Couleurs et styles d'un graphique, tirés des jetons du thème courant.
class ChartPalette {
  final Color grid;
  final Color axis;
  final Color tooltipBackground;
  final Color tooltipText;
  final Color dotStroke;
  final TextStyle axisLabel;

  const ChartPalette._({
    required this.grid,
    required this.axis,
    required this.tooltipBackground,
    required this.tooltipText,
    required this.dotStroke,
    required this.axisLabel,
  });

  factory ChartPalette.of(BuildContext context) {
    final dc = context.dc;
    final scheme = Theme.of(context).colorScheme;
    return ChartPalette._(
      grid: dc.border.withValues(alpha: dc.isDark ? 0.9 : 0.8),
      axis: dc.borderStrong,
      tooltipBackground: scheme.inverseSurface,
      tooltipText: scheme.onInverseSurface,
      dotStroke: dc.surface,
      axisLabel: AppTextStyles.monospacedValue.copyWith(
        color: dc.textMuted,
        fontSize: 10,
        fontWeight: FontWeight.w500,
        height: 1.25,
      ),
    );
  }
}

/// Couleur d'une série lisible sur le fond courant : en thème sombre, les
/// teintes trop foncées (indigo, violet…) sont éclaircies.
Color chartSeriesColor(BuildContext context, Color color) {
  if (!context.dc.isDark) return color;
  final hsl = HSLColor.fromColor(color);
  return hsl.lightness < 0.6 ? hsl.withLightness(0.62).toColor() : color;
}

/// Sélecteur segmenté compact (périodes…), défilable horizontalement.
class ChartSegmented<T> extends StatelessWidget {
  final List<T> values;
  final T? selected;
  final String Function(T) labelOf;

  /// null : sélecteur désactivé (chargement en cours).
  final ValueChanged<T>? onSelected;

  const ChartSegmented({
    super.key,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final enabled = onSelected != null;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: dc.surfaceSunken,
          borderRadius: BorderRadius.circular(DcRadius.md),
          border: Border.all(color: dc.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: values.map((value) {
            final isSelected = value == selected;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  borderRadius: BorderRadius.circular(DcRadius.md - 3),
                  onTap: enabled && !isSelected ? () => onSelected!(value) : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? dc.surface : Colors.transparent,
                      borderRadius: BorderRadius.circular(DcRadius.md - 3),
                      border: Border.all(color: isSelected ? dc.borderStrong : Colors.transparent),
                      boxShadow: isSelected ? dc.cardShadow : null,
                    ),
                    child: Text(
                      labelOf(value),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: isSelected
                                ? (dc.link)
                                : (enabled ? dc.textSecondary : dc.textMuted),
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Une statistique : libellé en sur-titre, valeur en chasse fixe.
class ChartStat {
  final String label;
  final String value;
  final IconData? icon;

  const ChartStat({required this.label, required this.value, this.icon});
}

/// Rangée de blocs de statistiques (points, min, max, moyenne…).
class ChartStatsRow extends StatelessWidget {
  final List<ChartStat> stats;

  /// Couleur de la série (icônes et liseré).
  final Color? color;
  final bool dense;

  const ChartStatsRow({super.key, required this.stats, this.color, this.dense = false});

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final accent = color != null ? dc.toneOf(color!).fg : dc.textSecondary;
    return Container(
      decoration: BoxDecoration(
        color: dc.surfaceSunken,
        borderRadius: BorderRadius.circular(DcRadius.md),
        border: Border.all(color: dc.border),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (var i = 0; i < stats.length; i++) ...[
              if (i > 0) VerticalDivider(width: 1, thickness: 1, color: dc.border),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: dense ? 8 : 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          if (stats[i].icon != null) ...[
                            Icon(stats[i].icon, size: 12, color: accent),
                            const SizedBox(width: 4),
                          ],
                          Flexible(
                            child: Text(
                              stats[i].label.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.overline.copyWith(color: dc.textMuted, fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        stats[i].value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.monospacedValue.copyWith(
                          color: dc.textPrimary,
                          fontSize: dense ? 13 : 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Message d'état compact pour une zone de graphique (vide, erreur, chargement).
class ChartMessage extends StatelessWidget {
  final IconData? icon;
  final String? message;
  final DcTone? tone;
  final Widget? action;
  final bool loading;
  final bool compact;

  const ChartMessage({
    super.key,
    this.icon,
    this.message,
    this.tone,
    this.action,
    this.loading = false,
    this.compact = false,
  });

  const ChartMessage.loading({super.key, this.message, this.compact = false})
      : icon = null,
        tone = null,
        action = null,
        loading = true;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final t = tone ?? dc.neutral;
    final size = compact ? 36.0 : 48.0;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 8 : 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              SizedBox(
                width: compact ? 22 : 28,
                height: compact ? 22 : 28,
                child: const CircularProgressIndicator(strokeWidth: 2.5),
              )
            else if (icon != null)
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: t.bg,
                  border: Border.all(color: t.border),
                ),
                child: Icon(icon, size: size * 0.48, color: t.fg),
              ),
            if (message != null) ...[
              SizedBox(height: compact ? 8 : 12),
              Text(
                message!,
                textAlign: TextAlign.center,
                maxLines: compact ? 2 : 4,
                overflow: TextOverflow.ellipsis,
                style: (compact ? Theme.of(context).textTheme.bodySmall : Theme.of(context).textTheme.bodyMedium)
                    ?.copyWith(color: tone == dc.danger ? dc.danger.fg : dc.textSecondary),
              ),
            ],
            if (action != null) ...[
              SizedBox(height: compact ? 8 : 16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
