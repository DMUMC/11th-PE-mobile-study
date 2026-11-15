class TmdbMovieDto {
  const TmdbMovieDto({
    required this.id,
    required this.title,
    required this.posterPath,
    this.overview = '',
    this.releaseDate = '',
    this.voteAverage,
    this.genreIds = const [],
  });

  final int id;
  final String title;
  final String? posterPath;
  final String overview;
  final String releaseDate;
  final double? voteAverage;
  final List<int> genreIds;

  String? get posterUrl =>
      posterPath == null ? null : 'https://image.tmdb.org/t/p/w342$posterPath';

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
      overview: json['overview'] is String ? json['overview'] as String : '',
      releaseDate: json['release_date'] is String
          ? json['release_date'] as String
          : '',
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
      genreIds:
          (json['genre_ids'] as List?)
              ?.whereType<num>()
              .map((e) => e.toInt())
              .toList() ??
          const [],
      posterPath: posterPath is String && posterPath.startsWith('/')
          ? posterPath
          : null,
    );
  }
}
