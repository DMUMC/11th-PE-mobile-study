import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:movielog/data/genre_preference_store.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';

class MemoryGenreStore implements GenrePreferenceStore {
  List<String> genres = [];
  String sort = 'popular';
  @override
  Future<List<String>> readGenres() async => genres;
  @override
  Future<void> writeGenres(List<String> value) async {
    genres = value;
  }

  @override
  Future<String> readSortOrder() async => sort;
  @override
  Future<void> writeSortOrder(String value) async {
    sort = value;
  }
}

Map<String, dynamic> movieJson(
  int id, {
  List<int> genreIds = const [28],
  String? posterPath,
}) => {
  'id': id,
  'title': '영화 $id',
  'overview': '',
  'poster_path': posterPath,
  'backdrop_path': null,
  'release_date': null,
  'genre_ids': genreIds,
  'vote_average': 8,
  'popularity': 12,
  'vote_count': 10,
};
Map<String, dynamic> pageJson(
  List<Map<String, dynamic>> movies, {
  int page = 1,
  int totalPages = 1,
}) => {
  'page': page,
  'results': movies,
  'total_pages': totalPages,
  'total_results': movies.length,
};

class FixtureAdapter implements HttpClientAdapter {
  FixtureAdapter({this.respond});
  Future<ResponseBody> Function(RequestOptions)? respond;
  final List<RequestOptions> requests = [];

  static ResponseBody json(Object data, [int status = 200]) =>
      ResponseBody.fromString(
        jsonEncode(data),
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (respond != null) return respond!(options);
    if (options.path == '/genre/movie/list') {
      return json({
        'genres': [
          {'id': 28, 'name': '액션'},
          {'id': 878, 'name': 'SF'},
        ],
      });
    }
    if (options.path == '/movie/popular') {
      return json(pageJson(List.generate(8, (i) => movieJson(550 + i))));
    }
    if (options.path.startsWith('/movie/')) {
      final id = int.parse(options.path.split('/').last);
      return json(movieJson(id));
    }
    final page = options.queryParameters['page'] as int;
    return json(
      pageJson(
        List.generate(20, (i) => movieJson((page - 1) * 20 + i + 1)),
        page: page,
        totalPages: 2,
      ),
    );
  }

  @override
  void close({bool force = false}) {}
}

({Dio dio, FixtureAdapter adapter, TmdbMovieService service}) fixture({
  FixtureAdapter? adapter,
}) {
  final transport = adapter ?? FixtureAdapter();
  final dio = Dio(BaseOptions(baseUrl: 'https://api.themoviedb.org/3'));
  dio.httpClientAdapter = transport;
  return (dio: dio, adapter: transport, service: TmdbMovieService(dio));
}
