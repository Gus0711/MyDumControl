import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';
import 'dc_tokens.dart';

/// Thèmes clair et sombre, construits à partir des mêmes jetons ([DcTokens]).
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => _build(DcTokens.light);
  static ThemeData get darkTheme => _build(DcTokens.dark);

  static ThemeData _build(DcTokens t) {
    final isDark = t.isDark;

    final scheme = ColorScheme(
      brightness: t.brightness,
      primary: t.accent,
      onPrimary: isDark ? const Color(0xFF03162A) : Colors.white,
      primaryContainer: t.accentTone.bg,
      onPrimaryContainer: t.accentTone.fg,
      secondary: isDark ? AppColors.brandOrange : const Color(0xFFD06F0B),
      onSecondary: isDark ? const Color(0xFF2A1400) : Colors.white,
      secondaryContainer: t.overrideTone.bg,
      onSecondaryContainer: t.overrideTone.fg,
      tertiary: t.violet.fg,
      onTertiary: isDark ? const Color(0xFF1A1040) : Colors.white,
      tertiaryContainer: t.violet.bg,
      onTertiaryContainer: t.violet.fg,
      error: isDark ? const Color(0xFFFF6B70) : const Color(0xFFD1343B),
      onError: isDark ? const Color(0xFF3A0508) : Colors.white,
      errorContainer: t.danger.bg,
      onErrorContainer: t.danger.fg,
      surface: t.surface,
      onSurface: t.textPrimary,
      onSurfaceVariant: t.textSecondary,
      surfaceDim: t.canvas,
      surfaceBright: t.surfaceRaised,
      surfaceContainerLowest: isDark ? t.canvas : Colors.white,
      surfaceContainerLow: isDark ? const Color(0xFF0E1726) : const Color(0xFFF7F9FC),
      surfaceContainer: isDark ? AppColors.surfaceContainerDark : const Color(0xFFF2F5F9),
      surfaceContainerHigh: isDark ? AppColors.surfaceContainerHighDark : const Color(0xFFEBEFF5),
      surfaceContainerHighest: isDark ? const Color(0xFF1C2E4C) : const Color(0xFFE3E9F1),
      outline: t.borderStrong,
      outlineVariant: t.border,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: isDark ? const Color(0xFFE8EEF7) : const Color(0xFF15233A),
      onInverseSurface: isDark ? const Color(0xFF0E1726) : const Color(0xFFE8EEF7),
      inversePrimary: isDark ? AppColors.brandBlue : AppColors.brandSky,
      surfaceTint: Colors.transparent,
    );

    final textTheme = AppTextStyles.textTheme.apply(
      fontFamily: AppTextStyles.fontFamily,
      bodyColor: t.textPrimary,
      displayColor: t.textPrimary,
    );

    final radiusMd = BorderRadius.circular(DcRadius.md);
    final radiusLg = BorderRadius.circular(DcRadius.lg);
    const buttonPadding = EdgeInsets.symmetric(horizontal: 18, vertical: 12);
    const buttonMinSize = Size(64, 42);
    final buttonText = textTheme.labelLarge;

    OutlineInputBorder inputBorder(Color color, [double width = 1]) => OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: t.brightness,
      colorScheme: scheme,
      fontFamily: AppTextStyles.fontFamily,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      extensions: [t],
      scaffoldBackgroundColor: t.canvas,
      canvasColor: t.canvas,
      cardColor: t.surface,
      dividerColor: t.border,
      hintColor: t.textMuted,
      disabledColor: t.textMuted,
      splashFactory: InkSparkle.splashFactory,
      hoverColor: t.accent.withValues(alpha: isDark ? 0.06 : 0.04),
      focusColor: t.accent.withValues(alpha: 0.12),
      highlightColor: Colors.transparent,
      visualDensity: VisualDensity.standard,
      iconTheme: IconThemeData(color: t.textSecondary, size: 22),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.gradientMiddle,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleSpacing: 16,
        iconTheme: const IconThemeData(color: Colors.white, size: 22),
        actionsIconTheme: const IconThemeData(color: Color(0xFFD5E2F3), size: 22),
        titleTextStyle: textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 17),
        toolbarTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
      ),

      cardTheme: CardThemeData(
        color: t.surface,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: radiusLg,
          side: BorderSide(color: t.border),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: t.surfaceSunken,
          disabledForegroundColor: t.textMuted,
          padding: buttonPadding,
          minimumSize: buttonMinSize,
          textStyle: buttonText,
          shape: RoundedRectangleBorder(borderRadius: radiusMd),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: t.surfaceSunken,
          disabledForegroundColor: t.textMuted,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: buttonPadding,
          minimumSize: buttonMinSize,
          textStyle: buttonText,
          shape: RoundedRectangleBorder(borderRadius: radiusMd),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: t.textPrimary,
          padding: buttonPadding,
          minimumSize: buttonMinSize,
          textStyle: buttonText,
          shape: RoundedRectangleBorder(borderRadius: radiusMd),
          side: BorderSide(color: t.borderStrong),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDark ? t.accentTone.fg : t.accent,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          textStyle: buttonText,
          shape: RoundedRectangleBorder(borderRadius: radiusMd),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: radiusMd),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        focusElevation: 3,
        hoverElevation: 4,
        highlightElevation: 2,
        extendedTextStyle: buttonText,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DcRadius.lg)),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(textTheme.labelMedium),
          side: WidgetStatePropertyAll(BorderSide(color: t.borderStrong)),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: radiusMd)),
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? t.accentTone.bg : Colors.transparent,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? t.accentTone.fg : t.textSecondary,
          ),
        ),
      ),
      toggleButtonsTheme: ToggleButtonsThemeData(
        borderRadius: radiusMd,
        borderColor: t.borderStrong,
        selectedBorderColor: t.accentTone.border,
        selectedColor: t.accentTone.fg,
        fillColor: t.accentTone.bg,
        color: t.textSecondary,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: t.surfaceSunken,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: inputBorder(t.border),
        enabledBorder: inputBorder(t.border),
        disabledBorder: inputBorder(t.border.withValues(alpha: 0.5)),
        focusedBorder: inputBorder(t.accent, 1.6),
        errorBorder: inputBorder(scheme.error),
        focusedErrorBorder: inputBorder(scheme.error, 1.6),
        labelStyle: textTheme.bodyMedium?.copyWith(color: t.textSecondary),
        floatingLabelStyle: textTheme.bodyMedium?.copyWith(color: isDark ? t.accentTone.fg : t.accent),
        hintStyle: textTheme.bodyMedium?.copyWith(color: t.textMuted),
        helperStyle: textTheme.bodySmall?.copyWith(color: t.textMuted),
        prefixIconColor: t.textMuted,
        suffixIconColor: t.textMuted,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: t.accent,
        selectionColor: t.accent.withValues(alpha: 0.28),
        selectionHandleColor: t.accent,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: t.surfaceSunken,
        selectedColor: t.accentTone.bg,
        disabledColor: t.surfaceSunken,
        side: BorderSide(color: t.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DcRadius.sm + 2)),
        labelStyle: textTheme.labelMedium?.copyWith(color: t.textPrimary),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(color: t.accentTone.fg),
        checkmarkColor: t.accentTone.fg,
        iconTheme: IconThemeData(color: t.textSecondary, size: 16),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.disabled)) return t.textMuted;
          return s.contains(WidgetState.selected) ? Colors.white : t.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) {
            return s.contains(WidgetState.disabled) ? t.accent.withValues(alpha: 0.4) : t.accent;
          }
          return t.surfaceSunken;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.transparent : t.borderStrong,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: BorderSide(color: t.borderStrong, width: 1.5),
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? t.accent : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(scheme.onPrimary),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? t.accent : t.borderStrong,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: t.accent,
        inactiveTrackColor: t.border,
        thumbColor: t.accent,
        overlayColor: t.accent.withValues(alpha: 0.14),
        valueIndicatorColor: scheme.inverseSurface,
        valueIndicatorTextStyle: textTheme.labelMedium?.copyWith(color: scheme.onInverseSurface),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: t.accent,
        linearTrackColor: t.border,
        circularTrackColor: Colors.transparent,
        linearMinHeight: 3,
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF9FB2CC),
        labelStyle: textTheme.labelLarge,
        unselectedLabelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w500),
        indicatorColor: AppColors.brandSky,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        overlayColor: WidgetStatePropertyAll(Colors.white.withValues(alpha: 0.06)),
      ),

      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        iconColor: t.textSecondary,
        textColor: t.textPrimary,
        titleTextStyle: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500, color: t.textPrimary),
        subtitleTextStyle: textTheme.bodySmall?.copyWith(color: t.textSecondary),
        leadingAndTrailingTextStyle: textTheme.labelMedium?.copyWith(color: t.textSecondary),
        selectedColor: isDark ? t.accentTone.fg : t.accent,
        selectedTileColor: t.accentTone.bg,
        shape: RoundedRectangleBorder(borderRadius: radiusMd),
        minVerticalPadding: 10,
      ),
      expansionTileTheme: ExpansionTileThemeData(
        iconColor: t.textSecondary,
        collapsedIconColor: t.textMuted,
        textColor: t.textPrimary,
        collapsedTextColor: t.textPrimary,
        shape: const Border(),
        collapsedShape: const Border(),
      ),
      dividerTheme: DividerThemeData(color: t.border, thickness: 1, space: 1),

      dialogTheme: DialogThemeData(
        backgroundColor: t.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DcRadius.xl),
          side: BorderSide(color: t.border),
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(color: t.textPrimary),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: t.textSecondary),
        iconColor: t.accent,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: t.surfaceRaised,
        modalBackgroundColor: t.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: t.borderStrong,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(DcRadius.xl)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: t.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.6 : 0.18),
        textStyle: textTheme.bodyMedium?.copyWith(color: t.textPrimary),
        labelTextStyle: WidgetStatePropertyAll(textTheme.bodyMedium?.copyWith(color: t.textPrimary)),
        shape: RoundedRectangleBorder(borderRadius: radiusMd, side: BorderSide(color: t.border)),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(t.surfaceRaised),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: radiusMd, side: BorderSide(color: t.border)),
          ),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: textTheme.bodyMedium,
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(t.surfaceRaised),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: radiusMd, side: BorderSide(color: t.border)),
          ),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(DcRadius.sm),
        ),
        textStyle: textTheme.bodySmall?.copyWith(color: scheme.onInverseSurface),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        waitDuration: const Duration(milliseconds: 400),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: scheme.onInverseSurface),
        actionTextColor: isDark ? AppColors.brandBlue : AppColors.brandSky,
        elevation: 4,
        width: null,
        shape: RoundedRectangleBorder(borderRadius: radiusMd),
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: scheme.error,
        textColor: scheme.onError,
        textStyle: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: t.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(),
        endShape: const RoundedRectangleBorder(),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: t.surface,
        indicatorColor: t.accentTone.bg,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelSmall),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: t.surface,
        indicatorColor: t.accentTone.bg,
        selectedIconTheme: IconThemeData(color: t.accentTone.fg),
        unselectedIconTheme: IconThemeData(color: t.textSecondary),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(color: t.accentTone.fg),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(color: t.textSecondary),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thickness: const WidgetStatePropertyAll(6),
        radius: const Radius.circular(6),
        thumbColor: WidgetStatePropertyAll(t.borderStrong),
      ),
      dataTableTheme: DataTableThemeData(
        headingTextStyle: textTheme.labelMedium?.copyWith(color: t.textSecondary),
        dataTextStyle: textTheme.bodyMedium?.copyWith(color: t.textPrimary),
        dividerThickness: 1,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: t.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: AppColors.gradientMiddle,
        headerForegroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DcRadius.xl)),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: t.surfaceRaised,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DcRadius.xl)),
      ),
    );
  }
}
