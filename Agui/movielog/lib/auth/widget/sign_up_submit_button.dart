import 'package:flutter/material.dart';

import '../../widgets/movielog_button.dart';

class SignUpSubmitButton extends StatelessWidget {
  const SignUpSubmitButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => MovieLogButton(
    label: '가입하기',
    width: double.infinity,
    onPressed: onPressed,
  );
}
