import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

/// Figma의 8px 간격 단위입니다.
abstract final class AppSpacing {
  static const x1 = 8.0;
  static const x2 = 16.0;
  static const x3 = 24.0;
  static const x4 = 32.0;

  static const pagePadding = EdgeInsets.all(x3);
}

/// 공통 Card, Button, Input의 8px 모서리 반경입니다.
abstract final class AppRadius {
  static const value = 8.0;
  static const borderRadius = BorderRadius.all(Radius.circular(value));
}

abstract final class AppTheme {
  static final ThemeData light = ThemeData(
    useMaterial3: true,
    fontFamily: 'Manrope',
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary500,
      onPrimary: AppColors.neutral100,
      primaryContainer: AppColors.primary200,
      onPrimaryContainer: AppColors.primary800,
      secondary: AppColors.secondary500,
      onSecondary: AppColors.neutral100,
      secondaryContainer: AppColors.secondary200,
      onSecondaryContainer: AppColors.secondary800,
      tertiary: AppColors.tertiary500,
      onTertiary: AppColors.neutral100,
      tertiaryContainer: AppColors.tertiary200,
      onTertiaryContainer: AppColors.tertiary900,
      error: AppColors.error,
      onError: AppColors.neutral100,
      surface: AppColors.surfaceBase,
      onSurface: AppColors.neutral700,
      surfaceDim: AppColors.surfaceHighest,
      surfaceBright: AppColors.surfaceLowest,
      surfaceContainerLowest: AppColors.surfaceLowest,
      surfaceContainerLow: AppColors.surfaceLow,
      surfaceContainer: AppColors.surfaceContainer,
      surfaceContainerHigh: AppColors.surfaceHigh,
      surfaceContainerHighest: AppColors.surfaceHighest,
      outline: AppColors.neutral500,
      outlineVariant: AppColors.primary200,
    ),
    scaffoldBackgroundColor: AppColors.surface,
    textTheme: AppTextStyles.textTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.onSurface,
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.surface,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    ),
    cardTheme: const CardThemeData(
      color: AppColors.surfaceLow,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderRadius),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x2,
          vertical: AppSpacing.x1,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.borderRadius,
        ),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: AppRadius.borderRadius,
        borderSide: BorderSide(color: AppColors.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.borderRadius,
        borderSide: BorderSide(color: AppColors.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.borderRadius,
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppSpacing.x2,
        vertical: AppSpacing.x1,
      ),
    ),
  );
}
