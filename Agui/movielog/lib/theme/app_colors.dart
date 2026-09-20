import 'package:flutter/material.dart';

abstract final class AppColors {
  /// Figma Design System 원본 Color Palette
  ///
  /// 스케일 값은 원본 색상 토큰이며, 화면에서는 아래 semantic alias 또는
  /// `Theme.of(context).colorScheme`를 사용합니다.

  // Primary scale
  static const primary100 = Color(0xFFF3EFFF);
  static const primary200 = Color(0xFFE9DDFF);
  static const primary300 = Color(0xFFD0BCFF);
  static const primary400 = Color(0xFFB69DF8);
  static const primary500 = Color(0xFF6750A4);
  static const primary600 = Color(0xFF4F378A);
  static const primary700 = Color(0xFF381E72);
  static const primary800 = Color(0xFF22005C);
  static const primary900 = Color(0xFF10002B);

  // Secondary scale
  static const secondary100 = Color(0xFFF5F3F7);
  static const secondary200 = Color(0xFFE8DEF9);
  static const secondary300 = Color(0xFFCCC2DC);
  static const secondary400 = Color(0xFFB0A7C0);
  static const secondary500 = Color(0xFF625B71);
  static const secondary600 = Color(0xFF4A4358);
  static const secondary700 = Color(0xFF332D41);
  static const secondary800 = Color(0xFF1E192B);
  static const secondary900 = Color(0xFF0F0B1A);

  // Surface tones
  static const surfaceLowest = Color(0xFFFFFFFF);
  static const surfaceLow = Color(0xFFF5F3F0);
  static const surfaceBase = Color(0xFFFAF9F5);
  static const surfaceContainer = Color(0xFFEFEEEA);
  static const surfaceHigh = Color(0xFFE9E8E4);
  static const surfaceHighest = Color(0xFFE3E2DF);

  // Tertiary scale
  static const tertiary100 = Color(0xFFFFDF93);
  static const tertiary200 = Color(0xFFE7C365);
  static const tertiary300 = Color(0xFFC9A74D);
  static const tertiary500 = Color(0xFF765B00);
  static const tertiary700 = Color(0xFF594400);
  static const tertiary900 = Color(0xFF241A00);

  // Neutral scale
  static const neutral100 = Color(0xFFFFFFFF);
  static const neutral200 = Color(0xFFF5F3F0);
  static const neutral300 = Color(0xFFEFEEEA);
  static const neutral400 = Color(0xFFE3E2DF);
  static const neutral500 = Color(0xFF7A7582);
  static const neutral700 = Color(0xFF1B1C1A);

  // Semantic aliases used by the app theme and screens.
  static const primary = primary500;
  static const onPrimary = neutral100;
  static const surface = surfaceBase;
  static const onSurface = neutral700;
  static const outline = neutral500;

  static const violet = primary;
  static const warmWhite = surface;
  static const white = neutral100;
  static const black = onSurface;
  static const gray = neutral500;
  static const error = Color(0xFFB3261E);
}
