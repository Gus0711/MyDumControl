import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/active_connection_provider.dart';
import '../../application/providers/app_overrides_provider.dart';
import '../../data/database/app_database.dart';
import '../../domain/models/bacnet_object.dart';
import '../../domain/models/display_preferences.dart';
import '../../l10n/app_localizations.dart';

/// Libellé court d'une durée de forçage ("15 min", "2 h", "Permanent").
String overrideDurationLabel(AppLocalizations l10n, Duration? duration) {
  if (duration == null) return l10n.overridePermanent;
  if (duration.inMinutes < 60) return l10n.durationMinutes(duration.inMinutes);
  return l10n.durationHours(duration.inHours);
}

String _hm(DateTime dt) => DisplayPreferences.formatHourMinute(dt.hour, dt.minute);

/// Forçage enregistré par l'application pour [point] sur la connexion
/// active (null si le point n'a pas été forcé depuis l'application).
AppOverride? watchAppOverride(WidgetRef ref, BacnetObject point) {
  final connectionId = ref.watch(activeConnectionProvider.select((s) => s.connection?.id));
  if (connectionId == null) return null;
  final overrides = ref.watch(appOverridesProvider(connectionId)).valueOrNull;
  return overrides?[appOverrideKey(point.type.apiName, point.instance)];
}

/// Résumé sur une ligne : "Forcé à 14:02 · relâché à 14:32".
String? appOverrideSummary(AppLocalizations l10n, AppOverride? override) {
  if (override == null) return null;
  final forced = l10n.forcedAtTime(_hm(override.forcedAt.toLocal()));
  final expiresAt = override.expiresAt;
  if (expiresAt == null) return forced;
  return '$forced · ${l10n.autoReleaseAtTime(_hm(expiresAt.toLocal()))}';
}

/// Lignes d'information d'un forçage posé depuis l'application (heure,
/// relâchement automatique, échec du relâchement). Rien si le point a été
/// forcé par un autre outil.
class AppOverrideInfo extends ConsumerWidget {
  const AppOverrideInfo({super.key, required this.point});

  final BacnetObject point;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final override = watchAppOverride(ref, point);
    final textStyle = Theme.of(context).textTheme.bodySmall;
    if (override == null) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(l10n.overrideOriginUnknown, style: textStyle?.copyWith(fontStyle: FontStyle.italic)),
      );
    }
    final expiresAt = override.expiresAt?.toLocal();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule, size: 16),
              const SizedBox(width: 6),
              Text(l10n.forcedAtTime(_hm(override.forcedAt.toLocal())), style: textStyle),
            ],
          ),
          if (expiresAt != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.timer_outlined, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.autoReleaseAtTime(_hm(expiresAt)),
                    style: textStyle?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
          if (override.lastError != null) ...[
            const SizedBox(height: 4),
            Text(
              l10n.autoReleaseFailed(override.lastError!),
              style: textStyle?.copyWith(color: Colors.red.shade700),
            ),
          ],
        ],
      ),
    );
  }
}

/// Choix de la durée d'un forçage (null = permanent).
class OverrideDurationSelector extends StatelessWidget {
  const OverrideDurationSelector({super.key, required this.value, required this.onChanged});

  final Duration? value;
  final ValueChanged<Duration?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.overrideDuration, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final duration in timedOverrideDurations)
              ChoiceChip(
                label: Text(overrideDurationLabel(l10n, duration)),
                selected: value == duration,
                onSelected: (_) => onChanged(duration),
              ),
          ],
        ),
        if (value != null) ...[
          const SizedBox(height: 6),
          Text(
            l10n.timedOverrideHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
          ),
        ],
      ],
    );
  }
}
