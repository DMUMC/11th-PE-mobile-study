import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

enum MemberField { nickname, email }

class MemberRating {
  const MemberRating({required this.movieId, required this.score});
  final int movieId;
  final num score;
}

class MemberApiException implements Exception {
  const MemberApiException(this.message);
  final String message;
}

abstract interface class MemberApi {
  Future<bool> checkAvailability(MemberField field, String value);
  Future<List<MemberRating>> fetchRatings(int memberId);
}

class HttpMemberApi implements MemberApi {
  HttpMemberApi({required this.client});
  final http.Client client;
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
    final data = await _get(path, {field.name: value});
    if (data case {'available': final bool available}) return available;
    throw const MemberApiException('중복 확인 응답 형식을 확인해주세요.');
  }

  @override
  Future<List<MemberRating>> fetchRatings(int memberId) async {
    final data = await _get(ratingsPath.replaceAll('{memberId}', '$memberId'));
    final items = data is Map ? data['ratings'] : data;
    if (items is! List) {
      throw const MemberApiException('평점 목록 응답 형식을 확인해주세요.');
    }
    return items.map((item) {
      if (item case {'movieId': final int id}) {
        final score = item['score'] ?? item['rating'];
        if (score is num) return MemberRating(movieId: id, score: score);
      }
      throw const MemberApiException('평점 항목의 데이터 형식을 확인해주세요.');
    }).toList();
  }

  Future<Object?> _get(String path, [Map<String, String>? query]) async {
    if (baseUrl.isEmpty) {
      throw const MemberApiException('실행 설정에 MEMBER_API_URL을 입력해주세요.');
    }
    final root = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final uri = Uri.parse('$root$path').replace(queryParameters: query);
    try {
      final response = await client
          .get(uri)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw MemberApiException(
          '서버 요청에 실패했습니다. (HTTP ${response.statusCode})',
        );
      }
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on TimeoutException {
      throw const MemberApiException('응답 시간이 초과됐습니다. 다시 시도해주세요.');
    } on http.ClientException {
      throw const MemberApiException('통신에 실패했습니다. 연결을 확인하고 다시 시도해주세요.');
    } on FormatException {
      throw const MemberApiException('서버 응답 형식을 확인해주세요.');
    }
  }
}
