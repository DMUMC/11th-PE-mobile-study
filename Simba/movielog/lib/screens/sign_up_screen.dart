import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/create_member_request.dart';
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

  /// 서버(CreateMemberDto)와 같은 규칙: 8자 이상, 소문자·대문자·숫자·특수문자(!@#$%^&*) 각 1개 이상.
  /// 클라이언트 검증은 빠른 안내용이며 서버 검증을 대체하지 않는다.
  static final _passwordPattern = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*]).{8,}$',
  );
  static const _passwordRuleMessage =
      '비밀번호는 대문자/소문자/숫자/특수문자(!@#\$%^&*)를 포함한 8자 이상이어야 합니다.';

  String? _validatePasswordFormat(String? value) {
    final val = value ?? '';
    if (val.isEmpty) return '비밀번호를 입력해주세요.';
    if (!_passwordPattern.hasMatch(val)) return _passwordRuleMessage;
    return null;
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
      } else if (!_passwordPattern.hasMatch(pw)) {
        _passwordError = _passwordRuleMessage;
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
      _viewModel.areDuplicatesChecked &&
      _viewModel.passwordErrorText == null &&
      !_viewModel.isSubmitting;

  Future<void> _handleSubmit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || !_canSubmit) return;
    FocusScope.of(context).unfocus();

    final viewModel = _viewModel;
    // 비밀번호는 요청 body로만 보내고 로그·저장소에 남기지 않는다.
    await viewModel.submit(
      CreateMemberRequest(
        email: _emailController.text,
        password: _passwordController.text,
        nickname: _nicknameController.text,
      ),
    );
    if (!mounted) return; // 제출 중 화면이 사라졌으면 결과를 반영하지 않는다.

    final memberId = viewModel.createdMemberId;
    final messenger = ScaffoldMessenger.of(context);
    if (viewModel.submitStatus == SubmitStatus.success && memberId != null) {
      // v7: 회원가입은 로그인이 아니다. 가입한 이메일로 로그인 화면에서 토큰을 받는다.
      messenger.showSnackBar(
        const SnackBar(content: Text('회원가입이 완료되었습니다! 로그인해 주세요.')),
      );
      context.go('/login', extra: _emailController.text.trim());
      return;
    }
    final message = viewModel.snackbarMessage;
    if (message != null) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    // 중복 확인 상태가 바뀌면 화면을 다시 그린다.
    final viewModel = context.watch<SignUpViewModel>();
    final nicknameStatus = viewModel.nicknameCheckStatus;
    final emailStatus = viewModel.emailCheckStatus;
    final isSubmitting = viewModel.isSubmitting;

    // 제출 중에는 뒤로가기·스와이프 백으로 화면을 벗어날 수 없다. (Challenge)
    return PopScope(
      canPop: !isSubmitting,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: isSubmitting ? null : () => context.go('/login'),
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
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
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
                            hasError:
                                _nicknameError != null ||
                                viewModel.nicknameErrorText != null,
                            isValid:
                                _isNicknameValid &&
                                nicknameStatus == CheckStatus.available,
                            errorMessage:
                                _nicknameError ?? viewModel.nicknameErrorText,
                            // 로컬 validator가 통과해도 서버 결과(중복/실패)가 있으면 에러 상태
                            errorText: viewModel.nicknameErrorText,
                            helperMessage:
                                nicknameStatus == CheckStatus.available
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
                            onFieldSubmitted: (_) =>
                                _emailFocusNode.requestFocus(),
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
                            hasError:
                                _emailError != null ||
                                viewModel.emailErrorText != null,
                            isValid:
                                _isEmailValid &&
                                emailStatus == CheckStatus.available,
                            errorMessage:
                                _emailError ?? viewModel.emailErrorText,
                            errorText: viewModel.emailErrorText,
                            helperMessage: emailStatus == CheckStatus.available
                                ? '사용할 수 있는 이메일입니다.'
                                : null,
                            trailing: MovieLogButton(
                              label: '중복 확인',
                              isLoading: emailStatus == CheckStatus.checking,
                              onPressed:
                                  viewModel.canCheckEmail && _isEmailValid
                                  ? () => viewModel.checkEmail(
                                      _emailController.text,
                                    )
                                  : null,
                            ),
                            validator: (value) {
                              final val = value?.trim() ?? '';
                              if (val.isEmpty) return '이메일을 입력해주세요.';
                              if (!_isValidEmailFormat(val)) {
                                return '올바른 이메일 형식이 아닙니다.';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              _updateValidationStatus();
                              viewModel.onEmailChanged(value);
                            },
                            onFieldSubmitted: (_) =>
                                _passwordFocusNode.requestFocus(),
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
                            hasError:
                                _passwordError != null ||
                                viewModel.passwordErrorText != null,
                            isValid:
                                _isPasswordValid &&
                                viewModel.passwordErrorText == null,
                            errorMessage:
                                _passwordError ?? viewModel.passwordErrorText,
                            // 로컬 validator가 통과해도 서버가 거부한 값이면 계속 에러로 보인다.
                            errorText: viewModel.passwordErrorText,
                            suffixIcon:
                                _passwordError != null ||
                                    viewModel.passwordErrorText != null
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
                                              _obscurePassword =
                                                  !_obscurePassword;
                                            });
                                          },
                                        )
                                      : null),
                            validator: _validatePasswordFormat,
                            onChanged: (_) {
                              _updateValidationStatus();
                              viewModel.onPasswordChanged();
                            },
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
                            // 제출 중에는 인디케이터 + 비활성으로 연속 탭을 막는다.
                            isLoading: isSubmitting,
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
          style: TextStyle(fontSize: 14, color: AppColors.black),
        ),
        GestureDetector(
          onTap: () => context.go('/login'),
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
