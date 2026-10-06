import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppTextStyles {
  // 앱바 제목
  static const appBarTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.violet,
  );

  // 헤더 닉네임, 메인 타이틀
  static const titleLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.black,
  );

  // 섹션 제목 ("선호하는 장르")
  static const sectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.black,
  );

  // 통계 카드 숫자
  static const statValue = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.violet,
  );

  // 본문 / 소개글
  static const bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.black,
    height: 1.4,
  );

  // 통계 라벨 / 보조 텍스트
  static const labelSmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.gray,
  );

  // 장르 칩 텍스트
  static const chipText = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.violet,
  );
}