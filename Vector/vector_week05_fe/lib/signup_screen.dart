import 'package:flutter/material.dart';

import 'widgets/movielog_text_form_field.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _agreeTerms = false;

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateNickname(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '닉네임을 입력해주세요.';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '이메일 주소를 입력해주세요.';
    }

    if (!value.contains('@')) {
      return '올바른 이메일 주소를 입력해주세요.';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return '비밀번호를 입력해주세요.';
    }

    if (value.length < 8) {
      return '비밀번호는 8자 이상이어야 합니다.';
    }

    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(value);
    final hasNumber = RegExp(r'[0-9]').hasMatch(value);

    if (!hasLetter || !hasNumber) {
      return '영문과 숫자를 모두 포함해주세요.';
    }

    return null;
  }

  void _submit() {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    if (!_agreeTerms) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('필수 약관에 동의해주세요.')));
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('회원가입 입력이 완료되었습니다.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 700;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isWide ? 560 : double.infinity,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 60),

                        Text(
                          '회원가입',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          'MovieLog에 오신 것을 환영합니다!',
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 40),

                        MovieLogTextFormField(
                          label: '닉네임',
                          hintText: '영화로운 닉네임을 입력하세요',
                          controller: _nicknameController,
                          validator: _validateNickname,
                        ),

                        const SizedBox(height: 20),

                        MovieLogTextFormField(
                          label: '이메일 주소',
                          hintText: 'example@movielog.com',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: _validateEmail,
                        ),

                        const SizedBox(height: 20),

                        MovieLogTextFormField(
                          label: '비밀번호',
                          hintText: '영문, 숫자 포함 8자 이상',
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          validator: _validatePassword,
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        Row(
                          children: [
                            Checkbox(
                              value: _agreeTerms,
                              onChanged: (value) {
                                setState(() {
                                  _agreeTerms = value ?? false;
                                });
                              },
                            ),
                            const Expanded(child: Text('필수 약관에 동의합니다')),
                          ],
                        ),

                        const SizedBox(height: 20),

                        SizedBox(
                          height: 52,
                          child: FilledButton(
                            onPressed: _submit,
                            child: const Text('가입하기'),
                          ),
                        ),

                        const SizedBox(height: 28),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('이미 계정이 있나요? '),
                            TextButton(
                              onPressed: () {},
                              child: const Text('로그인'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
