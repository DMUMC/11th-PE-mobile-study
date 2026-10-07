import 'package:shared_preferences/shared_preferences.dart';

enum MovieSort { recommended, rating, newest, title }

extension MovieSortLabel on MovieSort {
  String get label => switch (this) {
    MovieSort.recommended => '추천순',
    MovieSort.rating => '평점 높은순',
    MovieSort.newest => '최신순',
    MovieSort.title => '제목순',
  };
}

abstract interface class MoviePreferencesStore {
  Future<List<String>> loadGenres();
  Future<void> saveGenres(Iterable<String> genres);
  Future<MovieSort> loadSort();
  Future<void> saveSort(MovieSort sort);
}

class SharedMoviePreferences implements MoviePreferencesStore {
  SharedMoviePreferences({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _genresKey = 'selected_movie_genres';
  static const _sortKey = 'movie_sort';

  final SharedPreferencesAsync _preferences;

  @override
  Future<List<String>> loadGenres() async =>
      await _preferences.getStringList(_genresKey) ?? const <String>[];

  @override
  Future<void> saveGenres(Iterable<String> genres) async {
    await _preferences.setStringList(_genresKey, genres.toList());
  }

  @override
  Future<MovieSort> loadSort() async {
    final saved = await _preferences.getString(_sortKey);
    return MovieSort.values.where((sort) => sort.name == saved).firstOrNull ??
        MovieSort.recommended;
  }

  @override
  Future<void> saveSort(MovieSort sort) async {
    await _preferences.setString(_sortKey, sort.name);
  }
}

class MemoryMoviePreferences implements MoviePreferencesStore {
  MemoryMoviePreferences({
    Iterable<String> genres = const [],
    this.sort = MovieSort.recommended,
  }) : genres = genres.toList();

  List<String> genres;
  MovieSort sort;

  @override
  Future<List<String>> loadGenres() async => List<String>.of(genres);

  @override
  Future<void> saveGenres(Iterable<String> value) async {
    genres = value.toList();
  }

  @override
  Future<MovieSort> loadSort() async => sort;

  @override
  Future<void> saveSort(MovieSort value) async {
    sort = value;
  }
}
