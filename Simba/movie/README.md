# movie (영화 평점 서비스 백엔드)

UMC 11th PE 5주차 NestJS 미션 (Simba). 영화 정보는 프론트가 TMDB에서 직접 받고, 이 서버는 회원과 평점만 담당합니다.

## 실행 방법

```bash
# 1. DB 생성 + 테이블 + 시드 데이터
mysql -u root -p < sql/schema.sql   # 또는 MySQL Workbench에서 sql/schema.sql 실행

# 2. 환경 변수 (.env는 Git에 커밋되지 않음)
cp .env.example .env                # DB_PASSWORD 입력

# 3. 설치 및 실행
npm install
npm run start:dev                   # http://localhost:3000
```

## 폴더 구조 (레이어 기준)

```
src
├── controller   # MemberController, RatingController
├── service      # MemberService, RatingService
├── entity       # BaseTimeEntity, Member, Rating
├── dto          # 응답 DTO, 경로 파라미터 검증 DTO
├── app.module.ts
└── main.ts      # ValidationPipe, CORS
```

## API 명세

| API | Method | URL | Request | Success Response (200) |
| --- | --- | --- | --- | --- |
| 닉네임 중복 체크 | GET | `/members/nickname/{nickname}` | Path: nickname (string, 2~12자) | `{ "available": true }` |
| 이메일 중복 체크 | GET | `/members/email/{email}` | Path: email (string, 이메일 형식) | `{ "available": true }` |
| 유저별 평점 조회 | GET | `/members/{memberId}/ratings` | Path: memberId (number) | `[{ "ratingId": 2, "movieId": 155, "score": 4, "comment": "다시 봐도 명작", "createdAt": "...", "updatedAt": "..." }]` |

### 오류 응답

| 상황 | Status |
| --- | --- |
| 닉네임이 2~12자가 아님 / 이메일 형식이 아님 | 400 |
| memberId가 숫자가 아님 | 400 |
| 존재하지 않는 memberId | 404 |

## CORS

`main.ts`에서 `.env`의 `CORS_ORIGINS`(기본 `http://localhost:5173`)만 허용합니다. Flutter 네이티브 앱은 브라우저가 아니라서 CORS 설정과 관계없이 호출할 수 있습니다.
