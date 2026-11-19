import 'package:flutter/material.dart';

import '../../widgets/movielog_button.dart';

class SignUpSubmitButton extends StatelessWidget {
  const SignUpSubmitButton({super.key, this.onPressed, this.isLoading = false});

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) => MovieLogButton(
    label: '가입하기',
    isLoading: isLoading,
    width: double.infinity,
    onPressed: onPressed,
  );
}
