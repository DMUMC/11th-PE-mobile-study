import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/movie_log_text_form_field.dart';

abstract final class SignUpValidators {
  static String? nickname(String? value) {
    final nickname = value?.trim() ?? '';
    if (nickname.isEmpty) return '닉네임을 입력해주세요.';
    if (nickname.length < 2) return '닉네임은 2자 이상이어야 합니다.';
    return null;
  }

  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return '이메일을 입력해주세요.';
    final emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailPattern.hasMatch(email)) return '올바른 이메일 형식이 아닙니다.';
    return null;
  }

  static String? password(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return '비밀번호를 입력해주세요.';
    if (password.length < 8) return '비밀번호는 8자 이상이어야 합니다.';
    return null;
  }
}

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
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _agreedToTerms = false;
  bool _obscurePassword = true;
  bool _nicknameTouched = false;
  bool _emailTouched = false;
  bool _passwordTouched = false;
  bool _submitted = false;

  bool get _nicknameValid =>
      SignUpValidators.nickname(_nicknameController.text) == null;
  bool get _emailValid => SignUpValidators.email(_emailController.text) == null;
  bool get _passwordValid =>
      SignUpValidators.password(_passwordController.text) == null;
  bool get _canSubmit =>
      _nicknameValid && _emailValid && _passwordValid && _agreedToTerms;

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _onFieldChanged(_SignUpField field) {
    setState(() {
      switch (field) {
        case _SignUpField.nickname:
          _nicknameTouched = true;
        case _SignUpField.email:
          _emailTouched = true;
        case _SignUpField.password:
          _passwordTouched = true;
      }
    });
  }

  void _submit() {
    setState(() => _submitted = true);
    if (!(_formKey.currentState?.validate() ?? false) || !_agreedToTerms) {
      return;
    }
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('회원가입 정보가 확인되었습니다.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 700;
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 32 : 24,
                vertical: isWide ? 24 : 12,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 24,
                ),
                child: Center(
                  child: ConstrainedBox(
                    key: const Key('signUpFormContent'),
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: IntrinsicHeight(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (isWide)
                              const SizedBox(height: 240)
                            else
                              const _MobileAppBar(),
                            SizedBox(height: isWide ? 12 : 70),
                            SignUpHeader(isWide: isWide),
                            SizedBox(height: isWide ? 34 : 64),
                            SignUpFields(
                              isWide: isWide,
                              nicknameController: _nicknameController,
                              emailController: _emailController,
                              passwordController: _passwordController,
                              emailFocusNode: _emailFocusNode,
                              passwordFocusNode: _passwordFocusNode,
                              obscurePassword: _obscurePassword,
                              nicknameValid: _nicknameValid,
                              emailValid: _emailValid,
                              passwordValid: _passwordValid,
                              nicknameHasError:
                                  (_nicknameTouched || _submitted) &&
                                  !_nicknameValid,
                              emailHasError:
                                  (_emailTouched || _submitted) && !_emailValid,
                              passwordHasError:
                                  (_passwordTouched || _submitted) &&
                                  !_passwordValid,
                              onNicknameChanged: (_) =>
                                  _onFieldChanged(_SignUpField.nickname),
                              onEmailChanged: (_) =>
                                  _onFieldChanged(_SignUpField.email),
                              onPasswordChanged: (_) =>
                                  _onFieldChanged(_SignUpField.password),
                              onTogglePassword: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                            if (isWide)
                              const SizedBox(height: 24)
                            else
                              const Spacer(),
                            AgreementCheckbox(
                              value: _agreedToTerms,
                              onChanged: (value) =>
                                  setState(() => _agreedToTerms = value),
                            ),
                            const SizedBox(height: 24),
                            SignUpActionArea(
                              enabled: _canSubmit,
                              onSubmit: _submit,
                            ),
                            SizedBox(height: isWide ? 26 : 38),
                            const _LoginPrompt(),
                            SizedBox(height: isWide ? 80 : 28),
                          ],
                        ),
                      ),
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

enum _SignUpField { nickname, email, password }

class _MobileAppBar extends StatelessWidget {
  const _MobileAppBar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              tooltip: '뒤로가기',
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.arrow_back, size: 30),
              color: AppColors.onSurfaceVariant,
            ),
          ),
          Text('회원가입', style: Theme.of(context).textTheme.headlineSmall),
        ],
      ),
    );
  }
}

class SignUpHeader extends StatelessWidget {
  const SignUpHeader({required this.isWide, super.key});

  final bool isWide;

  @override
  Widget build(BuildContext context) {
    if (isWide) {
      return Column(
        children: [
          Text('회원가입', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text('MovieLog에 오신 것을 환영합니다!'),
        ],
      );
    }
    return Text(
      '환영합니다!\n간단한 정보만 입력하고 시작해보세요.',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyLarge,
    );
  }
}

class SignUpFields extends StatelessWidget {
  const SignUpFields({
    required this.isWide,
    required this.nicknameController,
    required this.emailController,
    required this.passwordController,
    required this.emailFocusNode,
    required this.passwordFocusNode,
    required this.obscurePassword,
    required this.nicknameValid,
    required this.emailValid,
    required this.passwordValid,
    required this.nicknameHasError,
    required this.emailHasError,
    required this.passwordHasError,
    required this.onNicknameChanged,
    required this.onEmailChanged,
    required this.onPasswordChanged,
    required this.onTogglePassword,
    super.key,
  });

  final bool isWide;
  final TextEditingController nicknameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final FocusNode emailFocusNode;
  final FocusNode passwordFocusNode;
  final bool obscurePassword;
  final bool nicknameValid;
  final bool emailValid;
  final bool passwordValid;
  final bool nicknameHasError;
  final bool emailHasError;
  final bool passwordHasError;
  final ValueChanged<String> onNicknameChanged;
  final ValueChanged<String> onEmailChanged;
  final ValueChanged<String> onPasswordChanged;
  final VoidCallback onTogglePassword;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MovieLogTextFormField(
          fieldKey: const Key('nicknameField'),
          label: '닉네임',
          hintText: isWide ? '영화로운 닉네임을 입력하세요' : '닉네임을 입력해주세요',
          controller: nicknameController,
          validator: SignUpValidators.nickname,
          onChanged: onNicknameChanged,
          textInputAction: TextInputAction.next,
          isValid: nicknameValid,
          showErrorState: nicknameHasError,
          onFieldSubmitted: (_) => emailFocusNode.requestFocus(),
        ),
        const SizedBox(height: 24),
        MovieLogTextFormField(
          fieldKey: const Key('emailField'),
          label: isWide ? '이메일 주소' : '이메일',
          hintText: isWide ? 'example@movielog.com' : '이메일 주소를 입력해주세요',
          controller: emailController,
          focusNode: emailFocusNode,
          keyboardType: TextInputType.emailAddress,
          validator: SignUpValidators.email,
          onChanged: onEmailChanged,
          textInputAction: TextInputAction.next,
          isValid: emailValid,
          showErrorState: emailHasError,
          onFieldSubmitted: (_) => passwordFocusNode.requestFocus(),
        ),
        const SizedBox(height: 24),
        MovieLogTextFormField(
          fieldKey: const Key('passwordField'),
          label: '비밀번호',
          hintText: isWide ? '영문, 숫자 포함 8자 이상' : '비밀번호를 입력해주세요',
          controller: passwordController,
          focusNode: passwordFocusNode,
          keyboardType: TextInputType.visiblePassword,
          validator: SignUpValidators.password,
          onChanged: onPasswordChanged,
          textInputAction: TextInputAction.done,
          obscureText: obscurePassword,
          isValid: passwordValid,
          showErrorState: passwordHasError,
          onToggleObscure: onTogglePassword,
          onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
        ),
      ],
    );
  }
}

class AgreementCheckbox extends StatelessWidget {
  const AgreementCheckbox({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          Checkbox(
            key: const Key('termsCheckbox'),
            value: value,
            onChanged: (newValue) => onChanged(newValue ?? false),
          ),
          const SizedBox(width: 6),
          const Expanded(
            child: Text('필수 약관에 동의합니다', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

class SignUpActionArea extends StatelessWidget {
  const SignUpActionArea({
    required this.enabled,
    required this.onSubmit,
    super.key,
  });

  final bool enabled;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: ElevatedButton(
        key: const Key('signUpButton'),
        onPressed: enabled ? onSubmit : null,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.disabledPrimary,
          disabledForegroundColor: AppColors.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        child: const Text('가입하기'),
      ),
    );
  }
}

class _LoginPrompt extends StatelessWidget {
  const _LoginPrompt();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('이미 계정이 있나요? ', style: TextStyle(fontSize: 15)),
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 2),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            '로그인',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
