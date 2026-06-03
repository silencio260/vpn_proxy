import 'package:flutter/material.dart';

/// Raw color constants for both palettes plus a [ThemeExtension] that exposes
/// theme-aware tokens via `Theme.of(context).extension<AppPalette>()` or the
/// `context.palette` shortcut.
///
/// Legacy static [AppColors] members are kept (mapped to the dark palette) so
/// existing call-sites continue to compile during the migration.
class AppColors {
  // ---------- Light palette (Mash VPN — clean blue/white) ----------
  static const Color lightBackground = Color(0xffEBF1FC);
  static const Color lightCard = Color(0xffFFFFFF);
  static const Color lightSurface = Color(0xffF5F8FF);
  static const Color lightBottomSheet = Color(0xffFFFFFF);

  static const Color lightPrimary = Color(0xff2B7BF3);
  static const Color lightPrimaryLight = Color(0xff5E9BF7);
  static const Color lightPrimaryDark = Color(0xff1E5DCC);

  static const Color lightAccent = Color(0xffF7A832); // premium crown / ad pill
  static const Color lightSuccess = Color(0xff16A34A);
  static const Color lightWarning = Color(0xffF59E0B);
  static const Color lightError = Color(0xffDC2626);

  static const Color lightTextPrimary = Color(0xff0B1A33);
  static const Color lightTextSecondary = Color(0xff6B7280);
  static const Color lightTextHint = Color(0xff9CA3AF);

  static const Color lightBorder = Color(0xffE5EAF2);
  static const Color lightDivider = Color(0xffEEF1F6);

  // ---------- Dark palette (purple neon) ----------
  static const Color darkBackground = Color(0xff0A0A0F);
  static const Color darkCard = Color(0xff16161E);
  static const Color darkSurface = Color(0xff1C1C26);
  static const Color darkBottomSheet = Color(0xff20202D);

  static const Color darkPrimary = Color(0xff8B5CF6);
  static const Color darkPrimaryLight = Color(0xffA78BFA);
  static const Color darkPrimaryDark = Color(0xff6D28D9);

  static const Color darkAccent = Color(0xffC4B5FD);
  static const Color darkSuccess = Color(0xff4ADE80);
  static const Color darkWarning = Color(0xffF59E0B);
  static const Color darkError = Color(0xffF87171);

  static const Color darkTextPrimary = Color(0xffFFFFFF);
  static const Color darkTextSecondary = Color(0xffA5A5B8);
  static const Color darkTextHint = Color(0xff6B6B80);

  static const Color darkBorder = Color(0xff2A2A38);
  static const Color darkDivider = Color(0xff1E1E30);

  // ---------- Legacy aliases (dark palette) — used by older widgets ----------
  static const Color background = darkBackground;
  static const Color cardBackground = darkCard;
  static const Color surfaceBackground = darkSurface;
  static const Color bottomSheetBackground = darkBottomSheet;
  static const Color primary = darkPrimary;
  static const Color primaryLight = darkPrimaryLight;
  static const Color primaryDark = darkPrimaryDark;
  static const Color connected = darkSuccess;
  static const Color connecting = darkWarning;
  static const Color disconnected = darkPrimary;
  static const Color error = darkError;
  static const Color textPrimary = darkTextPrimary;
  static const Color textSecondary = darkTextSecondary;
  static const Color textHint = darkTextHint;
  static const Color border = darkBorder;
  static const Color divider = darkDivider;
  static const Color white = Colors.white;
}

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color background;
  final Color card;
  final Color surface;
  final Color bottomSheet;
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final Color accent;
  final Color success;
  final Color warning;
  final Color error;
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;
  final Color border;
  final Color divider;

  const AppPalette({
    required this.background,
    required this.card,
    required this.surface,
    required this.bottomSheet,
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.accent,
    required this.success,
    required this.warning,
    required this.error,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.border,
    required this.divider,
  });

  static const AppPalette light = AppPalette(
    background: AppColors.lightBackground,
    card: AppColors.lightCard,
    surface: AppColors.lightSurface,
    bottomSheet: AppColors.lightBottomSheet,
    primary: AppColors.lightPrimary,
    primaryLight: AppColors.lightPrimaryLight,
    primaryDark: AppColors.lightPrimaryDark,
    accent: AppColors.lightAccent,
    success: AppColors.lightSuccess,
    warning: AppColors.lightWarning,
    error: AppColors.lightError,
    textPrimary: AppColors.lightTextPrimary,
    textSecondary: AppColors.lightTextSecondary,
    textHint: AppColors.lightTextHint,
    border: AppColors.lightBorder,
    divider: AppColors.lightDivider,
  );

  static const AppPalette dark = AppPalette(
    background: AppColors.darkBackground,
    card: AppColors.darkCard,
    surface: AppColors.darkSurface,
    bottomSheet: AppColors.darkBottomSheet,
    primary: AppColors.darkPrimary,
    primaryLight: AppColors.darkPrimaryLight,
    primaryDark: AppColors.darkPrimaryDark,
    accent: AppColors.darkAccent,
    success: AppColors.darkSuccess,
    warning: AppColors.darkWarning,
    error: AppColors.darkError,
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
    textHint: AppColors.darkTextHint,
    border: AppColors.darkBorder,
    divider: AppColors.darkDivider,
  );

  @override
  AppPalette copyWith({
    Color? background,
    Color? card,
    Color? surface,
    Color? bottomSheet,
    Color? primary,
    Color? primaryLight,
    Color? primaryDark,
    Color? accent,
    Color? success,
    Color? warning,
    Color? error,
    Color? textPrimary,
    Color? textSecondary,
    Color? textHint,
    Color? border,
    Color? divider,
  }) =>
      AppPalette(
        background: background ?? this.background,
        card: card ?? this.card,
        surface: surface ?? this.surface,
        bottomSheet: bottomSheet ?? this.bottomSheet,
        primary: primary ?? this.primary,
        primaryLight: primaryLight ?? this.primaryLight,
        primaryDark: primaryDark ?? this.primaryDark,
        accent: accent ?? this.accent,
        success: success ?? this.success,
        warning: warning ?? this.warning,
        error: error ?? this.error,
        textPrimary: textPrimary ?? this.textPrimary,
        textSecondary: textSecondary ?? this.textSecondary,
        textHint: textHint ?? this.textHint,
        border: border ?? this.border,
        divider: divider ?? this.divider,
      );

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      card: Color.lerp(card, other.card, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      bottomSheet: Color.lerp(bottomSheet, other.bottomSheet, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textHint: Color.lerp(textHint, other.textHint, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
    );
  }
}

extension PaletteX on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.dark;
}
