# 4주차 미션 기록 · HoGiSim

작성일: 2026-10-29 (한국 시간)

## 목표와 범위

3주차의 Raw SQL 도서 API를 NestJS + TypeORM 기반으로 리팩터링했다.
필수 구현과 선택 심화 3개를 모두 구현했다.
이 노트북에서 기존 3주차 DB 접속 정보를 확인하지 못해,
별도 로컬 MySQL 8.4.13과 실습 DB를 준비해 검증했다.
다른 PC의 기존 3주차 DB에 연결할 때는 실제 스키마와 엔티티 타입을 다시 비교해야 한다.

## 진행 과정

1. 기존 `book.controller.ts → book.service.ts → book.repository.ts` 흐름을 확인했다.
   목록은 `SELECT * FROM book` 결과를 그대로 반환했고,
   등록은 SQL 파라미터 배열을 직접 만들고 완료 문자열을 반환했다.
2. `week04_HoGiSim_be` 브랜치를 만들었다.
   수정 전 6개 파일을 `docs/week03-raw-sql/`에 보관했다.
3. `@nestjs/typeorm`, `typeorm`, `class-validator`, `class-transformer`를 추가했다.
   DB 드라이버는 기존 `mysql2`를 사용했다.
4. `Book`과 `Category` 엔티티를 만들고
   `category 1 : N book` 관계를 `OneToMany` / `ManyToOne`으로 표현했다.
   `book_id`, `category_id`, `is_available`을 명시적으로 매핑했다.
5. `CreateBookDto`, `BookQueryDto`, `BookResponseDto`를 분리했다.
   전역 ValidationPipe를 적용해 제목·카테고리 ID·설명을 검증하고,
   정의하지 않은 입력 필드는 400으로 차단했다.
6. `BookRepository`에서 SQL 문자열 대신 TypeORM Repository의 `find`, `findOneBy`, `create`, `save`를 사용했다.
   목록은 도서 ID 내림차순으로 정렬하고 카테고리를 함께 조회했다.
7. Service에서 카테고리 존재 여부를 검사하고, 없는 경우 404를 반환하도록 했다.
   등록 성공은 Response DTO와 201을 반환한다.
8. 선택 심화로 제목 부분 검색과 중복 제목 방지를 추가했다.
   MySQL UNIQUE 인덱스를 마이그레이션으로 적용하고
   중복 INSERT 오류를 409 Conflict로 바꿨다.
9. 기존 MySQL 설치를 기본 경로·서비스·실행 파일 경로에서 찾지 못했다.
   사용자 요청에 따라 `.local/`에 별도 MySQL을 준비하고,
   `127.0.0.1:3307/study_week04`에 실습 테이블과 더미 데이터를 만들었다.
   무작위 DB 비밀번호는 `.env`에 저장하고 Git에서 제외했다.
10. HTTP 테스트 22개, 실제 MySQL 검증 15개,
    Postman Collection의 요청 9개·검증 13개를 실행했다.

## 구현 항목

| 구분 | 구현 내용 | 상태 |
| --- | --- | --- |
| 필수 | Book·Category 엔티티와 N:1 관계 | 완료 |
| 필수 | GET /books: 5개 응답 필드, 최신순, 모든 대여 상태 | 완료 |
| 필수 | POST /books: 저장 후 201 및 응답 DTO | 완료 |
| 필수 | DTO 검증 및 없는 카테고리 예외 처리 | 완료 |
| 선택 1 | categoryName 포함 및 Response DTO 사용 | 완료 |
| 선택 2 | GET /books?keyword=스프링 | 완료 |
| 선택 3 | DB title UNIQUE, 중복 등록 시 409 | 완료 |

선택 1의 카테고리 이름과 Response DTO는 이번 워크북의 필수 요구사항과도 겹친다.
선택 2·3도 별도로 구현하고 검증했다.

## 실행 결과

- `npm run build`: 성공.
- `npm run lint`: 성공.
- `npm test`: 기존 단위 테스트 1개 통과.
- `npm run test:http`: HTTP/DTO/Service 테스트 22개 통과. Repository 대역 사용.
- `npm run test:e2e`: 실제 MySQL·TypeORM·Nest HTTP 검증 15개 통과.
- `npm run test:postman`: Newman으로 Postman Collection 실행. 요청 9개와 검증 13개 통과.

| 요청/상황 | 실제 결과 |
| --- | --- |
| 도서 목록 | 200, bookId 내림차순, categoryName 포함 |
| 도서 등록 | 201, 실제 MySQL 행 저장 확인 |
| 설명 생략 | 201, description=null |
| 대여 중인 도서 | GET 목록에 포함, isAvailable=false |
| 제목 부분 검색 | 200, 해당 제목만 반환 |
| 검색 결과 없음 | 200, 빈 배열 |
| 빈 제목·공백 제목·101자 제목 | 400 |
| 문자열 categoryId | 400 |
| 없는 카테고리 | 404 |
| 중복 제목 | 409 |
| 동시 중복 등록 2회 | 201 1회, 409 1회 |
| 직접 SQL 중복 INSERT | ER_DUP_ENTRY, DB 제약이 차단 |

실제 요청·응답은 `docs/evidence/mysql-api-results.json`과
`docs/evidence/postman-results.json`에 기록했다.
Newman 결과는 Postman Collection 실행 증거이며 Postman 앱 화면 캡처는 아니다.

**요구사항 검증 한 문장:**
실제 MySQL에서 도서 목록·등록·검색이 지정된 응답 DTO와 상태 코드로 동작하고, 잘못된 요청·없는 카테고리·중복 제목이 각각 400·404·409로 차단됨을 확인했다.

## Raw SQL과 비교해 바뀐 점

3주차에는 Repository에서 SQL 문자열과 물음표 파라미터 순서를 직접 관리했지만,
4주차에는 Entity 매핑과 TypeORM Repository 메서드로 조회·저장을 표현했다.
기존에는 DB 컬럼명이 응답에 드러났지만, 이제 Response DTO에서 필요한 다섯 필드만 골라
camelCase 이름으로 반환한다.
요청은 CreateBookDto와 ValidationPipe를 거치므로 제목 누락·공백·길이 초과와
잘못된 카테고리 ID 자료형을 저장 전에 차단한다.
카테고리 존재 여부를 확인하고 DB의 UNIQUE 위반을 409로 변환해
사용자가 실패 원인을 알 수 있도록 했다.
ORM도 내부적으로 SQL을 실행하므로 PK/FK, 정렬, 조인과 DB 제약을 계속 이해해야 한다.

## 핵심 키워드 정리

- **JPA / Hibernate / TypeORM**:
  JPA는 Java의 ORM 명세이고 Hibernate는 그 구현체 중 하나다.
  이 프로젝트에서 사용한 TypeORM은 TypeScript/JavaScript ORM 라이브러리다.
- **Entity Lifecycle / Persistence Context**:
  JPA의 영속성 컨텍스트는 엔티티를 관리하고 flush 때 SQL을 반영할 수 있다.
  TypeORM을 JPA와 같은 변경 감지 구조로 가정하면 안 된다.
  이번 구현은 `await repository.save()`로 저장 완료를 기다린다.
- **DTO / API Contract**:
  DB 엔티티와 외부 API 형식을 분리한다.
  DB 컬럼·관계 전체를 노출하지 않고 필요한 응답만 제공한다.
- **Validation**:
  요청 경계에서 자료형·필수 값·길이를 검증하면 Service는 유효한 입력을 기준으로 동작한다.
  단, 카테고리 존재 여부처럼 DB가 필요한 검증은 Service/DB에서 처리한다.
- **N+1 Query**:
  목록 N개에 대해 관계 조회를 N번 추가하면 쿼리가 증가한다.
  이번 목록은 `relations: { category: true }`로 카테고리를 함께 조회한다.
- **Migration / synchronize**:
  `synchronize: false`를 유지하고 UNIQUE 인덱스는 명시적 마이그레이션으로 변경한다.
  기존 중복 제목이 있으면 데이터를 자동 삭제하지 않고 오류로 중단한다.

## 트러블슈팅 기록

### 1. 실제 MySQL 접속 환경 부재

**이슈**: 프로젝트에 .env가 없고 로컬 MySQL 서비스 및 기본 설치 경로를 찾지 못했다.

**문제**: 다른 컴퓨터의 DB 환경과 이 노트북의 환경이 달랐다.

**해결**: 사용자 요청에 따라 별도 로컬 MySQL과 전용 실습 DB를 준비했다.
3307 포트와 별도 데이터 폴더를 사용하고 접속 정보는 Git에서 제외했다.

### 2. DTO 검증과 실제 요청 적용

**이슈**: 기존 Controller가 `Record<string, any>`를 받아 입력 형식을 제한하지 않았다.

**문제**: 타입 선언만으로는 런타임 HTTP 요청을 검증할 수 없다.

**해결**: DTO의 검증 데코레이터와 전역 ValidationPipe를 함께 적용했다.
빈 문자열뿐 아니라 공백만 있는 제목도 차단하고 HTTP 테스트로 확인했다.

### 3. 중복 제목의 동시 요청

**이슈**: 애플리케이션에서 제목 존재 여부만 미리 확인하면 두 요청이 동시에 통과할 수 있다.

**문제**: 사전 조회만으로는 DB 저장 시점의 경쟁 상태를 막지 못한다.

**해결**: DB UNIQUE 인덱스로 중복을 보장하고 ER_DUP_ENTRY를 409로 변환했다.
실제 동시 요청 2개의 결과가 201·409임을 확인했다.

## 제출 전 남은 항목

- [ ] Postman 앱에 `postman/week04-books.postman_collection.json`을 Import.
- [ ] 01 GET 성공, 02 POST 201, 04/05/07 오류 화면 캡처.
- [ ] 선택 기능인 검색(03), 중복 오류(04)의 화면 캡처.
- [ ] 핵심 코드 캡처 또는 GitHub 링크 첨부.
- [ ] 이 기록과 캡처를 개인 Notion 미션 페이지에 옮기기.
- [ ] 본인의 학습 후기 작성, 필요 시 실제 추가 트러블슈팅 기록.
- [ ] 스터디 인증샷 첨부.
- [ ] 개인 Notion 페이지 URL을 UMC 사이트에 제출.

권장 활동인 블로그 챌린지와 CodeRabbit 리뷰는 별도 진행 항목이다.
작성자의 실제 학습 후기와 인증샷은 대신 만들어 기록하지 않았다.

## 참고 자료

- [NestJS TypeORM](https://docs.nestjs.com/techniques/database)
- [NestJS Validation](https://docs.nestjs.com/techniques/validation)
- [TypeORM Entity decorators](https://typeorm.io/docs/help/decorator-reference/)
- [TypeORM Migrations](https://typeorm.io/docs/migrations/api/)
- [MySQL Community Server](https://dev.mysql.com/downloads/mysql/8.4.html)
