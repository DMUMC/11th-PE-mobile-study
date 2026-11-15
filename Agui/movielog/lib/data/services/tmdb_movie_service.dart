import 'package:dio/dio.dart';

import '../models/tmdb_movie_dto.dart';

class TmdbMovieService {
  TmdbMovieService(this._dio);

  final Dio _dio;

  Future<List<TmdbMovieDto>> fetchPopularMovies() async {
    final response = await _dio.get<dynamic>(
      '/movie/popular',
      queryParameters: {'language': 'ko-KR', 'page': 1},
    );
    final data = response.data;
    if (data is! Map<String, dynamic> || data['results'] is! List) {
      throw const FormatException('Expected a movie list');
    }
    return (data['results'] as List)
        .map((item) => TmdbMovieDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<TmdbMovieDto> fetchMovieDetail(int movieId) async {
    final response = await _dio.get<dynamic>(
      '/movie/$movieId',
      queryParameters: {'language': 'ko-KR'},
    );
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Expected a movie object');
    }
    return TmdbMovieDto.fromJson(data);
  }

  Future<TmdbMovieDto?> findMovieById(int movieId) async {
    try {
      return await fetchMovieDetail(movieId);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  void close() => _dio.close(force: true);
}
