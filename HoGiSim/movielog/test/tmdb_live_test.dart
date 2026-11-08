import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/core/network/tmdb_client.dart';
import 'package:movielog/core/network/tmdb_logging_interceptor.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/view_models/movie_home_view_model.dart';
import 'package:movielog/view_models/movie_list_view_model.dart';
import 'package:movielog/view_models/movie_load_status.dart';

import 'support/tmdb_fixture.dart';

void main() {
  const enabled = bool.fromEnvironment('TMDB_LIVE');
  test(
    '실제 TMDB Popular/Genre/Discover 및 잘못된 인증 검증',
    () async {
      dotenv.loadFromString(envString: await File('.env').readAsString());
      expect(
        dotenv.env['TMDB_ACCESS_TOKEN']?.trim().isNotEmpty,
        isTrue,
        reason: '.env에 본인의 Read Access Token이 필요합니다.',
      );
      final dio = createTmdbClient();
      final requests = <Map<String, dynamic>>[];
      dio.interceptors.add(
        InterceptorsWrapper(
          onResponse: (response, handler) {
            requests.add({
              'path': response.requestOptions.path,
              'query': response.requestOptions.queryParameters,
              'status': response.statusCode,
            });
            handler.next(response);
          },
        ),
      );
      final service = TmdbMovieService(dio);
      final home = MovieHomeViewModel(service);
      final list = MovieListViewModel(
        service,
        preferenceStore: MemoryGenreStore(),
      );
      addTearDown(() {
        home.dispose();
        list.dispose();
        dio.close(force: true);
      });

      await home.loadPopular();
      expect(home.status, MovieLoadStatus.success, reason: home.message);
      expect(home.popularMovies.length, inInclusiveRange(1, 5));
      await list.loadInitial();
      expect(list.status, MovieLoadStatus.success, reason: list.message);
      expect(list.movies.length, inInclusiveRange(1, 30));
      expect(
        list.movies.map((movie) => movie.id).toSet().length,
        list.movies.length,
      );
      expect(list.genres, isNotEmpty);
      final allCount = list.movies.length;
      final genreId = list.genres.first.id;
      await list.selectGenres([genreId]);
      expect([
        MovieLoadStatus.success,
        MovieLoadStatus.empty,
      ], contains(list.status));
      expect(list.movies.length, lessThanOrEqualTo(30));
      expect(
        list.movies.every((movie) => movie.genreIds.contains(genreId)),
        isTrue,
      );

      final invalid = Dio(
        BaseOptions(
          baseUrl: 'https://api.themoviedb.org/3',
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            'Authorization': 'Bearer intentionally-invalid-workbook-token',
          },
        ),
      );
      final errorLogs = <String>[];
      invalid.interceptors.add(TmdbLoggingInterceptor(write: errorLogs.add));
      int? unauthorizedStatus;
      try {
        await TmdbMovieService(invalid).fetchPopular();
      } on DioException catch (error) {
        unauthorizedStatus = error.response?.statusCode;
      } finally {
        invalid.close(force: true);
      }
      expect(unauthorizedStatus, 401);
      expect(
        errorLogs.join(),
        isNot(contains('intentionally-invalid-workbook-token')),
      );
      expect(
        errorLogs.join(),
        isNot(contains(dotenv.env['TMDB_ACCESS_TOKEN']!)),
      );

      await Directory('docs/evidence').create(recursive: true);
      await File('docs/evidence/tmdb-live.json').writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          'testedAt': DateTime.now().toUtc().toIso8601String(),
          'result': 'PASS',
          'popularCount': home.popularMovies.length,
          'discoverCount': allCount,
          'filteredGenreId': genreId,
          'filteredCount': list.movies.length,
          'filteredMovieIds': list.movies.map((movie) => movie.id).toList(),
          'requests': requests,
          'invalidTokenStatus': unauthorizedStatus,
          'maskedErrorLogs': errorLogs,
          'tokenIncludedInEvidence': false,
        }),
      );
      // ignore: avoid_print
      print(
        '실제 TMDB 검증 통과: Popular ${home.popularMovies.length}, Discover $allCount, 장르 ${list.movies.length}, 인증 오류 $unauthorizedStatus',
      );
    },
    skip: !enabled,
    timeout: const Timeout(Duration(seconds: 90)),
  );
}
