import 'package:dio/dio.dart';

import '../models/tmdb_movie_dto.dart';
import '../models/tmdb_movie_page.dart';
import '../models/tmdb_genre_dto.dart';

/// Stateless transport + DTO parsing. Collection limits belong to ViewModels.
class TmdbMovieService {
  TmdbMovieService(this._dio);
  final Dio _dio;

  Future<TmdbMoviePageDto> fetchPopular({
    int page = 1,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/movie/popular',
      queryParameters: {'language': 'ko-KR', 'page': page},
      cancelToken: cancelToken,
    );
    return TmdbMoviePageDto.fromJson(response.data!);
  }

  Future<TmdbMoviePageDto> discoverMovies({
    required int page,
    List<int>? genreIds,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/discover/movie',
      queryParameters: {
        'language': 'ko-KR',
        'page': page,
        'sort_by': 'popularity.desc',
        'include_adult': false,
        'include_video': false,
        if (genreIds != null && genreIds.isNotEmpty)
          'with_genres': genreIds.join('|'),
      },
      cancelToken: cancelToken,
    );
    return TmdbMoviePageDto.fromJson(response.data!);
  }

  Future<List<TmdbGenreDto>> fetchGenres({CancelToken? cancelToken}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/genre/movie/list',
      queryParameters: {'language': 'ko'},
      cancelToken: cancelToken,
    );
    return List.unmodifiable(
      (response.data!['genres'] as List<dynamic>? ?? const []).map(
        (item) => TmdbGenreDto.fromJson(item as Map<String, dynamic>),
      ),
    );
  }

  Future<TmdbMovieDto> fetchMovie(
    int movieId, {
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/movie/$movieId',
      queryParameters: {'language': 'ko-KR'},
      cancelToken: cancelToken,
    );
    return TmdbMovieDto.fromJson(response.data!);
  }
}
