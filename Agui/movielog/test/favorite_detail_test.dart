import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/core/network/auth_interceptor.dart';
import 'package:movielog/core/session/auth_session_bridge.dart';
import 'package:movielog/core/storage/token_storage.dart';
import 'package:movielog/data/models/login_models.dart';
import 'package:movielog/data/models/member_info.dart';
import 'package:movielog/data/services/auth_api_service.dart';
import 'package:movielog/data/services/favorite_api_service.dart';
import 'package:movielog/data/services/member_api_service.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/view_models/favorite_detail_view_model.dart';

class _Storage implements TokenStorage {
  String? token = 'test-token';
  int reads = 0;
  int deletes = 0;
  @override
  Future<String?> readAccessToken() async {
    reads++;
    return token;
  }

  @override
  Future<void> saveAccessToken(String value) async => token = value;
  @override
  Future<void> deleteAccessToken() async {
    deletes++;
    token = null;
  }
}

final _member = MemberInfo(
  email: 'test@example.com',
  nickname: 'tester',
  createdAt: DateTime(2026),
);

class _AuthApi extends AuthApiService {
  _AuthApi() : super(Dio());
  @override
  Future<LoginResult> login(LoginRequest request) async =>
      const LoginResult(nickname: 'tester', accessToken: 'new-token');
}

class _MemberApi extends MemberApiService {
  _MemberApi() : super(Dio());
  @override
  Future<MemberInfo> fetchMe() async => _member;
}

ResponseBody _response(Object? result, {int status = 200, String? code}) =>
    ResponseBody.fromString(
      jsonEncode({
        'isSuccess': status < 400,
        'code': code ?? 'COMMON$status',
        'message': 'test',
        'result': result,
      }),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );

class _Adapter implements HttpClientAdapter {
  bool favorite = false;
  final requests = <RequestOptions>[];
  Future<ResponseBody> Function(RequestOptions)? respond;

  ResponseBody normal(RequestOptions options) {
    if (options.method == 'POST') {
      favorite = true;
      return _response({
        'favoriteId': 3,
        'movieId': 550,
        'createdAt': '2026-11-26T00:00:00Z',
      }, status: 201);
    }
    if (options.method == 'DELETE') {
      favorite = false;
      return _response(null);
    }
    return _response({'isFavorite': favorite});
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return respond == null ? normal(options) : await respond!(options);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _Storage storage;
  late _Adapter adapter;
  late Dio dio;
  late AuthViewModel auth;
  late AuthSessionBridge bridge;
  late FavoriteApiService service;
  late FavoriteDetailViewModel vm;

  setUp(() {
    storage = _Storage();
    adapter = _Adapter();
    auth = AuthViewModel(_AuthApi(), _MemberApi(), storage)
      ..status = AuthStatus.signedIn
      ..member = _member;
    final interceptor = AuthInterceptor(storage)
      ..bindSession(
        sessionVersion: () => auth.sessionVersion,
        onSessionExpired: auth.expireSessionIfCurrent,
      );
    dio = Dio(BaseOptions(baseUrl: 'https://workbook.devnoco.com'))
      ..interceptors.add(interceptor)
      ..httpClientAdapter = adapter;
    bridge = AuthSessionBridge(
      authSignals: auth,
      sessionVersion: () => auth.sessionVersion,
      verifiedEmail: () =>
          auth.status == AuthStatus.signedIn ? auth.member?.email : null,
    );
    service = FavoriteApiService(dio);
    vm = FavoriteDetailViewModel(
      movieId: 550,
      favoriteApi: service,
      sessionGuard: bridge.guard,
      accountId: _member.email,
    );
  });
  tearDown(() {
    if (!vm.isDisposed) vm.dispose();
    bridge.dispose();
    auth.dispose();
    dio.close(force: true);
  });

  test(
    'GET/POST/DELETE use movieId, JWT and CommonResponse contracts',
    () async {
      await vm.load();
      expect(vm.hasLoadedStatus, isTrue);
      expect(vm.isFavorite, isFalse);
      expect(await vm.toggle(), '즐겨찾기에 추가했습니다.');
      await vm.load();
      expect(vm.isFavorite, isTrue);
      expect(await vm.toggle(), '즐겨찾기에서 삭제했습니다.');
      expect(vm.isFavorite, isFalse);
      expect(adapter.requests.map((r) => (r.method, r.path)).toList(), [
        ('GET', '/v8/favorites/550'),
        ('POST', '/v8/favorites'),
        ('GET', '/v8/favorites/550'),
        ('DELETE', '/v8/favorites/550'),
      ]);
      expect(adapter.requests[1].data, {'movieId': 550});
      for (final request in adapter.requests) {
        expect(request.headers['Authorization'], 'Bearer test-token');
      }
    },
  );

  test('pending save preserves the icon and rejects duplicate taps', () async {
    await vm.load();
    final entered = Completer<void>(), gate = Completer<void>();
    adapter.respond = (options) async {
      entered.complete();
      await gate.future;
      return adapter.normal(options);
    };
    final saving = vm.toggle();
    await entered.future;
    expect(vm.isSaving, isTrue);
    expect(vm.isFavorite, isFalse);
    expect(await vm.toggle(), isNull);
    gate.complete();
    await saving;
    expect(vm.isFavorite, isTrue);
    expect(vm.isSaving, isFalse);
    expect(adapter.requests.where((r) => r.method == 'POST').length, 1);
  });

  test(
    'timeout keeps prior state and never repeats POST automatically',
    () async {
      await vm.load();
      adapter.respond = (options) async {
        adapter.favorite =
            true; // The server may have committed before timeout.
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.receiveTimeout,
        );
      };
      expect(await vm.toggle(), '즐겨찾기 등록에 실패했습니다.');
      expect(vm.isFavorite, isFalse);
      expect(auth.status, AuthStatus.signedIn);
      expect(adapter.requests.where((r) => r.method == 'POST').length, 1);
      adapter.respond = null;
      await vm.load();
      expect(vm.isFavorite, isTrue);
    },
  );

  for (final conflict in [(409, 'FAVORITE409_1'), (404, 'FAVORITE404_1')]) {
    test(
      '${conflict.$2} resynchronizes by GET instead of repeating the write',
      () async {
        adapter.favorite = conflict.$1 == 404;
        await vm.load();
        adapter.respond = (options) async {
          if (options.method != 'GET') {
            adapter.favorite = conflict.$1 == 409;
            return _response(null, status: conflict.$1, code: conflict.$2);
          }
          return adapter.normal(options);
        };
        await vm.toggle();
        expect(vm.isFavorite, conflict.$1 == 409);
        expect(vm.errorMessage, isNull);
        expect(adapter.requests.length, 3);
        expect(adapter.requests.last.method, 'GET');
      },
    );
  }

  test('MEMBER404_1 is distinct from an absent favorite', () async {
    await vm.load();
    adapter.respond = (_) async =>
        _response(null, status: 404, code: 'MEMBER404_1');
    expect(await vm.toggle(), '회원 정보를 찾을 수 없습니다.');
    expect(adapter.requests.length, 2);
    expect(vm.isFavorite, isFalse);
  });

  test(
    'failed initial status disables writes until a successful retry',
    () async {
      adapter.respond = (_) async => _response(null, status: 500);
      await vm.load();
      expect(vm.hasLoadedStatus, isFalse);
      expect(vm.isLoading, isFalse);
      expect(await vm.toggle(), isNull);
      adapter.respond = null;
      await vm.load();
      expect(vm.hasLoadedStatus, isTrue);
      expect(vm.errorMessage, isNull);
    },
  );

  test(
    'old response and old ViewModel cannot act in a new same-email session',
    () async {
      final entered = Completer<void>(), gate = Completer<void>();
      adapter.respond = (options) async {
        entered.complete();
        await gate.future;
        return _response({'isFavorite': true});
      };
      final loading = vm.load();
      await entered.future;
      await auth.logout();
      await auth.login(_member.email, 'password');
      await auth.loadMember();
      gate.complete();
      await loading;
      expect(vm.isCurrent, isFalse);
      expect(vm.hasLoadedStatus, isFalse);
      final count = adapter.requests.length;
      await vm.load();
      expect(adapter.requests.length, count);
    },
  );

  test(
    'dispose while saving suppresses result and later notifications',
    () async {
      await vm.load();
      final entered = Completer<void>(), gate = Completer<void>();
      adapter.respond = (options) async {
        entered.complete();
        await gate.future;
        return adapter.normal(options);
      };
      var notifications = 0;
      vm.addListener(() => notifications++);
      final saving = vm.toggle();
      await entered.future;
      vm.dispose();
      final before = notifications;
      gate.complete();
      expect(await saving, isNull);
      expect(notifications, before);
    },
  );

  test(
    'simultaneous expired-token responses clear the current session once',
    () async {
      final entered = Completer<void>(), gate = Completer<void>();
      var count = 0;
      adapter.respond = (_) async {
        if (++count == 2) entered.complete();
        await gate.future;
        return _response(null, status: 401, code: 'AUTH401_4');
      };
      final checking = expectLater(
        Future.wait([
          service.checkFavorite(movieId: 550),
          service.checkFavorite(movieId: 550),
        ]),
        throwsA(isA<DioException>()),
      );
      await entered.future;
      gate.complete();
      await checking;
      expect(auth.status, AuthStatus.signedOut);
      expect(storage.token, isNull);
      expect(storage.deletes, 1);
      expect(bridge.guard.accountId, isNull);
    },
  );

  test(
    'late 401 from a prior session cannot log out a newly logged in account',
    () async {
      final entered = Completer<void>(), gate = Completer<void>();
      adapter.respond = (_) async {
        entered.complete();
        await gate.future;
        return _response(null, status: 401, code: 'AUTH401_4');
      };
      final checking = expectLater(
        service.checkFavorite(movieId: 550),
        throwsA(isA<DioException>()),
      );
      await entered.future;
      await auth.logout();
      await auth.login(_member.email, 'password');
      await auth.loadMember();
      gate.complete();
      await checking;
      expect(auth.status, AuthStatus.signedIn);
      expect(storage.token, 'new-token');
      expect(storage.deletes, 1); // Only the explicit logout.
      expect(auth.sessionExpired, isFalse);
    },
  );

  for (final error in [(403, 'RATING403_1'), (401, 'AUTH401_1')]) {
    test('${error.$2} does not expire the session', () async {
      adapter.respond = (_) async =>
          _response(null, status: error.$1, code: error.$2);
      await vm.load();
      expect(auth.status, AuthStatus.signedIn);
      expect(storage.token, 'test-token');
      expect(storage.deletes, 0);
    });
  }

  test('nickname changes preserve the verified session generation', () {
    final generation = bridge.guard.generation;
    auth.updateMember(
      MemberInfo(
        email: _member.email,
        nickname: 'new nickname',
        createdAt: _member.createdAt,
      ),
    );
    expect(bridge.guard.generation, generation);
    expect(vm.isCurrent, isTrue);
  });

  test(
    'public paths and TMDB never read or receive the MovieLog JWT',
    () async {
      for (final path in [
        '/v8/auth/login',
        '/v8/members/nickname/test',
        'https://api.themoviedb.org/3/movie/550',
      ]) {
        await dio.get<dynamic>(path);
        expect(adapter.requests.last.headers['Authorization'], isNull);
      }
      expect(storage.reads, 0);
    },
  );

  test('DELETE 204 is not accepted as the v8 success contract', () async {
    adapter.respond = (_) async => _response(null, status: 204);
    await expectLater(
      service.deleteFavorite(movieId: 550),
      throwsA(isA<FormatException>()),
    );
  });

  test(
    'my favorites parses an array inside result, including an empty array',
    () async {
      adapter.respond = (_) async => _response([]);
      expect(await service.fetchMyFavorites(), isEmpty);
      adapter.respond = (_) async => _response([
        {'favoriteId': 7, 'movieId': 550, 'createdAt': '2026-11-26T00:00:00Z'},
      ]);
      expect((await service.fetchMyFavorites()).single.movieId, 550);
    },
  );
}
