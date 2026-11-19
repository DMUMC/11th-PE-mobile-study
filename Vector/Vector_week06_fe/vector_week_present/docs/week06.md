# 6주차 실행 가이드

홈 오른쪽 상단의 회원가입 아이콘에서 중복 확인 화면을 열 수 있습니다. 마이 탭의 **내가 등록한 평점**에서 회원 1의 평점을 확인합니다.

## 실제 서버 연결

회원 API 주소와 TMDB 읽기 토큰을 전달합니다. 환경값은 예시이며 실제 주소와 토큰으로 바꿔 사용합니다.

```bash
flutter pub get
flutter run -d chrome \
  --dart-define=MEMBER_API_URL=https://your-member-api.example \
  --dart-define=TMDB_READ_ACCESS_TOKEN=YOUR_TMDB_READ_TOKEN
```

| 기본 요청 경로 | 사용하는 값 | 기대 응답 |
| --- | --- | --- |
| GET /members/check-nickname | 쿼리 nickname | JSON 객체의 boolean available |
| GET /members/check-email | 쿼리 email | JSON 객체의 boolean available |
| GET /members/1/ratings | 경로 memberId | movieId와 score 또는 rating을 담은 배열, 또는 ratings 배열이 담긴 객체 |

회원 API 명세를 받으면 기본 요청 경로를 확인하세요. 경로는 각각 `MEMBER_NICKNAME_PATH`, `MEMBER_EMAIL_PATH`, `MEMBER_RATINGS_PATH`로 바꿀 수 있습니다. 평점 경로에 `{memberId}`를 넣으면 회원 ID로 치환합니다. 영화 제목은 TMDB 영화 상세에서 가져옵니다.

현재 소스는 기존 `package:http`를 사용합니다. 네트워크 오류와 타임아웃, 중복 응답을 구분합니다. 작업 환경에서 Dio를 내려받을 수 없어 DioException 타입 연동은 남아 있습니다. 실제 서버 주소와 토큰이 제공되지 않아 실서버 호출은 검증하지 못했습니다.
