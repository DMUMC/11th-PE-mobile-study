# Required Mission 기능 확인 기록

- 확인일: 2026-11-14 (Asia/Seoul)
- 기기: Device Hub / iPhone 18 Pro / iOS 27.0
- 순서: 버튼 비교 → 평점 상태 → 회원가입 상태 → 제출 자료
- 자동 회귀 테스트 전체 실행이나 부하·장애 종합 QA는 진행하지 않았습니다.

## 1. 공용 버튼

- 같은 `확인` 라벨로 내용 크기(`null`), 전체 너비(`double.infinity`), 고정 너비(`96`)를 한 화면에서 비교했습니다.
- 기본 상태는 보라색, 통신 중과 비활성은 회색입니다. 통신 중에는 라벨 대신 인디케이터만 표시됩니다.
- 공용 위젯은 `lib/widgets/movielog_button.dart`에 있고, 회원가입의 두 확인 버튼과 가입 버튼이 함께 사용합니다.
- [확인 화면](mission-captures/2026-11-14-required/button-widths-and-states.png)

## 2. 평점 목록

| 기능 | 응답 출처 | 확인 결과 |
| --- | --- | --- |
| Loading | 개발용 GET 응답 3초 지연 | 진행 표시와 안내 문구 표시 |
| Empty | 개발용 빈 배열 | Error와 구분되는 빈 목록 안내, 다시 불러오기 표시 |
| Error | 개발용 HTTP 500 | 오류 안내, 다시 불러오기 표시 |
| 재시도 | 첫 요청 500, 두 번째 요청 정상 배열 | 정상 목록으로 복구 |
| 영화 정보 일부 누락 | 영화 ID 13의 요청만 개발용으로 실패 처리, 나머지는 TMDB | 기록 3건 유지, ID 13은 대체 제목·포스터, 나머지는 정상 표시 |
| 실제 조회 | 워크북 회원 1 GET + TMDB | 포레스트 검프·펄프 픽션·파이트 클럽 표시 |
| 후기 없음 | `comment: null` | 후기 영역 생략 |
| 화면 이동 | 일반 앱 `/my` → `/my/ratings` | 진입 항목 동작, 목록에서 하단 탭 숨김, 뒤로가기 후 복원 |

개발용 응답은 서버 데이터나 실제 네트워크를 변경하지 않습니다.
평점 조회는 실제 `RatingApiService`의 JSON 파싱과 `MyRatingsViewModel`의 상태 전환을 거칩니다.
TMDB 일부 누락은 전송 전 개발용 인터셉터에서 실패시킨 것이며 실제 서버 장애를 관찰한 결과는 아닙니다.

## 3. 회원가입

일반 앱과 같은 `SignUpScreen`·`SignUpViewModel`·`MemberCheckService`에 로컬 응답 어댑터를 연결했습니다.

| 기능 | 닉네임 | 이메일 |
| --- | --- | --- |
| 확인 전 안내 | 확인 | 확인 |
| 통신 중 비활성·인디케이터 | 확인 | 확인 |
| 정상 중복 응답과 빨간 Form 오류 | 확인 | 확인 |
| 입력 변경 시 확인 결과 제거 | 확인 | 확인 |
| 사용 가능 문구·체크 표시 | 확인 | 확인 |
| 중복값 재입력 시 즉시 오류 복원 | 확인 | 확인 |
| HTTP 500 실패 문구, 재시도 가능한 버튼 | 확인 | 확인 |

두 항목이 사용 가능이고 약관에 동의했을 때 가입 버튼이 활성화됐습니다.
약관을 해제하거나 한 필드가 중복·확인 전 상태가 되면 가입 버튼은 비활성화됐습니다.
약관 조건은 Device Hub의 switch 값과 가입 버튼의 disabled 상태로 확인했습니다.
약관 토글 직후의 캡처는 전환 중 이미지여서 제출 자료에서 제외했습니다.
회원가입 POST는 호출하지 않았습니다.

개발용 로그에는 입력값·토큰 대신 필드와 횟수만 기록했습니다.

```text
nickname request=1 available=false
email request=1 available=false
nickname request=2 available=true
email request=2 available=true
# 중복값 재입력: 추가 요청 없음
nickname request=3 status=500
email request=3 status=500
```

## 4. 제출 준비와 남은 항목

- [워크북 양식의 제출 초안](week06-mission-submission.md)
- [Device Hub 캡처 폴더](mission-captures/2026-11-14-required/)
- [앱 범위 flutter analyze 결과](mission-captures/2026-11-14-required/flutter-analyze.txt)
- 분석 결과: 오류 0, 경고 0, 기존 Dart 연습 파일의 info 1건. 종료 코드 1.
- 현재 브랜치의 PR을 조회했으나 아직 없습니다. PR 링크는 미생성으로 표시했습니다.
- 회고는 사실에 기반한 초안으로 작성했으며 제출 전 본인의 표현으로 수정할 수 있습니다.
- 기능 확인 후 일반 `lib/main.dart`와 실제 API 연결로 되돌렸습니다.
- 자료 정리 과정에서 푸시·PR 생성·외부 제출은 수행하지 않았습니다.

일반 앱의 내비게이션이나 업무 로직을 바꾸지 않고 별도 개발용 실행 화면과 자료만 추가했습니다.
