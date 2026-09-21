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

String? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  final emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  if (email.isEmpty) {
    return '이메일을 입력해주세요.';
  }

  if (!emailPattern.hasMatch(email)) {
    return '올바른 이메일 형식이 아닙니다.';
  }

  return null;
}

String? validatePassword(String? value) {
  final password = value ?? '';

  if (password.isEmpty) {
    return '비밀번호를 입력해주세요.';
  }

  if (password.length < 8) {
    return '비밀번호는 8자 이상이어야 합니다.';
  }

  return null;
}

class SignUpForm extends StatelessWidget {
  const SignUpForm({
    super.key,
    required this.nicknameController,
    required this.emailController,
    required this.passwordController,
    required this.nicknameFocusNode,
    required this.emailFocusNode,
    required this.passwordFocusNode,
    required this.onNicknameChanged,
    required this.onEmailChanged,
    required this.onPasswordChanged,
    required this.isNicknameValid,
    required this.isEmailValid,
    required this.isPasswordValid,
    this.nicknameErrorText,
    this.emailErrorText,
    this.passwordErrorText,
  });

  final TextEditingController nicknameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final FocusNode nicknameFocusNode;
  final FocusNode emailFocusNode;
  final FocusNode passwordFocusNode;
  final ValueChanged<String> onNicknameChanged;
  final ValueChanged<String> onEmailChanged;
  final ValueChanged<String> onPasswordChanged;
  final bool isNicknameValid;
  final bool isEmailValid;
  final bool isPasswordValid;
  final String? nicknameErrorText;
  final String? emailErrorText;
  final String? passwordErrorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SignUpTextField(
          controller: nicknameController,
          label: '닉네임',
          hintText: '닉네임을 입력해주세요',
          focusNode: nicknameFocusNode,
          validator: validateNickname,
          errorText: nicknameErrorText,
          onChanged: onNicknameChanged,
          showSuccessIcon: isNicknameValid,
        ),
        const SizedBox(height: AppSpacing.x2),
        SignUpTextField(
          controller: emailController,
          label: '이메일',
          hintText: '이메일 주소를 입력해주세요',
          focusNode: emailFocusNode,
          keyboardType: TextInputType.emailAddress,
          validator: validateEmail,
          errorText: emailErrorText,
          onChanged: onEmailChanged,
          showSuccessIcon: isEmailValid,
        ),
        const SizedBox(height: AppSpacing.x2),
        SignUpTextField(
          controller: passwordController,
          focusNode: passwordFocusNode,
          label: '비밀번호',
          hintText: '비밀번호를 입력해주세요',
          obscureText: true,
          validator: validatePassword,
          errorText: passwordErrorText,
          onChanged: onPasswordChanged,
          showSuccessIcon: isPasswordValid,
        ),
      ],
    );
  }
}
