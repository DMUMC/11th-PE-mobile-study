import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../theme/app_colors.dart';
import '../view_models/movie_list_view_model.dart';
import '../widgets/genre_filter_bottom_sheet.dart';
import '../widgets/movie_card.dart';
import '../widgets/movie_load_failure_dialog.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  final _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  late final MovieListViewModel _viewModel;
  bool _isFailureDialogOpen = false;

  @override
  void initState() {
    super.initState();
    // 요청 실패는 "한 번만 보여줄 이벤트"이므로 build가 아니라 listener에서 Dialog를 띄운다.
    _viewModel = context.read<MovieListViewModel>();
    _viewModel.addListener(_handleViewModelChanged);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_handleViewModelChanged);
    super.dispose();
  }

  void _handleViewModelChanged() {
    if (!_viewModel.hasPendingFailure || _isFailureDialogOpen) return;
    _viewModel.consumeFailure();
    _isFailureDialogOpen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _showFailureDialog());
  }

  Future<void> _showFailureDialog() async {
    if (!mounted) {
      _isFailureDialogOpen = false;
      return;
    }
    final shouldRetry = await MovieLoadFailureDialog.show(context);
    _isFailureDialogOpen = false;
    if (!mounted || !shouldRetry) return;
    _retry();
  }

  /// 마지막으로 선택한 장르로 page 1부터 다시 요청한다.
  /// 목록이 남아 있으면 RefreshIndicator를 띄워 기존 목록 위에서 새로고침한다.
  void _retry() {
    final refreshIndicator = _refreshIndicatorKey.currentState;
    if (_viewModel.movies.isNotEmpty && refreshIndicator != null) {
      refreshIndicator.show();
    } else {
      _viewModel.retry();
    }
  }

  Future<void> _openFilterBottomSheet() async {
    final result = await GenreFilterBottomSheet.show(
      context,
      genres: _viewModel.genres,
      initialSelectedIds: _viewModel.selectedGenreIds ?? const [],
    );
    // 바깥을 눌러 닫으면 null → 선택을 바꾸지 않는다. 빈 목록이면 전체로 요청한다.
    if (result != null) _viewModel.applyGenres(result);
  }

  void _openDetail(TmdbMovieDto movie) {
    // 배열 index가 아니라 TMDB id를 경로로 전달한다.
    context.push('/movies/${movie.id}', extra: movie);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('영화', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          Consumer<MovieListViewModel>(
            builder: (context, viewModel, child) {
              final selectedCount = viewModel.selectedGenreIds?.length ?? 0;
              final canChangeGenre =
                  !viewModel.isBusy && viewModel.genres.isNotEmpty;
              return IconButton(
                tooltip: '장르 필터',
                onPressed: canChangeGenre ? _openFilterBottomSheet : null,
                icon: Badge(
                  isLabelVisible: selectedCount > 0,
                  backgroundColor: AppColors.violet,
                  label: Text('$selectedCount'),
                  child: const Icon(Icons.filter_list),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<MovieListViewModel>(
        builder: (context, viewModel, child) {
          return Column(
            children: [
              _GenreChipBar(viewModel: viewModel),
              Expanded(child: _buildContent(viewModel)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(MovieListViewModel viewModel) {
    if (viewModel.status == MovieListLoadStatus.idle ||
        viewModel.status == MovieListLoadStatus.loading) {
      // Loading 중에는 RefreshIndicator를 두지 않아 당겨서 새로고침이 동작하지 않는다.
      return const _MovieListLoading();
    }

    return RefreshIndicator(
      key: _refreshIndicatorKey,
      color: AppColors.violet,
      // 요청 중(새로고침/재시도 포함)에는 제스처를 무시한다.
      notificationPredicate: (notification) =>
          viewModel.canRefresh && notification.depth == 0,
      onRefresh: viewModel.refresh,
      child: switch (viewModel.status) {
        MovieListLoadStatus.success => _MovieGrid(
          movies: viewModel.movies,
          genreNameOf: viewModel.genreNameOf,
          onTap: _openDetail,
        ),
        MovieListLoadStatus.empty => const _MovieListMessage(
          icon: Icons.movie_filter_outlined,
          message: '조건에 맞는 영화가 없어요.\n다른 장르를 선택해 보세요.',
        ),
        _ => _MovieListMessage(
          icon: Icons.wifi_off_rounded,
          message: viewModel.message ?? '영화를 불러오지 못했어요.',
          actionLabel: '다시 시도',
          onAction: viewModel.retry,
        ),
      },
    );
  }
}

/// "전체" + TMDB 장르 Chip. 여러 장르를 켜고 끌 수 있고, 요청 중에는 비활성화된다.
class _GenreChipBar extends StatelessWidget {
  const _GenreChipBar({required this.viewModel});

  final MovieListViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    if (viewModel.genres.isEmpty) return const SizedBox.shrink();

    final enabled = !viewModel.isBusy;
    final isAllSelected = viewModel.selectedGenreIds == null;

    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _GenreChip(
            label: '전체',
            selected: isAllSelected,
            onSelected: enabled ? () => viewModel.applyGenres(null) : null,
          ),
          for (final genre in viewModel.genres)
            _GenreChip(
              label: genre.name,
              selected: viewModel.isGenreSelected(genre.id),
              onSelected: enabled ? () => viewModel.toggleGenre(genre.id) : null,
            ),
        ],
      ),
    );
  }
}

class _GenreChip extends StatelessWidget {
  const _GenreChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback? onSelected;

  @override
  Widget build(BuildContext context) {
    final callback = onSelected;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        // onSelected가 null이면 Chip이 비활성화된다 (요청 중 장르 변경 방지).
        onSelected: callback == null ? null : (_) => callback(),
        selectedColor: AppColors.violet,
        backgroundColor: AppColors.warmWhite,
        disabledColor: selected ? AppColors.violet : AppColors.warmWhite,
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color: selected ? AppColors.white : AppColors.black,
        ),
        side: BorderSide(
          color: selected ? AppColors.violet : AppColors.chipBorder,
        ),
        shape: const StadiumBorder(),
      ),
    );
  }
}

class _MovieGrid extends StatelessWidget {
  const _MovieGrid({
    required this.movies,
    required this.genreNameOf,
    required this.onTap,
  });

  final List<TmdbMovieDto> movies;
  final String? Function(TmdbMovieDto movie) genreNameOf;
  final ValueChanged<TmdbMovieDto> onTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      // 목록이 짧아도 당겨서 새로고침이 가능하도록 항상 스크롤 가능하게 둔다.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: movies.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 20,
        childAspectRatio: 0.65,
      ),
      itemBuilder: (context, index) {
        final movie = movies[index];
        return MovieCard(
          key: ValueKey(movie.id),
          movie: movie,
          genreLabel: genreNameOf(movie),
          onTap: () => onTap(movie),
        );
      },
    );
  }
}

/// Loading 상태: 카드 모양의 회색 skeleton
class _MovieListLoading extends StatelessWidget {
  const _MovieListLoading();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 20,
        childAspectRatio: 0.65,
      ),
      itemBuilder: (context, index) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(width: 100, height: 12, color: Colors.grey.shade200),
            const SizedBox(height: 6),
            Container(width: 60, height: 10, color: Colors.grey.shade200),
          ],
        );
      },
    );
  }
}

/// Empty / Error 상태. 스크롤 가능하게 만들어 이 화면에서도 당겨서 새로고침할 수 있다.
class _MovieListMessage extends StatelessWidget {
  const _MovieListMessage({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 96),
      children: [
        Icon(icon, size: 48, color: AppColors.gray),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.gray, height: 1.5),
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 20),
          Center(
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.violet),
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ),
        ],
      ],
    );
  }
}
