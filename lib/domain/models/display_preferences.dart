/// Global display preferences (from the user settings), read by the domain
/// models' formatting getters (formattedValue, formattedTime...).
///
/// Display only: values written to controllers are never converted.
/// Kept in sync by SettingsNotifier; defaults match AppSettings defaults.
class DisplayPreferences {
  DisplayPreferences._();

  /// Decimal places used for non-integer analog values.
  static int decimalPlaces = 2;

  /// Show °C values in °F (conversion for display only).
  static bool useFahrenheit = false;

  /// 24-hour clock (14:30) or 12-hour clock (2:30 PM).
  static bool use24HourFormat = true;

  /// Applies the user settings.
  static void apply({
    required int decimalPlaces,
    required String temperatureUnit,
    required bool use24HourFormat,
  }) {
    DisplayPreferences.decimalPlaces = decimalPlaces.clamp(0, 6);
    useFahrenheit = temperatureUnit == 'fahrenheit';
    DisplayPreferences.use24HourFormat = use24HourFormat;
  }

  /// Restores the defaults (tests).
  static void reset() => apply(decimalPlaces: 2, temperatureUnit: 'celsius', use24HourFormat: true);

  /// Formats an analog value with its unit: integers without decimals,
  /// otherwise [decimalPlaces] decimals. Only values in exactly "°C" are
  /// converted to °F when [useFahrenheit] is set (not Δ°C or other units).
  static String formatAnalog(num value, String? units, {int? decimals}) {
    var displayValue = value;
    var displayUnits = units;
    if (useFahrenheit && units == '°C') {
      displayValue = value * 9 / 5 + 32;
      displayUnits = '°F';
    }
    final places = displayValue.truncateToDouble() == displayValue
        ? 0
        : (decimals ?? decimalPlaces);
    final formatted = displayValue.toStringAsFixed(places);
    return displayUnits != null && displayUnits.isNotEmpty ? '$formatted $displayUnits' : formatted;
  }

  /// Formats a time of day according to [use24HourFormat].
  /// [hour] may be 24 (end of day), shown as 24:00 / 12:00 AM.
  static String formatHourMinute(int hour, int minute) {
    final mm = minute.toString().padLeft(2, '0');
    if (use24HourFormat) return '${hour.toString().padLeft(2, '0')}:$mm';
    final h24 = hour % 24;
    final suffix = h24 < 12 ? 'AM' : 'PM';
    final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
    return '$h12:$mm $suffix';
  }

  /// Formats a date and time as dd/MM/yyyy + time of day (see
  /// [formatHourMinute]). [withSeconds] adds :ss in 24-hour mode only.
  static String formatDateTime(DateTime dt, {bool withSeconds = false}) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final time = formatHourMinute(dt.hour, dt.minute);
    final seconds = withSeconds && use24HourFormat ? ':${dt.second.toString().padLeft(2, '0')}' : '';
    return '$d/$m/${dt.year} $time$seconds';
  }
}
