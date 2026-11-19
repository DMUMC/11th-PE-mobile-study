class TmdbMovieDto {
  const TmdbMovieDto({
    required this.id,
    required this.title,
    this.overview = '',
    required this.posterPath,
    this.backdropPath,
    this.releaseDate,
    this.genreIds = const [],
    this.voteAverage = 0,
    this.popularity = 0,
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

  String? get posterUrl => posterPath != null && posterPath!.startsWith('/')
      ? 'https://image.tmdb.org/t/p/w342$posterPath'
      : null;

  factory TmdbMovieDto.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final title = json['title'];
    final posterPath = json['poster_path'];
    if (id is! num ||
        title is! String ||
        (posterPath != null && posterPath is! String)) {
      throw const FormatException('Invalid movie response');
    }
    return TmdbMovieDto(
      id: id.toInt(),
      title: title.trim().isEmpty ? '영화 #${id.toInt()}' : title,
      overview: json['overview'] as String? ?? '',
      posterPath: posterPath is String && posterPath.startsWith('/')
          ? posterPath
          : null,

      backdropPath: json['backdrop_path'] as String?,
      releaseDate: json['release_date'] as String?,
      genreIds: (json['genre_ids'] as List<dynamic>? ?? const [])
          .map((value) => (value as num).toInt())
          .toList(),
      voteAverage: (json['vote_average'] as num? ?? 0).toDouble(),
      popularity: (json['popularity'] as num? ?? 0).toDouble(),
    );
  }
}
