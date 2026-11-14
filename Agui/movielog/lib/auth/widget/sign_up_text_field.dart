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
    this.trailing,
    this.helperText,
    this.helperColor,
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
  final Widget? trailing;
  final String? helperText;
  final Color? helperColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final hasError = errorText != null;

    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: AppRadius.borderRadius,
      borderSide: BorderSide(color: color),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Semantics(
                label: label,
                child: TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  cursorColor: colors.primary,
                  keyboardType: keyboardType,
                  textInputAction: textInputAction,
                  obscureText: obscureText,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.onSurface,
                  ),
                  validator: validator,
                  forceErrorText: errorText,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  onChanged: onChanged,
                  onFieldSubmitted: onSubmitted,
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: textTheme.bodyMedium?.copyWith(
                      color: colors.outline,
                    ),
                    filled: true,
                    fillColor: hasError
                        ? colors.errorContainer
                        : colors.surface,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    enabledBorder: border(colors.surfaceContainerHighest),
                    focusedBorder: border(colors.primary),
                    errorBorder: border(colors.error),
                    focusedErrorBorder: border(colors.error),
                    errorStyle: textTheme.labelSmall?.copyWith(
                      color: colors.error,
                    ),
                    errorMaxLines: 3,
                    suffixIconConstraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 20,
                    ),
                    suffixIcon: hasError
                        ? Icon(
                            Icons.error_outline,
                            color: colors.error,
                            size: 20,
                          )
                        : showSuccessIcon
                        ? Icon(
                            Icons.check_circle,
                            color: colors.primary,
                            size: 20,
                          )
                        : null,
                  ),
                ),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.x1),
              trailing!,
            ],
          ],
        ),
        if (!hasError && helperText != null) ...[
          const SizedBox(height: AppSpacing.x1),
          Text(
            helperText!,
            style: textTheme.labelSmall?.copyWith(
              color: helperColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}
