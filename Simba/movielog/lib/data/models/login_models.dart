/// POST /v7/auth/login 요청 body
class LoginRequest {
  const LoginRequest({required this.email, required this.password});

  final String email;

  /// 요청 body로만 보내고 저장하거나 로그에 남기지 않는다.
  final String password;

  Map<String, dynamic> toJson() => {
    'email': email.trim(),
    'password': password,
  };
}

/// 로그인 성공 result. v7 계약상 memberId는 없다. (JWT claim도 추정하지 않는다)
class LoginResult {
  const LoginResult({required this.nickname, required this.accessToken});

  final String nickname;
  final String accessToken;

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    return LoginResult(
      nickname: json['nickname'] as String,
      accessToken: json['accessToken'] as String,
    );
  }
}
