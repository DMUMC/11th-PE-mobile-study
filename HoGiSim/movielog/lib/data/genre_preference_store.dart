import 'package:shared_preferences/shared_preferences.dart';

abstract interface class GenrePreferenceStore {
  Future<List<String>> readGenres();
  Future<void> writeGenres(List<String> genres);
  Future<String> readSortOrder();
  Future<void> writeSortOrder(String order);
}

class SharedPreferencesGenreStore implements GenrePreferenceStore {
  SharedPreferencesGenreStore([SharedPreferencesAsync? preferences])
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _genresKey = 'movie_selected_genres';
  static const _sortKey = 'movie_sort_order';
  final SharedPreferencesAsync _preferences;

  @override
  Future<List<String>> readGenres() async =>
      await _preferences.getStringList(_genresKey) ?? const [];

  @override
  Future<void> writeGenres(List<String> genres) =>
      _preferences.setStringList(_genresKey, genres);

  @override
  Future<String> readSortOrder() async =>
      await _preferences.getString(_sortKey) ?? 'latest';

  @override
  Future<void> writeSortOrder(String order) =>
      _preferences.setString(_sortKey, order);
}
