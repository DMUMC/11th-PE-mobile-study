# [week06] [BE] 아귀 6주차 미션

<!-- PR 설정: base=main / compare=week06_Agui_be / Assignee=본인 -->
<!-- 아래 '구현 내용'부터 PR 본문에 복사합니다. -->
<!-- 캡처는 Git 추적에서 제외되어 있으므로, 각 안내 위치에 로컬 이미지를 드래그해 GitHub 첨부 URL을 생성합니다. -->

## 구현 내용

### Standard Mission

- 회원가입 API를 구현했습니다. 이메일 형식, 닉네임 길이, 비밀번호 규칙을 DTO에서 검증하고, 이메일·닉네임 중복 여부를 확인합니다.
- 비밀번호는 BCrypt로 해시해 저장하며, 회원가입 응답에는 포함하지 않습니다.
- 평점 등록·조회·수정·삭제를 구현했습니다. 동일 회원·영화의 중복 평점을 방지하고, 수정·삭제 시 경로로 전달받은 회원 ID와 작성자 ID를 비교합니다.
- `ApiResponse`와 전역 예외 처리로 쓰기 API의 성공·실패 응답을 정리했습니다. 삭제 성공은 본문 없는 204로 반환합니다.

| 기능 | Method | 경로 | 성공 상태 |
| --- | --- | --- | --- |
| 회원가입 | POST | `/members` | 201 |
| 회원 평점 조회 | GET | `/members/{memberId}/ratings` | 200 |
| 평점 등록 | POST | `/members/{memberId}/ratings` | 201 |
| 평점 수정 | PATCH | `/members/{memberId}/ratings/{ratingId}` | 200 |
| 평점 삭제 | DELETE | `/members/{memberId}/ratings/{ratingId}` | 204 |

현재 평점 API는 로그인 도입 전 실습 단계로, 요청 경로의 `memberId`를 사용합니다.

### Challenge Mission

- `DuplicateMemberException`으로 이메일·닉네임 중복 오류를 구분했습니다.
- 사전 중복 검사를 동시에 통과하더라도 DB UNIQUE 제약 위반을 전역 예외 처리에서 409로 변환합니다.
- MySQL 제약 이름 `member.email`·`member.nickname` 및 `uk_member_email`·`uk_member_nickname`을 구분해 사전 검사와 동일한 오류 코드를 반환합니다. 그 외 DB 제약 위반은 `COMMON4091`로 처리합니다.

| 상황 | HTTP 상태 | 오류 코드 |
| --- | --- | --- |
| 이메일 중복 | 409 | `MEMBER4091` |
| 닉네임 중복 | 409 | `MEMBER4092` |
| 입력값 검증 실패 | 400 | `COMMON4001` |
| 평점 사전 중복 검사 실패 | 409 | `COMMON4092` |
| 다른 회원 ID로 평점 수정·삭제 | 403 | `COMMON403` |
| 존재하지 않는 회원·평점 | 404 | `COMMON404` |

## 실행 화면

아래 내용은 기존 Postman 실행 캡처를 기준으로 정리했습니다.

### 1. 회원가입 및 입력 검증

회원가입 시 201과 비밀번호가 제외된 회원 정보를 반환하고, 잘못된 이메일 입력은 400으로 거절됩니다.

<!-- 첨부: mission-captures/week06/01-signup-201.jpg -->
<!-- 첨부: mission-captures/week06/02-validation-400.jpg -->

### 2. 평점 등록·중복 및 범위 검증

평점 등록은 201, 같은 회원·영화로 재등록하면 409, 별점 6점 입력은 400을 반환합니다.

<!-- 첨부: mission-captures/week06/03-rating-create-201.jpg -->
<!-- 첨부: mission-captures/week06/05-rating-duplicate-409.jpg -->
<!-- 첨부: mission-captures/week06/06-rating-validation-400.jpg -->

### 3. 평점 수정·삭제 및 작성자 검증

| 확인 항목 | 캡처에서 확인한 결과 |
| --- | --- |
| 본인 평점 수정 | 200, `COMMON200` |
| 다른 회원 ID로 수정 | 403, `COMMON403` |
| 수정 후 조회 | 평점 1개 유지, 별점 4점·변경한 후기 반영 |
| 다른 회원 ID로 삭제 | 403, `COMMON403` |
| 본인 평점 삭제 | 204, 빈 본문 |
| 삭제한 평점 재삭제 | 404, `COMMON404` |
| 삭제 후 조회 | 200, 빈 배열 |

<!-- 첨부: mission-captures/week06/07-rating-update-200.jpg -->
<!-- 첨부: mission-captures/week06/08-rating-owner-403.jpg -->
<!-- 첨부: mission-captures/week06/09-rating-updated-list-200.jpg -->
<!-- 첨부: mission-captures/week06/10-rating-delete-owner-403.jpg -->
<!-- 첨부: mission-captures/week06/11-rating-delete-204.jpg -->
<!-- 첨부: mission-captures/week06/12-rating-not-found-404.jpg -->
<!-- 첨부: mission-captures/week06/13-rating-deleted-list-200.jpg -->

### 4. 이메일·닉네임 중복 오류 구분

이메일 중복은 `MEMBER4091`, 닉네임 중복은 `MEMBER4092`와 각각의 안내 메시지를 반환합니다.

<!-- 첨부: mission-captures/week06-challenge/01-email-conflict-409.jpg -->
<!-- 첨부: mission-captures/week06-challenge/02-nickname-conflict-409.jpg -->

필수 미션의 `04-signup-duplicate-409.jpg`는 챌린지 반영 전 캡처로, 이메일 중복 코드가 `COMMON4092`입니다. 최종 구현의 중복 오류 증빙은 위 챌린지 캡처를 기준으로 합니다.

### 5. 동시 회원가입 및 DB UNIQUE 제약 검증

Postman 스크립트로 같은 이메일을 사용하는 요청 8건과 같은 닉네임을 사용하는 요청 8건을 각각 동시에 전송했습니다.

| 조건 | 생성 성공 | 중복 거절 | 중복 응답 코드 |
| --- | --- | --- | --- |
| 같은 이메일·서로 다른 닉네임 8건 | 201 1건 | 409 7건 | `MEMBER4091` |
| 서로 다른 이메일·같은 닉네임 8건 | 201 1건 | 409 7건 | `MEMBER4092` |

Postman Test Results에서 **19/19 PASSED**를 확인했습니다. 서버 로그에서도 동일 실행 값인 `race-email-5330524@example.com`과 `N5330524`의 MySQL 오류 1062 및 `member.email`·`member.nickname` 제약 위반을 확인했습니다.

이를 통해 사전 검사 이후 실제 DB INSERT에서 발생하는 중복 오류도 500 대신 409로 응답하는 것을 확인했습니다.

<!-- 첨부: mission-captures/week06-challenge/03-concurrent-email-postman.jpg -->
<!-- 첨부: mission-captures/week06-challenge/04-concurrent-nickname-postman.jpg -->
<!-- 첨부: mission-captures/week06-challenge/05-mysql-unique-1062.jpg -->

## 학습 내용

- DTO 검증은 입력 형식·범위를, 서비스 검증은 존재 여부·중복·작성자 비교를, DB 제약은 최종 데이터 무결성을 담당한다는 점을 학습했습니다.
- 회원 엔티티를 직접 반환하는 대신 응답 DTO를 사용해 비밀번호 노출을 방지했습니다.
- `@Transactional`만으로 동시 요청의 중복을 막을 수 없으므로, 사전 검사와 DB UNIQUE 제약을 함께 적용해야 한다는 점을 확인했습니다.
- HTTP 상태 코드와 응답의 오류 코드를 함께 사용해 클라이언트가 실패 원인을 구분하도록 구성했습니다.

## 오류와 해결 과정

### 테이블 누락으로 인한 서버 실행 실패

- **문제:** 회원·평점 엔티티 추가 후 `Schema-validation: missing table [member]`가 발생했습니다.
- **원인:** `ddl-auto: validate`는 테이블을 생성하지 않으며, 연결한 DB에 필요한 테이블이 없었습니다.
- **해결:** 연결 DB를 확인하고 회원·평점 테이블을 준비한 뒤, `validate` 설정을 유지한 상태로 서버를 재실행했습니다. 이후 Postman으로 회원가입·평점 CRUD를 확인했습니다.

### 동시 가입 시 DB 중복 오류 처리

- **문제:** 동일 이메일·닉네임으로 동시에 가입하면 여러 요청이 사전 중복 검사를 통과할 수 있습니다.
- **원인:** 중복 조회와 INSERT 시점이 다르기 때문에, 사전 검사만으로는 동시 저장을 방지할 수 없습니다.
- **해결:** DB UNIQUE 제약을 유지하고 `DataIntegrityViolationException`의 원인 예외에서 제약 이름을 확인해 회원 중복 오류로 변환했습니다. 동시 요청 결과와 MySQL 로그로 처리 결과를 확인했습니다.
