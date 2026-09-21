import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class EditProfileButton extends StatelessWidget {
  const EditProfileButton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsetsGeometry.all(0),
      child: TextButton(
        // 프로필 수정 화면은 아직 연결하지 않습니다.
        onPressed: () {},
        style: TextButton.styleFrom(
          padding: EdgeInsets.only(
            top: AppSpacing.x1,
            right: AppSpacing.x3,
            bottom: AppSpacing.x1,
            left: AppSpacing.x3,
          ),
          side: BorderSide(color: colors.primary),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.borderRadius,
          ),
          textStyle: textTheme.bodySmall?.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: const Text('프로필 수정'),
      ),
    );
  }
}
