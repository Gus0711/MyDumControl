import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/dc_tokens.dart';

/// Centre le contenu et limite sa largeur sur grand écran.
class DcContent extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  const DcContent({
    super.key,
    required this.child,
    this.maxWidth = DcSpace.contentMaxWidth,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Sur-titre de section : « ÉQUIPEMENTS · 4 », avec action optionnelle.
class DcSectionHeader extends StatelessWidget {
  final String title;
  final int? count;
  final IconData? icon;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const DcSectionHeader(
    this.title, {
    super.key,
    this.count,
    this.icon,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(20, 20, 16, 8),
  });

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    return Padding(
      padding: padding,
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: dc.textMuted),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              title.toUpperCase(),
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.overline.copyWith(color: dc.textMuted),
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: dc.surfaceSunken,
                borderRadius: BorderRadius.circular(DcRadius.sm),
                border: Border.all(color: dc.border),
              ),
              child: Text(
                '$count',
                style: AppTextStyles.overline.copyWith(color: dc.textSecondary, letterSpacing: 0.2),
              ),
            ),
          ],
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}

/// Carré arrondi coloré contenant une icône (tête de carte, de ligne…).
class DcIconBox extends StatelessWidget {
  final IconData icon;
  final DcTone? tone;
  final double size;
  final double? iconSize;

  const DcIconBox({super.key, required this.icon, this.tone, this.size = 40, this.iconSize});

  @override
  Widget build(BuildContext context) {
    final t = tone ?? context.dc.accentTone;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: t.bg,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: t.border),
      ),
      child: Icon(icon, size: iconSize ?? size * 0.5, color: t.fg),
    );
  }
}

/// Carte de surface avec bordure, survol (bureau) et clic optionnel.
class DcCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? color;
  final Color? borderColor;

  /// Liseré coloré à gauche (état, forçage…).
  final Color? accentColor;
  final double radius;

  const DcCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding = const EdgeInsets.all(DcSpace.lg),
    this.margin = EdgeInsets.zero,
    this.color,
    this.borderColor,
    this.accentColor,
    this.radius = DcRadius.lg,
  });

  @override
  State<DcCard> createState() => _DcCardState();
}

class _DcCardState extends State<DcCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final interactive = widget.onTap != null || widget.onLongPress != null;
    final radius = BorderRadius.circular(widget.radius);
    final border = widget.borderColor ?? (_hover && interactive ? dc.borderStrong : dc.border);

    Widget content = Padding(padding: widget.padding, child: widget.child);
    if (widget.accentColor != null) {
      content = IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 3, color: widget.accentColor),
            Expanded(child: content),
          ],
        ),
      );
    }

    return Padding(
      padding: widget.margin,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: widget.color ?? dc.surface,
          borderRadius: radius,
          border: Border.all(color: border),
          boxShadow: _hover && interactive ? dc.raisedShadow : dc.cardShadow,
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            onLongPress: widget.onLongPress,
            onHover: interactive ? (h) => setState(() => _hover = h) : null,
            child: content,
          ),
        ),
      ),
    );
  }
}

/// Indicateur chiffré (KPI) : libellé, valeur, icône et ton.
class DcKpi extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final DcTone? tone;
  final String? caption;
  final VoidCallback? onTap;

  const DcKpi({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.tone,
    this.caption,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final t = tone ?? dc.neutral;
    final textTheme = Theme.of(context).textTheme;
    return DcCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          DcIconBox(icon: icon, tone: t, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.headlineSmall?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: t == dc.neutral ? dc.textPrimary : t.fg,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelMedium?.copyWith(color: dc.textSecondary),
                ),
                if (caption != null)
                  Text(
                    caption!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(color: dc.textMuted),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Ligne « libellé : valeur » des fiches d'information.
class DcInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final bool mono;
  final Color? valueColor;
  final double labelWidth;
  final Widget? trailing;

  const DcInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.mono = false,
    this.valueColor,
    this.labelWidth = 150,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: dc.textMuted),
            const SizedBox(width: 10),
          ],
          SizedBox(
            width: labelWidth,
            child: Text(label, style: textTheme.bodyMedium?.copyWith(color: dc.textSecondary)),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: (mono ? AppTextStyles.monospacedValue.copyWith(fontSize: 13) : textTheme.bodyMedium)
                  ?.copyWith(color: valueColor ?? dc.textPrimary, fontWeight: FontWeight.w500),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
