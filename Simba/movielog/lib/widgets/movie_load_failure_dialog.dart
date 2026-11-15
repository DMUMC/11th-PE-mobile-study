import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 영화 목록 요청 실패 안내 Dialog.
/// "다시 시도"는 true, "취소"는 false를 반환한다.
class MovieLoadFailureDialog extends StatelessWidget {
  const MovieLoadFailureDialog({super.key});

  static Future<bool> show(BuildContext context) async {
    final shouldRetry = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const MovieLoadFailureDialog(),
    );
    return shouldRetry ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.lightViolet,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.refresh, color: AppColors.violet, size: 36),
            ),
            const SizedBox(height: 16),
            const Text(
              '영화를 불러오지 못했어요',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '네트워크 상태를 확인하고\n다시 시도해 주세요.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, height: 1.6, color: AppColors.gray),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: _DialogButton(
                    label: '취소',
                    backgroundColor: AppColors.lightViolet,
                    foregroundColor: AppColors.violet,
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _DialogButton(
                    label: '다시 시도',
                    backgroundColor: AppColors.violet,
                    foregroundColor: AppColors.white,
                    onPressed: () => Navigator.pop(context, true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          shape: const StadiumBorder(),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
