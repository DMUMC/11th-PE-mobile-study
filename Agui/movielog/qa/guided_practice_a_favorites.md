# Guided Practice A — 상세 즐겨찾기 API 연동

- 확인일: 2026-11-26 (Asia/Seoul)
- 기준: `workbook.md`의 Essential 5·7 및 Guided Practice A
- 기기: Device Hub의 iPhone 18 Pro / iOS 27.0

## 구현 결과

- 기존 로그인·내 정보·평점·회원가입·중복 확인 경로를 `/v8`로 전환했다.
- 보호용 MovieLog Client에만 JWT를 붙이고, TMDB와 공개 요청에는 붙이지 않는다.
- `SessionGuard`, `AuthSessionBridge`, `SafeNotify`를 추가했다.
- 보호 요청을 시작한 인증 세션 버전을 기록하고, 현재 세션의 `AUTH401_2/3/4`만 만료 처리한다.
- `FavoriteApiService`에서 CommonResponse와 movieId 기준 조회·등록·해제를 처리한다.
- 상세 Route는 루트 Navigator를 사용한다. 상세 Provider는 영화 ID·이메일·세션 generation으로 구분한다.
- 상세 진입 시 여부를 한 번 조회하고, 제목 오른쪽 북마크로 등록·해제한다.
- 서버 성공 후에만 아이콘을 바꾸고, 요청 중에는 북마크 영역에만 로딩을 표시한다.
- 첫 조회 실패에는 재조회 버튼을 제공한다. 저장 실패에는 이전 아이콘을 유지하고 Snackbar로 안내한다.
- 즐겨찾기 중복·없음 오류는 GET으로 동기화하며, timeout으로 POST를 자동 재전송하지 않는다.

## 실제 서버 + Device Hub

사용자가 앱에서 테스트 계정으로 직접 로그인한 뒤, 일반 `lib/main.dart` 앱으로 확인했다.
서버는 `https://workbook.devnoco.com`, 영화는 TMDB ID `1726`(아이언맨)이다.

| 동작 | 관찰 결과 |
| --- | --- |
| 상세 최초 진입 | 서버 여부 조회 후 미등록 북마크, 하단 탭 없음 |
| 북마크 등록 | 채워진 북마크와 “즐겨찾기에 추가했습니다.” Snackbar |
| 상세를 나갔다가 재진입 | 새 여부 조회 후 등록 상태 유지 |
| 북마크 해제 | 빈 북마크와 “즐겨찾기에서 삭제했습니다.” Snackbar |
| 해제 후 재진입 | 새 여부 조회 후 미등록 상태 확인 |

테스트 영화는 원래의 미등록 상태로 복원했다.

## 실제 서버 + Postman

요청은 `--report-events=false`로 실행했다. 인증 정보와 사용자 데이터는 출력하지 않았다.

| 요청 | 결과 | assertions | 종료 코드 |
| --- | --- | --- | --- |
| 인증 없이 `GET /v8/favorites/550` | HTTP 401, `AUTH401_2` | 2개 통과 | 1: HTTP 401에 따른 비성공 종료이며 assertions는 통과 |
| `GET /v8/members/nickname/agui_guided_a_20261126` | HTTP 200, 직접 반환된 `available: boolean` | 1개 통과 | 0 |

## 자동 검사

아래 관련 테스트 36개와 `favorite_button_test.dart`의 화면 테스트 4개가 각각 종료 코드 0으로 통과했다.

```sh
flutter test test/favorite_detail_test.dart test/auth_session_test.dart test/rating_v7_test.dart test/rating_update_delete_test.dart test/merge_movie_rating_test.dart --reporter expanded
flutter test test/favorite_button_test.dart --reporter expanded
```

검증한 경계 조건:

- CommonResponse 파싱, Bearer 부착, movieId 사용, 등록 body, 해제 HTTP 200/null
- 저장 중 아이콘 유지와 중복 탭 방지
- timeout 이후 POST 자동 재전송 없음, 명시적 조회로 상태 복구
- FAVORITE409_1·FAVORITE404_1의 GET 동기화, MEMBER404_1 구분
- 첫 여부 조회 실패와 재시도
- 동일 이메일 재로그인 후 과거 응답·과거 ViewModel 무효화
- dispose 이후 응답·알림·Snackbar 무시
- 동시 만료 응답의 세션 정리 1회, 과거 401의 새 세션 영향 방지
- 네트워크 실패·403·AUTH401_1에서 세션 유지
- 닉네임 변경 시 세션 generation 유지
- TMDB·공개 경로에 MovieLog JWT 미부착
- 기존 평점 등록·수정·삭제 및 상세 화면 통합 흐름

수정한 앱 코드·개발용 화면·새 테스트의 정적 분석은 문제 없이 통과했다.
오류·timeout·세션 경합은 제어한 응답을 사용하는 자동 검사 결과이며, 실제 서버에 장애를 유발해 확인한 결과가 아니다.

Guided Practice B의 즐겨찾기 목록 API 연결은 이번 작업 범위에 포함하지 않았다.
Git 명령, 커밋, 푸시는 실행하지 않았다.
