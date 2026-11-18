# Guided Practice A 검증 기록

- 검증일: 2026-11-13 (Asia/Seoul)
- 대상: `Agui/movielog`, `week06_Agui_fe`
- 기기: Device Hub의 iPhone 18 Pro / iOS 27.0
- 범위: 닉네임·이메일 중복 확인, 공용 버튼, Form 오류, 입력 변경 및 요청 수명 관리
- 실제 회원가입 POST와 평점 조회는 이번 작업에 포함하지 않음

## 구현

- Dio Client, v5 `CheckResult`, `MemberCheckService`, 화면 전용 `SignUpViewModel`, Provider 연결
- 닉네임·이메일별 `idle / checking / available / duplicated / error` 상태와 요청 버전 분리
- 예시 입력값은 유지하되 확인 결과는 `idle`에서 시작, 첫 요청에서도 ViewModel의 현재 값과 일치
- `TextFormField.forceErrorText`로 서버 오류를 Form 검증과 연결
- 중복값 재입력은 저장된 마지막 중복값을 기준으로 즉시 에러 복원
- 두 중복 확인과 입력 형식·약관 조건이 모두 충족되면 홈으로 이동 (계정 생성 요청 없음)
- 공용 버튼의 최소 너비 102 제약 제거, 가입 버튼도 공용 버튼 사용

## 실제 API + Device Hub

기본 주소는 `https://workbook.devnoco.com`이며 성공 body는 Wrapper 없이 직접 파싱한다.

| 검증 | 관찰 | 결과 |
| --- | --- | --- |
| 초기 진입 | 닉네임·이메일 확인 전 안내, 가입 버튼 비활성, 무한 로딩 없음 | 통과 |
| 닉네임 `영화광` 확인 | `available: false`, 빨간 입력창·중복 문구·확인 버튼 비활성 | 통과 |
| `영화광a`로 변경 후 확인 | 변경 즉시 이전 결과 제거, 실제 GET 후 사용 가능 문구와 체크 표시 | 통과 |
| `영화광` 재입력 | API 재요청 버튼을 누르지 않아도 즉시 중복 오류와 비활성 복원 | 통과 |
| 이메일 `movie@umc.com` 확인 | 실제 GET 후 이메일 중복 오류, 닉네임 상태 유지 | 통과 |

터미널에서도 닉네임 `영화광` / `agui_guided_a_20261113`과 이메일 `movie@umc.com`을 GET하여 각각 `false` / `true` / `false` 응답을 확인했다.

## 제어한 응답 + Device Hub

일반 사용자 서버의 장애를 유발하지 않고 화면을 검증하기 위해 임시 로컬 Postman simulation을 사용했다.
워크북의 두 GET 경로와 실제로 확인한 `{ "available": boolean }` 형식을 모델링했다.
로그의 `user-agent: Dart/3.13 (dart:io)` 요청으로 앱이 해당 HTTP 경로를 실제 호출했음을 확인했다.
공유된 조직 mock 검색은 수행하지 않았으며, 로컬 mock은 워크북 계약으로 생성했다.

실행 설정: `--dart-define=MOVIE_LOG_BASE_URL=http://127.0.0.1:4548/workbook`.
아래 결과는 제어한 응답에 대한 검증이며, 실제 서버의 장애 응답 형식을 검증한 것은 아니다.

| 조건 | 관찰 | 결과 |
| --- | --- | --- |
| GET 응답 2.5초 지연 | 회색 비활성 버튼, 라벨 대신 진행 표시, 확인 중 안내 | 통과 |
| HTTP 500 주입 | 정상 중복과 다른 실패 문구, 확인 버튼은 재시도 가능 | 통과 |
| 실패 후 200 / available=true로 재시도 | 오류 제거, 사용 가능 표시로 전환 | 통과 |
| 닉네임·이메일 동시 요청 | 각 버튼이 독립적으로 로딩하고 각각 완료 | 통과 |
| 두 확인 모두 사용 가능 | 가입 버튼 활성 | 통과 |
| 요청 중 닉네임을 `영화광a`로 변경 | 닉네임 즉시 확인 전으로 초기화, 이메일 성공 유지, 가입 버튼 비활성 | 통과 |
| 이전 `영화광` 성공 응답 도착 | 변경된 닉네임은 계속 확인 전, 이전 응답에 덮어쓰이지 않음 | 통과 |

## 자동 검사

```sh
flutter analyze lib/auth lib/core lib/data lib/view_models lib/widgets lib/main.dart lib/router test/member_check_test.dart test/sign_up_check_test.dart test/widget_test.dart
flutter test test/member_check_test.dart test/sign_up_check_test.dart
flutter test test/member_check_test.dart test/sign_up_check_test.dart test/widget_test.dart
```

- 관련 코드 분석: 문제 없음
- 새 검사 10개: 모두 통과
- 새 검사와 기존 widget 검사 합계: 19개 중 16개 통과, 아래 기존 영화 화면 검사 3개 실패
- 기존 커밋 `ecd4ed9`의 앱을 `/tmp`에 별도로 추출해 같은 3개 검사를 실행했고 동일한 실패를 재현함
- 이번 변경의 범위 밖인 영화 화면 및 해당 검사는 수정하지 않음

기존 실패:

1. `movie catalog filters, searches, and opens the selected movie`: 인라인 `SF` 텍스트를 찾지 못함
2. `movie detail actions work from a direct route`: 평점 버튼 탭이 적중하지 않아 대화상자를 찾지 못함
3. `movie detail keeps its actions visible on a phone`: `SingleChildScrollView` 두 개로 drag 대상이 모호함

새 검사는 raw JSON·경로 인코딩, 첫 예시 값 확인, 중복값 기억, 중복 요청 방지, 오래된 응답 무시,
필드별 요청 독립성, 통신 실패와 재시도, 비정상 응답, dispose 이후 응답 무시,
Form 오류 표시 및 `validate()` 실패, 버튼의 내용 기반·전체·고정 너비를 검증한다.

버튼 너비 자동 측정: 너비 300인 부모에서 `null` + 짧은 라벨은 96 미만, `double.infinity`는 300, 고정값 96은 96.
고정 너비 예시는 자동 검사에서 확인했으며 일반 회원가입 화면에는 추가하지 않았다.

## 마무리 상태

- 지연·오류 주입용 로컬 서버를 종료하고, 앱을 기본 실제 API 주소로 다시 실행함
- 복원 후 Device Hub에서 `영화광a`를 다시 확인해 사용 가능 응답을 확인함
- QA 중 사용한 키보드 캡처와 클립보드 연결 설정을 원래 상태로 되돌림
- 커밋·푸시는 수행하지 않음
- QA에 사용한 Postman CLI 1.74.0은 `postman status` 명령을 지원하지 않아 해당 상태 조회는 불가능했음. 공유 워크스페이스를 생성하거나 게시하지 않고 로컬 simulation만 실행함
