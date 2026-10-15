import '../../../domain/models/schedule.dart';
import '../../../l10n/app_localizations.dart';

/// Localized texts of a [Schedule] (the model keeps French defaults for
/// non-UI uses).
extension ScheduleL10n on Schedule {
  static ScheduleStateLabels labels(AppLocalizations l10n) => ScheduleStateLabels(
        auto: l10n.auto,
        active: l10n.active,
        inactive: l10n.inactive,
        state: (value) => l10n.scheduleStateN(value),
      );

  /// Localized [Schedule.getStateText].
  String localizedStateText(AppLocalizations l10n, dynamic value) =>
      getStateText(value, labels(l10n));

  /// Localized [Schedule.possibleValues].
  List<({dynamic value, String text})> localizedPossibleValues(AppLocalizations l10n) =>
      possibleValuesWith(labels(l10n));
}
