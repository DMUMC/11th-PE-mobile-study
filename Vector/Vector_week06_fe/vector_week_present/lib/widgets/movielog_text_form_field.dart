import 'package:flutter/material.dart';

class MovieLogTextFormField extends StatelessWidget {
  final Key? fieldKey;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final String? helperText;
  final String label;
  final String hintText;
  final TextEditingController? controller;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const MovieLogTextFormField({
    super.key,
    this.fieldKey,
    this.onChanged,
    this.errorText,
    this.helperText,
    required this.label,
    required this.hintText,
    this.controller,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),

        const SizedBox(height: 8),

        TextFormField(
          key: fieldKey,
          onChanged: onChanged,
          forceErrorText: errorText,
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            helperText: helperText,
            helperMaxLines: 2,
            errorMaxLines: 3,
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }
}
