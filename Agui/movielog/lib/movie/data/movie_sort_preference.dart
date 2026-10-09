import 'package:shared_preferences/shared_preferences.dart';

enum MovieSortOrder {
  catalog('기본순'),
  newest('최신순'),
  highestRated('평점 높은순');

  const MovieSortOrder(this.label);

  final String label;
}

class MovieSortPreference {
  MovieSortPreference({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _sortOrderKey = 'selected_sort_order';

  final SharedPreferencesAsync _preferences;

  Future<MovieSortOrder> read() async {
    final saved = await _preferences.getString(_sortOrderKey);
    return MovieSortOrder.values.firstWhere(
      (order) => order.name == saved,
      orElse: () => MovieSortOrder.catalog,
    );
  }

  Future<void> save(MovieSortOrder order) async {
    await _preferences.setString(_sortOrderKey, order.name);
  }
}
