# MovieLog 6주차 미션

## 회원가입과 공용 버튼

| 검증 항목 | 화면 |
| --- | --- |
| 확인 전 | [초기 상태](evidence/week06/signup-idle.png) |
| 닉네임과 이메일 확인 중, 회색 버튼과 인디케이터 | [통신 중](evidence/week06/signup-loading.png) |
| 실제 v5의 `available: true` 응답 | [사용 가능](evidence/week06/signup-available.png) |
| `available: false` 응답으로 필드 오류와 버튼 비활성화 | [중복](evidence/week06/signup-duplicate.png) |
| 다른 문자열 입력으로 오류 해제 | [입력 변경](evidence/week06/signup-reset.png) |
| 같은 문자열을 다시 입력하면 요청 없이 오류 복원 | [중복값 재입력](evidence/week06/signup-restored-duplicate.png) |
| HTTP 503에서 재시도 안내와 버튼 활성화 | [통신 실패](evidence/week06/signup-network-error.png) |
| `null`과 `double.infinity` | [중복 확인과 가입하기 버튼](evidence/week06/signup-idle.png) |
| 고정 너비 96 | [평점 다시 시도 버튼](evidence/week06/ratings-error.png) |

## 내가 등록한 평점

마이에서 진입하면 하단 탭 없이 상세 화면이 열린다. 앱바 뒤로가기로 마이에 돌아갈 수 있다.

| 상태 | 검증 조건 | 화면 |
| --- | --- | --- |
| 진입 | 마이의 항목을 선택 | [마이](evidence/week06/profile-ratings-entry.png) |
| Loading | 회원 1의 응답을 지연 | [로딩](evidence/week06/ratings-loading.png) |
| Empty | 서버 응답을 빈 배열로 재현 | [빈 목록](evidence/week06/ratings-empty.png) |
| Error | 서버 응답을 HTTP 404로 재현 | [실패 및 재시도](evidence/week06/ratings-error.png) |
| Success | 실제 워크북과 TMDB 응답으로 평점 3개, 영화 제목·포스터 표시 | [성공](evidence/week06/ratings-success.png) |

## 검증 기록

- `flutter analyze --no-pub` 통과
- `flutter test --reporter expanded` 25개 통과. 기본 실행에서 별도 플래그가 필요한 TMDB 통합 테스트 1개 제외
- `flutter build web --release --no-web-resources-cdn` 성공
- Chrome의 420 × 900 뷰포트에서 회원가입 및 마이 화면 조작. 사용 가능과 평점 성공은 실제 응답을 사용했다. 중복·503·404·빈 목록은 브라우저에서 응답을 재현했고, 로딩은 실제 응답을 지연시켜 확인했다.
- 위젯 테스트에서 입력 변경 뒤 도착한 이전 응답 무시, 중복 문자열 재입력 시 요청 횟수 유지, 버튼 너비, TMDB 조회 실패 시 평점 보존을 확인했다.

## 트러블슈팅과 회고

닉네임 확인 중에 값을 수정하면 요청 시점의 값과 현재 입력이 달라진다. 필드별로 요청 버전을 관리해 이전 응답이 현재 입력의 상태를 덮어쓰지 않도록 했다. 같은 필드에서 마지막으로 중복이었던 값은 별도로 기억해 즉시 오류를 복원한다.

v5는 중복 확인 객체와 평점 배열을 성공 응답 본문에 직접 내려준다. 정상 응답의 `available: false`, 빈 평점 배열, HTTP 오류를 각기 다른 상태로 모델링했다. TMDB 상세 조회는 동일한 영화 ID를 한 번만 요청하며, 영화 정보를 가져오지 못해도 워크북에서 조회한 평점 기록을 계속 표시한다.
