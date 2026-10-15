import 'package:flutter/material.dart';

import '../../core/theme/app_text_styles.dart';
import '../../core/theme/dc_tokens.dart';
import '../../domain/models/bacnet_object.dart';
import '../../domain/models/display_preferences.dart';
import '../../l10n/app_localizations.dart';
import '../shared/utils/bacnet_type_utils.dart';
import 'ui/dc_tag.dart';

/// Pastille carrée du type de point (AI, BO, MSV…), colorée par famille.
class PointTypeBadge extends StatelessWidget {
  final BacnetObjectType type;
  final double size;

  const PointTypeBadge({super.key, required this.type, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final tone = BacnetTypeUtils.typeTone(context, type);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tone.bg,
        borderRadius: BorderRadius.circular(size * 0.25),
        border: Border.all(color: tone.border),
      ),
      child: Text(
        type.shortName,
        style: AppTextStyles.monospacedValue.copyWith(
          color: tone.fg,
          fontWeight: FontWeight.w600,
          fontSize: size * (type.shortName.length > 2 ? 0.26 : 0.3),
        ),
      ),
    );
  }
}

/// Texte de la valeur courante d'un point (unités, libellés binaires et
/// multi-états), selon les préférences d'affichage.
String pointValueText(BacnetObject point) {
  final value = point.presentValue;
  if (value == null) return '—';
  if (value is num && !point.type.isBinary && !point.type.isMultiState) {
    return DisplayPreferences.formatAnalog(value, point.units);
  }
  return BacnetTypeUtils.formatValue(point);
}

/// Valeur d'un point dans une pastille colorée (état binaire, forçage…).
class PointValueChip extends StatelessWidget {
  final BacnetObject point;

  /// Texte à afficher à la place de la valeur formatée.
  final String? text;
  final double minWidth;
  final bool large;

  /// Ton imposé (sinon déduit de l'état du point).
  final DcTone? tone;

  const PointValueChip({
    super.key,
    required this.point,
    this.text,
    this.tone,
    this.minWidth = 92,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final tone = this.tone ?? BacnetTypeUtils.valueTone(context, point);
    final isBinary = point.type.isBinary && point.presentValue != null;
    final active = isBinary && BacnetTypeUtils.isBinaryActive(point.presentValue);

    return Container(
      constraints: BoxConstraints(minWidth: minWidth),
      padding: EdgeInsets.symmetric(horizontal: large ? 12 : 10, vertical: large ? 7 : 5),
      decoration: BoxDecoration(
        color: tone.bg,
        borderRadius: BorderRadius.circular(DcRadius.md - 2),
        border: Border.all(color: tone.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (isBinary) ...[
            DcStatusDot(color: active ? tone.fg : context.dc.textMuted, size: 7, glow: active),
            const SizedBox(width: 7),
          ],
          Flexible(
            child: Text(
              text ?? pointValueText(point),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: AppTextStyles.monospacedValue.copyWith(
                color: tone.fg,
                fontSize: large ? 15 : 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pastilles d'état d'un point : alarme, forçage (priorité), hors service.
class PointStatusTags extends StatelessWidget {
  final BacnetObject point;
  final bool dense;

  const PointStatusTags({super.key, required this.point, this.dense = true});

  static bool hasAny(BacnetObject point) =>
      point.inAlarm || point.isOverridden || (point.type.isInput && point.outOfService == true);

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final l10n = AppLocalizations.of(context)!;
    final oos = point.type.isInput && point.outOfService == true && !point.isOverridden;
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        if (point.inAlarm)
          DcTag(l10n.alarm, icon: Icons.notifications_active_rounded, tone: dc.danger, dense: dense),
        if (point.isOverridden)
          DcTag(
            point.overridePriority != null ? 'P${point.overridePriority}' : l10n.overrides,
            icon: Icons.back_hand_rounded,
            tone: dc.overrideTone,
            dense: dense,
          ),
        if (oos) DcTag('OOS', icon: Icons.power_settings_new_rounded, tone: dc.overrideTone, dense: dense),
      ],
    );
  }
}
