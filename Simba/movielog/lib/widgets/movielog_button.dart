import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 여러 화면이 함께 쓰는 공용 버튼.
/// 상태(기본 · 통신 중 · 비활성)는 화면(ViewModel)이 정해서 넘겨주고, 버튼은 표시만 한다.
///
/// - [onPressed]가 null이면 비활성 상태
/// - [isLoading]이 true면 [onPressed]와 관계없이 비활성 + 중앙에 인디케이터만 표시
/// - [width]
///   - null: 내용(label) 기반 크기 (예: 입력창 옆 중복 확인 버튼)
///   - double.infinity: 부모가 허용하는 최대 너비 (예: Form 하단 가입하기 버튼)
///   - 고정 값: 항상 같은 크기 (예: 다시 시도 버튼)
class MovieLogButton extends StatelessWidget {
  const MovieLogButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.width,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;

  bool get _disabled => isLoading || onPressed == null;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 44,
      child: ElevatedButton(
        onPressed: _disabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.violet,
          disabledBackgroundColor: AppColors.gray,
          foregroundColor: AppColors.white,
          disabledForegroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        // 통신 중에는 label과 인디케이터 중 하나만 그린다.
        child: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.white,
                ),
              )
            : Text(label),
      ),
    );
  }
}
