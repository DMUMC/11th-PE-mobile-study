import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

import 'services/member_api.dart';
import 'widgets/availability_field.dart';
import 'widgets/movielog_button.dart';
import 'widgets/movielog_text_form_field.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key, required this.api, this.onSignup});
  final MemberApi api;
  final ValueChanged<int>? onSignup;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nicknameKey = GlobalKey<AvailabilityFieldState>();
  final _emailKey = GlobalKey<AvailabilityFieldState>();
  final _formKey = GlobalKey<FormState>();

  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _agreeTerms = false;
  bool _submitting = false;

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
    if (value.trim().length < 2 || value.trim().length > 24) {
      return '닉네임은 2~24자로 입력해주세요.';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '이메일 주소를 입력해주세요.';
    }

    if (value.trim().length > 254 ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim())) {
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

    if (!RegExp(r'^[!-~]{8,72}$').hasMatch(value)) {
      return '공백 없이 출력 가능한 영문 문자로 8~72자를 입력해주세요.';
    }
    return null;
  }

  void _notice(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    if (!_nicknameKey.currentState!.isVerified ||
        !_emailKey.currentState!.isVerified) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('닉네임과 이메일 중복 확인을 완료해주세요.')));
      return;
    }

    if (!_agreeTerms) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('필수 약관에 동의해주세요.')));
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    try {
      final id = await widget.api.signup(
        _nicknameController.text,
        _emailController.text,
        _passwordController.text,
      );
      if (!mounted) return;
      widget.onSignup?.call(id);
      _passwordController.clear();
      _notice('회원가입 완료 · 회원 #$id');
    } on MemberApiException catch (error) {
      if (!mounted) return;
      if (error.status == 409) {
        _nicknameKey.currentState?.invalidate();
        _emailKey.currentState?.invalidate();
      }
      _notice(error.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_submitting,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: '뒤로',
            icon: const Icon(Icons.arrow_back),
            onPressed: _submitting
                ? null
                : () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home');
                    }
                  },
          ),
        ),
        body: AbsorbPointer(
          absorbing: _submitting,
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 700;

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 40,
                  ),
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

                            AvailabilityField(
                              key: _nicknameKey,
                              api: widget.api,
                              field: MemberField.nickname,
                              label: '닉네임',
                              hint: '영화로운 닉네임을 입력하세요',
                              controller: _nicknameController,
                              validator: _validateNickname,
                            ),
                            const SizedBox(height: 20),
                            AvailabilityField(
                              key: _emailKey,
                              api: widget.api,
                              field: MemberField.email,
                              label: '이메일',
                              hint: 'example@movielog.com',
                              controller: _emailController,
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

                            MovieLogButton(
                              width: double.infinity,
                              label: '가입하기',
                              onPressed: _submit,
                              loading: _submitting,
                            ),
                            TextButton(
                              onPressed: () => context.push('/button-widths'),
                              child: const Text('버튼 너비 비교'),
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
        ),
      ),
    );
  }
}
