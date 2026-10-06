import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class MovieLogTextFormField extends StatelessWidget {
  const MovieLogTextFormField({
    required this.label,
    required this.hintText,
    required this.controller,
    required this.validator,
    required this.onChanged,
    required this.textInputAction,
    required this.isValid,
    required this.showErrorState,
    this.fieldKey,
    this.focusNode,
    this.keyboardType,
    this.obscureText = false,
    this.onFieldSubmitted,
    this.onToggleObscure,
    super.key,
  });

  final Key? fieldKey;
  final String label;
  final String hintText;
  final TextEditingController controller;
  final String? Function(String?) validator;
  final ValueChanged<String> onChanged;
  final TextInputAction textInputAction;
  final bool isValid;
  final bool showErrorState;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final bool obscureText;
  final ValueChanged<String>? onFieldSubmitted;
  final VoidCallback? onToggleObscure;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.outline),
    );
    final errorBorder = border.copyWith(
      borderSide: const BorderSide(color: AppColors.error, width: 1.5),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextFormField(
          key: fieldKey,
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscureText,
          obscuringCharacter: '•',
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: onChanged,
          onFieldSubmitted: onFieldSubmitted,
          style: const TextStyle(fontSize: 17, color: AppColors.onSurface),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: AppColors.onSurfaceVariant,
              fontSize: 16,
            ),
            filled: true,
            fillColor: showErrorState
                ? AppColors.errorContainer
                : AppColors.fieldSurface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 17,
            ),
            enabledBorder: border,
            focusedBorder: border.copyWith(
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
            errorBorder: errorBorder,
            focusedErrorBorder: errorBorder,
            errorStyle: const TextStyle(
              color: AppColors.error,
              fontSize: 13,
              height: 1.3,
            ),
            suffixIcon: _buildSuffixIcon(),
          ),
        ),
      ],
    );
  }

  Widget? _buildSuffixIcon() {
    if (showErrorState) {
      return const Icon(Icons.error_outline, color: AppColors.error);
    }
    if (isValid) {
      return const Icon(Icons.check_circle, color: AppColors.primary);
    }
    if (onToggleObscure != null) {
      return IconButton(
        tooltip: obscureText ? '비밀번호 표시' : '비밀번호 숨기기',
        onPressed: onToggleObscure,
        icon: Icon(
          obscureText
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: AppColors.onSurfaceVariant,
        ),
      );
    }
    return null;
  }
}
