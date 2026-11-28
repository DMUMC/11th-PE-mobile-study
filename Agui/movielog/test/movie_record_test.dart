import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/core/network/auth_interceptor.dart';
import 'package:movielog/core/storage/token_storage.dart';
import 'package:movielog/data/models/movie_record_request.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/services/auth_api_service.dart';
import 'package:movielog/data/services/member_api_service.dart';
import 'package:movielog/data/services/movie_record_api_service.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/view_models/movie_detail_view_model.dart';

class _Storage implements TokenStorage {
  String? token = 'test-token';
  @override
  Future<String?> readAccessToken() async => token;
  @override
  Future<void> saveAccessToken(String value) async => token = value;
  @override
  Future<void> deleteAccessToken() async => token = null;
}

class _Adapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  int status = 201;
  String code = 'COMMON201';
  bool timeout = false;
  bool omitFavorite = false;
  Completer<void>? entered;
  Completer<void>? gate;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    entered?.complete();
    await gate?.future;
    if (timeout) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.receiveTimeout,
      );
    }
    final request = options.data as Map<String, dynamic>;
    final rating = {
      'ratingId': 12,
      'movieId': request['movieId'],
      'score': request['score'],
      'comment': request['comment'],
      'createdAt': '2026-11-28T10:00:00Z',
    };
    return ResponseBody.fromString(
      jsonEncode({
        'isSuccess': status == 201,
        'code': code,
        'message': '입력값을 확인해 주세요.',
        'result': status != 201
            ? null
            : options.path == '/v8/ratings'
            ? rating
            : {
                'rating': rating,
                'favorite': request['addToFavorites'] == true && !omitFavorite
                    ? {
                        'favoriteId': 9,
                        'movieId': request['movieId'],
                        'createdAt': '2026-11-28T10:00:00Z',
                      }
                    : null,
              },
      }),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Dio dio;
  late _Storage storage;
  late _Adapter adapter;
  late AuthViewModel auth;
  late MovieRecordApiService records;
  late MovieDetailViewModel vm;
  setUp(() {
    storage = _Storage();
    adapter = _Adapter();
    dio = Dio(BaseOptions(baseUrl: 'https://workbook.devnoco.com'))
      ..interceptors.add(AuthInterceptor(storage))
      ..httpClientAdapter = adapter;
    auth = AuthViewModel(AuthApiService(dio), MemberApiService(dio), storage)
      ..status = AuthStatus.signedIn;
    records = MovieRecordApiService(dio);
    vm = MovieDetailViewModel(
      RatingApiService(dio, dio),
      auth,
      const TmdbMovieDto(id: 550, title: '영화', posterPath: null),
      movieRecordApi: records,
    );
  });
  tearDown(() {
    vm.dispose();
    auth.dispose();
    dio.close(force: true);
  });

  for (final add in [false, true]) {
    test(
      'record request sends JWT and required boolean $add in one POST',
      () async {
        final result = await records.createMovieRecord(
          CreateMovieRecordRequest(
            movieId: 550,
            score: 4,
            comment: ' 좋아요 ',
            addToFavorites: add,
          ),
        );
        final request = adapter.requests.single;
        expect(request.path, '/v8/movie-records');
        expect(request.method, 'POST');
        expect(request.headers['Authorization'], 'Bearer test-token');
        expect(request.data, {
          'movieId': 550,
          'score': 4,
          'comment': '좋아요',
          'addToFavorites': add,
        });
        expect(result.rating.ratingId, 12);
        expect(result.favorite?.movieId, add ? 550 : null);
      },
    );
    test('successful record $add stores rating in current session', () async {
      await vm.createMovieRecord(score: 4, addToFavorites: add);
      expect(auth.sessionRatings.single.rating.movieId, 550);
      expect(auth.sessionRatings.single.movie!.title, '영화');
      expect(adapter.requests.length, 1);
    });
  }

  test(
    'blank comment is omitted while false boolean remains present',
    () async {
      await records.createMovieRecord(
        const CreateMovieRecordRequest(
          movieId: 550,
          score: 3,
          comment: ' ',
          addToFavorites: false,
        ),
      );
      expect(adapter.requests.single.data, {
        'movieId': 550,
        'score': 3,
        'addToFavorites': false,
      });
    },
  );

  test('invalid integer score is rejected before sending request', () async {
    await expectLater(
      records.createMovieRecord(
        const CreateMovieRecordRequest(
          movieId: 550,
          score: 0,
          addToFavorites: false,
        ),
      ),
      throwsArgumentError,
    );
    expect(adapter.requests, isEmpty);
  });

  test('rating-only path keeps existing ratings API', () async {
    await vm.createRating(score: 4);
    expect(adapter.requests.single.path, '/v8/ratings');
    expect(
      (adapter.requests.single.data as Map).containsKey('addToFavorites'),
      isFalse,
    );
  });

  for (final failure in [
    (400, 'COMMON400', false),
    (409, 'RATING409_1', true),
    (409, 'FAVORITE409_1', true),
    (404, 'MEMBER404_1', true),
    (403, 'AUTH401_4', false),
  ]) {
    test('${failure.$2} indicates whether dialog should close', () async {
      adapter.status = failure.$1;
      adapter.code = failure.$2;
      await expectLater(
        vm.createMovieRecord(score: 4, addToFavorites: true),
        throwsA(
          isA<RatingSubmissionException>().having(
            (e) => e.closeDialog,
            'closeDialog',
            failure.$3,
          ),
        ),
      );
      expect(auth.sessionRatings, isEmpty);
      expect(auth.status, AuthStatus.signedIn);
      expect(storage.token, 'test-token');
      expect(adapter.requests.length, 1);
    });
  }

  test(
    'timeout remains retryable without automatically repeating POST',
    () async {
      adapter.timeout = true;
      await expectLater(
        vm.createMovieRecord(score: 4, addToFavorites: true),
        throwsA(
          isA<RatingSubmissionException>().having(
            (e) => e.closeDialog,
            'closeDialog',
            false,
          ),
        ),
      );
      expect(adapter.requests.length, 1);
      expect(auth.sessionRatings, isEmpty);
      expect(auth.status, AuthStatus.signedIn);
    },
  );

  test(
    'missing favorite for a checked request is not treated as success',
    () async {
      adapter.omitFavorite = true;
      await expectLater(
        vm.createMovieRecord(score: 4, addToFavorites: true),
        throwsA(isA<RatingSubmissionException>()),
      );
      expect(auth.sessionRatings, isEmpty);
    },
  );

  test('pending submission blocks duplicate saves and discards old-session response', () async {
    adapter.entered = Completer<void>();
    adapter.gate = Completer<void>();
    final pending = vm.createMovieRecord(score: 4, addToFavorites: true);
    await adapter.entered!.future;
    await expectLater(
      vm.createMovieRecord(score: 4, addToFavorites: true),
      throwsA(isA<RatingSubmissionException>()),
    );
    await auth.logout();
    adapter.gate!.complete();
    await expectLater(pending, throwsA(isA<RatingSubmissionException>()));
    expect(adapter.requests.length, 1);
    expect(auth.sessionRatings, isEmpty);
  });
}
