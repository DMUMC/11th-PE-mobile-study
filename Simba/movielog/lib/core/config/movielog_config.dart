import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// MovieLog 자체 API(NestJS 서버) 설정.
abstract final class MovieLogConfig {
  static const _baseUrlKey = 'MOVIELOG_API_BASE_URL';
  static const _demoMemberIdKey = 'MOVIELOG_DEMO_MEMBER_ID';

  /// .env에 값이 있으면 그 주소를, 없으면 실행 환경에 맞는 로컬 서버 주소를 쓴다.
  /// - Android 에뮬레이터: 10.0.2.2가 PC(호스트)를 가리킨다. localhost는 에뮬레이터 자신이다.
  /// - iOS 시뮬레이터, 데스크톱, 웹: localhost
  /// - 실제 휴대폰: .env에 PC의 IP 주소를 직접 적는다. (예: http://192.168.0.10:3000)
  static String get apiBaseUrl {
    final fromEnv = dotenv.env[_baseUrlKey]?.trim();
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;

    final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    return isAndroid ? 'http://10.0.2.2:3000' : 'http://localhost:3000';
  }

  /// 로그인(7주차) 전까지 마이페이지에서 평점을 조회할 회원 id. 시드 데이터의 1번 회원(수현)
  static int get demoMemberId =>
      int.tryParse(dotenv.env[_demoMemberIdKey] ?? '') ?? 1;
}
