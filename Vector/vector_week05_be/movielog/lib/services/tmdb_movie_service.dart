import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/movie.dart';
import 'movie_service.dart';
import 'network_logger.dart';

class TmdbMovieService implements MovieService {
  TmdbMovieService({
    required String token,
    http.Client? client,
    NetworkLogger? logger,
    this.timeout = const Duration(seconds: 10),
  }) : _token = token.trim(),
       _client = client ?? http.Client(),
       _logger = logger ?? NetworkLogger(secrets: [token.trim()]);

  final String _token;
  final http.Client _client;
  final NetworkLogger _logger;
  final Duration timeout;

  Uri discoverUri({required int page, List<int>? genreIds}) {
    final ids = normalizeGenreIds(genreIds);
    return Uri.https('api.themoviedb.org', '/3/discover/movie', {
      'language': 'ko-KR',
      'include_adult': 'false',
      'sort_by': 'popularity.desc',
      'page': '$page',
      if (ids != null) 'with_genres': ids.join('|'),
    });
  }

  @override
  Future<List<Movie>> fetchMovies({List<int>? genreIds}) async {
    final ids = normalizeGenreIds(genreIds);
    final movies = <Movie>[];
    final seen = <String>{};
    // 각 호출은 항상 page 1부터 시작하며 부분 성공을 화면에 반영하지 않습니다.
    var page = 1;
    while (movies.length < 30) {
      final uri = discoverUri(page: page, genreIds: ids);
      final data = await _getPage(uri);
      try {
        final results = data['results'] as List<dynamic>;
        final totalPages = (data['total_pages'] as num).toInt();
        for (final value in results) {
          final movie = Movie.fromJson(value as Map<String, dynamic>);
          if (seen.add(movie.id)) movies.add(movie);
          if (movies.length == 30) break;
        }
        if (results.isEmpty || page >= totalPages || page >= 500) break;
        page++;
      } on Object {
        _logger.failure(uri, 'INVALID_RESPONSE: 영화 데이터 형식이 올바르지 않습니다.');
        throw const MovieLoadException('영화 데이터 형식이 올바르지 않습니다.');
      }
    }
    return List<Movie>.unmodifiable(movies);
  }

  Future<Map<String, dynamic>> _getPage(Uri uri) async {
    if (_token.isEmpty) {
      _logger.failure(uri, 'CONFIG: TMDB_READ_ACCESS_TOKEN이 설정되지 않았습니다.');
      throw const MovieLoadException('실행 설정에 TMDB_READ_ACCESS_TOKEN을 입력해주세요.');
    }
    try {
      final response = await _client
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $_token',
              'Accept': 'application/json',
            },
          )
          .timeout(timeout);
      if (response.statusCode != 200) {
        final message = switch (response.statusCode) {
          401 || 403 => '인증에 실패했습니다. API 토큰을 확인해주세요.',
          429 => '요청이 너무 많습니다. 잠시 후 다시 시도해주세요.',
          _ => '서버가 요청을 처리하지 못했습니다.',
        };
        _logger.failure(uri, 'HTTP ${response.statusCode}: $message');
        throw MovieLoadException(message);
      }
      return jsonDecode(utf8.decode(response.bodyBytes))
          as Map<String, dynamic>;
    } on MovieLoadException {
      rethrow;
    } on TimeoutException {
      _logger.failure(uri, 'TIMEOUT: 영화 요청 시간이 초과되었습니다.');
      rethrow;
    } on http.ClientException {
      _logger.failure(uri, 'NETWORK: 네트워크 연결을 확인해주세요.');
      throw const MovieLoadException('네트워크 연결을 확인해주세요.');
    } on Object {
      _logger.failure(uri, 'INVALID_RESPONSE: 응답을 읽을 수 없습니다.');
      throw const MovieLoadException('서버 응답을 읽을 수 없습니다.');
    }
  }

  void close() => _client.close();
}
