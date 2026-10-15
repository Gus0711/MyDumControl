import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Couleurs d'un ton sémantique : texte/icône ([fg]), fond doux ([bg]) et
/// bordure ([border]). Toujours lisibles entre elles, en clair comme en sombre.
@immutable
class DcTone {
  final Color fg;
  final Color bg;
  final Color border;

  const DcTone({required this.fg, required this.bg, required this.border});

  static DcTone lerp(DcTone a, DcTone b, double t) => DcTone(
        fg: Color.lerp(a.fg, b.fg, t)!,
        bg: Color.lerp(a.bg, b.bg, t)!,
        border: Color.lerp(a.border, b.border, t)!,
      );

  /// Ton construit à partir d'une couleur quelconque (dossiers, types de points).
  factory DcTone.fromColor(Color color, Brightness brightness) {
    final hsl = HSLColor.fromColor(color);
    if (brightness == Brightness.dark) {
      return DcTone(
        fg: hsl.withLightness(hsl.lightness.clamp(0.62, 0.74)).toColor(),
        bg: color.withValues(alpha: 0.14),
        border: color.withValues(alpha: 0.34),
      );
    }
    return DcTone(
      fg: hsl.withLightness(hsl.lightness.clamp(0.30, 0.40)).toColor(),
      bg: color.withValues(alpha: 0.10),
      border: color.withValues(alpha: 0.30),
    );
  }
}

/// Jetons de design de l'application (surfaces, textes, tons d'état…).
///
/// Accès : `context.dc`. Les écrans utilisent ces jetons plutôt que des
/// `Colors.grey.shadeXXX` ou des tests `isDark` : le rendu reste lisible et
/// cohérent dans les deux thèmes.
@immutable
class DcTokens extends ThemeExtension<DcTokens> {
  final Brightness brightness;

  // Surfaces
  final Color canvas;
  final Color surface;
  final Color surfaceRaised;
  final Color surfaceSunken;
  final Color border;
  final Color borderStrong;

  // Textes
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  // Accent (bleu de marque)
  final Color accent;
  final DcTone accentTone;

  // Tons d'état
  final DcTone success;
  final DcTone warning;
  final DcTone danger;
  final DcTone neutral;

  /// Forçage / dérogation (orange de marque).
  final DcTone overrideTone;

  /// Violet du logo, pour les éléments secondaires (dossiers, tendances…).
  final DcTone violet;

  final List<BoxShadow> cardShadow;
  final List<BoxShadow> raisedShadow;

  const DcTokens({
    required this.brightness,
    required this.canvas,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceSunken,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accent,
    required this.accentTone,
    required this.success,
    required this.warning,
    required this.danger,
    required this.neutral,
    required this.overrideTone,
    required this.violet,
    required this.cardShadow,
    required this.raisedShadow,
  });

  bool get isDark => brightness == Brightness.dark;

  /// Info = accent.
  DcTone get info => accentTone;

  /// Texte posé sur un fond plein d'un ton (bouton rouge, pastille pleine…).
  Color get onSolid => isDark ? const Color(0xFF0A111D) : Colors.white;

  /// Couleur des liens et actions textuelles.
  Color get link => isDark ? accentTone.fg : accent;

  /// Ton dérivé d'une couleur arbitraire (couleur de dossier, type de point…).
  DcTone toneOf(Color color) => DcTone.fromColor(color, brightness);

  static const dark = DcTokens(
    brightness: Brightness.dark,
    canvas: AppColors.backgroundDark,
    surface: AppColors.surfaceDark,
    surfaceRaised: AppColors.surfaceContainerHighDark,
    surfaceSunken: AppColors.sunkenDark,
    border: AppColors.borderDark,
    borderStrong: AppColors.borderStrongDark,
    textPrimary: AppColors.textPrimaryDark,
    textSecondary: AppColors.textSecondaryDark,
    textMuted: AppColors.textMutedDark,
    accent: AppColors.brandSky,
    accentTone: DcTone(fg: Color(0xFF7CC6FA), bg: Color(0xFF10294A), border: Color(0xFF1D4673)),
    success: DcTone(fg: Color(0xFF4ADE9A), bg: Color(0xFF0D2A20), border: Color(0xFF1B5440)),
    warning: DcTone(fg: Color(0xFFF7C04A), bg: Color(0xFF2B2210), border: Color(0xFF5C4718)),
    danger: DcTone(fg: Color(0xFFFF7A7E), bg: Color(0xFF331519), border: Color(0xFF6B2932)),
    neutral: DcTone(fg: Color(0xFFA6B3C8), bg: Color(0xFF162236), border: Color(0xFF263755)),
    overrideTone: DcTone(fg: Color(0xFFFFAA5C), bg: Color(0xFF2F200F), border: Color(0xFF6A4220)),
    violet: DcTone(fg: Color(0xFFB9A2FF), bg: Color(0xFF1F1A3D), border: Color(0xFF3D3170)),
    cardShadow: [
      BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 4)),
    ],
    raisedShadow: [
      BoxShadow(color: Color(0x55000000), blurRadius: 24, offset: Offset(0, 10)),
    ],
  );

  static const light = DcTokens(
    brightness: Brightness.light,
    canvas: AppColors.backgroundLight,
    surface: AppColors.surfaceLight,
    surfaceRaised: AppColors.surfaceLight,
    surfaceSunken: AppColors.sunkenLight,
    border: AppColors.borderLight,
    borderStrong: AppColors.borderStrongLight,
    textPrimary: AppColors.textPrimaryLight,
    textSecondary: AppColors.textSecondaryLight,
    textMuted: AppColors.textMutedLight,
    accent: AppColors.brandBlue,
    accentTone: DcTone(fg: Color(0xFF0F5BAA), bg: Color(0xFFE4F0FC), border: Color(0xFFB5D4F3)),
    success: DcTone(fg: Color(0xFF0E7A55), bg: Color(0xFFE3F6EE), border: Color(0xFFAEE0C8)),
    warning: DcTone(fg: Color(0xFF8F5B00), bg: Color(0xFFFFF3D6), border: Color(0xFFF0D392)),
    danger: DcTone(fg: Color(0xFFBE2A31), bg: Color(0xFFFDECEC), border: Color(0xFFF3C0C2)),
    neutral: DcTone(fg: Color(0xFF4A5A72), bg: Color(0xFFEDF1F6), border: Color(0xFFD6DEE9)),
    overrideTone: DcTone(fg: Color(0xFFAD5500), bg: Color(0xFFFFF0E0), border: Color(0xFFF5CFA6)),
    violet: DcTone(fg: Color(0xFF5B3CC4), bg: Color(0xFFF0ECFE), border: Color(0xFFD4C8FA)),
    cardShadow: [
      BoxShadow(color: Color(0x0F0E1726), blurRadius: 10, offset: Offset(0, 2)),
      BoxShadow(color: Color(0x080E1726), blurRadius: 2, offset: Offset(0, 1)),
    ],
    raisedShadow: [
      BoxShadow(color: Color(0x1F0E1726), blurRadius: 28, offset: Offset(0, 12)),
    ],
  );

  @override
  DcTokens copyWith({Color? accent}) => this;

  @override
  DcTokens lerp(ThemeExtension<DcTokens>? other, double t) {
    if (other is! DcTokens) return this;
    List<BoxShadow> shadows(List<BoxShadow> a, List<BoxShadow> b) =>
        BoxShadow.lerpList(a, b, t) ?? b;
    return DcTokens(
      brightness: t < 0.5 ? brightness : other.brightness,
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      surfaceSunken: Color.lerp(surfaceSunken, other.surfaceSunken, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentTone: DcTone.lerp(accentTone, other.accentTone, t),
      success: DcTone.lerp(success, other.success, t),
      warning: DcTone.lerp(warning, other.warning, t),
      danger: DcTone.lerp(danger, other.danger, t),
      neutral: DcTone.lerp(neutral, other.neutral, t),
      overrideTone: DcTone.lerp(overrideTone, other.overrideTone, t),
      violet: DcTone.lerp(violet, other.violet, t),
      cardShadow: shadows(cardShadow, other.cardShadow),
      raisedShadow: shadows(raisedShadow, other.raisedShadow),
    );
  }
}

/// Rayons et espacements communs.
class DcRadius {
  DcRadius._();
  static const double sm = 6;
  static const double md = 10;
  static const double lg = 14;
  static const double xl = 20;
}

class DcSpace {
  DcSpace._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Largeur maximale du contenu sur grand écran.
  static const double contentMaxWidth = 1240;
}

extension DcContext on BuildContext {
  DcTokens get dc => Theme.of(this).extension<DcTokens>() ?? DcTokens.light;
  TextTheme get text => Theme.of(this).textTheme;
}
