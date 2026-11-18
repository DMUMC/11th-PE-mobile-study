# MovieLog 7주차 백엔드

- `POST /auth/login`에 이메일과 비밀번호를 보내면 200 응답으로 1시간짜리 JWT `accessToken`을 받습니다.
- `GET /members/me`와 평점 등록·수정·삭제는 `Authorization: Bearer <accessToken>` 헤더를 사용합니다.
- 평점 등록 본문은 `{"movieId":550,"score":4}`입니다. 서버가 JWT에서 회원 ID를 읽습니다.
- 인증 실패는 401 `UNAUTHORIZED`, 다른 회원의 평점 변경은 403 `RATING_FORBIDDEN`입니다.

## 로컬 실행

1. `npm ci`를 실행합니다. 기존 6주차와 동일하게 `htpasswd`가 PATH에 필요합니다.
2. `.env.example`을 `.env`로 복사하고 DB 접속 정보와 `openssl rand -hex 32`로 만든 `JWT_SECRET`을 설정합니다.
3. 새 DB라면 `work/bookdb-schema.sql`과 `work/week06-schema.sql`을 순서대로 적용합니다. 기존 6주차 DB는 그대로 사용합니다.
4. `npm run start:dev`를 실행합니다.
5. Postman에서 `work/week07.postman_collection.json`을 가져와 1~9번을 순서대로 실행합니다. 워크북 본문이 제공되지 않아 첨부된 제출 조건을 기준으로 순서를 구성했습니다.

## 검증 자료

`npm run build && node work/week07-verify.cjs`는 실제 NestJS HTTP 요청과 응답을 인메모리 테스트 데이터로 재현합니다. `week07-evidence`의 PNG는 이 응답을 시각화한 이미지입니다. Postman 화면이나 MySQL 연동 캡처는 포함되지 않습니다. 이미지 속 토큰은 실행할 때마다 만들어지는 테스트 전용 키로 발급했습니다.
