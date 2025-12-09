import 'package:flutter/material.dart';

/// Palette de couleurs de l'application
class AppColors {
  AppColors._();

  // Couleurs principales - Inspirées de Distech Controls
  static const Color primary = Color(0xFF1565C0); // Bleu Distech
  static const Color primaryLight = Color(0xFF5E92F3);
  static const Color primaryDark = Color(0xFF003C8F);

  static const Color secondary = Color(0xFF00897B); // Teal
  static const Color secondaryLight = Color(0xFF4EBAAA);
  static const Color secondaryDark = Color(0xFF005B4F);

  // Couleurs d'état
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFFFA726);
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color error = Color(0xFFE53935);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color info = Color(0xFF29B6F6);
  static const Color infoLight = Color(0xFFE1F5FE);

  // Couleurs de fond - Mode clair
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);

  // Couleurs de fond - Mode sombre (Material You - teinte bleue)
  static const Color backgroundDark = Color(0xFF111318); // Gris très foncé teinté bleu
  static const Color surfaceDark = Color(0xFF1A1C22); // Surface légèrement plus claire
  static const Color cardDark = Color(0xFF23262E); // Cartes avec teinte bleue subtile
  static const Color surfaceContainerDark = Color(0xFF1E2128); // Container intermédiaire
  static const Color surfaceContainerHighDark = Color(0xFF282C34); // Container élevé

  // Couleurs de texte - Mode clair
  static const Color textPrimaryLight = Color(0xFF212121);
  static const Color textSecondaryLight = Color(0xFF757575);
  static const Color textDisabledLight = Color(0xFFBDBDBD);

  // Couleurs de texte - Mode sombre
  static const Color textPrimaryDark = Color(0xFFE4E6EB); // Blanc cassé plus doux
  static const Color textSecondaryDark = Color(0xFF9AA0AB); // Gris bleuté
  static const Color textDisabledDark = Color(0xFF5C6370); // Gris moyen

  // Couleurs de bordure
  static const Color borderLight = Color(0xFFE0E0E0);
  static const Color borderDark = Color(0xFF2E3440); // Bordure teintée bleue

  // Couleurs spécifiques aux points BACnet
  static const Color analogInput = Color(0xFF42A5F5); // Bleu
  static const Color analogOutput = Color(0xFFFF7043); // Orange
  static const Color analogValue = Color(0xFF66BB6A); // Vert
  static const Color binaryInput = Color(0xFF7E57C2); // Violet
  static const Color binaryOutput = Color(0xFFEC407A); // Rose
  static const Color binaryValue = Color(0xFF26A69A); // Teal

  // Couleurs de sévérité des alarmes
  static const Color alarmCritical = Color(0xFFD32F2F);
  static const Color alarmMajor = Color(0xFFFF5722);
  static const Color alarmMinor = Color(0xFFFFC107);
  static const Color alarmInfo = Color(0xFF2196F3);

  // États de connexion
  static const Color connected = Color(0xFF4CAF50);
  static const Color disconnected = Color(0xFF9E9E9E);
  static const Color connecting = Color(0xFFFFA726);

  // Override actif
  static const Color overrideActive = Color(0xFFFF9800);
}
