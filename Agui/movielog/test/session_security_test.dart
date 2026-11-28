import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/core/storage/token_storage.dart';
import 'package:movielog/data/models/login_models.dart';
import 'package:movielog/data/models/member_info.dart';
import 'package:movielog/data/services/auth_api_service.dart';
import 'package:movielog/data/services/member_api_service.dart';
import 'package:movielog/view_models/auth_view_model.dart';

class _Storage implements TokenStorage {
  String? token = 'token';
  int deletes = 0;
  @override
  Future<String?> readAccessToken() async => token;
  @override
  Future<void> saveAccessToken(String value) async => token = value;
  @override
  Future<void> deleteAccessToken() async {
    deletes++;
    token = null;
  }
}

class _AuthApi extends AuthApiService {
  _AuthApi() : super(Dio());
  @override
  Future<LoginResult> login(LoginRequest request) async =>
      const LoginResult(nickname: 'tester', accessToken: 'new-token');
}

class _MemberApi extends MemberApiService {
  _MemberApi() : super(Dio());
  DioException? error;
  @override
  Future<MemberInfo> fetchMe() async {
    if (error != null) throw error!;
    return MemberInfo(
      email: 'a@example.com',
      nickname: 'tester',
      createdAt: DateTime(2026),
    );
  }
}

DioException _error(int? status, String code) {
  final request = RequestOptions(path: '/v8/members/me');
  return DioException(
    requestOptions: request,
    type: status == null
        ? DioExceptionType.connectionError
        : DioExceptionType.badResponse,
    response: status == null
        ? null
        : Response<dynamic>(
            requestOptions: request,
            statusCode: status,
            data: {'code': code},
          ),
  );
}

void main() {
  late _Storage storage;
  late _MemberApi memberApi;
  late AuthViewModel auth;
  setUp(() {
    storage = _Storage();
    memberApi = _MemberApi();
    auth = AuthViewModel(_AuthApi(), memberApi, storage);
  });
  tearDown(() => auth.dispose());

  for (final status in [null, 403]) {
    test('$status during restore retains token and offers retry', () async {
      memberApi.error = _error(status, 'AUTH401_4');
      await auth.restoreSession();
      expect(auth.status, AuthStatus.retryRequired);
      expect(storage.token, 'token');
      expect(storage.deletes, 0);
      expect(auth.sessionExpired, isFalse);
      memberApi.error = null;
      await auth.restoreSession();
      expect(auth.status, AuthStatus.signedIn);
    });

    test('$status during member refresh preserves signed-in session', () async {
      await auth.restoreSession();
      final version = auth.sessionVersion;
      memberApi.error = _error(status, 'AUTH401_4');
      await auth.loadMember(force: true);
      expect(auth.status, AuthStatus.signedIn);
      expect(auth.sessionVersion, version);
      expect(auth.member?.email, 'a@example.com');
      expect(auth.memberStatus, MemberLoadStatus.error);
      expect(storage.token, 'token');
      expect(storage.deletes, 0);
    });
  }

  for (final code in ['AUTH401_2', 'AUTH401_3', 'AUTH401_4']) {
    test('$code during restore clears current session once', () async {
      memberApi.error = _error(401, code);
      await auth.restoreSession();
      expect(auth.status, AuthStatus.signedOut);
      expect(auth.member, isNull);
      expect(auth.sessionExpired, isTrue);
      expect(storage.token, isNull);
      expect(storage.deletes, 1);
    });

    test('$code during member refresh clears current session once', () async {
      await auth.restoreSession();
      final version = auth.sessionVersion;
      memberApi.error = _error(401, code);
      await auth.loadMember(force: true);
      await auth.expireSessionIfCurrent(version);
      expect(auth.status, AuthStatus.signedOut);
      expect(auth.member, isNull);
      expect(auth.sessionExpired, isTrue);
      expect(storage.deletes, 1);
    });
  }
}
