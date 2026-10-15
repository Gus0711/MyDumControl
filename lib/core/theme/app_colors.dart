import 'package:flutter/material.dart';

/// Palette de l'application, tirée du logo (bleu ciel / orange sur bleu nuit).
///
/// Les écrans n'utilisent pas ces constantes directement pour les textes et
/// les fonds : ils passent par `context.dc` (DcTokens), qui donne la bonne
/// teinte selon le thème clair ou sombre. Ces constantes servent à construire
/// les thèmes et aux rares éléments identiques dans les deux modes (barre
/// d'application, splash).
class AppColors {
  AppColors._();

  // Marque
  static const Color brandNavy = Color(0xFF0B1628);
  static const Color brandNavyLight = Color(0xFF13274A);
  static const Color brandSky = Color(0xFF4AAEF5);
  static const Color brandBlue = Color(0xFF1676D2);
  static const Color brandOrange = Color(0xFFF28C28);
  static const Color brandViolet = Color(0xFF8B6CF0);

  // Barre d'application et en-têtes (identiques en clair et en sombre)
  static const Color gradientStart = Color(0xFF0A1424);
  static const Color gradientMiddle = Color(0xFF0E1D35);
  static const Color gradientEnd = Color(0xFF132A4B);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [gradientStart, gradientMiddle, gradientEnd],
  );

  /// Filet de marque (bleu ciel → orange) sous la barre d'application.
  static const LinearGradient brandLine = LinearGradient(
    colors: [Color(0x004AAEF5), brandSky, Color(0xFF8B6CF0), brandOrange, Color(0x00F28C28)],
    stops: [0.0, 0.25, 0.55, 0.8, 1.0],
  );

  // Compatibilité : anciens noms encore utilisés par quelques widgets.
  static const Color primary = brandBlue;
  static const Color primaryLight = brandSky;
  static const Color primaryDark = brandNavy;
  static const Color secondary = brandOrange;
  static const Color secondaryLight = Color(0xFFFFB066);
  static const Color secondaryDark = Color(0xFFB85C00);

  // États (teintes moyennes, lisibles sur les deux fonds)
  static const Color success = Color(0xFF22B573);
  static const Color warning = Color(0xFFF2A516);
  static const Color error = Color(0xFFE5484D);
  static const Color info = brandSky;

  // Mode sombre — bleu nuit
  static const Color backgroundDark = Color(0xFF0A111D);
  static const Color surfaceDark = Color(0xFF101A2A);
  static const Color surfaceContainerDark = Color(0xFF13203A);
  static const Color surfaceContainerHighDark = Color(0xFF172741);
  static const Color cardDark = Color(0xFF101A2A);
  static const Color sunkenDark = Color(0xFF0C1524);
  static const Color borderDark = Color(0xFF1F2D45);
  static const Color borderStrongDark = Color(0xFF2B3D5C);
  static const Color textPrimaryDark = Color(0xFFE8EEF7);
  static const Color textSecondaryDark = Color(0xFFA6B3C8);
  static const Color textMutedDark = Color(0xFF71819B);

  // Mode clair — gris bleuté
  static const Color backgroundLight = Color(0xFFF2F5F9);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color sunkenLight = Color(0xFFEDF1F6);
  static const Color borderLight = Color(0xFFDCE3EC);
  static const Color borderStrongLight = Color(0xFFC3CFDE);
  static const Color textPrimaryLight = Color(0xFF0E1726);
  static const Color textSecondaryLight = Color(0xFF4A5A72);
  static const Color textMutedLight = Color(0xFF75849A);

  // Points BACnet (teintes moyennes, lisibles sur les deux fonds)
  static const Color analogInput = Color(0xFF34C17A);
  static const Color analogOutput = Color(0xFFF28C28);
  static const Color analogValue = Color(0xFF22B8CF);
  static const Color binaryInput = Color(0xFF4A90E2);
  static const Color binaryOutput = Color(0xFFE5579A);
  static const Color binaryValue = Color(0xFF9B72F2);
  static const Color multiStateInput = Color(0xFF6C7CF0);
  static const Color multiStateOutput = Color(0xFFE9B227);
  static const Color multiStateValue = Color(0xFF1FAE9B);

  // Sévérité des alarmes
  static const Color alarmCritical = Color(0xFFE5484D);
  static const Color alarmMajor = Color(0xFFF26B3A);
  static const Color alarmMinor = Color(0xFFF2A516);
  static const Color alarmInfo = brandSky;

  // États de connexion
  static const Color connected = success;
  static const Color disconnected = Color(0xFF7D8BA3);
  static const Color connecting = warning;

  /// Forçage actif (orange : convention GTB pour « forcé »)
  static const Color overrideActive = brandOrange;
}
