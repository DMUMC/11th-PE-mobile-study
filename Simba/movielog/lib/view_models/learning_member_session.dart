import 'package:flutter/foundation.dart';

/// 회원가입 결과로 받은 학습용 memberId를 메모리에 보관한다.
/// memberId를 알고 있다는 사실은 인증이 아니다. (다음 JWT 주차에 토큰으로 바뀐다)
/// 앱을 재시작하면 사라진다.
class LearningMemberSession extends ChangeNotifier {
  int? memberId;

  void setMemberId(int id) {
    memberId = id;
    notifyListeners();
  }

  void clear() {
    memberId = null;
    notifyListeners();
  }
}
