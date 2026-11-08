import 'package:flutter/material.dart';

class SignUpHeader extends StatelessWidget {
  const SignUpHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Text(
          '환영합니다!',
          style: textTheme.bodyLarge?.copyWith(
            height: 1.25,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text('간단한 정보만 입력하고 시작해보세요.', style: textTheme.bodyMedium),
      ],
    );
  }
}
