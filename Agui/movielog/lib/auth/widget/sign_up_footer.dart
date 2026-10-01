import 'package:flutter/material.dart';

class SignUpFooter extends StatelessWidget {
  const SignUpFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Text.rich(
      TextSpan(
        text: '이미 계정이 있나요? ',
        style: textTheme.bodySmall,
        children: [
          TextSpan(
            text: '로그인',
            style: textTheme.bodySmall?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
