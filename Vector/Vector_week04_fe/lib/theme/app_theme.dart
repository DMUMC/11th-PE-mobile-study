import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static final ThemeData light = ThemeData(
    useMaterial3: true,
    fontFamily: 'Manrope',
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.violet,
      primary: AppColors.violet,
      surface: AppColors.warmWhite,
    ),
    scaffoldBackgroundColor: AppColors.warmWhite,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.warmWhite,
      foregroundColor: AppColors.violet,
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: 'Manrope',
        color: AppColors.violet,
        fontSize: 22,
        fontWeight: FontWeight.w800,
      ),
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.warmWhite,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.warmWhite,
      surfaceTintColor: Colors.transparent,
      indicatorColor: const Color(0xFFE9DDFB),
      height: 80,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 12,
          color: const Color(0xFF49454F),
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.bold
              : FontWeight.w500,
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.violet,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(0, 48),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.violet,
        side: const BorderSide(color: AppColors.violet),
        minimumSize: const Size(0, 48),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFD3CFD8),
      thickness: 1,
      space: 1,
    ),
    chipTheme: const ChipThemeData(
      side: BorderSide.none,
      backgroundColor: Color(0xFFE7E4E4),
      shape: StadiumBorder(),
    ),
  );
}
