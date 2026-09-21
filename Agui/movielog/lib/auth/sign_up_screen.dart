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

  final emailFocusNode = FocusNode();
  final passwordFocusNode = FocusNode();

  bool agreedToTerms = false;
  String? nicknameErrorText;

  @override
  void dispose() {
    nicknameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SignUpAppBar(),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.x2,
                AppSpacing.x3,
                AppSpacing.x2,
                AppSpacing.x3,
              ),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - (AppSpacing.x3 * 2),
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          const SignUpHeader(),
                          const SizedBox(height: AppSpacing.x4),
                          SignUpForm(
                            nicknameController: nicknameController,
                            emailController: emailController,
                            passwordController: passwordController,
                            emailFocusNode: emailFocusNode,
                            passwordFocusNode: passwordFocusNode,
                            nicknameErrorText: nicknameErrorText,
                            onNicknameChanged: (value) {
                              setState(() {
                                nicknameErrorText = value.trim().isEmpty
                                    ? null
                                    : validateNickname(value);
                              });
                            },
                          ),
                        ],
                      ),
                      Column(
                        children: const [
                          TermsCheckbox(),
                          SizedBox(height: AppSpacing.x2),
                          SignUpSubmitButton(),
                          SizedBox(height: AppSpacing.x3),
                          SignUpFooter(),
                        ],
                      ),
                    ],
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
