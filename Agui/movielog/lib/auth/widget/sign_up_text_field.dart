import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class SignUpTextField extends StatelessWidget {
  const SignUpTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hintText,
    this.focusNode,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.onChanged,
    this.errorText,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final bool obscureText;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return FormField<String>(
      validator: validator,
      autovalidateMode: AutovalidateMode.disabled,
      builder: (field) {
        final displayedErrorText = errorText ?? field.errorText;
        final hasError = displayedErrorText != null;

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
                        horizontal: AppSpacing.x2,
                      ),
                      child: TextField(
                        controller: controller,
                        focusNode: focusNode,
                        keyboardType: keyboardType,
                        obscureText: obscureText,
                        textAlign: TextAlign.start,
                        textAlignVertical: TextAlignVertical.center,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.onSurface,
                        ),
                        onChanged: (value) {
                          field.didChange(value);
                          onChanged?.call(value);
                        },
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
                      padding: const EdgeInsets.only(right: AppSpacing.x2),
                      child: Icon(
                        Icons.error_outline,
                        size: 25,
                        color: colors.error,
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
  }
}
