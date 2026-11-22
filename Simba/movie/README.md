# movie (영화 평점 서비스 백엔드)

UMC 11th PE 5~7주차 NestJS 미션 (Simba). 영화 정보는 프론트가 TMDB에서 직접 받고, 이 서버는 회원과 평점만 담당합니다.

## 실행 방법

```bash
# 1. DB 생성 + 테이블 + 시드 데이터
mysql -u root -p < sql/schema.sql   # 또는 MySQL Workbench에서 sql/schema.sql 실행

# 2. 환경 변수 (.env는 Git에 커밋되지 않음)
cp .env.example .env                # DB_PASSWORD, JWT_SECRET(32자 이상) 입력

# 3. 설치 및 실행
npm install
npm run start:dev                   # http://localhost:3000
npm run lint
```

## 폴더 구조 (레이어 기준)

```
src
├── common       # ApiResponse, ErrorStatus, ResponseInterceptor, HttpExceptionFilter
├── exception    # ApiException (HttpException + code)
├── guard        # AuthGuard (Bearer 토큰 검증 → request.memberId)
├── decorator    # @LoginMember() (request.memberId를 파라미터로 꺼냄)
├── pipe         # PositiveIntPipe (경로 id가 1 이상인지 확인)
├── controller   # Auth, Member, Rating, Favorite, MovieRecord Controller
├── service      # Auth, Member, Rating, Favorite, MovieRecord Service
├── entity       # BaseTimeEntity, Member, Rating, Favorite
├── dto          # 요청/응답 DTO, 경로 파라미터 검증 DTO
├── app.module.ts
└── main.ts      # ValidationPipe(whitelist, forbidNonWhitelisted), 전역 Interceptor/Filter, CORS, Swagger(/api-docs)
scripts
└── concurrent-signup.mjs  # 동시 요청으로 DB UNIQUE 위반 → 409 변환 재현
```

## 공통 응답 형식

성공과 실패 모두 `{ isSuccess, code, message, result }` 모양입니다. (DELETE도 200 + `result: null`)

```json
{ "isSuccess": true, "code": "COMMON201", "message": "생성되었습니다.", "result": { "memberId": 3, "email": "simba@umc.com", "nickname": "심바", "createdAt": "..." } }
{ "isSuccess": false, "code": "MEMBER409_2", "message": "이미 가입된 이메일입니다.", "result": null }
```

## API 명세

🔒 표시는 `Authorization: Bearer <accessToken>` 헤더가 필요합니다. 쓰기 API는 URL·Body로 memberId를 받지 않고 토큰에서 꺼냅니다.

| API | Method | URL | Request | Success |
| --- | --- | --- | --- | --- |
| 회원가입 | POST | `/members` | Body: email(이메일 형식), nickname(2~12자), password(대·소문자·숫자·특수문자 포함 8자 이상) | 201, result: `{ memberId, email, nickname, createdAt }` (password 없음) |
| 로그인 | POST | `/auth/login` | Body: email, password (비밀번호 규칙은 검사하지 않음) | 200, result: `{ nickname, accessToken }` |
| 닉네임 중복 체크 | GET | `/members/nickname/{nickname}` | Path: nickname (2~12자) | 200, result: `{ "available": true }` |
| 이메일 중복 체크 | GET | `/members/email/{email}` | Path: email (이메일 형식) | 200, result: `{ "available": true }` |
| 🔒 내 정보 조회 | GET | `/members/me` | - | 200, result: `{ memberId, email, nickname, createdAt }` |
| 🔒 내 정보 수정 | PATCH | `/members/me` | Body: nickname(2~12자) | 200, result: 위와 같음 |
| 유저별 평점 조회 | GET | `/members/{memberId}/ratings` | Path: memberId (공개, 토큰 불필요) | 200, result: `[{ ratingId, movieId, score, comment, createdAt, updatedAt }]` |
| 🔒 평점 등록 | POST | `/ratings` | Body: movieId(양의 정수, TMDB id), score(1~5 정수, 필수), comment(선택, 500자 이하) | 201, result: 평점 1건 |
| 🔒 평점 수정 | PATCH | `/ratings/{ratingId}` | Body: score?, comment? (movieId는 수정 불가) | 200, result: 평점 1건 |
| 🔒 평점 삭제 | DELETE | `/ratings/{ratingId}` | - | 200, result: `null` |
| 🔒 즐겨찾기 추가 | POST | `/favorites` | Body: movieId(양의 정수, TMDB id) | 201, result: `{ favoriteId, movieId, createdAt }` |
| 🔒 내 즐겨찾기 목록 | GET | `/favorites` | - | 200, result: 즐겨찾기 배열 (favoriteId 내림차순, 없으면 `[]`) |
| 🔒 즐겨찾기 여부 | GET | `/favorites/{movieId}` | Path: movieId (양의 정수) | 200, result: `{ "isFavorite": true }` (안 했어도 오류 아님) |
| 🔒 즐겨찾기 해제 | DELETE | `/favorites/{movieId}` | Path: movieId (양의 정수) | 200, result: `null` |
| 🔒 영화 기록 | POST | `/movie-records` | Body: movieId, score(1~5), comment?, addToFavorites(boolean) | 201, result: `{ rating, favorite }` (addToFavorites가 false면 favorite은 `null`) |

### 오류 응답

| 상황 | Status | code |
| --- | --- | --- |
| DTO 검증 실패, DTO에 없는 필드, id가 숫자가 아님, JSON 형식 오류 | 400 | COMMON400 (result에 실패 사유 배열) |
| 로그인 실패 (없는 이메일·틀린 비밀번호 모두) | 401 | AUTH401_1 |
| Authorization: Bearer 헤더 없음 | 401 | AUTH401_2 |
| 위조·손상된 토큰 | 401 | AUTH401_3 |
| 만료된 토큰 | 401 | AUTH401_4 |
| 다른 회원의 평점 수정·삭제 | 403 | RATING403_1 |
| 존재하지 않는 회원 | 404 | MEMBER404_1 |
| 존재하지 않는 평점 | 404 | RATING404_1 |
| 닉네임 중복 (가입, 내 정보 수정 — 나는 제외) | 409 | MEMBER409_1 |
| 이메일 중복 | 409 | MEMBER409_2 |
| 같은 영화에 평점 중복 | 409 | RATING409_1 |
| 즐겨찾기하지 않은 영화를 해제 | 404 | FAVORITE404_1 |
| 같은 영화를 즐겨찾기 중복 | 409 | FAVORITE409_1 |
| 예상하지 못한 서버 오류 | 500 | COMMON500 |

평점 수정·삭제는 평점이 있는지(404)를 먼저 확인한 뒤 작성자가 다르면 403으로 응답합니다.

### 영화 기록 트랜잭션 (8주차)

`POST /movie-records`는 `MovieRecordService`(`src/service/movie-record.service.ts`)에서 `DataSource.transaction()` 콜백 안의 `manager.getRepository()`로 평점과 즐겨찾기를 함께 저장합니다. 즐겨찾기 저장이 실패하면(`FAVORITE409_1`) 먼저 INSERT한 평점도 롤백되어, 평점만 남는 반쪽 기록이 생기지 않습니다.

### Swagger

서버 실행 후 `http://localhost:3000/api-docs`. 로그인으로 받은 accessToken을 Authorize에 넣으면 🔒 API를 호출할 수 있습니다.

### 토큰 만료 테스트

`.env`의 `JWT_ACCESS_EXPIRATION=60`으로 바꾸고 서버를 다시 켠 뒤, 로그인해서 받은 토큰으로 60초가 지난 후 `GET /members/me`를 호출하면 401 `AUTH401_4`가 옵니다. 테스트 후 `3600`으로 되돌립니다.

사전 중복 체크(`exists`)를 통과한 동시 요청이 DB UNIQUE 제약(`ER_DUP_ENTRY`)에 걸려도 `HttpExceptionFilter`가 인덱스 이름(email / nickname / uk_rating_member_movie / uk_favorite_member_movie)을 보고 위와 같은 409로 바꿉니다.

```bash
npm run race                 # 같은 회원가입 요청 10개를 동시에 → 201 1건, 409 9건
npm run race -- rating <accessToken>   # 로그인한 회원이 같은 영화에 평점 10개를 동시에
```

## CORS

`main.ts`에서 `.env`의 `CORS_ORIGINS`(기본 `http://localhost:5173`)만 허용합니다. Flutter 네이티브 앱은 브라우저가 아니라서 CORS 설정과 관계없이 호출할 수 있습니다.
