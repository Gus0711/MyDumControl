import '../../domain/models/display_preferences.dart';

/// Formats a number for display: integers without decimals, otherwise
/// [decimals] decimals (defaults to the user setting
/// [DisplayPreferences.decimalPlaces]). No unit, no °C/°F conversion.
String formatNumber(num value, {int? decimals}) =>
    DisplayPreferences.formatAnalog(value, null, decimals: decimals);
