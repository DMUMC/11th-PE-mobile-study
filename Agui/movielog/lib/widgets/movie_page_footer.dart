import 'package:flutter/material.dart';

import '../view_models/load_phase.dart';
import '../view_models/paged_movies_view_model.dart';
import 'movielog_button.dart';

class MoviePageFooter extends StatelessWidget {
  const MoviePageFooter({
    super.key,
    required this.vm,
    this.loadMoreLabel = '더 보기',
    this.automatic = false,
  });

  final PagedMoviesViewModel vm;
  final String loadMoreLabel;
  final bool automatic;

  @override
  Widget build(BuildContext context) {
    if (vm.phase != LoadPhase.ready) return const SizedBox.shrink();
    if (automatic && vm.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox.square(
            dimension: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              semanticsLabel: '다음 페이지를 불러오는 중',
            ),
          ),
        ),
      );
    }
    if (automatic && vm.hasMore && vm.loadMoreError == null) {
      return const SizedBox(height: 76);
    }
    if (!vm.hasMore && !vm.isLoadingMore && vm.loadMoreError == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('더 이상 조회할 페이지가 없습니다.', textAlign: TextAlign.center),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (vm.loadMoreError != null) ...[
            Text(
              vm.loadMoreError!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 12),
          ],
          MovieLogButton(
            label: vm.loadMoreError == null ? loadMoreLabel : '다음 페이지 다시 시도',
            width: double.infinity,
            isLoading: vm.isLoadingMore,
            onPressed: vm.loadNextPage,
          ),
        ],
      ),
    );
  }
}
