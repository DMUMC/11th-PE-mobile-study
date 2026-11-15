/// v6 공통 응답 형식: { isSuccess, code, message, result }
/// 회원가입·평점 등록·평점 수정 성공 응답과 모든 실패 응답이 이 형식이다.
/// (닉네임/이메일 확인·평점 조회의 성공 응답은 직접 객체/배열이라 이 형식이 아니다.)
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

  /// API마다 담기는 값이 달라 제네릭으로 둔다. 값이 없거나 실패면 null.
  final T? result;

  factory CommonResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? value) parseResult,
  ) {
    final rawResult = json['result'];
    return CommonResponse<T>(
      isSuccess: json['isSuccess'] as bool,
      code: json['code'] as String,
      message: json['message'] as String,
      result: rawResult == null ? null : parseResult(rawResult),
    );
  }

  /// 오류 응답 body가 공통 형식이면 파싱하고, 아니면(네트워크 오류 등) null.
  static CommonResponse<Object?>? tryParseError(Object? data) {
    if (data is! Map<String, dynamic>) return null;
    if (data['code'] is! String || data['message'] is! String) return null;
    return CommonResponse<Object?>(
      isSuccess: data['isSuccess'] as bool? ?? false,
      code: data['code'] as String,
      message: data['message'] as String,
      result: data['result'],
    );
  }
}
