import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class SignUpSubmitButton extends StatelessWidget {
  const SignUpSubmitButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          disabledBackgroundColor: Theme.of(context).colorScheme.primary
              .withValues(alpha: 0.32),
          disabledForegroundColor: Theme.of(context).colorScheme.onPrimary,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.borderRadius,
          ),
        ),
        child: Text(
          '가입하기',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
