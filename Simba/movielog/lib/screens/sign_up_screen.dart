import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../view_models/sign_up_view_model.dart';
import '../widgets/movie_log_text_form_field.dart';
import '../widgets/movielog_button.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nicknameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  late final FocusNode _emailFocusNode;
  late final FocusNode _passwordFocusNode;

  bool _agreedToTerms = false;
  bool _obscurePassword = true;

  // 에러 메시지 상태 관리
  String? _nicknameError;
  String? _emailError;
  String? _passwordError;

  bool _isNicknameValid = false;
  bool _isEmailValid = false;
  bool _isPasswordValid = false;

  // 닉네임/이메일 중복 여부는 서버에 묻는다 (형식 검사는 이 화면에서).
  late final SignUpViewModel _viewModel;

  static const _nicknameMinLength = 2;
  static const _nicknameMaxLength = 12; // 서버 검증(2~12자)과 같은 범위

  @override
  void initState() {
    super.initState();
    _viewModel = context.read<SignUpViewModel>();
    _nicknameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();

    _emailFocusNode = FocusNode();
    _passwordFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();

    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  bool _isValidEmailFormat(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // 실시간 에러 검사
  void _updateValidationStatus() {
    final nick = _nicknameController.text.trim();
    final email = _emailController.text.trim();
    final pw = _passwordController.text;

    setState(() {
      // 닉네임 검증
      if (nick.isEmpty) {
        _nicknameError = null;
        _isNicknameValid = false;
      } else if (nick.length < _nicknameMinLength) {
        _nicknameError = '닉네임은 2자 이상이어야 합니다.';
        _isNicknameValid = false;
      } else if (nick.length > _nicknameMaxLength) {
        _nicknameError = '닉네임은 12자 이하여야 합니다.';
        _isNicknameValid = false;
      } else {
        _nicknameError = null;
        _isNicknameValid = true;
      }

      // 이메일 검증
      if (email.isEmpty) {
        _emailError = null;
        _isEmailValid = false;
      } else if (!_isValidEmailFormat(email)) {
        _emailError = '올바른 이메일 형식이 아닙니다.';
        _isEmailValid = false;
      } else {
        _emailError = null;
        _isEmailValid = true;
      }

      // 비밀번호 검증
      if (pw.isEmpty) {
        _passwordError = null;
        _isPasswordValid = false;
      } else if (pw.length < 8) {
        _passwordError = '비밀번호는 8자 이상이어야 합니다.';
        _isPasswordValid = false;
      } else {
        _passwordError = null;
        _isPasswordValid = true;
      }
    });
  }

  bool get _canSubmit =>
      _isNicknameValid &&
      _isEmailValid &&
      _isPasswordValid &&
      _agreedToTerms &&
      _viewModel.nicknameCheckStatus == CheckStatus.available &&
      _viewModel.emailCheckStatus == CheckStatus.available;

  void _handleSubmit() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || !_canSubmit) return;
    FocusScope.of(context).unfocus();

    // v5에는 회원가입 API가 없다. 실제 가입 요청은 보내지 않고 홈으로 이동만 한다.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('회원가입이 완료되었습니다!')),
    );
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    // 중복 확인 상태가 바뀌면 화면을 다시 그린다.
    final viewModel = context.watch<SignUpViewModel>();
    final nicknameStatus = viewModel.nicknameCheckStatus;
    final emailStatus = viewModel.emailCheckStatus;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/start'),
        ),
        title: const Text('회원가입', style: AppTextStyles.appBarTitle),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWideScreen = constraints.maxWidth >= 700;
            final formWidth = isWideScreen ? 560.0 : double.infinity;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: formWidth),
                child: SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SignUpHeader(),
                        const SizedBox(height: 32),

                        // 1. 닉네임 입력창
                        MovieLogTextFormField(
                          label: '닉네임',
                          hintText: '닉네임을 입력해주세요',
                          controller: _nicknameController,
                          textInputAction: TextInputAction.next,
                          hasError: _nicknameError != null ||
                              viewModel.nicknameErrorText != null,
                          isValid: _isNicknameValid &&
                              nicknameStatus == CheckStatus.available,
                          errorMessage:
                              _nicknameError ?? viewModel.nicknameErrorText,
                          // 로컬 validator가 통과해도 서버 결과(중복/실패)가 있으면 에러 상태
                          errorText: viewModel.nicknameErrorText,
                          helperMessage: nicknameStatus == CheckStatus.available
                              ? '사용할 수 있는 닉네임입니다.'
                              : null,
                          // 입력창 옆 보조 버튼: width를 주지 않아 내용 기반 크기(null)
                          trailing: MovieLogButton(
                            label: '중복 확인',
                            isLoading: nicknameStatus == CheckStatus.checking,
                            onPressed:
                                viewModel.canCheckNickname && _isNicknameValid
                                ? () => viewModel.checkNickname(
                                    _nicknameController.text,
                                  )
                                : null,
                          ),
                          validator: (value) {
                            final val = value?.trim() ?? '';
                            if (val.isEmpty) return '닉네임을 입력해주세요.';
                            if (val.length < _nicknameMinLength) {
                              return '닉네임은 2자 이상이어야 합니다.';
                            }
                            if (val.length > _nicknameMaxLength) {
                              return '닉네임은 12자 이하여야 합니다.';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            _updateValidationStatus();
                            // 입력이 바뀌면 이전 확인 결과를 무효화한다.
                            viewModel.onNicknameChanged(value);
                          },
                          onFieldSubmitted: (_) => _emailFocusNode.requestFocus(),
                        ),
                        const SizedBox(height: 18),

                        // 2. 이메일 입력창
                        MovieLogTextFormField(
                          label: '이메일',
                          hintText: '이메일 주소를 입력해주세요',
                          controller: _emailController,
                          focusNode: _emailFocusNode,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          hasError: _emailError != null ||
                              viewModel.emailErrorText != null,
                          isValid: _isEmailValid &&
                              emailStatus == CheckStatus.available,
                          errorMessage: _emailError ?? viewModel.emailErrorText,
                          errorText: viewModel.emailErrorText,
                          helperMessage: emailStatus == CheckStatus.available
                              ? '사용할 수 있는 이메일입니다.'
                              : null,
                          trailing: MovieLogButton(
                            label: '중복 확인',
                            isLoading: emailStatus == CheckStatus.checking,
                            onPressed: viewModel.canCheckEmail && _isEmailValid
                                ? () => viewModel.checkEmail(
                                    _emailController.text,
                                  )
                                : null,
                          ),
                          validator: (value) {
                            final val = value?.trim() ?? '';
                            if (val.isEmpty) return '이메일을 입력해주세요.';
                            if (!_isValidEmailFormat(val)) return '올바른 이메일 형식이 아닙니다.';
                            return null;
                          },
                          onChanged: (value) {
                            _updateValidationStatus();
                            viewModel.onEmailChanged(value);
                          },
                          onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
                        ),
                        const SizedBox(height: 18),

                        // 3. 비밀번호 입력창
                        MovieLogTextFormField(
                          label: '비밀번호',
                          hintText: '비밀번호를 입력해주세요',
                          controller: _passwordController,
                          focusNode: _passwordFocusNode,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          hasError: _passwordError != null,
                          isValid: _isPasswordValid,
                          errorMessage: _passwordError,
                          suffixIcon: _passwordError != null
                              ? const Icon(
                                  Icons.error_outline,
                                  color: Color(0xFFD32F2F),
                                )
                              : (_passwordController.text.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: AppColors.gray,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    )
                                  : null),
                          validator: (value) {
                            final val = value ?? '';
                            if (val.isEmpty) return '비밀번호를 입력해주세요.';
                            if (val.length < 8) return '비밀번호는 8자 이상이어야 합니다.';
                            return null;
                          },
                          onChanged: (_) => _updateValidationStatus(),
                          onFieldSubmitted: (_) => _handleSubmit(),
                        ),
                        const SizedBox(height: 24),

                        // 필수 약관 동의 체크박스
                        TermsAgreementRow(
                          value: _agreedToTerms,
                          onChanged: (val) {
                            setState(() {
                              _agreedToTerms = val ?? false;
                            });
                          },
                        ),
                        const SizedBox(height: 24),

                        // 가입하기 버튼: Form 하단 전체 너비(double.infinity)
                        MovieLogButton(
                          label: '가입하기',
                          width: double.infinity,
                          onPressed: _canSubmit ? _handleSubmit : null,
                        ),
                        const SizedBox(height: 28),

                        const LoginFooter(),
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

class SignUpHeader extends StatelessWidget {
  const SignUpHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SizedBox(height: 12),
        Text(
          '환영합니다!\n간단한 정보만 입력하고 시작해보세요.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class TermsAgreementRow extends StatelessWidget {
  const TermsAgreementRow({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(6),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.violet,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            '필수 약관에 동의합니다',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class LoginFooter extends StatelessWidget {
  const LoginFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          '이미 계정이 있나요? ',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.black,
          ),
        ),
        GestureDetector(
          // 로그인 화면은 7주차에 만든다. 지금은 가입 없이 홈으로 이동한다.
          onTap: () => context.go('/home'),
          child: const Text(
            '로그인',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.violet,
            ),
          ),
        ),
      ],
    );
  }
}