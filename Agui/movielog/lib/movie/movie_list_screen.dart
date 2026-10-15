import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/movie/data/fake_movie_service.dart';
import 'package:movielog/movie/data/genre_preference.dart';
import 'package:movielog/movie/data/mock_movies.dart';
import 'package:movielog/movie/data/movie_sort_preference.dart';
import 'package:movielog/movie/model/movie.dart';
import 'package:movielog/movie/widgets/movie_genre_filter_sheet.dart';
import 'package:movielog/movie/widgets/movie_grid.dart';
import 'package:movielog/movie/widgets/movie_list_empty.dart';
import 'package:movielog/movie/widgets/movie_list_error.dart';
import 'package:movielog/movie/widgets/movie_list_loading.dart';
import 'package:movielog/movie/widgets/movie_list_timeout.dart';
import 'package:movielog/theme/app_colors.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key, this.initialGenreQuery});

  final String? initialGenreQuery;

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  static const _movieService = FakeMovieService();
  static const _loadTimeout = Duration(seconds: 2);
  late final _genrePreference = GenrePreference();
  late final _sortPreference = MovieSortPreference();

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
  MovieSortOrder _sortOrder = MovieSortOrder.catalog;
  int _sortSelectionRevision = 0;
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _selectedGenres = _genresFromQuery(widget.initialGenreQuery);
    _moviesFuture = _fetchMovies();
    _isRestoringGenres = widget.initialGenreQuery == null;
    if (_isRestoringGenres) unawaited(_restoreSelectedGenres());
    unawaited(_restoreSortOrder());
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

  Future<List<Movie>> _fetchMovies({
    MovieLoadMode mode = MovieLoadMode.success,
  }) {
    return _movieService.fetchMovies(mode: mode).timeout(_loadTimeout);
  }

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

  Future<void> _restoreSortOrder() async {
    final revision = _sortSelectionRevision;
    try {
      final savedOrder = await _sortPreference.read();
      if (!mounted || revision != _sortSelectionRevision) return;
      setState(() => _sortOrder = savedOrder);
    } catch (error, stackTrace) {
      debugPrint('정렬 설정 읽기 실패: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _changeSortOrder(MovieSortOrder order) async {
    if (_sortOrder == order) return;
    _sortSelectionRevision++;
    setState(() => _sortOrder = order);

    try {
      await _sortPreference.save(order);
    } catch (error, stackTrace) {
      debugPrint('정렬 설정 저장 실패: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('정렬 방식을 저장하지 못했습니다.')));
      }
    }
  }

  void _sortMovies(List<Movie> movies) {
    int catalogOrder(Movie a, Movie b) =>
        catalogMovieIds.indexOf(a.id).compareTo(catalogMovieIds.indexOf(b.id));

    switch (_sortOrder) {
      case MovieSortOrder.catalog:
        return;
      case MovieSortOrder.newest:
        movies.sort((a, b) {
          final byYear = b.year.compareTo(a.year);
          return byYear != 0 ? byYear : catalogOrder(a, b);
        });
      case MovieSortOrder.highestRated:
        movies.sort((a, b) {
          final byRating = (b.rating ?? -1).compareTo(a.rating ?? -1);
          return byRating != 0 ? byRating : catalogOrder(a, b);
        });
    }
  }

  void _simulateEmpty() {
    setState(() {
      _moviesFuture = _fetchMovies(mode: MovieLoadMode.empty);
    });
  }

  void _simulateError() {
    setState(() {
      _moviesFuture = _fetchMovies(mode: MovieLoadMode.failure);
    });
  }

  void _simulateTimeout() {
    setState(() {
      _moviesFuture = _fetchMovies(mode: MovieLoadMode.slow);
    });
  }

  void _retry() {
    setState(() {
      _moviesFuture = _fetchMovies();
    });
  }

  Future<void> _refreshMovies() async {
    final future = _fetchMovies();
    setState(() {
      _moviesFuture = future;
    });

    try {
      await future;
    } catch (error, stackTrace) {
      debugPrint('영화 목록 새로고침 실패: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
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
          if (kDebugMode)
            IconButton(
              tooltip: '영화 로드 시간 초과 재현',
              onPressed: _simulateTimeout,
              icon: const Icon(Icons.timer_off_outlined),
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
                height: 48,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    PopupMenuButton<MovieSortOrder>(
                      tooltip: '영화 정렬',
                      initialValue: _sortOrder,
                      onSelected: _changeSortOrder,
                      itemBuilder: (context) => [
                        for (final order in MovieSortOrder.values)
                          PopupMenuItem(value: order, child: Text(order.label)),
                      ],
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_sortOrder.label),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: '장르 필터',
                      onPressed: _isRestoringGenres ? null : _showGenreFilter,
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.filter_list),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshMovies,
                child: FutureBuilder<List<Movie>>(
                  future: _moviesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const MovieListLoading();
                    }

                    if (snapshot.hasError) {
                      return snapshot.error is TimeoutException
                          ? MovieListTimeout(onRetry: _retry)
                          : MovieListError(onRetry: _retry);
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
                    _sortMovies(visibleMovies);

                    return visibleMovies.isEmpty
                        ? const CustomScrollView(
                            physics: AlwaysScrollableScrollPhysics(),
                            slivers: [
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: MovieListEmpty(),
                              ),
                            ],
                          )
                        : MovieGrid(movies: visibleMovies);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
