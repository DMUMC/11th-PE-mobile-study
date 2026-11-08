import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import 'widget/sign_up_app_bar.dart';
import 'widget/sign_up_footer.dart';
import 'widget/sign_up_form.dart';
import 'widget/sign_up_header.dart';
import 'widget/sign_up_submit_button.dart';
import 'widget/terms_checkbox.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final formKey = GlobalKey<FormState>();
  // W6-01 디자인의 예시 상태입니다. 중복 확인 API는 다음 미션에서 연결합니다.
  final nicknameController = TextEditingController(text: '영화광');
  final emailController = TextEditingController(text: 'movie@umc.com');
  final passwordController = TextEditingController(text: '12345678');

  final nicknameFocusNode = FocusNode();
  final emailFocusNode = FocusNode();
  final passwordFocusNode = FocusNode();

  bool agreedToTerms = true;
  String? nicknameErrorText;
  String? emailErrorText;
  String? passwordErrorText;
  bool isNicknameValid = true;
  bool isEmailValid = true;
  bool isPasswordValid = true;
  bool isNicknameChecked = true;
  bool isEmailCheckLoading = true;

  bool get canSubmit =>
      isNicknameValid &&
      isEmailValid &&
      isPasswordValid &&
      agreedToTerms &&
      !isEmailCheckLoading;

  void showPreviewNotice() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('화면 미리보기입니다.')));
  }

  @override
  void dispose() {
    nicknameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    nicknameFocusNode.dispose();
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width >= 700;

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: isTablet ? null : const SignUpAppBar(),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWideScreen = constraints.maxWidth >= 700;

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 48, 18, 40),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isWideScreen ? 560 : double.infinity,
                      minHeight: (constraints.maxHeight - 88).clamp(
                        0,
                        double.infinity,
                      ),
                    ),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: isWideScreen
                            ? MainAxisAlignment.center
                            : MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: [
                              if (isWideScreen) ...[
                                Text(
                                  '회원가입',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: AppSpacing.x3),
                              ],
                              const SignUpHeader(),
                              const SizedBox(height: AppSpacing.x4),
                              SignUpForm(
                                nicknameController: nicknameController,
                                emailController: emailController,
                                passwordController: passwordController,
                                nicknameFocusNode: nicknameFocusNode,
                                emailFocusNode: emailFocusNode,
                                passwordFocusNode: passwordFocusNode,
                                nicknameErrorText: nicknameErrorText,
                                emailErrorText: emailErrorText,
                                passwordErrorText: passwordErrorText,
                                isNicknameChecked: isNicknameChecked,
                                isEmailCheckLoading: isEmailCheckLoading,
                                onCheckNickname: showPreviewNotice,
                                onCheckEmail: showPreviewNotice,
                                onNicknameChanged: (value) {
                                  setState(() {
                                    final errorText = value.trim().isEmpty
                                        ? null
                                        : validateNickname(value);
                                    nicknameErrorText = errorText;
                                    isNicknameChecked = false;
                                    isNicknameValid =
                                        value.trim().isNotEmpty &&
                                        errorText == null;
                                  });
                                },
                                onEmailChanged: (value) {
                                  setState(() {
                                    final errorText = value.trim().isEmpty
                                        ? null
                                        : validateEmail(value);
                                    emailErrorText = errorText;
                                    isEmailCheckLoading = false;
                                    isEmailValid =
                                        value.trim().isNotEmpty &&
                                        errorText == null;
                                  });
                                },
                                onPasswordChanged: (value) {
                                  setState(() {
                                    final errorText = value.isEmpty
                                        ? null
                                        : validatePassword(value);
                                    passwordErrorText = errorText;
                                    isPasswordValid =
                                        value.isNotEmpty && errorText == null;
                                  });
                                },
                              ),
                            ],
                          ),
                          if (isWideScreen)
                            const SizedBox(height: AppSpacing.x4),
                          Column(
                            children: [
                              TermsCheckbox(
                                agreedToTerms: agreedToTerms,
                                onChanged: (value) {
                                  setState(() {
                                    agreedToTerms = value;
                                  });
                                },
                              ),
                              const SizedBox(height: AppSpacing.x3),
                              SignUpSubmitButton(
                                onPressed: canSubmit
                                    ? () {
                                        final isValid =
                                            formKey.currentState?.validate() ??
                                            false;
                                        if (!isValid) return;
                                        FocusScope.of(context).unfocus();
                                        context.go('/home');
                                      }
                                    : null,
                              ),
                              const SizedBox(height: 56),
                              const SignUpFooter(),
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
    );
  }
}
