import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/movie/data/fake_movie_service.dart';
import 'package:movielog/movie/data/genre_preference.dart';
import 'package:movielog/movie/data/mock_movies.dart';
import 'package:movielog/movie/model/movie.dart';
import 'package:movielog/movie/widgets/movie_genre_filter_sheet.dart';
import 'package:movielog/movie/widgets/movie_grid.dart';
import 'package:movielog/movie/widgets/movie_list_empty.dart';
import 'package:movielog/movie/widgets/movie_list_error.dart';
import 'package:movielog/theme/app_colors.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key, this.initialGenreQuery});

  final String? initialGenreQuery;

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  static const _movieService = FakeMovieService();
  late final _genrePreference = GenrePreference();

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
  late Future<List<Movie>> _moviesFuture;
  late bool _isRestoringGenres;
  int _genreSelectionRevision = 0;
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _selectedGenres = _genresFromQuery(widget.initialGenreQuery);
    _moviesFuture = _movieService.fetchMovies();
    _isRestoringGenres = widget.initialGenreQuery == null;
    if (_isRestoringGenres) unawaited(_restoreSelectedGenres());
  }

  @override
  void didUpdateWidget(covariant MovieListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialGenreQuery != widget.initialGenreQuery) {
      _genreSelectionRevision++;
      if (widget.initialGenreQuery == null) {
        _isRestoringGenres = true;
        unawaited(_restoreSelectedGenres());
      } else {
        _selectedGenres = _genresFromQuery(widget.initialGenreQuery);
        _isRestoringGenres = false;
      }
    }
  }

  Set<String> _genresFromQuery(String? query) => query == null
      ? <String>{}
      : query.split(',').where(_genres.contains).toSet();

  Future<void> _restoreSelectedGenres() async {
    final revision = _genreSelectionRevision;

    try {
      final storedGenres = await _genrePreference.read();
      if (!mounted ||
          widget.initialGenreQuery != null ||
          revision != _genreSelectionRevision) {
        return;
      }

      setState(() {
        _selectedGenres = _genresFromQuery(storedGenres);
        _isRestoringGenres = false;
      });
    } catch (error, stackTrace) {
      debugPrint('장르 설정 읽기 실패: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted || revision != _genreSelectionRevision) return;
      setState(() => _isRestoringGenres = false);
    }
  }

  void _simulateEmpty() {
    setState(() {
      _moviesFuture = _movieService.fetchMovies(mode: MovieLoadMode.empty);
    });
  }

  void _simulateError() {
    setState(() {
      _moviesFuture = _movieService.fetchMovies(mode: MovieLoadMode.failure);
    });
  }

  void _retry() {
    setState(() {
      _moviesFuture = _movieService.fetchMovies();
    });
  }

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
    _genreSelectionRevision++;
    setState(() => _selectedGenres = appliedGenres);

    final genreQuery = _genres.where(appliedGenres.contains).join(',');
    try {
      await _genrePreference.save(genreQuery);
    } catch (error, stackTrace) {
      debugPrint('장르 설정 저장 실패: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('장르 선택을 저장하지 못했습니다.')));
    }

    if (!mounted) return;
    final location = Uri(
      path: '/movies',
      queryParameters: genreQuery.isEmpty ? null : {'genre': genreQuery},
    );
    context.go(location.toString());
  }

  @override
  Widget build(BuildContext context) {
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
          if (kDebugMode)
            IconButton(
              tooltip: '빈 영화 목록 재현',
              onPressed: _simulateEmpty,
              icon: const Icon(Icons.inbox_outlined),
            ),
          if (kDebugMode)
            IconButton(
              tooltip: '영화 로드 오류 재현',
              onPressed: _simulateError,
              icon: const Icon(Icons.bug_report_outlined),
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
                    onPressed: _isRestoringGenres ? null : _showGenreFilter,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.filter_list),
                  ),
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Movie>>(
                future: _moviesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return MovieListError(onRetry: _retry);
                  }

                  final visibleMovies = (snapshot.data ?? const <Movie>[])
                      .where((movie) {
                        if (!catalogMovieIds.contains(movie.id)) return false;
                        final matchesGenre =
                            _selectedGenres.isEmpty ||
                            _selectedGenres.contains(movie.genre);
                        final matchesSearch =
                            _searchQuery.isEmpty ||
                            movie.title.contains(_searchQuery.trim());
                        return matchesGenre && matchesSearch;
                      })
                      .toList();

                  return visibleMovies.isEmpty
                      ? const MovieListEmpty()
                      : MovieGrid(movies: visibleMovies);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
