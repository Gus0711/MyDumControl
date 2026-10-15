import 'package:flutter/material.dart';

import '../../../core/theme/dc_tokens.dart';

/// Pastille de texte compacte (modèle, version d'API, état…).
class DcTag extends StatelessWidget {
  final String label;
  final DcTone? tone;
  final IconData? icon;

  /// Plus petit, pour les listes denses.
  final bool dense;

  /// Fond plein (fg) et texte contrasté, pour attirer l'œil.
  final bool solid;

  /// Police à chasse fixe (adresses, instances, versions).
  final bool mono;

  const DcTag(
    this.label, {
    super.key,
    this.tone,
    this.icon,
    this.dense = false,
    this.solid = false,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final t = tone ?? dc.neutral;
    final fg = solid ? dc.onSolid : t.fg;
    final fontSize = dense ? 10.5 : 11.5;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 6 : 8, vertical: dense ? 1.5 : 3),
      decoration: BoxDecoration(
        color: solid ? t.fg : t.bg,
        borderRadius: BorderRadius.circular(DcRadius.sm),
        border: Border.all(color: solid ? t.fg : t.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 1.5, color: fg),
            SizedBox(width: dense ? 3 : 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: mono ? 'JetBrainsMono' : null,
                fontSize: fontSize,
                height: 1.25,
                fontWeight: FontWeight.w600,
                letterSpacing: mono ? 0 : 0.2,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Point d'état (connecté, hors ligne…), avec halo optionnel.
class DcStatusDot extends StatelessWidget {
  final Color color;
  final double size;
  final bool glow;

  const DcStatusDot({super.key, required this.color, this.size = 8, this.glow = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: glow
            ? [BoxShadow(color: color.withValues(alpha: 0.55), blurRadius: size, spreadRadius: size / 6)]
            : null,
      ),
    );
  }
}
