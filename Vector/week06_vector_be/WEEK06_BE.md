# MovieLog 6주차 백엔드

5주차의 NestJS·TypeORM·MySQL 프로젝트에 회원가입과 영화 평점 API를 추가했다. 영화 ID는 TMDB 영화 ID를 사용한다. 중복 확인과 회원별 평점 조회는 6주차 Flutter의 기본 요청 경로와 호환된다.

## 실행

1. Node.js 24와 MySQL을 준비한다. macOS의 `htpasswd` 또는 bcrypt 옵션을 지원하는 Apache `htpasswd`가 PATH에 있어야 한다. 다른 경로라면 `HTPASSWD_BIN`으로 지정한다.
2. `.env.example`을 참고해 `.env`에 DB 접속 정보를 입력한다. 기존 MySQL 데이터베이스에 `work/week06-schema.sql`을 실행한다. 새 데이터베이스에는 5주차 도서 API용 `work/bookdb-schema.sql`도 실행한다.
3. `npm ci` 후 `npm run start:dev`를 실행한다.
4. Postman에서 [컬렉션](work/week06.postman_collection.json)을 가져온 뒤 표시 순서로 실행한다. 첫 요청의 사전 스크립트가 테스트 회원용 값을 만들고 이후 요청에 필요한 ID는 이전 응답에서 저장한다.

## API 명세

기본 주소는 `http://127.0.0.1:3000`이다. JSON 요청은 `Content-Type: application/json`을 사용한다. 평점 변경 요청의 `X-Member-Id`는 워크북에서 호출자를 구분하기 위한 로컬 테스트 입력이다. 누구나 헤더를 바꿀 수 있으므로 실제 서비스에서 인증을 도입할 때는 서버가 확인한 사용자 ID로 교체해야 한다.

| 메서드와 경로 | 입력 예시 | 성공 응답 |
| --- | --- | --- |
| `POST /members` | `{"email":"vector@example.com","nickname":"Vector","password":"SamplePassword123!"}` | 201 · `{"id":1,"email":"vector@example.com","nickname":"Vector"}` |
| `GET /members/check-email?email=vector%40example.com` | 이메일 쿼리 | 200 · `{"available":false}` |
| `GET /members/check-nickname?nickname=Vector` | 닉네임 쿼리 | 200 · `{"available":false}` |
| `POST /ratings` | 헤더 `X-Member-Id: 1` · `{"movieId":157336,"score":5}` | 201 · `{"id":1,"memberId":1,"movieId":157336,"score":5}` |
| `PATCH /ratings/1` | 헤더 `X-Member-Id: 1` · `{"score":4}` | 200 · 갱신한 평점 객체 |
| `DELETE /ratings/1` | 헤더 `X-Member-Id: 1` | 204 · 빈 본문 |
| `GET /members/1/ratings` | 회원 ID | 200 · 해당 회원의 평점 배열 |

이메일은 앞뒤 공백을 제거하고 소문자로 저장한다. 닉네임은 앞뒤 공백 제거 후 2~24자다. 비밀번호는 8~72자의 공백 없는 ASCII 문자이며 영문과 숫자를 포함해야 한다. bcrypt 해시만 DB에 저장하며 가입 응답에는 비밀번호 관련 필드를 포함하지 않는다. 평점은 1~5 정수다.

오류 형식은 `{"statusCode":409,"code":"DUPLICATE_RATING","message":"이미 평점을 등록한 영화입니다."}`과 같다.

| 상태 | 코드 | 발생 조건 |
| --- | --- | --- |
| 400 | VALIDATION_ERROR | 잘못된 가입 정보, 별점 또는 ID |
| 403 | RATING_FORBIDDEN | 다른 회원의 평점을 수정하거나 삭제 |
| 404 | RATING_NOT_FOUND | 해당 평점이 없음 |
| 404 | MEMBER_NOT_FOUND | 등록을 요청한 회원이 없음 |
| 409 | DUPLICATE_MEMBER | 이메일 또는 닉네임 중복 |
| 409 | DUPLICATE_RATING | 같은 회원이 같은 영화에 평점을 중복 등록 |

## 핵심 코드

- [컨트롤러](src/movielog/movielog.controller.ts) · [DTO](src/movielog/dto.ts)
- [회원 서비스](src/movielog/members.service.ts) · [bcrypt 처리](src/movielog/password.ts) · [회원 Entity](src/movielog/member.entity.ts)
- [평점 서비스](src/movielog/ratings.service.ts) · [평점 Entity](src/movielog/rating.entity.ts) · [MySQL 스키마](work/week06-schema.sql)

## 요청·응답 증빙

- [회원가입과 검증](week06-evidence/01-members.png)
- [평점 등록과 중복 처리](week06-evidence/02-ratings.png)
- [소유권 검사, 수정, 삭제](week06-evidence/03-ownership-and-delete.png)
- [전체 요청·응답 원본](week06-evidence/requests-responses.json)

이미지는 실행 기록을 읽기 쉽게 정리한 것이다. 실제 NestJS 컨트롤러·서비스·검증 파이프와 bcrypt를 실행했고, DB 저장소만 테스트용으로 대체했다. 18개 HTTP 사례에서 비밀번호 필드 제외, 중복 저장 차단, 타인 수정·삭제의 403, 누락 404, 삭제 204 빈 본문을 확인했다. MySQL 저장은 로컬 실행 후 Postman 컬렉션으로 확인해야 한다.

```bash
npm run build
npm test -- --runInBand
node work/week06-verify.cjs
```

## 트러블슈팅

중복 확인 후 저장하는 방식은 동시에 두 요청이 오면 두 요청 모두 중복 확인을 통과할 수 있다. 이메일·닉네임과 `(member_id, movie_id)`에 MySQL 고유 제약을 두고, 삽입 시 발생하는 `ER_DUP_ENTRY`를 409로 변환했다.

작업 환경에서 MySQL 소켓이 `EPERM`으로 차단됐다. HTTP 검증에서는 MySQL 중복 오류를 재현하는 테스트 저장소를 주입했다. npm 레지스트리 DNS도 막혀 있어, 설치된 Apache `htpasswd`의 bcrypt 기능으로 비용 10의 해시를 생성했다. 비밀번호는 자식 프로세스에 표준입력으로 전달했다.
