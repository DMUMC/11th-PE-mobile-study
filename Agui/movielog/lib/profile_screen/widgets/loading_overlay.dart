import 'package:flutter/material.dart';

/// 화면 위에서 입력을 막고 로딩 상태를 표시합니다.
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

  final bool isLoading;
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      child,
      if (isLoading) ...[
        const Positioned.fill(
          child: ModalBarrier(dismissible: false, color: Colors.black45),
        ),
        const Center(child: CircularProgressIndicator(color: Colors.white)),
      ],
    ],
  );
}
