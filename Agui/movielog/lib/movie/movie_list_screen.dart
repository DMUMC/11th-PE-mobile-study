import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/movie/data/mock_movies.dart';
import 'package:movielog/movie/widgets/movie_card.dart';
import 'package:movielog/movie/widgets/movie_genre_filter_sheet.dart';
import 'package:movielog/theme/app_colors.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key, this.initialGenreQuery});

  final String? initialGenreQuery;

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  static const _genres = [
    '드라마',
    'SF',
    '애니메이션',
    '스릴러',
    '로맨스',
    '코미디',
    '판타지',
    '다큐멘터리',
  ];

  late Set<String> _selectedGenres;
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _selectedGenres = _genresFromQuery(widget.initialGenreQuery);
  }

  @override
  void didUpdateWidget(covariant MovieListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialGenreQuery != widget.initialGenreQuery) {
      _selectedGenres = _genresFromQuery(widget.initialGenreQuery);
    }
  }

  Set<String> _genresFromQuery(String? query) => query == null
      ? <String>{}
      : query.split(',').where(_genres.contains).toSet();

  Future<void> _showGenreFilter() async {
    final selectedGenres = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MovieGenreFilterSheet(
        genres: _genres,
        selectedGenres: _selectedGenres,
      ),
    );

    if (selectedGenres == null || !mounted) return;
    final appliedGenres = _genres.where(selectedGenres.contains).toSet();
    setState(() => _selectedGenres = appliedGenres);

    final genreQuery = _genres.where(appliedGenres.contains).join(',');
    final location = Uri(
      path: '/movies',
      queryParameters: genreQuery.isEmpty ? null : {'genre': genreQuery},
    );
    context.go(location.toString());
  }

  @override
  Widget build(BuildContext context) {
    final visibleMovies = movies.where((movie) {
      if (!catalogMovieIds.contains(movie.id)) return false;
      final matchesGenre =
          _selectedGenres.isEmpty || _selectedGenres.contains(movie.genre);
      final matchesSearch =
          _searchQuery.isEmpty || movie.title.contains(_searchQuery.trim());
      return matchesGenre && matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        centerTitle: false,
        titleSpacing: 16,
        title: _isSearching
            ? TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: '영화 제목 검색',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              )
            : const Text(
                '영화',
                style: TextStyle(
                  color: AppColors.primary600,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
        actions: [
          IconButton(
            tooltip: _isSearching ? '검색 닫기' : '영화 검색',
            onPressed: () => setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) _searchQuery = '';
            }),
            icon: _isSearching
                ? const Icon(Icons.close)
                : SvgPicture.asset(
                    'assets/icons/search.svg',
                    width: 24,
                    height: 24,
                    colorFilter: const ColorFilter.mode(
                      AppColors.onSurface,
                      BlendMode.srcIn,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.surfaceContainer),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 40,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    tooltip: '장르 필터',
                    onPressed: _showGenreFilter,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.filter_list),
                  ),
                ),
              ),
            ),
            Expanded(
              child: visibleMovies.isEmpty
                  ? const Center(child: Text('검색 결과가 없습니다.'))
                  : LayoutBuilder(
                      builder: (context, constraints) => GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: visibleMovies.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: constraints.maxWidth >= 700 ? 3 : 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 28,
                          mainAxisExtent: 312,
                        ),
                        itemBuilder: (context, index) =>
                            MovieCard(movie: visibleMovies[index]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
