import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/movielog_button.dart';

/// 앱 시작 시 저장된 토큰을 확인하는 동안 보여주는 화면.
/// 1주차 StartScreen의 로고·제목·설명 레이아웃을 그대로 재사용하고,
/// 하단 '시작하기' 버튼 자리를 로딩(확인 중) / 다시 시도(확인 실패)로 바꿨다.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key, this.message, this.onRetry});

  final String? message;

  /// null이면 확인 중(initializing), 있으면 확인 실패(retryRequired)
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  const SizedBox(height: 24),
                  const Text('FLUTTER 8주차', style: AppTextStyles.labelSmall),
                  const SizedBox(height: 56),
                  SvgPicture.asset(
                    'assets/logos/movielog_logo.svg',
                    width: 76,
                    height: 76,
                    colorFilter: const ColorFilter.mode(
                      AppColors.violet,
                      BlendMode.srcIn,
                    ),
                    semanticsLabel: 'MovieLog 로고',
                  ),
                  const SizedBox(height: 36),
                  const Text(
                    '영화의 순간을\n기록하세요',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '보고 싶은 영화부터 나만의 평점까지\n한곳에서 관리해요',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.gray,
                    ),
                  ),
                ],
              ),
              if (onRetry == null)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: CircularProgressIndicator(color: AppColors.violet),
                )
              else
                Column(
                  children: [
                    Text(
                      message ?? '로그인 상태를 확인하지 못했어요.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    MovieLogButton(
                      label: '다시 시도',
                      width: double.infinity,
                      onPressed: onRetry,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
