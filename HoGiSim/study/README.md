# HoGiSim · 4주차 ORM 도서 API

3주차 Raw SQL 기반 도서 API를 NestJS + TypeORM으로 전환했습니다.
필수 미션과 선택 미션 3개(카테고리 이름 조회, 제목 검색, 중복 등록 방지)를 구현했습니다.

## 실행

Node.js 24 기준입니다. 프로젝트 폴더에서 실행합니다.

```powershell
npm ci
npm run db:start:local
npm run db:check
npm run start:prod
```

빌드 결과가 없거나 소스를 변경했다면 먼저 `npm run build`를 실행합니다.
API 주소는 `http://127.0.0.1:3000/books`입니다.
이 노트북에는 별도 실습 MySQL을 `.local/`에 준비했으며,
접속 정보는 Git에서 제외한 `.env`에 저장했습니다.
DB는 `127.0.0.1:3307/study_week04`입니다.
DB와 서버는 컴퓨터 재시작 후 위 명령으로 다시 실행합니다.
DB 종료 명령은 `npm run db:stop:local`입니다.

다른 컴퓨터에서 실행한다면 `.env.example`을 `.env`로 복사하고 실제 MySQL 정보를 입력합니다.
기존 3주차 DB는 `npm run db:check`로 스키마를 확인하고 엔티티의 타입/길이를 맞춘 다음
`npm run migration:run`으로 제목 UNIQUE 제약을 적용합니다.
이 노트북의 실습 DB에는 이미 적용했습니다.
새 DB만 사용할 경우 Workbench 또는 mysql CLI에서
`sql/fresh-practice-schema.sql`을 먼저 실행합니다.
기존 데이터는 이 SQL로 다시 생성하지 않습니다.

## API

| 요청 | 동작 | 정상 상태 |
| --- | --- | --- |
| GET /books | 대여 상태와 무관하게 도서 ID 내림차순 조회 | 200 |
| GET /books?keyword=스프링 | 제목 부분 검색, 검색 결과가 없으면 빈 배열 | 200 |
| POST /books | 카테고리 확인 후 도서 등록 | 201 |

POST 본문:

```json
{ "categoryId": 1, "title": "ORM으로 배우는 도서 API", "description": "선택 입력" }
```

응답은 `bookId, title, description, categoryName, isAvailable`만 포함합니다.
`categoryId`는 양의 정수 숫자이며 숫자 문자열/boolean을 허용하지 않습니다.
제목은 공백만 입력할 수 없고 100자 이하여야 합니다.
설명은 생략하거나 null을 전달할 수 있습니다.
잘못된 본문/검색 조건은 400, 없는 카테고리는 404,
중복 제목은 409를 반환합니다. MySQL의 현재 collation 기준으로 중복을 판단합니다.

## 구조

- `src/entities/`: book/category 테이블 및 N:1, 1:N 관계
- `src/dto/`: 요청 검증과 응답 형식
- `src/book.repository.ts`: TypeORM Repository 조회·저장
- `src/book.service.ts`: 카테고리 확인, 응답 DTO 변환, DB 오류 변환
- `src/book.controller.ts`: GET/POST 요청 수신
- `src/books.module.ts`: 엔티티 Repository 및 서비스 등록
- `src/setup-app.ts`: 전역 ValidationPipe
- `src/migrations/`: 중복 데이터 사전 확인 후 UNIQUE 인덱스 생성
- `docs/week03-raw-sql/`: 수정 전 3주차 코드 원본
- `docs/week04-mission.md`: 제출용 진행 기록과 비교 설명

`synchronize: false`를 유지하며 스키마 변경은 명시적 마이그레이션으로 수행합니다.
목록 조회 시 category를 함께 조회해 응답 DTO 변환 때 추가 조회하지 않습니다.

## 검증

```powershell
npm run lint
npm test
npm run test:http
npm run test:e2e
npm run test:postman
```

- `test:http`: 컴파일된 실제 Nest HTTP/DTO/Service 경로. Repository 대역을 사용하는 22개 테스트.
- `test:e2e`: 실제 MySQL과 ORM을 사용하는 15개 검증. 전용 카테고리와 도서를 생성하고 완료 후 해당 데이터만 정리.
- `test:postman`: 실행 중인 서버에 Postman Collection을 Newman으로 요청. 등록한 도서 1개는 캡처용으로 DB에 남음.
- 실제 MySQL 결과: `docs/evidence/mysql-api-results.json`
- Postman Collection: `postman/week04-books.postman_collection.json`

Postman 앱에서는 위 Collection을 Import한 후 01부터 순서대로 실행합니다.
02 실행 시 고유한 제목을 만들고, 03과 04에서 같은 제목으로 검색/중복 오류를 확인합니다.
앱의 GET 성공, POST 201, 400/404/409 응답 화면은 직접 캡처해 미션 기록에 첨부합니다.
