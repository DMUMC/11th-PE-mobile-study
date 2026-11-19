import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/movie.dart';
import '../services/movie_service.dart';

class MoviesController extends ChangeNotifier {
  MoviesController({
    required this.service,
    this.timeout = const Duration(seconds: 30),
  });
  final MovieService service;
  final Duration timeout;
  List<int>? _genreIds;
  List<int>? get genreIds => _genreIds;
  List<Movie> movies = const [];
  bool loading = false;
  bool hasSucceeded = false;
  Object? error;
  int failureVersion = 0;
  int _requestId = 0;
  bool _disposed = false;

  Future<void> load({List<int>? genreIds}) async {
    final id = ++_requestId;
    _genreIds = normalizeGenreIds(genreIds);
    loading = true;
    error = null;
    notifyListeners();
    try {
      final next = await service
          .fetchMovies(genreIds: _genreIds)
          .timeout(timeout);
      if (_disposed || id != _requestId) return;
      movies = List<Movie>.unmodifiable(next.take(30));
      hasSucceeded = true;
    } on Object catch (failure) {
      if (_disposed || id != _requestId) return;
      error = failure;
      failureVersion++;
      // 마지막 성공 목록을 유지하고 실패한 요청의 부분 결과는 반영하지 않습니다.
    } finally {
      if (!_disposed && id == _requestId) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> refresh() async {
    if (loading) return;
    await load(genreIds: _genreIds);
  }

  @override
  void dispose() {
    _disposed = true;
    _requestId++;
    super.dispose();
  }
}
