import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'sign_up_text_field.dart';

class SignUpForm extends StatelessWidget {
  const SignUpForm({
    super.key,
    required this.nicknameController,
    required this.emailController,
    required this.passwordController,
    required this.emailFocusNode,
    required this.passwordFocusNode,
  });

  final TextEditingController nicknameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final FocusNode emailFocusNode;
  final FocusNode passwordFocusNode;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SignUpTextField(
          controller: nicknameController,
          label: '닉네임',
          hintText: '닉네임을 입력해주세요',
        ),
        const SizedBox(height: AppSpacing.x2),
        SignUpTextField(
          controller: emailController,
          label: '이메일',
          hintText: '이메일 주소를 입력해주세요',
          focusNode: emailFocusNode,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: AppSpacing.x2),
        SignUpTextField(
          controller: passwordController,
          focusNode: passwordFocusNode,
          label: '비밀번호',
          hintText: '비밀번호를 입력해주세요',
          obscureText: true,
        ),
      ],
    );
  }
}
