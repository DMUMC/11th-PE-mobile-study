import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/core/network/tmdb_client.dart';
import 'package:movielog/core/network/tmdb_logging_interceptor.dart';

import 'support/tmdb_fixture.dart';

void main() {
  test('Service는 API별 경로와 query를 올바르게 전송한다', () async {
    final f = fixture();
    await f.service.fetchPopular(page: 2);
    await f.service.fetchGenres();
    await f.service.discoverMovies(page: 3, genreIds: [28, 878]);
    expect(f.adapter.requests[0].path, '/movie/popular');
    expect(f.adapter.requests[0].queryParameters, {
      'language': 'ko-KR',
      'page': 2,
    });
    expect(f.adapter.requests[1].queryParameters, {'language': 'ko'});
    expect(f.adapter.requests[2].queryParameters, {
      'language': 'ko-KR',
      'page': 3,
      'sort_by': 'popularity.desc',
      'include_adult': false,
      'include_video': false,
      'with_genres': '28|878',
    });
  });

  test('로그는 요청 URL/상태를 기록하며 헤더와 오류의 인증 값을 출력하지 않는다', () async {
    final f = fixture();
    final logs = <String>[];
    f.dio.options.headers['Authorization'] = 'Bearer fixture-secret';
    f.dio.interceptors.add(TmdbLoggingInterceptor(write: logs.add));
    await f.service.fetchPopular();
    expect(logs.join(), contains('/movie/popular'));
    expect(logs.join(), contains('200'));
    expect(logs.join(), contains('Bearer ***'));
    expect(logs.join(), isNot(contains('fixture-secret')));
    logs.clear();
    f.adapter.respond = (_) async =>
        FixtureAdapter.json({'status_message': 'fixture-secret'}, 401);
    await expectLater(f.service.fetchPopular(), throwsA(isA<DioException>()));
    expect(logs.join(), contains('401'));
    expect(logs.join(), isNot(contains('fixture-secret')));
  });

  test('TMDB Client는 토큰 누락 시 네트워크 요청 전에 설정 오류를 반환한다', () async {
    dotenv.loadFromString(envString: 'TMDB_ACCESS_TOKEN=');
    final dio = createTmdbClient();
    final adapter = FixtureAdapter();
    dio.httpClientAdapter = adapter;
    await expectLater(
      dio.get<Object>('/movie/popular'),
      throwsA(
        isA<DioException>().having(
          (e) => e.error,
          'configuration error',
          isA<TmdbConfigurationException>(),
        ),
      ),
    );
    expect(adapter.requests, isEmpty);
    dio.close();
  });
}
