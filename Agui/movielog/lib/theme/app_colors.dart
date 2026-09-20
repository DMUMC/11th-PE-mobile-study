import 'package:flutter/material.dart';

abstract final class AppColors {
  /// Figma Design System 원본 색상값
  static const primary = Color(0xFF6750A4);
  static const onPrimary = Color(0xFFFFFFFF);

  static const surface = Color(0xFFFAF9F5);
  static const onSurface = Color(0xFF1C1B1F);

  // 화면별 특수 표현이 필요할 때를 위한 별칭입니다.
  static const violet = primary;
  static const warmWhite = surface;
  static const white = Color(0xFFFFFFFF);

  static const black = onSurface;
  static const gray = Color(0xFF79747E);
  static const outline = gray;
  static const error = Color(0xFFB3261E);
}
