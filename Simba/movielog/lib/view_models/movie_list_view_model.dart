import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/tmdb_genre_dto.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/tmdb_movie_service.dart';

enum MovieListLoadStatus { idle, loading, success, empty, error }

class MovieListViewModel extends ChangeNotifier {
  MovieListViewModel(this._service);

  /// 영화 목록에 보여줄 최대 개수 (화면 정책)
  static const maxMovieCount = 30;

  final TmdbMovieService _service;

  List<TmdbMovieDto> movies = const [];
  List<TmdbGenreDto> genres = const [];

  /// 선택된 장르 ID 목록. null이면 "전체"(with_genres 없이 요청).
  List<int>? selectedGenreIds;

  MovieListLoadStatus status = MovieListLoadStatus.idle;

  /// 기존 목록을 유지한 채 다시 불러오는 중인지 (Pull to Refresh, 목록이 있을 때의 재시도)
  bool isRefreshing = false;

  String? message;

  Map<int, String> _genreNames = const {};
  bool _hasPendingFailure = false;
  int _requestVersion = 0;
  bool _disposed = false;

  /// Discover 요청이 진행 중이면 true. 이때는 장르 변경/새로고침을 막는다.
  bool get isBusy =>
      status == MovieListLoadStatus.idle ||
      status == MovieListLoadStatus.loading ||
      isRefreshing;

  /// Loading 중에는 Pull to Refresh 제스처가 동작하지 않게 한다.
  bool get canRefresh => !isBusy;

  /// 요청 실패 Dialog를 아직 보여주지 않은 실패가 있는지.
  bool get hasPendingFailure => _hasPendingFailure;

  bool isGenreSelected(int genreId) =>
      selectedGenreIds?.contains(genreId) ?? false;

  /// 카드에 표시할 대표 장르 이름 (첫 번째 장르 ID 기준)
  String? genreNameOf(TmdbMovieDto movie) {
    for (final id in movie.genreIds) {
      final name = _genreNames[id];
      if (name != null) return name;
    }
    return null;
  }

  /// View가 실패 Dialog를 띄우기 직전에 호출해 같은 실패를 두 번 처리하지 않게 한다.
  void consumeFailure() {
    _hasPendingFailure = false;
  }

  /// 최초 진입: 장르 목록과 Discover 영화 목록을 함께 불러온다.
  Future<void> loadInitial() => _load(keepCurrentList: false);

  /// Pull to Refresh: 현재 선택된 장르를 유지한 채 page 1부터 다시 불러온다.
  /// 새로고침 중에는 기존 목록을 지우지 않는다.
  Future<void> refresh() async {
    if (!canRefresh) return;
    await _load(keepCurrentList: true);
  }

  /// 실패 Dialog/Error 화면의 재시도: 마지막으로 선택한 장르로 page 1부터 다시 불러온다.
  /// 최근 성공한 목록이 있으면 유지하고, 없으면 Loading 상태로 보여준다.
  Future<void> retry() async {
    if (isBusy) return;
    await _load(keepCurrentList: movies.isNotEmpty);
  }

  /// 장르 Chip 하나를 켜고 끈다.
  Future<void> toggleGenre(int genreId) {
    final next = [...?selectedGenreIds];
    if (!next.remove(genreId)) next.add(genreId);
    return applyGenres(next);
  }

  /// BottomSheet 확인 / "전체" Chip. 빈 목록이나 null이면 "전체"로 요청한다.
  /// 선택이 바뀌었을 때만 목록을 초기화하고 page 1부터 다시 요청한다.
  Future<void> applyGenres(List<int>? genreIds) async {
    if (isBusy) return;

    final normalized = genreIds == null || genreIds.isEmpty
        ? null
        : List<int>.unmodifiable(genreIds.toSet().toList()..sort());
    if (listEquals(normalized, selectedGenreIds)) return;

    selectedGenreIds = normalized;
    await _load(keepCurrentList: false);
  }

  Future<void> _load({required bool keepCurrentList}) async {
    final version = ++_requestVersion;
    _hasPendingFailure = false;
    message = null;
    isRefreshing = keepCurrentList;
    if (!keepCurrentList) {
      movies = const [];
      status = MovieListLoadStatus.loading;
    }
    notifyListeners();

    try {
      if (genres.isEmpty) {
        final fetchedGenres = await _service.fetchGenres();
        if (!_isLatest(version)) return;
        genres = fetchedGenres;
        _genreNames = {for (final genre in genres) genre.id: genre.name};
      }

      final result = await _fetchUpToMaxMovies(genreIds: selectedGenreIds);
      if (!_isLatest(version)) return;

      movies = result;
      status = result.isEmpty
          ? MovieListLoadStatus.empty
          : MovieListLoadStatus.success;
    } on DioException {
      if (!_isLatest(version)) return;
      _applyFailure('영화를 불러오지 못했어요. 네트워크 상태를 확인해 주세요.');
    } catch (error) {
      if (!_isLatest(version)) return;
      debugPrint('[MovieList] 응답 변환 실패: $error');
      _applyFailure('영화 정보를 읽지 못했어요. 다시 시도해 주세요.');
    }

    isRefreshing = false;
    notifyListeners();
  }

  /// 최근 성공한 목록이 있으면 비우지 않고 유지한다. 목록이 없을 때만 Error 화면을 보여준다.
  void _applyFailure(String failureMessage) {
    message = failureMessage;
    _hasPendingFailure = true;
    if (movies.isEmpty) status = MovieListLoadStatus.error;
  }

  /// 결과가 30개가 되거나 더 이상 페이지가 없을 때까지 page 1부터 요청한다.
  /// TMDB id를 key로 써서 페이지 사이의 중복을 제거한다.
  Future<List<TmdbMovieDto>> _fetchUpToMaxMovies({List<int>? genreIds}) async {
    final byId = <int, TmdbMovieDto>{};
    var pageNumber = 1;
    var hasNextPage = true;

    while (byId.length < maxMovieCount && hasNextPage) {
      final page = await _service.discoverMovies(
        page: pageNumber,
        genreIds: genreIds,
      );

      for (final movie in page.results) {
        byId.putIfAbsent(movie.id, () => movie);
        if (byId.length == maxMovieCount) break;
      }

      hasNextPage = pageNumber < page.totalPages && page.results.isNotEmpty;
      pageNumber++;
    }

    return byId.values.take(maxMovieCount).toList();
  }

  bool _isLatest(int version) => !_disposed && version == _requestVersion;

  @override
  void dispose() {
    _disposed = true;
    _requestVersion++;
    super.dispose();
  }
}
