import 'package:flutter/material.dart';

import '../../../core/theme/dc_tokens.dart';

/// Élément de menu contextuel : icône + libellé, rouge si [danger].
PopupMenuItem<T> dcMenuItem<T>(
  BuildContext context,
  T value,
  IconData icon,
  String label, {
  bool danger = false,
  bool enabled = true,
}) {
  final dc = context.dc;
  final color = danger ? dc.danger.fg : null;
  return PopupMenuItem<T>(
    value: value,
    enabled: enabled,
    height: 42,
    child: Row(
      children: [
        Icon(icon, size: 18, color: color ?? dc.textSecondary),
        const SizedBox(width: 12),
        Flexible(child: Text(label, style: TextStyle(color: color))),
      ],
    ),
  );
}

/// Message éphémère : liseré coloré (succès, erreur…) devant le texte.
///
/// [color] donne la nature du message ; sans couleur, message neutre.
SnackBar dcSnackBar(
  String message, {
  Color? color,
  IconData? icon,
  SnackBarAction? action,
  Duration duration = const Duration(seconds: 4),
}) {
  return SnackBar(
    duration: duration,
    action: action,
    content: Row(
      children: [
        if (color != null) ...[
          Container(
            width: 4,
            height: 22,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 12),
        ],
        if (icon != null) ...[
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
        ],
        Expanded(child: Text(message)),
      ],
    ),
  );
}

/// Raccourcis pour les messages courants.
extension DcSnackContext on BuildContext {
  void showSuccess(String message) => ScaffoldMessenger.of(this)
      .showSnackBar(dcSnackBar(message, color: AppSnackColors.success, icon: Icons.check_circle_rounded));

  void showError(String message) => ScaffoldMessenger.of(this)
      .showSnackBar(dcSnackBar(message, color: AppSnackColors.danger, icon: Icons.error_rounded));

  void showWarning(String message) => ScaffoldMessenger.of(this)
      .showSnackBar(dcSnackBar(message, color: AppSnackColors.warning, icon: Icons.warning_amber_rounded));

  void showInfo(String message) =>
      ScaffoldMessenger.of(this).showSnackBar(dcSnackBar(message));
}

/// Couleurs des messages (le fond du message est inversé : teintes moyennes,
/// lisibles sur fond clair comme sur fond sombre).
class AppSnackColors {
  AppSnackColors._();
  static const Color success = Color(0xFF1FA971);
  static const Color danger = Color(0xFFE5484D);
  static const Color warning = Color(0xFFE59A0C);
}
