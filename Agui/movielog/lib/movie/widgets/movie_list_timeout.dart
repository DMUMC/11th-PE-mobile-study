import 'package:flutter/material.dart';

class MovieListTimeout extends StatelessWidget {
  const MovieListTimeout({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_off_outlined),
          const SizedBox(height: 12),
          const Text('응답 시간이 초과되었습니다. 다시 시도해 주세요.'),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}
