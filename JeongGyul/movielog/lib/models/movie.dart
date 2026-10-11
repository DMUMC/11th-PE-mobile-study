class Movie {
  const Movie({
    required this.id,
    required this.title,
    required this.genre,
    required this.year,
    required this.posterAsset,
    required this.averageRating,
    required this.durationMinutes,
    required this.synopsis,
    this.heroAsset,
    this.tags = const [],
    this.ratingCount = 1245,
    this.isPopular = false,
  });

  final int id;
  final String title;
  final String genre;
  final int year;
  final String posterAsset;
  final String? heroAsset;
  final double averageRating;
  final int durationMinutes;
  final String synopsis;
  final List<String> tags;
  final int ratingCount;
  final bool isPopular;
}
