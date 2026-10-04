import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class MovieLogTextFormField extends StatelessWidget {
  const MovieLogTextFormField({
    super.key,
    required this.label,
    required this.hintText,
    required this.controller,
    required this.validator,
    this.focusNode,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onFieldSubmitted,
    this.suffixIcon,
    this.hasError = false,
    this.isValid = false,
    this.errorMessage,
  });

  final String label;
  final String hintText;
  final TextEditingController controller;
  final String? Function(String?) validator;
  final FocusNode? focusNode;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final Widget? suffixIcon;
  final bool hasError;
  final bool isValid;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    // Figma 시안에 맞춘 접미사 아이콘 (오류 시 느낌표, 완료 시 체크 아이콘)
    Widget? trailingIcon = suffixIcon;
    if (trailingIcon == null) {
      if (hasError) {
        trailingIcon = const Icon(
          Icons.error_outline,
          color: Color(0xFFD32F2F),
        );
      } else if (isValid) {
        trailingIcon = const Icon(
          Icons.check_circle,
          color: AppColors.violet,
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onChanged: onChanged,
          onFieldSubmitted: onFieldSubmitted,
          validator: validator,
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.black,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              fontSize: 14,
              color: AppColors.gray,
            ),
            filled: true,
            // 에러 상태일 때 옅은 붉은색 배경 적용
            fillColor: hasError ? const Color(0xFFFFDEDE) : const Color(0xFFF3F2F0),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            suffixIcon: trailingIcon,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? const Color(0xFFD32F2F) : const Color(0xFFE0DDD7),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? const Color(0xFFD32F2F) : AppColors.violet,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFD32F2F),
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFD32F2F),
                width: 1.5,
              ),
            ),
            // TextFormField 기본 에러 메시지 공간 숨김 (아래 커스텀 Text로 통일)
            errorStyle: const TextStyle(height: 0, fontSize: 0),
          ),
        ),
        // 에러가 있을 때 바로 밑에 노출되는 텍스트 메시지
        if (hasError && errorMessage != null) ...[
          const SizedBox(height: 6),
          Text(
            errorMessage!,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFFD32F2F),
            ),
          ),
        ],
      ],
    );
  }
}