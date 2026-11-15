/// POST /v6/members 요청 body
class CreateMemberRequest {
  const CreateMemberRequest({
    required this.email,
    required this.password,
    required this.nickname,
  });

  final String email;

  /// 사용자가 입력한 문자 그대로 보낸다. (trim으로 값을 바꾸지 않는다)
  final String password;
  final String nickname;

  Map<String, dynamic> toJson() => {
    'email': email.trim(),
    'password': password,
    'nickname': nickname.trim(),
  };
}
