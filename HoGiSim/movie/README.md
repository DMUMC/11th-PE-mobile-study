# MovieLog · 5주차 백엔드

도서 API와 별도로 생성한 NestJS 영화 평점 서비스입니다.
닉네임·이메일 중복 확인과 회원별 평점 조회를 MySQL/TypeORM으로 구현하고,
브라우저 화면에서 API 3개를 모두 연결했습니다.

## 구현 내용

- Member/Rating 엔티티와 BaseTimeEntity, DTO 응답 분리
- Member–Rating 1:N, TMDB movieId 일반 컬럼, 복합 UNIQUE
- Favorite은 8주차를 위한 테이블 스키마만 준비
- 닉네임 2~12자·이메일 형식 검증, 잘못된 요청 400
- 없는 회원 404, 평점 없는 회원 200과 빈 배열
- ratingId 내림차순 및 선택적 page/size 페이지네이션
- localhost:5173만 허용하는 기본 CORS 정책
- 실제 웹 화면의 모든 API 연결과 CORS 실패/성공 비교

## 실행

프로젝트 폴더는 `HoGiSim/movie`입니다. Node.js 24, MySQL 8.4에서 검증했습니다.
`.env.example`을 `.env`로 복사하고 MySQL 정보를 입력합니다.
이 노트북에는 기존 실습 MySQL(127.0.0.1:3307)을 재사용하고 별도 `umc_movie` DB를 준비했습니다.

```powershell
npm ci
npm run db:setup
npm run build
npm run start:prod
```

다른 터미널에서 웹 화면을 실행합니다.

```powershell
npm run frontend
```

- 웹 화면: [http://localhost:5173](http://localhost:5173)
- API: http://localhost:3001
- DB: umc_movie, synchronize=false
- .env는 Git에서 제외합니다.
- 5173 대신 127.0.0.1:5173으로 접속하면 기본 허용 출처와 다르므로 CORS 설정을 맞춰야 합니다.

이 노트북에서 MySQL이 꺼져 있다면 기존 `HoGiSim/study` 프로젝트의
`npm run db:start:local`로 실습 DB 서버를 먼저 시작합니다.
DB 설정 스크립트는 기존 테이블/데이터를 삭제하지 않습니다.
별도 환경에서는 본인의 MySQL 호스트·포트로 .env를 설정합니다.

## API 명세와 ERD

| Method | URL | 정상 응답 |
| --- | --- | --- |
| GET | /members/nickname/{nickname} | {"available":true/false} |
| GET | /members/email/{email} | {"available":true/false} |
| GET | /members/{memberId}/ratings | 평점 DTO 배열 |

페이지 예시: `/members/1/ratings?page=0&size=1`.
page/size 모두 생략하면 전체 평점, 하나라도 있으면 기본 page=0·size=10을 적용합니다.

- [상세 API 명세](docs/api-spec.md)
- [ERD와 제약](docs/erd.md)
- [CORS 비교와 3문장 이상 설명](docs/cors-comparison.md)
- [진행 과정·학습·트러블슈팅·제출 기록](docs/week05-mission.md)

## 실행 화면

| 닉네임 중복 확인 | 이메일 중복 확인 |
| --- | --- |
| <img src="docs/evidence/nickname-success.jpg" alt="닉네임 200 응답" width="350"> | <img src="docs/evidence/email-success.jpg" alt="이메일 200 응답" width="350"> |

### 회원별 평점 조회

<img src="docs/evidence/ratings-success.jpg" alt="회원 1의 평점 2건" width="600">

### CORS 허용 범위 비교

| 허용되지 않은 5174 출처 | 전체 출처 허용 비교 |
| --- | --- |
| <img src="docs/evidence/cors-origin-blocked.jpg" alt="다른 출처 차단" width="420"> | <img src="docs/evidence/cors-wildcard-success.jpg" alt="같은 출처에서 wildcard 서버 성공" width="420"> |

## 검증

```powershell
npm run lint
npm test
npm run test:e2e
npm run test:postman
```

- HTTP/검증/CORS 테스트 33개 통과. DB Repository 대역 사용.
- 실제 MySQL 검증 16개 통과. DB UNIQUE/CHECK 제약 포함.
- Postman Collection: 14개 요청, 19개 검증 통과(Newman).
- 실제 브라우저에서 API 3개 호출, 페이지 이동, CORS 미설정/허용/불허/wildcard 확인.

Postman 앱에서 `postman/week05-movie.postman_collection.json`을 Import하면 같은 요청을 실행할 수 있습니다.
앱의 URL과 응답 JSON이 보이는 화면 캡처는 제출 전에 별도로 첨부합니다.
Newman 결과 파일은 Postman 앱 화면 캡처를 대신하지 않습니다.

이 프로젝트는 5주차 조회 실습입니다. 회원가입·로그인·평점 CRUD·Favorite API는 다음 주차 범위이며,
Flutter MovieLog 앱에는 이번 API를 추가 연결하지 않았습니다.
이번 주차의 실제 화면 연결은 이 프로젝트의 `frontend/` 웹 화면으로 검증했습니다.
