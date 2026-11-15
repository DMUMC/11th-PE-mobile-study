import 'package:dio/dio.dart';

/// NestJS 오류 응답 body의 message를 꺼낸다.
/// - 400(ValidationPipe): { "message": ["닉네임은 2~12자여야 합니다."], ... }
/// - 404(NotFoundException): { "message": "존재하지 않는 유저입니다.", ... }
String? serverMessageOf(DioException error) {
  final data = error.response?.data;
  if (data is! Map) return null;

  final message = data['message'];
  if (message is String && message.isNotEmpty) return message;
  if (message is List && message.isNotEmpty) return message.first.toString();
  return null;
}

/// 서버에 아예 닿지 못한 오류인지 (서버 꺼짐, 주소 오류, 네트워크 끊김, 시간 초과)
bool isConnectionProblem(DioException error) {
  return switch (error.type) {
    DioExceptionType.connectionError ||
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout => true,
    _ => false,
  };
}
