import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:movielog/home/movie_log_bottom_navigation_bar.dart';
import 'package:movielog/movie/data/mock_movies.dart';
import 'package:movielog/movie/widgets/movie_card.dart';
import 'package:movielog/theme/app_colors.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  static const _genres = ['전체', '드라마', 'SF', '애니메이션', '스릴러'];

  String _selectedGenre = '전체';
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  Widget build(BuildContext context) {
    final visibleMovies = catalogMovies.where((movie) {
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
      bottomNavigationBar: const MovieLogBottomNavigationBar(currentIndex: 1),
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
                  return Semantics(
                    button: true,
                    selected: selected,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(100),
                      onTap: () => setState(() => _selectedGenre = genre),
                      child: Container(
                        height: 32,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary500
                              : AppColors.secondary200,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          genre,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: selected
                                ? Colors.white
                                : AppColors.secondary700,
                          ),
                        ),
                      ),
                    ),
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
