import 'package:flutter/material.dart';

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
  final nicknameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final nicknameFocusNode = FocusNode();
  final emailFocusNode = FocusNode();
  final passwordFocusNode = FocusNode();

  bool agreedToTerms = false;
  String? nicknameErrorText;
  String? emailErrorText;
  String? passwordErrorText;
  bool isNicknameValid = false;
  bool isEmailValid = false;
  bool isPasswordValid = false;
  bool isPasswordObscured = true;

  bool get canSubmit =>
      isNicknameValid && isEmailValid && isPasswordValid && agreedToTerms;

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

    return Scaffold(
      appBar: isTablet ? null : const SignUpAppBar(),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWideScreen = constraints.maxWidth >= 700;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.x2,
                AppSpacing.x3,
                AppSpacing.x2,
                AppSpacing.x3,
              ),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isWideScreen ? 560 : double.infinity,
                    minHeight: constraints.maxHeight - (AppSpacing.x3 * 2),
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
                              isNicknameValid: isNicknameValid,
                              isEmailValid: isEmailValid,
                              isPasswordValid: isPasswordValid,
                              isPasswordObscured: isPasswordObscured,
                              onTogglePasswordVisibility: () {
                                setState(() {
                                  isPasswordObscured = !isPasswordObscured;
                                });
                              },
                              onNicknameChanged: (value) {
                                setState(() {
                                  final errorText = value.trim().isEmpty
                                      ? null
                                      : validateNickname(value);
                                  nicknameErrorText = errorText;
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
                        if (isWideScreen) const SizedBox(height: AppSpacing.x4),
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
                            const SizedBox(height: AppSpacing.x2),
                            SignUpSubmitButton(
                              onPressed: canSubmit
                                  ? () {
                                      final isValid =
                                          formKey.currentState?.validate() ??
                                          false;
                                      if (!isValid) return;
                                      FocusScope.of(context).unfocus();
                                    }
                                  : null,
                            ),
                            const SizedBox(height: AppSpacing.x3),
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
    );
  }
}
