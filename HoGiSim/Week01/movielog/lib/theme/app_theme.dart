import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  static ThemeData get light {
    const colorScheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      outline: AppColors.outline,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.surface,
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          fontSize: 38,
          fontWeight: FontWeight.w400,
          height: 1.2,
        ),
        bodyLarge: TextStyle(fontSize: 16, height: 1.5),
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primary,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 16,
        titleTextStyle: TextStyle(
          color: AppColors.primary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: AppColors.primaryContainer,
        side: BorderSide.none,
        shape: StadiumBorder(),
        labelStyle: TextStyle(
          color: AppColors.onPrimaryContainer,
          fontSize: 12,
        ),
      ),
    );
  }
}
