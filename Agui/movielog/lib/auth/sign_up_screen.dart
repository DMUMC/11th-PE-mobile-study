import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/validation/sign_up_validators.dart';
import '../theme/app_theme.dart';
import '../view_models/sign_up_view_model.dart';
import 'widget/sign_up_app_bar.dart';
import 'widget/sign_up_footer.dart';
import 'widget/sign_up_form.dart';
import 'widget/sign_up_header.dart';
import 'widget/sign_up_submit_button.dart';
import 'widget/terms_checkbox.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  static const initialNickname = '영화광';
  static const initialEmail = 'movie@umc.com';

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final formKey = GlobalKey<FormState>();
  final nicknameController = TextEditingController(
    text: SignUpScreen.initialNickname,
  );
  final emailController = TextEditingController(
    text: SignUpScreen.initialEmail,
  );
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

  bool canSubmit(SignUpViewModel viewModel) =>
      isNicknameValid &&
      isEmailValid &&
      isPasswordValid &&
      agreedToTerms &&
      viewModel.checksPassed;

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
    final viewModel = context.watch<SignUpViewModel>();
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
                                nicknameErrorText:
                                    nicknameErrorText ??
                                    viewModel.nicknameErrorText,
                                emailErrorText:
                                    emailErrorText ?? viewModel.emailErrorText,
                                passwordErrorText: passwordErrorText,
                                nicknameCheckStatus:
                                    viewModel.nicknameCheckStatus,
                                emailCheckStatus: viewModel.emailCheckStatus,
                                onCheckNickname: viewModel.canCheckNickname
                                    ? () => viewModel.checkNickname(
                                        nicknameController.text,
                                      )
                                    : null,
                                onCheckEmail: viewModel.canCheckEmail
                                    ? () => viewModel.checkEmail(
                                        emailController.text,
                                      )
                                    : null,
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
                                  viewModel.onNicknameChanged(value);
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
                                  viewModel.onEmailChanged(value);
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
                                onPressed: canSubmit(viewModel)
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
