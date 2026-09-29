import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class SignUpSubmitButton extends StatelessWidget {
  const SignUpSubmitButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppComponentHeight.button,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          disabledBackgroundColor: Theme.of(context)
              .colorScheme
              .primaryContainer,
          disabledForegroundColor: Theme.of(context).colorScheme.onPrimary,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.borderRadius,
          ),
        ),
        child: const Text('가입하기'),
      ),
    );
  }
}
