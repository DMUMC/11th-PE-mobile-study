class Movie {
  const Movie({
    required this.id,
    required this.title,
    required this.genres,
    required this.year,
    required this.posterAsset,
    required this.overview,
    required this.director,
    required this.runtime,
    required this.averageRating,
    required this.reviewCount,
  });

  final String id;
  final String title;
  final List<String> genres;
  final int year;
  final String posterAsset;
  final String overview;
  final String director;
  final int runtime;
  final double averageRating;
  final int reviewCount;

  String get genreLabel => genres.join(' · ');
}
