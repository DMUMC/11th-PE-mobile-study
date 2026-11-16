import 'package:flutter/material.dart';
import 'package:movielog/theme/app_colors.dart';

class MovieRequestErrorDialog extends StatelessWidget {
  const MovieRequestErrorDialog({super.key, this.onDebugRestore});

  final VoidCallback? onDebugRestore;

  @override
  Widget build(BuildContext context) {
    final icon = Container(
      width: 56,
      height: 56,
      decoration: const BoxDecoration(
        color: AppColors.primary100,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.replay_rounded,
        size: 36,
        color: AppColors.primary500,
      ),
    );

    return Dialog(
      backgroundColor: AppColors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: SizedBox(
        width: 326,
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onDebugRestore != null)
                Tooltip(
                  message: '디버그: 네트워크 복구',
                  child: InkWell(
                    onTap: onDebugRestore,
                    customBorder: const CircleBorder(),
                    child: icon,
                  ),
                )
              else
                icon,
              const SizedBox(height: 8),
              const Text(
                '영화를 불러오지 못했어요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  height: 1.4,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '네트워크 상태를 확인하고\n다시 시도해 주세요.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.65,
                  color: AppColors.secondary500,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 52,
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.primary100,
                          foregroundColor: AppColors.primary500,
                          padding: EdgeInsets.zero,
                          shape: const StadiumBorder(),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                          minimumSize: const Size(0, 52),
                        ),
                        child: const Text('취소'),
                      ),
                    ),
                    const SizedBox(width: 22),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary500,
                          foregroundColor: AppColors.white,
                          padding: EdgeInsets.zero,
                          shape: const StadiumBorder(),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                          minimumSize: const Size(0, 52),
                        ),
                        child: const Text('다시 시도'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
