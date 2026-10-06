import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SignUpFields extends StatelessWidget {
  const SignUpFields({
    super.key,
    required this.nicknameController,
    required this.emailController,
    required this.passwordController,
    required this.nicknameFocus,
    required this.emailFocus,
    required this.passwordFocus,
    required this.validateNickname,
    required this.validateEmail,
    required this.validatePassword,
    required this.onChanged,
    required this.onDone,
  });

  final TextEditingController nicknameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final FocusNode nicknameFocus;
  final FocusNode emailFocus;
  final FocusNode passwordFocus;
  final FormFieldValidator<String> validateNickname;
  final FormFieldValidator<String> validateEmail;
  final FormFieldValidator<String> validatePassword;
  final VoidCallback onChanged;
  final VoidCallback onDone;

  Widget _errorMessage(BuildContext context, String error) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        error,
        textAlign: TextAlign.start,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: Theme.of(context).colorScheme.error),
      ),
    );
  }

  InputDecoration _decoration(
    BuildContext context, {
    required String value,
    required String hint,
    required String? error,
  }) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final hasError = value.isNotEmpty && error != null;

    OutlineInputBorder border(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return InputDecoration(
      hintText: hint,
      hintStyle: textTheme.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
      filled: true,
      fillColor: hasError ? colors.errorContainer : colors.surfaceContainerLow,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      enabledBorder: border(colors.outlineVariant),
      focusedBorder: border(colors.primary, 2),
      errorBorder: border(colors.error),
      focusedErrorBorder: border(colors.error, 2),
      errorStyle: textTheme.labelSmall?.copyWith(color: colors.error),
      errorMaxLines: 2,
      suffixIconConstraints: const BoxConstraints.tightFor(
        width: 42,
        height: 42,
      ),
      suffixIcon: value.isEmpty
          ? null
          : Padding(
              padding: EdgeInsets.all(hasError ? 9 : 11),
              child: SvgPicture.asset(
                hasError
                    ? 'assets/icons/error.svg'
                    : 'assets/icons/check_circle_filled.svg',
                colorFilter: hasError
                    ? ColorFilter.mode(colors.error, BlendMode.srcIn)
                    : null,
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final nicknameError = nicknameController.text.isEmpty
        ? null
        : validateNickname(nicknameController.text);
    final emailError = emailController.text.isEmpty
        ? null
        : validateEmail(emailController.text);
    final passwordError = passwordController.text.isEmpty
        ? null
        : validatePassword(passwordController.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('닉네임', style: textTheme.bodyLarge),
        const SizedBox(height: 4),
        TextFormField(
          controller: nicknameController,
          focusNode: nicknameFocus,
          style: textTheme.bodyLarge,
          decoration: _decoration(
            context,
            value: nicknameController.text,
            hint: '닉네임을 입력해주세요',
            error: nicknameError,
          ),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (value) =>
              (value ?? '').isEmpty ? null : validateNickname(value),
          // 기본 오류 문구의 내부 패딩을 피하고 아래에서 직접 표시합니다.
          errorBuilder: (context, error) => const SizedBox.shrink(),
          textInputAction: TextInputAction.next,
          onChanged: (_) => onChanged(),
          onFieldSubmitted: (_) => emailFocus.requestFocus(),
        ),
        if (nicknameError != null) _errorMessage(context, nicknameError),
        const SizedBox(height: 16),
        Text('이메일', style: textTheme.bodyLarge),
        const SizedBox(height: 4),
        TextFormField(
          controller: emailController,
          focusNode: emailFocus,
          style: textTheme.bodyLarge,
          decoration: _decoration(
            context,
            value: emailController.text,
            hint: '이메일 주소를 입력해주세요',
            error: emailError,
          ),
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (value) =>
              (value ?? '').isEmpty ? null : validateEmail(value),
          errorBuilder: (context, error) => const SizedBox.shrink(),
          textInputAction: TextInputAction.next,
          onChanged: (_) => onChanged(),
          onFieldSubmitted: (_) => passwordFocus.requestFocus(),
        ),
        if (emailError != null) _errorMessage(context, emailError),
        const SizedBox(height: 16),
        Text('비밀번호', style: textTheme.bodyLarge),
        const SizedBox(height: 4),
        TextFormField(
          controller: passwordController,
          focusNode: passwordFocus,
          style: textTheme.bodyLarge,
          decoration: _decoration(
            context,
            value: passwordController.text,
            hint: '비밀번호를 입력해주세요',
            error: passwordError,
          ),
          obscureText: true,
          autocorrect: false,
          enableSuggestions: false,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (value) =>
              (value ?? '').isEmpty ? null : validatePassword(value),
          errorBuilder: (context, error) => const SizedBox.shrink(),
          textInputAction: TextInputAction.done,
          onChanged: (_) => onChanged(),
          onFieldSubmitted: (_) => onDone(),
        ),
        if (passwordError != null) _errorMessage(context, passwordError),
      ],
    );
  }
}
