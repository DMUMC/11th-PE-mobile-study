import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:movielog/widgets/sign_up/sign_up_header.dart';
import 'package:movielog/widgets/sign_up/sign_up_fields.dart';
import 'package:movielog/widgets/sign_up/sign_up_actions.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nicknameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _agreedToTerms = false;

  bool get _canSubmit =>
      _validateNickname(_nicknameController.text) == null &&
      _validateEmail(_emailController.text) == null &&
      _validatePassword(_passwordController.text) == null &&
      _agreedToTerms;

  String? _validateNickname(String? value) {
    final nickname = value?.trim() ?? '';
    if (nickname.isEmpty) return '닉네임을 입력해주세요.';
    if (nickname.characters.length < 2) return '닉네임은 2자 이상이어야 합니다.';
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return '이메일을 입력해주세요.';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return '올바른 이메일 형식이 아닙니다.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return '비밀번호를 입력해주세요.';
    if (password.characters.length < 8) return '비밀번호는 8자 이상이어야 합니다.';
    return null;
  }

  void _submit() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || !_canSubmit) return;
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: Center(
          child: SvgPicture.asset(
            'assets/icons/arrow_back.svg',
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(colors.onSurface, BlendMode.srcIn),
          ),
        ),
        title: Text(
          '회원가입',
          style: textTheme.headlineMedium?.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (constraints.maxHeight - 56).clamp(
                  0.0,
                  double.infinity,
                ),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SignUpHeader(),
                        const SizedBox(height: 48),
                        SignUpFields(
                          nicknameController: _nicknameController,
                          emailController: _emailController,
                          passwordController: _passwordController,
                          nicknameFocus: _nicknameFocus,
                          emailFocus: _emailFocus,
                          passwordFocus: _passwordFocus,
                          validateNickname: _validateNickname,
                          validateEmail: _validateEmail,
                          validatePassword: _validatePassword,
                          onChanged: () => setState(() {}),
                          onDone: () {
                            FocusScope.of(context).unfocus();
                          },
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 32),
                      child: SignUpActions(
                        agreedToTerms: _agreedToTerms,
                        onAgreementChanged: (value) {
                          setState(() => _agreedToTerms = value);
                        },
                        onSubmit: _canSubmit ? _submit : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nicknameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }
}
