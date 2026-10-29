import 'package:dio/dio.dart';

import '../core/network/tmdb_client.dart';

enum MovieLoadStatus { idle, loading, success, empty, error }

String movieLoadMessage(Object error) {
  if (error is DioException) {
    if (error.error is TmdbConfigurationException) {
      return 'TMDB 연결 설정이 필요해요. 설정 후 앱을 다시 실행해 주세요.';
    }
    if (error.response?.statusCode == 401) {
      return 'TMDB 인증에 실패했어요. 연결 설정을 확인해 주세요.';
    }
    if (error.response?.statusCode == 429) {
      return '요청이 많아 잠시 쉬고 있어요. 조금 뒤 다시 시도해 주세요.';
    }
  }
  return '영화를 불러오지 못했어요. 잠시 후 다시 시도해 주세요.';
}
