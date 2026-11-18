// Separate development entry point; not imported by the regular app.
// flutter run -t lib/dev/required_mission_main.dart --dart-define-from-file=.env
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../auth/sign_up_screen.dart';
import '../core/network/tmdb_client.dart';
import '../data/services/member_check_service.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';
import '../profile_screen/my_ratings_screen.dart';
import '../theme/app_theme.dart';
import '../view_models/my_ratings_view_model.dart';
import '../view_models/sign_up_view_model.dart';
import '../widgets/movielog_button.dart';

void main() => runApp(
  MaterialApp.router(
    debugShowCheckedModeBanner: false,
    title: 'Required Mission 기능 확인',
    theme: AppTheme.light,
    routerConfig: _router,
  ),
);

final _router = GoRouter(
  initialLocation: '/tools',
  routes: [
    GoRoute(path: '/start', redirect: (_, state) => '/tools'),
    GoRoute(path: '/home', redirect: (_, state) => '/tools'),
    GoRoute(
      path: '/tools',
      builder: (_, state) => const _MissionTools(),
      routes: [
        GoRoute(
          path: 'buttons',
          builder: (_, state) => const _ButtonExamples(),
        ),
        for (final scenario in _RatingsScenario.values)
          GoRoute(
            path: scenario.name,
            builder: (_, state) => _RatingsExample(scenario: scenario),
          ),
        GoRoute(
          path: 'signup',
          builder: (_, state) => MultiProvider(
            providers: [
              Provider<Dio>(
                create: (_) =>
                    Dio(BaseOptions(baseUrl: 'https://workbook.devnoco.com'))
                      ..httpClientAdapter = _SignupResponses(),
                dispose: (_, dio) => dio.close(force: true),
              ),
              ChangeNotifierProvider(
                create: (context) => SignUpViewModel(
                  MemberCheckService(context.read<Dio>()),
                  initialNickname: SignUpScreen.initialNickname,
                  initialEmail: SignUpScreen.initialEmail,
                ),
              ),
            ],
            child: const SignUpScreen(),
          ),
        ),
      ],
    ),
  ],
);

class _MissionTools extends StatelessWidget {
  const _MissionTools();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Required Mission 기능 확인')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('개발용 응답으로 기능을 확인합니다. 실제 서버 데이터는 변경하지 않습니다.'),
        const SizedBox(height: 24),
        for (final item in const [
          ('1. 버튼 너비와 상태', 'buttons'),
          ('2. 평점: 빈 목록', 'empty'),
          ('2. 평점: 오류 후 재시도', 'retry'),
          ('2. 평점: 영화 정보 일부 누락', 'partialMovie'),
          ('3. 회원가입: 확인 상태', 'signup'),
        ])
          ListTile(
            title: Text(item.$1),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/tools/${item.$2}'),
          ),
      ],
    ),
  );
}

class _ButtonExamples extends StatelessWidget {
  const _ButtonExamples();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('MovieLogButton 비교')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('같은 문구로 너비를 비교합니다.'),
        const SizedBox(height: 24),
        const Text('내용 크기 · width: null'),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: MovieLogButton(label: '확인', onPressed: () {}),
        ),
        const SizedBox(height: 24),
        const Text('전체 너비 · width: double.infinity'),
        const SizedBox(height: 8),
        MovieLogButton(label: '확인', width: double.infinity, onPressed: () {}),
        const SizedBox(height: 24),
        const Text('고정 너비 · width: 96'),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: MovieLogButton(label: '확인', width: 96, onPressed: () {}),
        ),
        const SizedBox(height: 32),
        const Text('기본 / 통신 중 / 비활성'),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            MovieLogButton(label: '확인', onPressed: () {}),
            MovieLogButton(label: '확인', isLoading: true, onPressed: () {}),
            const MovieLogButton(label: '확인', onPressed: null),
          ],
        ),
      ],
    ),
  );
}

enum _RatingsScenario { empty, retry, partialMovie }

class _RatingsExample extends StatelessWidget {
  const _RatingsExample({required this.scenario});

  final _RatingsScenario scenario;

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      Provider<Dio>(
        create: (_) =>
            Dio(BaseOptions(baseUrl: 'https://workbook.devnoco.com'))
              ..httpClientAdapter = _RatingResponses(scenario),
        dispose: (_, dio) => dio.close(force: true),
      ),
      Provider<TmdbMovieService>(
        create: (_) {
          final dio = createTmdbClient();
          if (scenario == _RatingsScenario.partialMovie) {
            dio.interceptors.add(
              InterceptorsWrapper(
                onRequest: (options, handler) {
                  if (options.path == '/movie/13') {
                    handler.reject(
                      DioException(
                        requestOptions: options,
                        type: DioExceptionType.connectionError,
                        message: 'Development-only movie lookup failure',
                      ),
                    );
                  } else {
                    handler.next(options);
                  }
                },
              ),
            );
          }
          return TmdbMovieService(dio);
        },
        dispose: (_, service) => service.close(),
      ),
      ChangeNotifierProvider(
        create: (context) => MyRatingsViewModel(
          RatingApiService(context.read<Dio>()),
          context.read<TmdbMovieService>(),
          sampleMemberId,
        )..load(),
      ),
    ],
    child: const MyRatingsScreen(),
  );
}

ResponseBody _jsonResponse(Object data, [int status = 200]) =>
    ResponseBody.fromString(
      jsonEncode(data),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );

class _RatingResponses implements HttpClientAdapter {
  _RatingResponses(this.scenario);

  final _RatingsScenario scenario;
  int _requests = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final request = ++_requests;
    await Future<void>.delayed(const Duration(seconds: 3));
    if (options.method != 'GET' || options.path != '/v5/members/1/ratings') {
      return _jsonResponse({
        'message': 'Outside the development scenario',
      }, 501);
    }
    if (scenario == _RatingsScenario.empty) return _jsonResponse([]);
    if (scenario == _RatingsScenario.retry && request == 1) {
      return _jsonResponse({
        'message': 'Development-only error',
        'error': 'Internal Server Error',
        'statusCode': 500,
      }, 500);
    }
    return _jsonResponse(_ratings);
  }

  @override
  void close({bool force = false}) {}
}

const _ratings = [
  {
    'ratingId': 3,
    'movieId': 13,
    'score': 3,
    'comment': null,
    'createdAt': '2026-11-14T00:00:00.000Z',
  },
  {
    'ratingId': 2,
    'movieId': 680,
    'score': 4,
    'comment': '다시 봐도 좋다',
    'createdAt': '2026-11-14T00:00:00.000Z',
  },
  {
    'ratingId': 1,
    'movieId': 550,
    'score': 5,
    'comment': '최고의 영화!',
    'createdAt': '2026-11-14T00:00:00.000Z',
  },
];

class _SignupResponses implements HttpClientAdapter {
  final _requests = <String, int>{};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final segments = options.uri.pathSegments;
    if (options.method != 'GET' ||
        segments.length != 4 ||
        segments[0] != 'v5' ||
        segments[1] != 'members' ||
        !{'nickname', 'email'}.contains(segments[2])) {
      return _jsonResponse({
        'message': 'Outside the development scenario',
      }, 501);
    }
    final field = segments[2];
    final value = segments[3];
    final request = _requests.update(
      field,
      (count) => count + 1,
      ifAbsent: () => 1,
    );
    await Future<void>.delayed(const Duration(seconds: 3));
    if (value.endsWith('e')) {
      debugPrint('[Required Mission] $field request=$request status=500');
      return _jsonResponse({
        'message': 'Development-only error',
        'error': 'Internal Server Error',
        'statusCode': 500,
      }, 500);
    }
    final available =
        value != SignUpScreen.initialNickname &&
        value != SignUpScreen.initialEmail;
    debugPrint(
      '[Required Mission] $field request=$request available=$available',
    );
    return _jsonResponse({'available': available});
  }

  @override
  void close({bool force = false}) {}
}
