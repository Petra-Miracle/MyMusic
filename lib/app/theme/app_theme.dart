import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Skala tipografi dari design system (Plus Jakarta Sans).
abstract final class AppText {
  static TextStyle _base(double size, FontWeight weight, Color color, [double? height]) =>
      GoogleFonts.plusJakartaSans(fontSize: size, fontWeight: weight, color: color, height: height);

  static TextStyle display([Color c = AppColors.textPrimary]) => _base(28, FontWeight.w700, c, 34 / 28);
  static TextStyle title([Color c = AppColors.textPrimary]) => _base(20, FontWeight.w700, c, 26 / 20);
  static TextStyle subtitle([Color c = AppColors.textPrimary]) => _base(16, FontWeight.w600, c, 22 / 16);
  static TextStyle body([Color c = AppColors.textPrimary]) => _base(14, FontWeight.w400, c, 20 / 14);
  static TextStyle bodyStrong([Color c = AppColors.textPrimary]) => _base(14, FontWeight.w600, c, 20 / 14);
  static TextStyle caption([Color c = AppColors.textSecondary]) => _base(12, FontWeight.w500, c, 16 / 12);
  static TextStyle label([Color c = AppColors.textMuted]) => _base(10, FontWeight.w500, c);
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accent,
      onPrimary: AppColors.textPrimary,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.error,
    ),
    splashFactory: InkSparkle.splashFactory,
  );

  return base.copyWith(
    textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),
    textSelectionTheme: const TextSelectionThemeData(cursorColor: AppColors.accent),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      showDragHandle: false,
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(AppColors.textPrimary),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? AppColors.accent : AppColors.border,
      ),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    sliderTheme: const SliderThemeData(
      trackHeight: 4,
      activeTrackColor: AppColors.accent,
      inactiveTrackColor: AppColors.border,
      thumbColor: AppColors.accent,
      overlayShape: RoundSliderOverlayShape(overlayRadius: 14),
      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7),
      trackShape: RectangularSliderTrackShape(),
    ),
  );
}
