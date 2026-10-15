import 'package:flutter/material.dart';

import '../../../core/theme/dc_tokens.dart';

/// Encadré d'information / d'avertissement / d'erreur.
class DcBanner extends StatelessWidget {
  final DcTone? tone;
  final IconData? icon;
  final String? title;
  final String? message;
  final Widget? child;
  final Widget? action;
  final EdgeInsetsGeometry padding;
  final bool dense;

  const DcBanner({
    super.key,
    this.tone,
    this.icon,
    this.title,
    this.message,
    this.child,
    this.action,
    this.padding = const EdgeInsets.all(12),
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final t = tone ?? dc.info;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: dense ? const EdgeInsets.symmetric(horizontal: 10, vertical: 8) : padding,
      decoration: BoxDecoration(
        color: t.bg,
        borderRadius: BorderRadius.circular(DcRadius.md),
        border: Border.all(color: t.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(icon, size: dense ? 16 : 18, color: t.fg),
            ),
            SizedBox(width: dense ? 8 : 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null)
                  Text(title!, style: textTheme.titleSmall?.copyWith(color: t.fg)),
                if (title != null && (message != null || child != null)) const SizedBox(height: 2),
                if (message != null)
                  Text(
                    message!,
                    style: (dense ? textTheme.bodySmall : textTheme.bodyMedium)?.copyWith(
                      color: title != null ? dc.textSecondary : t.fg,
                    ),
                  ),
                ?child,
              ],
            ),
          ),
          if (action != null) ...[const SizedBox(width: 8), action!],
        ],
      ),
    );
  }
}
