class SignUpResult {
  const SignUpResult({
    required this.memberId,
    required this.email,
    required this.nickname,
  });

  final int memberId;
  final String email;
  final String nickname;

  factory SignUpResult.fromJson(Object? data) {
    if (data
        case {
          'memberId': final int memberId,
          'email': final String email,
          'nickname': final String nickname,
        }
        when memberId > 0) {
      return SignUpResult(memberId: memberId, email: email, nickname: nickname);
    }
    throw const FormatException('가입 결과에 올바른 회원 정보가 없습니다.');
  }
}
