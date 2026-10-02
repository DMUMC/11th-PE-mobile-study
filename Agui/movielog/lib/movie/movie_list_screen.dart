import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/movie/data/mock_movies.dart';
import 'package:movielog/movie/widgets/movie_card.dart';
import 'package:movielog/theme/app_colors.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key, this.initialGenre});

  final String? initialGenre;

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  static const _genres = ['전체', '드라마', 'SF', '애니메이션', '스릴러'];

  late String _selectedGenre;
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _selectedGenre = _validGenre(widget.initialGenre);
  }

  @override
  void didUpdateWidget(covariant MovieListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialGenre != widget.initialGenre) {
      _selectedGenre = _validGenre(widget.initialGenre);
    }
  }

  String _validGenre(String? genre) => _genres.contains(genre) ? genre! : '전체';

  void _selectGenre(String genre) {
    setState(() => _selectedGenre = genre);
    final location = Uri(path: '/movies', queryParameters: {'genre': genre});
    context.go(location.toString());
  }

  @override
  Widget build(BuildContext context) {
    final visibleMovies = movies.where((movie) {
      if (!catalogMovieIds.contains(movie.id)) return false;
      final matchesGenre =
          _selectedGenre == '전체' || movie.genre == _selectedGenre;
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
            SizedBox(
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: _genres.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final genre = _genres[index];
                  final selected = genre == _selectedGenre;
                  return FilterChip(
                    label: Text(genre),
                    selected: selected,
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    side: BorderSide.none,
                    shape: const StadiumBorder(),
                    backgroundColor: AppColors.secondary200,
                    selectedColor: AppColors.primary500,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? Colors.white : AppColors.secondary700,
                    ),
                    onSelected: (_) => _selectGenre(genre),
                  );
                },
              ),
            ),
            Expanded(
              child: visibleMovies.isEmpty
                  ? const Center(child: Text('검색 결과가 없습니다.'))
                  : LayoutBuilder(
                      builder: (context, constraints) => GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
