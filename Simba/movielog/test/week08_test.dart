import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/core/network/api_logging_interceptor.dart';
import 'package:movielog/core/network/auth_interceptor.dart';
import 'package:movielog/core/storage/token_storage.dart';
import 'package:movielog/data/models/login_models.dart';
import 'package:movielog/data/models/member_info.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/models/rating_request.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/services/auth_api_service.dart';
import 'package:movielog/data/services/member_api_service.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/view_models/edit_profile_view_model.dart';
import 'package:movielog/view_models/movie_detail_view_model.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';
import 'package:movielog/view_models/session_ratings_store.dart';

DioException apiError(int status, String code, String message) {
  final options = RequestOptions(path: '/');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response(
      requestOptions: options,
      statusCode: status,
      data: {
        'isSuccess': false,
        'code': code,
        'message': message,
        'result': null,
      },
    ),
  );
}

DioException networkError() => DioException(
  requestOptions: RequestOptions(path: '/'),
  type: DioExceptionType.connectionError,
);

class MemoryTokenStorage implements TokenStorage {
  String? token;
  bool failRead = false;

  @override
  Future<void> saveAccessToken(String value) async => token = value;

  @override
  Future<String?> readAccessToken() async {
    if (failRead) throw Exception('keystore');
    return token;
  }

  @override
  Future<void> deleteAccessToken() async => token = null;
}

class FakeAuthApi implements AuthApiService {
  Future<LoginResult> Function(LoginRequest)? onLogin;

  @override
  Future<LoginResult> login(LoginRequest request) => onLogin!(request);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final me = MemberInfo(
  email: 'simba@umc.com',
  nickname: '심바',
  createdAt: DateTime.utc(2026, 10, 10, 3),
);

class FakeMemberApi implements MemberApiService {
  Object? fetchError;
  Object? updateError;
  int fetchCalls = 0;
  int updateCalls = 0;

  @override
  Future<MemberInfo> fetchMe() async {
    fetchCalls++;
    if (fetchError != null) throw fetchError!;
    return me;
  }

  @override
  Future<MemberInfo> updateNickname(String nickname) async {
    updateCalls++;
    if (updateError != null) throw updateError!;
    return MemberInfo(
      email: me.email,
      nickname: nickname,
      createdAt: me.createdAt,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

RatingDto rating(int id, {int movieId = 550, int score = 4, String? comment}) =>
    RatingDto.fromJson({
      'ratingId': id,
      'movieId': movieId,
      'score': score,
      'comment': comment,
      'createdAt': '2026-11-22T10:00:00.000Z',
    });

class FakeRatingApi implements RatingApiService {
  Object? createError;
  Object? updateError;
  Object? Function(int ratingId)? deleteError;
  final createdBodies = <Map<String, dynamic>>[];
  var nextId = 100;

  @override
  Future<RatingDto> createRating(CreateRatingRequest request) async {
    if (createError != null) throw createError!;
    createdBodies.add(request.toJson());
    return rating(
      nextId++,
      movieId: request.movieId,
      score: request.score,
      comment: request.comment,
    );
  }

  @override
  Future<RatingDto> updateRating({
    required int ratingId,
    required UpdateRatingRequest request,
  }) async {
    if (updateError != null) throw updateError!;
    return rating(ratingId, score: request.score, comment: request.comment);
  }

  @override
  Future<void> deleteRating(int ratingId) async {
    final error = deleteError?.call(ratingId);
    if (error != null) throw error;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeTmdb implements TmdbMovieService {
  @override
  Future<TmdbMovieDto?> findMovieById(int movieId) async => movieId == 404
      ? null
      : TmdbMovieDto.fromJson({'id': movieId, 'title': '영화 $movieId'});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('authRedirect', () {
    test('초기화·재시도 중에는 스플래시만', () {
      expect(authRedirect(AuthStatus.initializing, '/home'), '/start');
      expect(authRedirect(AuthStatus.retryRequired, '/login'), '/start');
      expect(authRedirect(AuthStatus.initializing, '/start'), isNull);
    });

    test('로그아웃 상태는 공개 화면만, 보호 화면은 /login', () {
      expect(authRedirect(AuthStatus.signedOut, '/my'), '/login');
      expect(authRedirect(AuthStatus.signedOut, '/my/ratings'), '/login');
      expect(authRedirect(AuthStatus.signedOut, '/register'), isNull);
      expect(authRedirect(AuthStatus.authenticating, '/login'), isNull);
    });

    test('로그인 상태에서 스플래시·로그인·회원가입은 /home', () {
      expect(authRedirect(AuthStatus.signedIn, '/start'), '/home');
      expect(authRedirect(AuthStatus.signedIn, '/login'), '/home');
      expect(authRedirect(AuthStatus.signedIn, '/my/profile/edit'), isNull);
    });
  });

  group('AuthInterceptor', () {
    Future<RequestOptions> run(
      AuthInterceptor interceptor,
      RequestOptions options,
    ) async {
      final dio = Dio()..interceptors.add(interceptor);
      RequestOptions? seen;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) {
            seen = o;
            h.reject(
              DioException(requestOptions: o, type: DioExceptionType.cancel),
            );
          },
        ),
      );
      try {
        await dio.fetch(options);
      } on DioException catch (_) {}
      return seen ?? options;
    }

    test('보호 host/path에만 Bearer를 붙인다', () {
      expect(
        AuthInterceptor.isProtected(
          Uri.parse('https://workbook.devnoco.com/v7/members/me'),
        ),
        isTrue,
      );
      expect(
        AuthInterceptor.isProtected(
          Uri.parse('https://workbook.devnoco.com/v7/ratings/3'),
        ),
        isTrue,
      );
      expect(
        AuthInterceptor.isProtected(
          Uri.parse('https://workbook.devnoco.com/v7/members/1/ratings'),
        ),
        isFalse,
      );
      expect(
        AuthInterceptor.isProtected(
          Uri.parse('https://workbook.devnoco.com/v7/auth/login'),
        ),
        isFalse,
      );
      expect(
        AuthInterceptor.isProtected(
          Uri.parse('https://api.themoviedb.org/v7/ratings'),
        ),
        isFalse,
      );
    });

    test('보호 요청에는 저장된 토큰을, 공개 요청에는 아무것도 붙이지 않는다', () async {
      final storage = MemoryTokenStorage()..token = 'jwt-abc';
      final interceptor = AuthInterceptor(storage);
      final protected = await run(
        interceptor,
        RequestOptions(path: 'https://workbook.devnoco.com/v7/members/me'),
      );
      expect(protected.headers['Authorization'], 'Bearer jwt-abc');

      final public = await run(
        interceptor,
        RequestOptions(
          path: 'https://workbook.devnoco.com/v7/auth/login',
          headers: {'Authorization': 'Bearer stale'},
        ),
      );
      expect(public.headers.containsKey('Authorization'), isFalse);
    });

    test('로그 body의 accessToken·password는 마스킹한다', () {
      final masked = ApiLoggingInterceptor.maskSensitive({
        'code': 'COMMON200',
        'result': {'nickname': '심바', 'accessToken': 'eyJ.secret'},
      });
      expect((masked as Map)['result'], {
        'nickname': '심바',
        'accessToken': '***',
      });
    });
  });

  group('AuthViewModel', () {
    late MemoryTokenStorage storage;
    late FakeAuthApi authApi;
    late FakeMemberApi memberApi;
    late SessionRatingsStore store;
    late AuthViewModel auth;

    setUp(() {
      storage = MemoryTokenStorage();
      authApi = FakeAuthApi();
      memberApi = FakeMemberApi();
      store = SessionRatingsStore();
      auth = AuthViewModel(
        authApi,
        memberApi,
        storage,
        onSessionReset: store.clear,
      );
    });

    test('재시작: 토큰이 없으면 signedOut', () async {
      await auth.restoreSession();
      expect(auth.status, AuthStatus.signedOut);
      expect(memberApi.fetchCalls, 0);
    });

    test('재시작: 토큰이 있어도 GET me 검증 뒤에만 signedIn', () async {
      storage.token = 'jwt';
      await auth.restoreSession();
      expect(auth.status, AuthStatus.signedIn);
      expect(auth.member?.nickname, '심바');
    });

    test('재시작: 만료 토큰(AUTH401_4)은 지우고 만료 안내를 켠다', () async {
      storage.token = 'expired';
      memberApi.fetchError = apiError(401, 'AUTH401_4', '토큰이 만료되었습니다.');
      await auth.restoreSession();
      expect(auth.status, AuthStatus.signedOut);
      expect(auth.sessionExpired, isTrue);
      expect(storage.token, isNull);
    });

    test('재시작: 네트워크 실패는 토큰을 지우지 않고 재시도 상태', () async {
      storage.token = 'jwt';
      memberApi.fetchError = networkError();
      await auth.restoreSession();
      expect(auth.status, AuthStatus.retryRequired);
      expect(storage.token, 'jwt');
    });

    test('재시작: 저장소 읽기 실패도 재시도 상태', () async {
      storage.failRead = true;
      await auth.restoreSession();
      expect(auth.status, AuthStatus.retryRequired);
      expect(auth.message, contains('저장소'));
    });

    test('로그인 성공: 토큰 저장 → signedIn, 이전 세션 평점은 비운다', () async {
      store.upsert(rating(1));
      authApi.onLogin = (_) async =>
          const LoginResult(nickname: '심바', accessToken: 'new-jwt');
      await auth.login('simba@umc.com', 'Umc1234!');
      expect(auth.status, AuthStatus.signedIn);
      expect(storage.token, 'new-jwt');
      expect(store.isEmpty, isTrue);
    });

    test('로그인 실패(AUTH401_1)는 Form 문구만, 만료 안내는 켜지 않는다', () async {
      authApi.onLogin = (_) async =>
          throw apiError(401, 'AUTH401_1', '이메일 또는 비밀번호가 올바르지 않습니다.');
      await auth.login('a@b.com', 'wrong');
      expect(auth.status, AuthStatus.signedOut);
      expect(auth.message, '이메일 또는 비밀번호를 확인해 주세요.');
      expect(auth.sessionExpired, isFalse);
    });

    test('loadMember: 네트워크 실패는 로그아웃하지 않고, 401은 세션 정리', () async {
      authApi.onLogin = (_) async =>
          const LoginResult(nickname: '심바', accessToken: 'jwt');
      await auth.login('a@b.com', 'pw');

      memberApi.fetchError = networkError();
      await auth.loadMember();
      expect(auth.memberStatus, MemberLoadStatus.error);
      expect(auth.status, AuthStatus.signedIn);

      memberApi.fetchError = apiError(401, 'AUTH401_3', '유효하지 않은 토큰입니다.');
      await auth.loadMember(force: true);
      expect(auth.status, AuthStatus.signedOut);
      expect(auth.sessionExpired, isTrue);
    });

    test('직접 로그아웃은 만료 안내를 켜지 않고 토큰·평점을 지운다', () async {
      authApi.onLogin = (_) async =>
          const LoginResult(nickname: '심바', accessToken: 'jwt');
      await auth.login('a@b.com', 'pw');
      store.upsert(rating(1));
      await auth.logout();
      expect(auth.status, AuthStatus.signedOut);
      expect(auth.sessionExpired, isFalse);
      expect(storage.token, isNull);
      expect(store.isEmpty, isTrue);
    });

    test('이전 세션의 늦은 401은 새 세션을 지우지 않는다', () async {
      authApi.onLogin = (_) async =>
          const LoginResult(nickname: '심바', accessToken: 'jwt');
      await auth.login('a@b.com', 'pw');
      final oldVersion = auth.sessionVersion;
      await auth.logout();
      await auth.login('b@b.com', 'pw');
      await auth.expireSession(sessionVersion: oldVersion);
      expect(auth.status, AuthStatus.signedIn);
    });
  });

  group('EditProfileViewModel', () {
    late MemoryTokenStorage storage;
    late FakeMemberApi memberApi;
    late AuthViewModel auth;
    late EditProfileViewModel vm;

    setUp(() async {
      storage = MemoryTokenStorage()..token = 'jwt';
      memberApi = FakeMemberApi();
      auth = AuthViewModel(FakeAuthApi(), memberApi, storage);
      await auth.restoreSession();
      vm = EditProfileViewModel(memberApi, auth);
    });

    test('2~12자 검증은 요청 전에, 같은 닉네임은 요청 없이 완료', () async {
      expect(await vm.save('a'), isFalse);
      expect(vm.nicknameError, isNotNull);
      expect(await vm.save('심바'), isTrue);
      expect(memberApi.updateCalls, 0);
    });

    test('성공하면 AuthViewModel.member를 교체한다', () async {
      expect(await vm.save('새닉네임'), isTrue);
      expect(auth.member?.nickname, '새닉네임');
    });

    test('MEMBER409_1은 필드 오류, 네트워크 실패는 Snackbar 문구 + 로그인 유지', () async {
      memberApi.updateError = apiError(409, 'MEMBER409_1', '이미 사용 중인 닉네임입니다.');
      expect(await vm.save('영화광'), isFalse);
      expect(vm.nicknameError, '이미 사용 중인 닉네임이에요.');

      memberApi.updateError = networkError();
      expect(await vm.save('영화광2'), isFalse);
      expect(vm.message, contains('네트워크'));
      expect(auth.status, AuthStatus.signedIn);
    });

    test('401이면 세션을 정리한다', () async {
      memberApi.updateError = apiError(401, 'AUTH401_4', '토큰이 만료되었습니다.');
      expect(await vm.save('새닉네임'), isFalse);
      expect(auth.status, AuthStatus.signedOut);
    });

    test('(Challenge) 변경 여부', () {
      expect(vm.isDirty(' 심바 '), isFalse);
      expect(vm.isDirty('심바2'), isTrue);
    });
  });

  group('토큰 기반 평점', () {
    late MemoryTokenStorage storage;
    late SessionRatingsStore store;
    late AuthViewModel auth;
    late FakeRatingApi api;
    final movie = TmdbMovieDto.fromJson({'id': 550, 'title': '파이트 클럽'});

    setUp(() async {
      storage = MemoryTokenStorage()..token = 'jwt';
      store = SessionRatingsStore();
      auth = AuthViewModel(
        FakeAuthApi(),
        FakeMemberApi(),
        storage,
        onSessionReset: store.clear,
      );
      await auth.restoreSession();
      api = FakeRatingApi();
    });

    test('등록 body에 memberId가 없고, result Rating으로 내 목록을 갱신한다', () async {
      final vm = MovieDetailViewModel(api, auth, store, movie);
      await vm.createRating(score: 5, comment: '최고');
      expect(api.createdBodies.single, {
        'movieId': 550,
        'score': 5,
        'comment': '최고',
      });
      expect(store.ratings.single.movieId, 550);
    });

    test('RATING409_1은 안내만 하고 로그인 유지, 401은 세션 정리', () async {
      final vm = MovieDetailViewModel(api, auth, store, movie);
      api.createError = apiError(409, 'RATING409_1', '이미 이 영화에 평점을 남기셨습니다.');
      await vm.createRating(score: 4);
      expect(vm.submitMessage, contains('기존 기록'));
      expect(auth.status, AuthStatus.signedIn);

      api.createError = apiError(401, 'AUTH401_2', '로그인이 필요한 요청입니다.');
      await vm.createRating(score: 4);
      expect(auth.status, AuthStatus.signedOut);
    });

    test('수정 result로 교체, 403은 다시 던지고 목록·로그인 유지, 404는 목록에서 제거', () async {
      store.upsert(rating(1, comment: '원래'));
      store.upsert(rating(2, movieId: 404));
      final vm = MyRatingsViewModel(api, FakeTmdb(), store, auth);

      await vm.updateRating(ratingId: 1, score: 2, comment: '바뀜');
      expect(store.ratings.firstWhere((r) => r.ratingId == 1).comment, '바뀜');

      api.updateError = apiError(
        403,
        'RATING403_1',
        '본인이 작성한 평점만 수정하거나 삭제할 수 있습니다.',
      );
      await expectLater(
        vm.updateRating(ratingId: 1, score: 3),
        throwsA(isA<DioException>()),
      );
      expect(store.ratings.length, 2);
      expect(auth.status, AuthStatus.signedIn);

      api.updateError = apiError(404, 'RATING404_1', '해당 평점을 찾을 수 없습니다.');
      await expectLater(
        vm.updateRating(ratingId: 2, score: 3),
        throwsA(isA<DioException>()),
      );
      expect(store.ratings.map((r) => r.ratingId), [1]);
    });

    test('TMDB에 없는 movieId도 평점은 남고 영화 정보만 null', () async {
      store.upsert(rating(5, movieId: 404));
      final vm = MyRatingsViewModel(api, FakeTmdb(), store, auth);
      await Future<void>.delayed(Duration.zero);
      expect(vm.ratings.single.movie, isNull);
      expect(vm.ratings.single.rating.ratingId, 5);
    });

    test('다중 삭제 일부 실패: 실패 항목은 선택 유지', () async {
      store
        ..upsert(rating(1))
        ..upsert(rating(2))
        ..upsert(rating(3));
      api.deleteError = (id) => id == 2 ? networkError() : null;
      final vm = MyRatingsViewModel(api, FakeTmdb(), store, auth)
        ..enterEditMode()
        ..toggleSelection(1)
        ..toggleSelection(2);
      expect(await vm.deleteSelectedRatings(), 1);
      expect(store.ratings.map((r) => r.ratingId), [3, 2]);
      expect(vm.selectedRatingIds, {2});
      expect(vm.isEditMode, isTrue);
    });

    test('로그아웃하면 이 세션의 평점은 비워진다', () async {
      store.upsert(rating(1));
      await auth.logout();
      expect(store.isEmpty, isTrue);
    });
  });

  test('(Challenge) 가입일 표시', () {
    expect(me.joinedText, '2026.10.10 가입');
  });
}
