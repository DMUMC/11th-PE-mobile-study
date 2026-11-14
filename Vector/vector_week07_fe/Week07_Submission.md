# MovieLog 7주차 프론트엔드 제출 양식

| 제출 항목 | 확인 내용과 파일 |
| --- | --- |
| PR 링크 | 미생성. 과제 브랜치에 소스를 반영한 뒤 PR URL 입력 |
| 생성한 본인 테스트 계정 | 모의 응답 검증용 닉네임 `VectorWeek07`, 이메일 `vector-week07@example.com`, 회원 ID `7`. 실제 서버 계정은 미생성 |
| 닉네임/이메일 확인과 입력 변경 무효화 | `01-availability-verified.png`, `02-availability-invalidated.png` |
| 회원가입 결과와 최종 409 | `03-signup-submitting.png` 제출 중 뒤로 가기 차단, `04-signup-conflict.png` 최종 POST 409, `05-signup-success.png` 재확인 후 가입 성공 |
| 선택한 TMDB id → MovieLog movieId | `06-tmdb-id-to-movie-id.png`에서 인셉션 ID 27205 확인. 요청 본문은 `mock-api-trace.txt`에 기록 |
| 등록→조회→수정→조회→삭제→조회 | `07-created-list.png` 4점, `08-updated-list.png` 5점, `09-single-delete-in-progress.png` 처리 중 기존 확인창 유지, `10-deleted-list.png` 삭제 후 빈 목록. 요청 순서는 `mock-api-trace.txt` 참고 |
| 오류 code 처리 | `04-signup-conflict.png`의 `DUPLICATE_MEMBER`, `12-api-error-code.png`의 `DUPLICATE_RATING` |
| 저장 성공/재조회 실패 분리 | `11-saved-refresh-failed.png`. 등록 POST 201 이후 조회 GET 503을 보내 화면에 별도로 표시하는지 확인 |
| 챌린지 다중 삭제 | `13-bulk-edit-entry.png` 기본 화면, `14-bulk-selection.png` 체크박스와 선택 개수, `15-bulk-confirmation.png` 확인창, `16-bulk-overlay.png` 확인창을 닫고 로딩 표시, `17-bulk-partial-failure.png` 성공한 항목을 제거하고 실패 항목 유지 |
| 트러블슈팅 | 최종 가입 요청이 409를 반환하면 이전 중복 확인 결과를 무효화한다. 평점 쓰기와 목록 재조회를 분리해 조회 실패 시 이미 성공한 쓰기를 다시 요청하도록 안내하지 않는다. 여러 삭제 요청은 각 ratingId의 성공 여부를 개별 집계한다. |
| 미검증 항목 | 배포 서버와 실 TMDB 호출, iOS 시뮬레이터, GitHub PR. 첨부 화면은 Flutter 위젯과 실제 HTTP 클라이언트 코드에 모의 응답을 연결해 캡처했다. |

## 실행

```bash
flutter pub get
flutter run \
  --dart-define=MEMBER_API_URL=YOUR_MEMBER_API_URL \
  --dart-define=TMDB_READ_ACCESS_TOKEN=YOUR_TMDB_READ_TOKEN
```

홈 오른쪽의 회원가입에서 새 계정을 만든 뒤 영화 탭에서 TMDB 영화의 상세 화면으로 이동한다. 가입 성공 응답의 회원 ID를 그 실행 세션에서 평점 요청에 사용한다. 앱을 다시 켜면 6주차의 기본 테스트 회원 ID 1로 시작한다. 평점 수정과 삭제는 마이 탭의 **내가 등록한 평점**에서 진행한다.

7주차 요청은 6주차 NestJS 백엔드 코드의 `POST /members`, `GET /members/{id}/ratings`, `POST /ratings`, `PATCH /ratings/{id}`, `DELETE /ratings/{id}` 규격을 사용한다. 평점 쓰기에는 `x-member-id`를 보낸다.
