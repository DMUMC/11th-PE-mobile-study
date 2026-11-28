import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' show TextFormField;
import 'package:provider/provider.dart';
import 'package:movielog/auth/login_screen.dart';
import 'package:movielog/core/session/session_guard.dart';
import 'package:movielog/main.dart';
import 'package:movielog/widgets/movielog_button.dart';
import 'package:movielog/core/storage/token_storage.dart';
import 'package:movielog/data/models/login_models.dart';
import 'package:movielog/data/models/member_info.dart';
import 'package:movielog/data/services/auth_api_service.dart';
import 'package:movielog/data/services/member_api_service.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class MemoryStorage implements TokenStorage {
  String? token;
  @override
  Future<void> saveAccessToken(String token) async => this.token = token;
  @override
  Future<String?> readAccessToken() async => token;
  @override
  Future<void> deleteAccessToken() async => token = null;
}

class FakeAuthApi extends AuthApiService {
  FakeAuthApi() : super(Dio());
  @override
  Future<LoginResult> login(LoginRequest request) async =>
      const LoginResult(nickname: 'tester', accessToken: 'test-token');
}

class FakeMemberApi extends MemberApiService {
  FakeMemberApi() : super(Dio());
  Future<MemberInfo> Function()? response;
  @override
  Future<MemberInfo> fetchMe() => response!();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });
  testWidgets('app opens login when no token is stored', (tester) async {
    const channel = MethodChannel(
      'plugins.it_nomads.com/flutter_secure_storage',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => null);
    await tester.pumpWidget(const MovieLogApp());
    await tester.pumpAndSettle();
    expect(find.text('MovieLog에 로그인'), findsOneWidget);
    // Read the actual app's lazy provider, as the detail loader does.
    // A plain Provider<SessionGuard> would throw for ChangeNotifier here.
    final loginContext = tester.element(find.byType(LoginScreen));
    expect(loginContext.read<SessionGuard>().accountId, isNull);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byType(MovieLogButton));
    await tester.pumpAndSettle();
    expect(find.text('이메일을 입력해 주세요.'), findsOneWidget);
    await tester.enterText(
      find.byType(TextFormField).first,
      'movie@example.com',
    );
    await tester.pumpAndSettle();
    expect(find.text('이메일을 입력해 주세요.'), findsNothing);
    expect(find.text('비밀번호를 입력해 주세요.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
  final member = MemberInfo(
    email: 'test@example.com',
    nickname: 'tester',
    createdAt: DateTime(2026),
  );
  test('restoration waits for server verification', () async {
    final storage = MemoryStorage()..token = 'test-token';
    final completer = Completer<MemberInfo>();
    final api = FakeMemberApi()..response = () => completer.future;
    final auth = AuthViewModel(FakeAuthApi(), api, storage);
    final restoring = auth.restoreSession();
    await Future<void>.delayed(Duration.zero);
    expect(auth.status, AuthStatus.initializing);
    completer.complete(member);
    await restoring;
    expect(auth.status, AuthStatus.signedIn);
    expect(auth.member, member);
    auth.dispose();
  });
  test('network failure keeps stored token and offers retry', () async {
    final storage = MemoryStorage()..token = 'test-token';
    final api = FakeMemberApi()
      ..response = () async => throw DioException(
        requestOptions: RequestOptions(path: '/v8/members/me'),
      );
    final auth = AuthViewModel(FakeAuthApi(), api, storage);
    await auth.restoreSession();
    expect(auth.status, AuthStatus.retryRequired);
    expect(storage.token, 'test-token');
    auth.dispose();
  });
  test('old member response does not repopulate logged out session', () async {
    final storage = MemoryStorage();
    final pending = Completer<MemberInfo>();
    final api = FakeMemberApi()..response = () => pending.future;
    final auth = AuthViewModel(FakeAuthApi(), api, storage);
    await auth.login('test@example.com', 'password');
    final loading = auth.loadMember();
    await auth.logout();
    pending.complete(member);
    await loading;
    expect(auth.status, AuthStatus.signedOut);
    expect(auth.member, isNull);
    expect(storage.token, isNull);
    auth.dispose();
  });
}
