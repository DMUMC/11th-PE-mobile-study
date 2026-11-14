import 'package:flutter/material.dart';

class MovieLogButton extends StatelessWidget {
  const MovieLogButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.width,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final double? width;
  final bool loading;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: 48,
    child: FilledButton(
      style: FilledButton.styleFrom(
        disabledBackgroundColor: Colors.grey.shade300,
      ),
      onPressed: loading ? null : onPressed,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(opacity: loading ? 0 : 1, child: Text(label)),
          if (loading)
            const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                semanticsLabel: '확인 중',
              ),
            ),
        ],
      ),
    ),
  );
}
