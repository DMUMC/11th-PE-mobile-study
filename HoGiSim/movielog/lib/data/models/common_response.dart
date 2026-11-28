import 'package:dio/dio.dart';

class CommonResponse<T> {
  const CommonResponse({
    required this.isSuccess,
    required this.code,
    required this.message,
    this.result,
  });

  final bool isSuccess;
  final String code;
  final String message;
  final T? result;

  factory CommonResponse.fromJson(
    Object? data,
    T Function(Object? value) parseResult,
  ) {
    if (data case {
      'isSuccess': final bool isSuccess,
      'code': final String code,
      'message': final String message,
    }) {
      final rawResult = (data as Map)['result'];
      return CommonResponse(
        isSuccess: isSuccess,
        code: code,
        message: message,
        result: !isSuccess || rawResult == null ? null : parseResult(rawResult),
      );
    }
    throw const FormatException('공통 응답 형식이 올바르지 않습니다.');
  }

  static CommonResponse<Object?>? errorFrom(Object error) {
    if (error is! DioException) return null;
    try {
      return CommonResponse<Object?>.fromJson(
        error.response?.data,
        (value) => value,
      );
    } on FormatException {
      return null;
    }
  }

  static CommonResponse<T> requireSuccess<T>(
    Response<dynamic> response,
    int expectedStatus,
    T Function(Object? value) parseResult,
  ) {
    final body = CommonResponse<T>.fromJson(response.data, parseResult);
    if (response.statusCode != expectedStatus || !body.isSuccess) {
      throw DioException.badResponse(
        statusCode: response.statusCode ?? 0,
        requestOptions: response.requestOptions,
        response: response,
      );
    }
    return body;
  }
}
