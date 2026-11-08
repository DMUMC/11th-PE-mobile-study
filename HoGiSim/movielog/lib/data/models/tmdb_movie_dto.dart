class TmdbMovieDto {
  const TmdbMovieDto({
    required this.id,
    required this.title,
    this.overview = '',
    this.posterPath,
    this.backdropPath,
    this.releaseDate,
    this.genreIds = const [],
    this.voteAverage = 0,
    this.popularity = 0,
    this.voteCount = 0,
    this.runtime,
  });

  final int id;
  final String title;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final String? releaseDate;
  final List<int> genreIds;
  final double voteAverage;
  final double popularity;
  final int voteCount;
  final int? runtime;

  factory TmdbMovieDto.fromJson(Map<String, dynamic> json) {
    final genreIds = json['genre_ids'] as List<dynamic>?;
    final genres = json['genres'] as List<dynamic>?;
    return TmdbMovieDto(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '제목 없음',
      overview: json['overview'] as String? ?? '',
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      releaseDate: json['release_date'] as String?,
      genreIds: List.unmodifiable(
        genreIds?.map((id) => (id as num).toInt()) ??
            genres?.map(
              (genre) => ((genre as Map<String, dynamic>)['id'] as num).toInt(),
            ) ??
            const <int>[],
      ),
      voteAverage: (json['vote_average'] as num? ?? 0).toDouble(),
      popularity: (json['popularity'] as num? ?? 0).toDouble(),
      voteCount: (json['vote_count'] as num? ?? 0).toInt(),
      runtime: (json['runtime'] as num?)?.toInt(),
    );
  }
}
