import 'package:dio/dio.dart';

String? apiErrorCode(DioException error) {
  final data = error.response?.data;
  return data is Map<String, dynamic> && data['code'] is String
      ? data['code'] as String
      : null;
}

String? apiErrorMessage(DioException error) {
  final data = error.response?.data;
  return data is Map<String, dynamic> && data['message'] is String
      ? data['message'] as String
      : null;
}
