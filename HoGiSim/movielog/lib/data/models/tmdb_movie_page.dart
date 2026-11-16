import 'tmdb_movie_dto.dart';

class TmdbMoviePageDto {
  const TmdbMoviePageDto({
    required this.page,
    required this.results,
    required this.totalPages,
    required this.totalResults,
  });
  final int page;
  final List<TmdbMovieDto> results;
  final int totalPages;
  final int totalResults;

  factory TmdbMoviePageDto.fromJson(Map<String, dynamic> json) =>
      TmdbMoviePageDto(
        page: (json['page'] as num).toInt(),
        results: List.unmodifiable(
          (json['results'] as List<dynamic>? ?? const []).map(
            (item) => TmdbMovieDto.fromJson(item as Map<String, dynamic>),
          ),
        ),
        totalPages: (json['total_pages'] as num).toInt(),
        totalResults: (json['total_results'] as num).toInt(),
      );
}
