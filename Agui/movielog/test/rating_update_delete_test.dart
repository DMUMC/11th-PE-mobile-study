import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/core/network/auth_interceptor.dart';
import 'package:movielog/core/storage/token_storage.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/services/auth_api_service.dart';
import 'package:movielog/data/services/member_api_service.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';

class _Storage implements TokenStorage {
  String? token = 'test-token';
  @override
  Future<String?> readAccessToken() async => token;
  @override
  Future<void> saveAccessToken(String token) async => this.token = token;
  @override
  Future<void> deleteAccessToken() async => token = null;
}

class _Adapter implements HttpClientAdapter {
  RequestOptions? request;
  int status = 200;
  Object body = {
    'isSuccess': true,
    'code': 'OK',
    'message': 'ok',
    'result': null,
  };
  Completer<void>? gate;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    if (gate != null) await gate!.future;
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
  late _Storage storage;
  late _Adapter adapter;
  late Dio publicDio;
  late Dio authDio;
  late AuthViewModel auth;
  late MyRatingsViewModel model;
  final rating = RatingDto(
    ratingId: 12,
    movieId: 550,
    score: 3,
    comment: '기존 후기',
    createdAt: DateTime(2026),
  );
  setUp(() {
    storage = _Storage();
    adapter = _Adapter();
    publicDio = Dio(BaseOptions(baseUrl: 'https://workbook.devnoco.com'));
    authDio = Dio(BaseOptions(baseUrl: 'https://workbook.devnoco.com'))
      ..interceptors.add(AuthInterceptor(storage))
      ..httpClientAdapter = adapter;
    auth = AuthViewModel(
      AuthApiService(publicDio),
      MemberApiService(authDio),
      storage,
    )..status = AuthStatus.signedIn;
    auth.saveSessionRating(rating);
    model = MyRatingsViewModel(RatingApiService(publicDio, authDio), auth);
  });
  tearDown(() {
    model.dispose();
    auth.dispose();
    publicDio.close();
    authDio.close();
  });

  test('PATCH sends both fields and replaces current session rating', () async {
    adapter.body = {
      'isSuccess': true,
      'code': 'OK',
      'message': 'ok',
      'result': {
        'ratingId': 12,
        'movieId': 550,
        'score': 5,
        'comment': '변경된 후기',
        'createdAt': '2026-11-20T10:00:00',
      },
    };
    await model.updateRating(ratingId: 12, score: 5, comment: '변경된 후기');
    expect(adapter.request!.method, 'PATCH');
    expect(adapter.request!.path, '/v7/ratings/12');
    expect(adapter.request!.data, {'score': 5, 'comment': '변경된 후기'});
    expect(adapter.request!.headers['Authorization'], 'Bearer test-token');
    expect(model.ratings.single.rating.score, 5);
    expect(model.ratings.single.rating.comment, '변경된 후기');
  });
  test(
    'DELETE requires 200 with successful null result before removing card',
    () async {
      await model.deleteRating(12);
      expect(adapter.request!.method, 'DELETE');
      expect(adapter.request!.path, '/v7/ratings/12');
      expect(adapter.request!.headers['Authorization'], 'Bearer test-token');
      expect(model.ratings, isEmpty);
    },
  );
  test('invalid DELETE wrapper leaves card in session', () async {
    adapter.body = {
      'isSuccess': false,
      'code': 'ERROR',
      'message': 'failed',
      'result': null,
    };
    await expectLater(
      model.deleteRating(12),
      throwsA(isA<RatingWriteException>()),
    );
    expect(model.ratings.single.rating.ratingId, 12);
  });
  for (final error in [(403, 'RATING403_1'), (409, 'RATING409_1')]) {
    test('${error.$2} retains session and rating', () async {
      adapter.status = error.$1;
      adapter.body = {
        'isSuccess': false,
        'code': error.$2,
        'message': 'error',
        'result': null,
      };
      await expectLater(
        model.deleteRating(12),
        throwsA(isA<RatingWriteException>()),
      );
      expect(auth.status, AuthStatus.signedIn);
      expect(model.ratings.single.rating.ratingId, 12);
    });
  }
  test('404 removes missing rating from current session', () async {
    adapter.status = 404;
    adapter.body = {
      'isSuccess': false,
      'code': 'RATING404_1',
      'message': 'missing',
      'result': null,
    };
    await expectLater(
      model.deleteRating(12),
      throwsA(isA<RatingWriteException>()),
    );
    expect(auth.status, AuthStatus.signedIn);
    expect(model.ratings, isEmpty);
  });
  test('401 expires current session', () async {
    adapter.status = 401;
    adapter.body = {
      'isSuccess': false,
      'code': 'AUTH401_4',
      'message': 'expired',
      'result': null,
    };
    await expectLater(
      model.deleteRating(12),
      throwsA(isA<RatingWriteException>()),
    );
    expect(auth.status, AuthStatus.signedOut);
    expect(storage.token, isNull);
  });
  test('late response after logout cannot alter the session', () async {
    adapter.gate = Completer<void>();
    final pending = model.deleteRating(12);
    await Future<void>.delayed(Duration.zero);
    await auth.logout();
    adapter.gate!.complete();
    await expectLater(pending, throwsA(isA<RatingWriteException>()));
    expect(auth.status, AuthStatus.signedOut);
    expect(model.ratings, isEmpty);
  });
}
