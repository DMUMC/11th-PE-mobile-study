import 'package:shared_preferences/shared_preferences.dart';

import '../models/movie.dart';

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
  Future<List<int>?> loadGenres();
  Future<void> saveGenres(List<int>? genres);
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
  Future<List<int>?> loadGenres() async => parseGenreIds(
    await _preferences.getStringList(_genresKey) ?? const <String>[],
  );

  @override
  Future<void> saveGenres(List<int>? genres) async {
    await _preferences.setStringList(
      _genresKey,
      (genres ?? <int>[]).map((id) => '$id').toList(),
    );
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
  MemoryMoviePreferences({List<int>? genres, this.sort = MovieSort.recommended})
    : genres = normalizeGenreIds(genres);

  List<int>? genres;
  MovieSort sort;

  @override
  Future<List<int>?> loadGenres() async => normalizeGenreIds(genres);

  @override
  Future<void> saveGenres(List<int>? value) async {
    genres = normalizeGenreIds(value);
  }

  @override
  Future<MovieSort> loadSort() async => sort;

  @override
  Future<void> saveSort(MovieSort value) async {
    sort = value;
  }
}
