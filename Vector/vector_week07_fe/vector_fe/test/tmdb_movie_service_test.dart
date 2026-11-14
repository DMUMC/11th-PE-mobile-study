import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vector_week01/services/movie_service.dart';
import 'package:vector_week01/services/network_logger.dart';
import 'package:vector_week01/services/tmdb_movie_service.dart';

Map<String, dynamic> item(int id) => {
  'id': id,
  'title': '영화 $id',
  'genre_ids': [18],
  'release_date': '2026-11-01',
  'vote_average': 8.0,
  'poster_path': null,
  'overview': '',
};
http.Response page(int page, {int total = 2}) => http.Response(
  jsonEncode({
    'page': page,
    'total_pages': total,
    'results': List.generate(20, (i) => item((page - 1) * 20 + i)),
  }),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  test('OR 장르, Bearer 인증, page 1부터 30개 제한 및 새 요청 초기화', () async {
    final requests = <http.Request>[];
    final service = TmdbMovieService(
      token: 'test-secret',
      client: MockClient((r) async {
        requests.add(r);
        return page(int.parse(r.url.queryParameters['page']!));
      }),
    );
    addTearDown(service.close);
    final movies = await service.fetchMovies(genreIds: [18, 878, 18]);
    expect(movies.length, 30);
    expect(movies.first.rating, 4);
    expect(movies.first.minutes, 0);
    expect(requests.map((r) => r.url.queryParameters['page']), ['1', '2']);
    expect(
      requests.every((r) => r.url.queryParameters['with_genres'] == '18|878'),
      isTrue,
    );
    expect(requests.first.headers['Authorization'], 'Bearer test-secret');
    await service.fetchMovies(genreIds: []);
    expect(requests[2].url.queryParameters['page'], '1');
    expect(requests[2].url.queryParameters.containsKey('with_genres'), isFalse);
  });

  test('빈 페이지는 추가 요청 없이 빈 목록을 반환한다', () async {
    var calls = 0;
    final service = TmdbMovieService(
      token: 'test',
      client: MockClient((_) async {
        calls++;
        return http.Response('{"results":[],"total_pages":0}', 200);
      }),
    );
    addTearDown(service.close);
    expect(await service.fetchMovies(), isEmpty);
    expect(calls, 1);
  });

  test('두 번째 페이지 실패는 부분 목록 대신 오류를 전달한다', () async {
    final logs = <String>[];
    final service = TmdbMovieService(
      token: 'secret',
      logger: NetworkLogger(sink: logs.add),
      client: MockClient(
        (r) async => r.url.queryParameters['page'] == '1'
            ? page(1)
            : http.Response('private response secret', 503),
      ),
    );
    addTearDown(service.close);
    await expectLater(
      service.fetchMovies(genreIds: [18]),
      throwsA(isA<MovieLoadException>()),
    );
    expect(logs.single, contains('page=2'));
    expect(logs.single, contains('HTTP 503'));
    expect(logs.single, isNot(contains('secret')));
  });

  test('인증/네트워크 실패 로그는 URL과 안전한 메시지만 포함한다', () async {
    final logs = <String>[];
    final service = TmdbMovieService(
      token: 'private-token',
      logger: NetworkLogger(sink: logs.add, secrets: const ['private-token']),
      client: MockClient((_) async => http.Response('private-token', 401)),
    );
    addTearDown(service.close);
    await expectLater(
      service.fetchMovies(),
      throwsA(isA<MovieLoadException>()),
    );
    expect(logs.single, contains('/3/discover/movie'));
    expect(logs.single, contains('HTTP 401'));
    expect(logs.single, isNot(contains('private-token')));
    expect(logs.single, isNot(contains('Authorization')));
    final offline = TmdbMovieService(
      token: 'private-token',
      logger: NetworkLogger(sink: logs.add),
      client: MockClient(
        (_) async => throw http.ClientException('Bearer private-token'),
      ),
    );
    addTearDown(offline.close);
    await expectLater(
      offline.fetchMovies(),
      throwsA(isA<MovieLoadException>()),
    );
    expect(logs.last, contains('NETWORK'));
    expect(logs.last, isNot(contains('private-token')));
  });

  test('시간 초과와 잘못된 응답도 안전하게 기록한다', () async {
    final logs = <String>[];
    final slow = TmdbMovieService(
      token: 'test',
      timeout: Duration.zero,
      logger: NetworkLogger(sink: logs.add),
      client: MockClient((_) => Completer<http.Response>().future),
    );
    addTearDown(slow.close);
    await expectLater(slow.fetchMovies(), throwsA(isA<TimeoutException>()));
    expect(logs.single, contains('TIMEOUT'));
    final malformed = TmdbMovieService(
      token: 'test',
      logger: NetworkLogger(sink: logs.add),
      client: MockClient(
        (_) async => http.Response('{"results":[{}],"total_pages":1}', 200),
      ),
    );
    addTearDown(malformed.close);
    await expectLater(
      malformed.fetchMovies(),
      throwsA(isA<MovieLoadException>()),
    );
    expect(logs.last, contains('INVALID_RESPONSE'));
  });

  test('명시적 로그 비활성화 및 민감 쿼리 마스킹', () {
    final logs = <String>[];
    final uri = Uri.parse('https://example.com/movie?api_key=secret&page=1');
    NetworkLogger(enabled: false, sink: logs.add).failure(uri, 'HTTP 401');
    expect(logs, isEmpty);
    NetworkLogger(
      sink: logs.add,
      secrets: const ['secret'],
    ).failure(uri, 'HTTP 401');
    expect(logs.single, isNot(contains('secret')));
    expect(logs.single, contains('page=1'));
  });
}
