class TmdbMovieDto {
  const TmdbMovieDto({
    required this.id,
    required this.title,
    required this.posterPath,
  });

  final int id;
  final String title;
  final String? posterPath;

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
      posterPath: posterPath is String && posterPath.startsWith('/')
          ? posterPath
          : null,
    );
  }
}
