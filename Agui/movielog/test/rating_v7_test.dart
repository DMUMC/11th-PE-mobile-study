import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/core/network/auth_interceptor.dart';
import 'package:movielog/core/storage/token_storage.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/services/auth_api_service.dart';
import 'package:movielog/data/services/member_api_service.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/view_models/movie_detail_view_model.dart';

class MemoryStorage implements TokenStorage {
  String? token = 'local-test-token';
  @override
  Future<void> deleteAccessToken() async {
    token = null;
  }

  @override
  Future<String?> readAccessToken() async => token;
  @override
  Future<void> saveAccessToken(String token) async {
    this.token = token;
  }
}

class Adapter implements HttpClientAdapter {
  RequestOptions? request;
  int status = 201;
  String code = 'OK';
  Completer<void>? gate;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    if (gate != null) await gate!.future;
    final Object body = options.method == 'GET'
        ? []
        : status == 201
        ? {
            'isSuccess': true,
            'code': 'OK',
            'message': 'ok',
            'result': {
              'ratingId': 12,
              'movieId': 550,
              'score': 4,
              'comment': '좋아요',
              'createdAt': '2026-11-20T10:00:00',
            },
          }
        : {
            'isSuccess': false,
            'code': code,
            'message': 'error',
            'result': null,
          };
    return ResponseBody.fromString(
      jsonEncode(body),
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
  late Adapter adapter;
  late MemoryStorage storage;
  late Dio publicClient;
  late Dio authClient;
  late AuthViewModel auth;
  late MovieDetailViewModel model;
  setUp(() {
    adapter = Adapter();
    storage = MemoryStorage();
    publicClient = Dio(BaseOptions(baseUrl: 'https://workbook.devnoco.com'));
    authClient = Dio(BaseOptions(baseUrl: 'https://workbook.devnoco.com'))
      ..interceptors.add(AuthInterceptor(storage))
      ..httpClientAdapter = adapter;
    auth = AuthViewModel(
      AuthApiService(publicClient),
      MemberApiService(authClient),
      storage,
    )..status = AuthStatus.signedIn;
    model = MovieDetailViewModel(
      RatingApiService(publicClient, authClient),
      auth,
      const TmdbMovieDto(id: 550, title: '영화', posterPath: null),
    );
  });
  tearDown(() {
    model.dispose();
    auth.dispose();
    publicClient.close();
    authClient.close();
  });

  test(
    'registration uses Bearer without memberId and stores response',
    () async {
      await model.createRating(score: 4, comment: '좋아요');
      expect(adapter.request!.path, '/v8/ratings');
      expect(
        adapter.request!.headers['Authorization'],
        'Bearer local-test-token',
      );
      expect(adapter.request!.data, {
        'movieId': 550,
        'score': 4,
        'comment': '좋아요',
      });
      expect(auth.sessionRatings.single.rating.ratingId, 12);
      expect(auth.sessionRatings.single.movie!.title, '영화');
    },
  );
  for (final error in [(403, 'RATING403_1'), (409, 'RATING409_1')]) {
    test('${error.$2} keeps session', () async {
      adapter.status = error.$1;
      adapter.code = error.$2;
      await expectLater(
        model.createRating(score: 4),
        throwsA(isA<RatingSubmissionException>()),
      );
      expect(auth.status, AuthStatus.signedIn);
      expect(storage.token, isNotNull);
    });
  }
  test('AUTH401_4 clears session and token', () async {
    adapter.status = 401;
    adapter.code = 'AUTH401_4';
    await expectLater(
      model.createRating(score: 4),
      throwsA(isA<RatingSubmissionException>()),
    );
    expect(auth.status, AuthStatus.signedOut);
    expect(auth.sessionExpired, isTrue);
    expect(storage.token, isNull);
  });
  test('response from previous session is ignored', () async {
    adapter.gate = Completer<void>();
    final pending = model.createRating(score: 4);
    await Future<void>.delayed(Duration.zero);
    await auth.logout();
    adapter.gate!.complete();
    await expectLater(pending, throwsA(isA<RatingSubmissionException>()));
    expect(auth.sessionRatings, isEmpty);
  });
  test('public user ratings use public client', () async {
    final publicAdapter = Adapter()..status = 200;
    publicClient.httpClientAdapter = publicAdapter;
    expect(
      await RatingApiService(publicClient, authClient).fetchMyRatings(7),
      isEmpty,
    );
    expect(publicAdapter.request!.path, '/v8/members/7/ratings');
    expect(publicAdapter.request!.headers['Authorization'], isNull);
  });
}
