import 'package:flutter/material.dart';

/// Échelle typographique (Inter) et styles de valeurs (JetBrains Mono).
class AppTextStyles {
  AppTextStyles._();

  static const String fontFamily = 'Inter';
  static const String monoFamily = 'JetBrainsMono';

  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  // Titres
  static const TextStyle displayLarge = TextStyle(fontSize: 52, fontWeight: FontWeight.w600, letterSpacing: -1.2, height: 1.1);
  static const TextStyle displayMedium = TextStyle(fontSize: 42, fontWeight: FontWeight.w600, letterSpacing: -1.0, height: 1.12);
  static const TextStyle displaySmall = TextStyle(fontSize: 34, fontWeight: FontWeight.w600, letterSpacing: -0.8, height: 1.15);

  static const TextStyle headlineLarge = TextStyle(fontSize: 28, fontWeight: FontWeight.w600, letterSpacing: -0.6, height: 1.2);
  static const TextStyle headlineMedium = TextStyle(fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: -0.5, height: 1.25);
  static const TextStyle headlineSmall = TextStyle(fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.3, height: 1.3);

  // Titres de section
  static const TextStyle titleLarge = TextStyle(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: -0.2, height: 1.3);
  static const TextStyle titleMedium = TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: -0.1, height: 1.35);
  static const TextStyle titleSmall = TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, letterSpacing: 0, height: 1.35);

  // Corps de texte
  static const TextStyle bodyLarge = TextStyle(fontSize: 15, fontWeight: FontWeight.w400, letterSpacing: 0, height: 1.5);
  static const TextStyle bodyMedium = TextStyle(fontSize: 13.5, fontWeight: FontWeight.w400, letterSpacing: 0, height: 1.45);
  static const TextStyle bodySmall = TextStyle(fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.1, height: 1.4);

  // Labels
  static const TextStyle labelLarge = TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, letterSpacing: 0.1);
  static const TextStyle labelMedium = TextStyle(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.2);
  static const TextStyle labelSmall = TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.3);

  /// Sur-titre de section (MAJUSCULES espacées).
  static const TextStyle overline = TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.1, height: 1.2);

  // Valeurs
  static const TextStyle valueDisplay = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.8,
    fontFeatures: _tabular,
  );

  static const TextStyle unitText = TextStyle(fontSize: 13, fontWeight: FontWeight.w500);

  /// Valeurs techniques (adresses IP, instances, horodatages).
  static const TextStyle monospacedValue = TextStyle(
    fontFamily: monoFamily,
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
    fontFeatures: _tabular,
  );

  /// Chiffres alignés dans la police principale.
  static const TextStyle tabular = TextStyle(fontFeatures: _tabular);

  static const TextTheme textTheme = TextTheme(
    displayLarge: displayLarge,
    displayMedium: displayMedium,
    displaySmall: displaySmall,
    headlineLarge: headlineLarge,
    headlineMedium: headlineMedium,
    headlineSmall: headlineSmall,
    titleLarge: titleLarge,
    titleMedium: titleMedium,
    titleSmall: titleSmall,
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    bodySmall: bodySmall,
    labelLarge: labelLarge,
    labelMedium: labelMedium,
    labelSmall: labelSmall,
  );
}
