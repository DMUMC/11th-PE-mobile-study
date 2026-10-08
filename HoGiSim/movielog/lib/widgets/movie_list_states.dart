import 'package:flutter/material.dart';

class MovieLoadingView extends StatelessWidget {
  const MovieLoadingView({super.key});

  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [CircularProgressIndicator(), SizedBox(height: 16), Text('영화 목록을 불러오는 중입니다.')],
    ),
  );
}

class MovieEmptyView extends StatelessWidget {
  const MovieEmptyView({super.key});

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(Icons.movie_filter_outlined, size: 48), SizedBox(height: 12), Text('표시할 영화가 없습니다.')],
      ),
    ),
  );
}

class MovieErrorView extends StatelessWidget {
  const MovieErrorView({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 48),
          const SizedBox(height: 12),
          const Text('영화 목록을 불러오지 못했습니다.\n잠시 후 다시 시도해 주세요.', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(key: const Key('retryMovies'), onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('다시 시도')),
        ],
      ),
    ),
  );
}

class MovieSkeletonGrid extends StatelessWidget {
  const MovieSkeletonGrid({required this.count, super.key});
  final int count;

  @override
  Widget build(BuildContext context) => GridView.builder(
    key: const Key('movieSkeletonGrid'),
    padding: const EdgeInsets.all(14),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 22, childAspectRatio: .57,
    ),
    itemCount: count,
    itemBuilder: (context, index) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Container(decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(10)))),
        const SizedBox(height: 10),
        Container(height: 14, width: 100, color: Colors.black12),
        const SizedBox(height: 7),
        Container(height: 12, width: 70, color: Colors.black12),
      ],
    ),
  );
}
