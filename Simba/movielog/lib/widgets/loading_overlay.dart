import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// [child] 위에 어두운 ModalBarrier와 흰색 인디케이터만 올려 조작을 막는다.
/// (흰색 카드나 로딩 문구는 띄우지 않는다)
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

  final bool isLoading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          const ModalBarrier(dismissible: false, color: Colors.black45),
        if (isLoading)
          const Center(
            child: CircularProgressIndicator(color: AppColors.white),
          ),
      ],
    );
  }
}
