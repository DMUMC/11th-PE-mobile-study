# movie (영화 평점 서비스 백엔드)

UMC 11th PE 5~6주차 NestJS 미션 (Simba). 영화 정보는 프론트가 TMDB에서 직접 받고, 이 서버는 회원과 평점만 담당합니다.

## 실행 방법

```bash
# 1. DB 생성 + 테이블 + 시드 데이터
mysql -u root -p < sql/schema.sql   # 또는 MySQL Workbench에서 sql/schema.sql 실행

# 2. 환경 변수 (.env는 Git에 커밋되지 않음)
cp .env.example .env                # DB_PASSWORD 입력

# 3. 설치 및 실행
npm install
npm run start:dev                   # http://localhost:3000
npm run lint
```

## 폴더 구조 (레이어 기준)

```
src
├── common       # ApiResponse, ErrorStatus, BusinessException, ResponseInterceptor, HttpExceptionFilter
├── controller   # MemberController, RatingController
├── service      # MemberService, RatingService
├── entity       # BaseTimeEntity, Member, Rating
├── dto          # 요청/응답 DTO, 경로 파라미터 검증 DTO
├── app.module.ts
└── main.ts      # ValidationPipe(whitelist, forbidNonWhitelisted), 전역 Interceptor/Filter, CORS
scripts
└── concurrent-signup.mjs  # 동시 요청으로 DB UNIQUE 위반 → 409 변환 재현
```

## 공통 응답 형식

성공과 실패 모두 `{ isSuccess, code, message, result }` 모양입니다. (DELETE 204는 본문 없음)

```json
{ "isSuccess": true, "code": "COMMON201", "message": "생성되었습니다.", "result": { "memberId": 3, "email": "simba@umc.com", "nickname": "심바", "createdAt": "..." } }
{ "isSuccess": false, "code": "MEMBER4091", "message": "이미 가입된 이메일입니다.", "result": null }
```

## API 명세

| API | Method | URL | Request | Success |
| --- | --- | --- | --- | --- |
| 회원가입 | POST | `/members` | Body: email(이메일 형식), nickname(2~12자), password(대·소문자·숫자·특수문자 포함 8자 이상) | 201, result: `{ memberId, email, nickname, createdAt }` (password 없음) |
| 닉네임 중복 체크 | GET | `/members/nickname/{nickname}` | Path: nickname (2~12자) | 200, result: `{ "available": true }` |
| 이메일 중복 체크 | GET | `/members/email/{email}` | Path: email (이메일 형식) | 200, result: `{ "available": true }` |
| 유저별 평점 조회 | GET | `/members/{memberId}/ratings` | Path: memberId | 200, result: `[{ ratingId, movieId, score, comment, createdAt, updatedAt }]` |
| 평점 등록 | POST | `/members/{memberId}/ratings` | Body: movieId(양의 정수, TMDB id), score(1~5 정수, 필수), comment(선택, 500자 이하) | 201, result: 평점 1건 |
| 평점 수정 | PATCH | `/members/{memberId}/ratings/{ratingId}` | Body: score?, comment? (movieId는 수정 불가) | 200, result: 평점 1건 |
| 평점 삭제 | DELETE | `/members/{memberId}/ratings/{ratingId}` | - | 204 (본문 없음) |

### 오류 응답

| 상황 | Status | code |
| --- | --- | --- |
| DTO 검증 실패, DTO에 없는 필드, id가 숫자가 아님, JSON 형식 오류 | 400 | COMMON400 (result에 실패 사유 배열) |
| 다른 회원의 평점 수정·삭제 | 403 | RATING4031 |
| 존재하지 않는 회원 | 404 | MEMBER4041 |
| 존재하지 않는 평점 | 404 | RATING4041 |
| 이메일 중복 | 409 | MEMBER4091 |
| 닉네임 중복 | 409 | MEMBER4092 |
| 같은 영화에 평점 중복 | 409 | RATING4091 |
| 예상하지 못한 서버 오류 | 500 | COMMON500 |

사전 중복 체크(`exists`)를 통과한 동시 요청이 DB UNIQUE 제약(`ER_DUP_ENTRY`)에 걸려도 `HttpExceptionFilter`가 인덱스 이름(email / nickname / uk_rating_member_movie)을 보고 위와 같은 409로 바꿉니다.

```bash
npm run race                 # 같은 회원가입 요청 10개를 동시에 → 201 1건, 409 9건
npm run race -- rating 1     # 1번 회원이 같은 영화에 평점 10개를 동시에
```

## CORS

`main.ts`에서 `.env`의 `CORS_ORIGINS`(기본 `http://localhost:5173`)만 허용합니다. Flutter 네이티브 앱은 브라우저가 아니라서 CORS 설정과 관계없이 호출할 수 있습니다.
