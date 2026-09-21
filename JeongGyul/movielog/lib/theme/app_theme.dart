import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

abstract final class AppTheme {
  static const _colorScheme = ColorScheme.light(
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
    tertiaryContainer: AppColors.tertiary100,
    onTertiaryContainer: AppColors.tertiary900,
    surface: AppColors.surfaceBase,
    onSurface: AppColors.neutral900,
    surfaceContainerLowest: AppColors.surfaceLowest,
    surfaceContainerLow: AppColors.surfaceLow,
    surfaceContainer: AppColors.surfaceContainer,
    surfaceContainerHigh: AppColors.surfaceHigh,
    surfaceContainerHighest: AppColors.surfaceHighest,
    onSurfaceVariant: AppColors.neutral800,
    outline: AppColors.secondary500,
    outlineVariant: AppColors.secondary300,
  );

  static const _textTheme = TextTheme(
    headlineLarge: AppTextStyles.titleLargeBold,
    headlineMedium: AppTextStyles.titleMediumSemiBold,
    bodyLarge: AppTextStyles.bodyLargeRegular,
    bodyMedium: AppTextStyles.bodyMediumRegular,
    labelLarge: AppTextStyles.labelLargeSemiBold,
    labelSmall: AppTextStyles.labelSmallRegular,
  );

  static final ThemeData light = ThemeData(
    useMaterial3: true,
    fontFamily: 'Manrope',
    scaffoldBackgroundColor: AppColors.surfaceBase,
    colorScheme: _colorScheme,
    textTheme: _textTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surfaceBase,
      foregroundColor: AppColors.neutral900,
      titleTextStyle: AppTextStyles.bodyLargeSemiBold,
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.surfaceBase,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(0, 48),
        backgroundColor: AppColors.primary500,
        foregroundColor: AppColors.neutral100,
        textStyle: AppTextStyles.labelLargeSemiBold,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    chipTheme: const ChipThemeData(
      backgroundColor: AppColors.primary200,
      labelStyle: AppTextStyles.labelSmallMedium,
      side: BorderSide.none,
      shape: StadiumBorder(),
    ),
  );
}
