# MovieLog 6주차 백엔드

## API 명세

| 기능 | 요청 | JSON 요청 본문 | 성공 응답 |
| --- | --- | --- | --- |
| 회원가입 | `POST /members` | `email`, `nickname`, `password` | 201 · `COMMON201` · 회원 ID, 이메일, 닉네임 |
| 평점 등록 | `POST /members/{memberId}/ratings` | `movieId`, `score`, 선택 `comment` | 201 · `COMMON201` · 평점 ID |
| 평점 수정 | `PATCH /members/{memberId}/ratings/{ratingId}` | `score`, 선택 `comment` | 200 · `COMMON200` · `result: null` |
| 평점 삭제 | `DELETE /members/{memberId}/ratings/{ratingId}` | 없음 | 204 · 본문 없음 |

- 이메일은 최대 254자의 이메일 형식이고, 닉네임은 공백만으로 이루어지지 않은 2~12자다.
- 비밀번호는 8자 이상이며 영문 대문자·소문자·숫자·특수문자를 포함해야 한다. bcrypt의 입력 한도인 UTF-8 72바이트를 적용하고, DB에는 60자 해시를 저장한다.
- 경로의 두 ID와 본문의 `movieId`는 양의 안전 정수다. `score`는 1~5 정수이며, `comment`는 최대 500자다. 수정에서 후기를 생략하거나 `null`로 보내면 기존 후기를 비운다.
- 쓰기 요청은 성공과 실패 모두 `isSuccess`, `code`, `message`, `result`를 사용한다. DELETE 성공은 HTTP 204 규칙에 따라 본문이 없다. 기존 조회 API는 5주차 형식을 유지한다.

```json
{
  "isSuccess": true,
  "code": "COMMON201",
  "message": "회원가입에 성공했습니다.",
  "result": { "memberId": 4, "email": "test@example.com", "nickname": "영화팬" }
}
```

| HTTP | 코드 | 조건 |
| --- | --- | --- |
| 400 | `COMMON400` | DTO 검증 실패 또는 잘못된 경로 ID |
| 403 | `COMMON403` | 다른 회원의 평점 수정·삭제 |
| 404 | `COMMON404` | 등록할 회원 또는 수정·삭제할 평점이 없음 |
| 409 | `MEMBER4091` | 이메일 중복 |
| 409 | `MEMBER4092` | 닉네임 중복 |
| 409 | `RATING4091` | 동일 회원이 같은 영화에 이미 평점을 등록함 |

실패 응답의 `result`는 `null`이다. 같은 충돌에는 사전 조회와 DB UNIQUE 위반 모두 동일한 코드와 문구를 반환한다.

## 핵심 코드

- [회원가입과 bcrypt 해시 저장](../src/service/member.service.ts)
- [평점 등록·수정·삭제 및 소유자 비교](../src/service/rating.service.ts)
- [전역 예외 필터](../src/write-exception.filter.ts) · [MySQL UNIQUE 오류 매핑](../src/write-errors.ts)
- [실제 MySQL 동시 요청 테스트](../test/week06.mysql.test.mjs)

## 실행 및 검증

```powershell
npm ci
npm run db:setup
npm test
npm run lint
npm run test:e2e:week06
```

MySQL 접속 정보는 `.env.example`을 기준으로 설정한다. 테스트가 만든 회원과 평점은 종료 시 정리한다. 증거 JSON을 다시 만들려면 PowerShell에서 `$env:WEEK06_EVIDENCE = '1'`을 설정한 뒤 6주차 통합 테스트를 실행한다.

- [회원가입 요청·응답](evidence/week06/signup.png)
- [평점 등록·수정·삭제 요청·응답](evidence/week06/rating-crud.png)
- [동시 요청과 UNIQUE 충돌](evidence/week06/unique-race.png)
- [전체 HTTP 요청·응답 기록](evidence/week06/mysql-http.json)

## 트러블슈팅

테스트에서 두 요청을 사전 중복 확인이 끝난 지점에 모은 뒤 동시에 저장했다. 두 요청 모두 사전 검사를 통과했지만, MySQL은 한 건만 저장하고 다른 요청에 `ER_DUP_ENTRY`를 반환했다. 전역 예외 필터에서 위반한 인덱스를 기준으로 이메일·닉네임·평점의 409 응답을 각각 매핑했다. 재검증에서 각 요청 쌍이 201 한 건과 409 한 건으로 끝났고, 중복 평점이 DB에 한 행만 남는 것을 확인했다.
