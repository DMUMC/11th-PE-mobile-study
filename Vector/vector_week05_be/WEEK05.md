# 5주차 백엔드 미션

기존 NestJS·TypeORM·MySQL 도서 API를 MovieLog의 **도서** 탭에 연결했다. 조회 응답으로 목록을 그리고, 등록 성공 후 목록을 다시 조회한다. 브라우저의 JSON POST 요청을 위해 NestJS에서 로컬 Flutter 웹 주소에 CORS를 허용했다.

| 기능 | API | 화면에서 확인할 내용 |
| --- | --- | --- |
| 목록 조회 | `GET /books` | 도서 탭의 `200 OK`와 MySQL 도서 목록 |
| 신규 등록 | `POST /books` | `201 Created`와 새 도서 ID, 갱신된 목록 |
| 요청 검증 | `POST /books` | 잘못된 DTO는 400, 존재하지 않는 카테고리는 404 |

## 실행

MySQL에서 기존 `bookdb`를 사용한다. 새 환경이라면 `.env.example`을 `.env`로 복사해 접속 정보를 입력하고 `work/bookdb-schema.sql`로 테이블을 만든다. 도서를 등록하기 전에 `SELECT id, name FROM bookdb.category;`로 카테고리 ID를 확인한다. 기존 Postman 실행 때는 ID 1이 프로그래밍 카테고리였다.

첫 번째 터미널에서 실행한다.

```bash
cd ~/Desktop/book-api
npm ci
npm run start:dev
```

두 번째 터미널에서 Flutter 웹을 실행한다.

```bash
cd ~/Desktop/book-api/movielog
flutter pub get
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8080 --dart-define=USE_FAKE_MOVIES=true
```

브라우저에서 [MovieLog 도서 탭](http://127.0.0.1:8080/#/books)을 연다. 위 실행 옵션은 영화 탭의 샘플 데이터에만 적용된다. 도서 탭은 항상 NestJS에 HTTP 요청을 보낸다. 영화 탭도 TMDB를 사용하려면 샘플 옵션 대신 이전 작업과 동일한 `TMDB_READ_ACCESS_TOKEN`을 전달한다.

## 제출 증빙

1. `src/book.entity.ts`, `src/category.entity.ts`, `src/create-book.dto.ts`, `src/books.controller.ts`, `src/books.service.ts`가 기존 ORM API 핵심 코드다. `src/main.ts`에서 CORS 변경을 확인할 수 있다.
2. `submission-screenshots/`에 이전 Postman의 GET 200, POST 201, 잘못된 DTO 400 캡처가 있다. 새로 재현할 때는 `work/week4-books.postman_collection.json`을 가져오고, 등록 요청의 `categoryId`를 현재 DB에 존재하는 ID로 설정한다.
3. Flutter 도서 탭에서 제목·설명·카테고리 ID를 입력해 등록한다. 화면에 POST 201과 GET 200, 새로 생긴 도서가 함께 보일 때 캡처한다.

## 트러블슈팅

- 기존 NestJS 폴더 이름 끝에 공백이 있어 지정된 작업 경로에서 열리지 않았다. 공백 없는 `~/Desktop/book-api`에 작업 사본을 만들었다.
- 이번 작업 환경은 MySQL TCP 접속과 Unix 소켓 접속을 모두 `EPERM`으로 차단했다. 실제 앱의 성공 응답 캡처는 위 두 터미널을 맥에서 실행해 남겨야 한다.
