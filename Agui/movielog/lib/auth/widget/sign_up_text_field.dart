import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class SignUpTextField extends StatelessWidget {
  const SignUpTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hintText,
    required this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.errorText,
    this.showSuccessIcon = false,
    this.onToggleObscureText,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final FocusNode focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? errorText;
  final bool showSuccessIcon;
  final VoidCallback? onToggleObscureText;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AnimatedBuilder(
      animation: focusNode,
      builder: (context, child) {
        return FormField<String>(
          validator: validator,
          autovalidateMode: AutovalidateMode.disabled,
          builder: (field) {
            final displayedErrorText = errorText ?? field.errorText;
            final hasError = displayedErrorText != null;
            final hasFocus = focusNode.hasFocus;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  label,
                  style: textTheme.labelSmall?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.x1),
                Container(
                  height: AppComponentHeight.input,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: hasError
                        ? colors.errorContainer
                        : colors.surfaceContainerLow,
                    border: Border.all(
                      color: hasError
                          ? colors.error
                          : hasFocus
                          ? colors.primary
                          : colors.surfaceContainerHighest,
                      width: 1,
                    ),
                    borderRadius: AppRadius.borderRadius,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.x1,
                          ),
                          child: TextField(
                            controller: controller,
                            focusNode: focusNode,
                            cursorColor: colors.primary,
                            keyboardType: keyboardType,
                            textInputAction: textInputAction,
                            obscureText: obscureText,
                            textAlign: TextAlign.start,
                            style: textTheme.bodySmall?.copyWith(
                              color: colors.onSurface,
                            ),
                            onChanged: (value) {
                              field.didChange(value);
                              onChanged?.call(value);
                            },
                            onSubmitted: onSubmitted,
                            decoration: InputDecoration(
                              hintText: hintText,
                              hintStyle: textTheme.bodySmall?.copyWith(
                                color: colors.outline,
                              ),
                              filled: false,
                              isCollapsed: true,
                              contentPadding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                      if (hasError)
                        Padding(
                          padding: EdgeInsets.only(
                            right: onToggleObscureText == null
                                ? AppSpacing.x2
                                : AppSpacing.x1,
                          ),
                          child: Icon(
                            Icons.error_outline,
                            size: 25,
                            color: colors.error,
                          ),
                        )
                      else if (showSuccessIcon)
                        Padding(
                          padding: EdgeInsets.only(
                            right: onToggleObscureText == null
                                ? AppSpacing.x2
                                : AppSpacing.x1,
                          ),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: colors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      if (onToggleObscureText != null)
                        Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.x1),
                          child: IconButton(
                            onPressed: onToggleObscureText,
                            tooltip: obscureText ? '비밀번호 표시' : '비밀번호 숨기기',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints.tightFor(
                              width: 24,
                              height: 24,
                            ),
                            icon: Icon(
                              obscureText
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 22,
                              color: colors.outline,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (displayedErrorText != null) ...[
                  const SizedBox(height: AppSpacing.x1),
                  Text(
                    displayedErrorText,
                    style: textTheme.labelSmall?.copyWith(color: colors.error),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }
}
