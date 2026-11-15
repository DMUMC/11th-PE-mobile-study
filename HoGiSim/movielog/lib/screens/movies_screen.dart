import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_genre_dto.dart';
import '../theme/app_colors.dart';
import '../view_models/movie_list_view_model.dart';
import '../view_models/movie_load_status.dart';
import '../widgets/movie_card.dart';
import '../widgets/movie_list_states.dart';

class MoviesScreen extends StatefulWidget {
  const MoviesScreen({super.key});
  @override
  State<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen> {
  MovieListViewModel? _viewModel;
  int _seenFailure = 0;
  bool _dialogOpen = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final vm = context.read<MovieListViewModel>();
    if (identical(vm, _viewModel)) return;
    _viewModel?.removeListener(_onChange);
    _viewModel = vm;
    vm.addListener(_onChange);
  }

  void _onChange() {
    final vm = _viewModel!;
    if (vm.failureVersion == _seenFailure || _dialogOpen) return;
    _seenFailure = vm.failureVersion;
    _dialogOpen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final retry = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('영화를 불러오지 못했어요'),
          content: Text('${vm.message ?? ''}\n최근에 불러온 목록을 유지할게요.'),
          actions: [
            TextButton(
              key: const Key('cancelRetry'),
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            FilledButton(
              key: const Key('confirmRetry'),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('재시도'),
            ),
          ],
        ),
      );
      _dialogOpen = false;
      if (mounted && retry == true) await vm.retry();
    });
  }

  @override
  void dispose() {
    _viewModel?.removeListener(_onChange);
    super.dispose();
  }

  Future<void> _openFilter(MovieListViewModel vm) async {
    if (vm.isBusy || vm.genres.isEmpty) return;
    final result = await showModalBottomSheet<List<int>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GenreFilterSheet(
        genres: vm.genres,
        initialGenres: vm.selectedGenreIds ?? const [],
      ),
    );
    if (!mounted || result == null) return;
    await vm.selectGenres(result);
  }

  @override
  Widget build(BuildContext context) => Consumer<MovieListViewModel>(
    builder: (context, vm, _) => Scaffold(
      appBar: AppBar(
        title: const Text(
          '영화',
          style: TextStyle(color: AppColors.primary, fontSize: 20),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            key: const Key('refreshMovies'),
            tooltip: '새로고침',
            onPressed: vm.isBusy ? null : vm.refresh,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            key: const Key('openGenreFilter'),
            tooltip: '여러 장르 선택',
            onPressed: vm.isBusy || vm.genres.isEmpty
                ? null
                : () => _openFilter(vm),
            icon: const Icon(Icons.tune),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 54,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _genreChip(vm, '전체', null),
                ...vm.genres.map(
                  (genre) => _genreChip(vm, genre.name, genre.id),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${vm.movies.length}개의 영화',
                    key: const Key('movieCount'),
                    style: const TextStyle(color: AppColors.onSurfaceVariant),
                  ),
                ),
                DropdownButton<String>(
                  key: const Key('movieSortOrder'),
                  value: vm.sortOrder,
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(value: 'popular', child: Text('인기순')),
                    DropdownMenuItem(value: 'latest', child: Text('최신순')),
                    DropdownMenuItem(value: 'rating', child: Text('평점순')),
                    DropdownMenuItem(value: 'title', child: Text('제목순')),
                  ],
                  onChanged: vm.isBusy
                      ? null
                      : (value) {
                          if (value != null) vm.changeSort(value);
                        },
                ),
              ],
            ),
          ),
          if (vm.showingPreviousResults)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                '최근 성공한 목록을 표시하고 있어요.',
                style: TextStyle(color: AppColors.onSurfaceVariant),
              ),
            ),
          if (vm.isRefreshing)
            const LinearProgressIndicator(key: Key('refreshProgress')),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (vm.status == MovieLoadStatus.idle ||
                    vm.status == MovieLoadStatus.loading) {
                  return const MovieSkeletonGrid(count: 6);
                }
                final columns = constraints.maxWidth >= 900
                    ? 5
                    : constraints.maxWidth >= 600
                    ? 3
                    : 2;
                final movies = vm.sortedMovies;
                Widget content;
                if (vm.status == MovieLoadStatus.error ||
                    vm.status == MovieLoadStatus.empty) {
                  content = ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: constraints.maxHeight,
                        child: vm.status == MovieLoadStatus.error
                            ? MovieErrorView(
                                message: vm.message,
                                onRetry: vm.retry,
                              )
                            : const MovieEmptyView(),
                      ),
                    ],
                  );
                } else {
                  content = GridView.builder(
                    key: const PageStorageKey('movies-scroll'),
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 28),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 22,
                      childAspectRatio: .57,
                    ),
                    itemCount: movies.length,
                    itemBuilder: (context, index) {
                      final movie = movies[index];
                      return MovieCard(
                        movie: movie,
                        genres: vm.genres,
                        onTap: () =>
                            context.push('/movies/${movie.id}', extra: movie),
                      );
                    },
                  );
                }
                return RefreshIndicator(
                  onRefresh: vm.refresh,
                  notificationPredicate: (notification) =>
                      !vm.isBusy && notification.depth == 0,
                  child: content,
                );
              },
            ),
          ),
        ],
      ),
    ),
  );

  Widget _genreChip(MovieListViewModel vm, String label, int? genreId) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
        child: ChoiceChip(
          key: Key('genreChip-${genreId ?? 'all'}'),
          label: Text(label),
          selected: genreId == null
              ? vm.selectedGenreIds == null
              : (vm.selectedGenreIds?.contains(genreId) ?? false),
          onSelected: vm.isBusy
              ? null
              : (selected) => vm.selectGenres(
                  genreId == null || !selected ? null : [genreId],
                ),
        ),
      );
}

class GenreFilterSheet extends StatefulWidget {
  const GenreFilterSheet({
    required this.genres,
    required this.initialGenres,
    super.key,
  });
  final List<TmdbGenreDto> genres;
  final List<int> initialGenres;

  @override
  State<GenreFilterSheet> createState() => _GenreFilterSheetState();
}

class _GenreFilterSheetState extends State<GenreFilterSheet> {
  late final Set<int> _draftGenres = {...widget.initialGenres};
  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    initialChildSize: .55,
    minChildSize: .32,
    maxChildSize: .88,
    expand: false,
    builder: (context, scrollController) => Material(
      color: AppColors.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '장르 필터',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '여러 장르를 선택할 수 있어요',
                    style: TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: widget.genres.length,
              itemBuilder: (context, index) {
                final genre = widget.genres[index];
                return CheckboxListTile(
                  key: ValueKey('genre-${genre.id}'),
                  title: Text(genre.name),
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _draftGenres.contains(genre.id),
                  onChanged: (checked) => setState(() {
                    if (checked ?? false) {
                      _draftGenres.add(genre.id);
                    } else {
                      _draftGenres.remove(genre.id);
                    }
                  }),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                key: const Key('applyGenreFilter'),
                onPressed: () => Navigator.pop(context, _draftGenres.toList()),
                child: const Text('확인'),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
