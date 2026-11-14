import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

enum MemberField { nickname, email }

class MemberRating {
  const MemberRating({
    required this.movieId,
    required this.score,
    this.id,
    this.comment,
  });

  final int? id;
  final int movieId;
  final num score;
  final String? comment;
}

class MemberApiException implements Exception {
  const MemberApiException(this.message, {this.status, this.code});

  final String message;
  final int? status;
  final String? code;
}

abstract interface class MemberApi {
  Future<bool> checkAvailability(MemberField field, String value);
  Future<List<MemberRating>> fetchRatings(int memberId);
  Future<int> signup(String nickname, String email, String password);
  Future<void> createRating(int memberId, int movieId, int score);
  Future<void> updateRating(int memberId, int ratingId, int score);
  Future<void> deleteRating(int memberId, int ratingId);
}

class HttpMemberApi implements MemberApi {
  HttpMemberApi({required this.client, this.url = baseUrl});

  final http.Client client;
  final String url;
  static const baseUrl = String.fromEnvironment('MEMBER_API_URL');
  static const nicknamePath = String.fromEnvironment(
    'MEMBER_NICKNAME_PATH',
    defaultValue: '/members/check-nickname',
  );
  static const emailPath = String.fromEnvironment(
    'MEMBER_EMAIL_PATH',
    defaultValue: '/members/check-email',
  );
  static const ratingsPath = String.fromEnvironment(
    'MEMBER_RATINGS_PATH',
    defaultValue: '/members/{memberId}/ratings',
  );

  @override
  Future<bool> checkAvailability(MemberField field, String value) async {
    final path = field == MemberField.nickname ? nicknamePath : emailPath;
    final data = await _request('GET', path, query: {field.name: value});
    if (data case {'available': final bool available}) return available;
    throw const MemberApiException('중복 확인 응답 형식을 확인해주세요.');
  }

  @override
  Future<int> signup(String nickname, String email, String password) async {
    final data = await _request(
      'POST',
      '/members',
      body: {
        'nickname': nickname.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
      },
    );
    if (data case {'id': final int id} when id > 0) return id;
    throw const MemberApiException('회원가입 응답 형식을 확인해주세요.');
  }

  @override
  Future<List<MemberRating>> fetchRatings(int memberId) async {
    final data = await _request(
      'GET',
      ratingsPath.replaceAll('{memberId}', '$memberId'),
    );
    final items = data is Map ? data['ratings'] : data;
    if (items is! List) {
      throw const MemberApiException('평점 목록 응답 형식을 확인해주세요.');
    }
    return items.map((item) {
      if (item case {'movieId': final int movieId}) {
        final score = item['score'] ?? item['rating'];
        final id = item['id'] ?? item['ratingId'];
        final comment = item['comment'];
        if (score is num) {
          return MemberRating(
            id: id is int && id > 0 ? id : null,
            movieId: movieId,
            score: score,
            comment: comment is String ? comment : null,
          );
        }
      }
      throw const MemberApiException('평점 항목의 데이터 형식을 확인해주세요.');
    }).toList();
  }

  @override
  Future<void> createRating(int memberId, int movieId, int score) async {
    await _request(
      'POST',
      '/ratings',
      memberId: memberId,
      body: {'movieId': movieId, 'score': score},
      decodeResponse: false,
    );
  }

  @override
  Future<void> updateRating(int memberId, int ratingId, int score) async {
    await _request(
      'PATCH',
      '/ratings/$ratingId',
      memberId: memberId,
      body: {'score': score},
      decodeResponse: false,
    );
  }

  @override
  Future<void> deleteRating(int memberId, int ratingId) async {
    await _request(
      'DELETE',
      '/ratings/$ratingId',
      memberId: memberId,
      decodeResponse: false,
    );
  }

  Future<Object?> _request(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, Object>? body,
    int? memberId,
    bool decodeResponse = true,
  }) async {
    if (url.isEmpty) {
      throw const MemberApiException('실행 설정에 MEMBER_API_URL을 입력해주세요.');
    }
    try {
      final root = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
      final request = http.Request(
        method,
        Uri.parse('$root$path').replace(queryParameters: query),
      );
      if (memberId != null) request.headers['x-member-id'] = '$memberId';
      if (body != null) {
        request.headers['content-type'] = 'application/json; charset=utf-8';
        request.body = jsonEncode(body);
      }
      final response = await client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _error(response);
      }
      if (!decodeResponse || response.bodyBytes.isEmpty) return null;
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on TimeoutException {
      throw const MemberApiException('응답 시간이 초과됐습니다. 다시 시도해주세요.');
    } on http.ClientException {
      throw const MemberApiException('통신에 실패했습니다. 연결을 확인하고 다시 시도해주세요.');
    } on FormatException {
      throw const MemberApiException('서버 응답 형식을 확인해주세요.');
    }
  }

  MemberApiException _error(http.Response response) {
    String? code;
    try {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data case {'code': final String value}) code = value;
    } on FormatException {
      // Some gateways send an HTML error body.
    }
    final status = response.statusCode;
    final message = switch (code) {
      'DUPLICATE_MEMBER' => '이미 사용 중인 이메일 또는 닉네임입니다. 다시 확인해주세요.',
      'DUPLICATE_RATING' => '이미 등록한 평점입니다. 내 평점 목록에서 수정해주세요.',
      'MEMBER_NOT_FOUND' => '회원을 찾을 수 없습니다. 회원가입을 먼저 진행해주세요.',
      'RATING_NOT_FOUND' => '평점을 찾을 수 없습니다.',
      'RATING_FORBIDDEN' => '본인이 등록한 평점만 변경할 수 있습니다.',
      'VALIDATION_ERROR' => '입력값을 확인해주세요.',
      _ when status == 409 => '이미 등록된 정보입니다. 입력값을 다시 확인해주세요.',
      _ => '서버 요청에 실패했습니다.',
    };
    return MemberApiException(
      '$message (HTTP $status${code == null ? '' : ' · $code'})',
      code: code,
      status: status,
    );
  }
}
