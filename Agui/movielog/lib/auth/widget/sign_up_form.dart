import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'sign_up_text_field.dart';

String? validateNickname(String? value) {
  final nickname = value?.trim() ?? '';

  if (nickname.isEmpty) {
    return '닉네임을 입력해주세요.';
  }

  if (nickname.length < 2) {
    return '닉네임은 2자 이상이어야 합니다.';
  }

  return null;
}

class SignUpForm extends StatelessWidget {
  const SignUpForm({
    super.key,
    required this.nicknameController,
    required this.emailController,
    required this.passwordController,
    required this.emailFocusNode,
    required this.passwordFocusNode,
    required this.onNicknameChanged,
    this.nicknameErrorText,
  });

  final TextEditingController nicknameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final FocusNode emailFocusNode;
  final FocusNode passwordFocusNode;
  final ValueChanged<String> onNicknameChanged;
  final String? nicknameErrorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SignUpTextField(
          controller: nicknameController,
          label: '닉네임',
          hintText: '닉네임을 입력해주세요',
          validator: validateNickname,
          errorText: nicknameErrorText,
          onChanged: onNicknameChanged,
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
