import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../theme/app_colors.dart';
import '../view_models/load_phase.dart';
import '../view_models/paged_movies_view_model.dart';
import '../widgets/movie_page_footer.dart';
import '../widgets/movielog_button.dart';
import '../widgets/tmdb_poster_image.dart';

class MovieSearchScreen extends StatefulWidget {
  const MovieSearchScreen({super.key});

  @override
  State<MovieSearchScreen> createState() => _MovieSearchScreenState();
}

class _MovieSearchScreenState extends State<MovieSearchScreen> {
  final _text = TextEditingController();
  String _submittedQuery = '';
  String? _inputError;

  void _submitSearch(String value) {
    final query = value.trim();
    setState(() {
      _submittedQuery = query;
      _inputError = query.isEmpty ? '검색어를 입력합니다.' : null;
    });
    context.read<PagedMoviesViewModel>().loadInitial(query: query);
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFEFCF9),
    appBar: AppBar(
      backgroundColor: const Color(0xFFFEFCF9),
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      toolbarHeight: 64,
      centerTitle: true,
      leading: IconButton(
        tooltip: '뒤로 가기',
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/movies');
          }
        },
      ),
      title: Text(
        '영화 검색',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    ),
    body: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _inputError == null
                          ? const Color(0xFFD9D3E1)
                          : Theme.of(context).colorScheme.error,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _text,
                          textInputAction: TextInputAction.search,
                          onSubmitted: _submitSearch,
                          style: const TextStyle(fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: '영화 제목을 입력하세요',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                            isDense: true,
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _submitSearch(_text.text),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          minimumSize: const Size(64, 48),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('검색'),
                      ),
                    ],
                  ),
                ),
                if (_inputError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 16),
                    child: Text(
                      _inputError!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<PagedMoviesViewModel>(
              builder: (context, vm, _) {
                switch (vm.phase) {
                  case LoadPhase.idle:
                    return const Center(child: Text('검색어를 입력합니다.'));
                  case LoadPhase.loading:
                    return const Center(child: CircularProgressIndicator());
                  case LoadPhase.empty:
                    return const Center(child: Text('검색 결과가 없습니다.'));
                  case LoadPhase.error:
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              vm.errorMessage ?? '검색 결과를 불러오지 못했습니다.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            MovieLogButton(
                              label: '다시 시도',
                              onPressed: () =>
                                  vm.loadInitial(query: _submittedQuery),
                            ),
                          ],
                        ),
                      ),
                    );
                  case LoadPhase.ready:
                    return CustomScrollView(
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          sliver: SliverList.separated(
                            itemCount: vm.movies.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 20),
                            itemBuilder: (context, index) =>
                                _SearchResultCard(movie: vm.movies[index]),
                          ),
                        ),
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(8, 24, 8, 124),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: MoviePageFooter(
                                vm: vm,
                                loadMoreLabel: '검색 결과 더 보기',
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                }
              },
            ),
          ),
        ],
      ),
    ),
  );
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({required this.movie});

  final TmdbMovieDto movie;

  @override
  Widget build(BuildContext context) {
    final year = movie.releaseDate?.split('-').first;
    return Material(
      color: const Color(0xFFFEFCF9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFD9D3E1)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/movies/${movie.id}', extra: movie),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: TmdbPosterImage(
                    posterPath: movie.posterPath,
                    width: 76,
                    height: 120,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movie.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (year != null && year.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          year,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.gray,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        '평점 ${movie.voteAverage.toStringAsFixed(1)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
