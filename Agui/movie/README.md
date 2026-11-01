# Movie

5주차 영화 평점 서비스의 Spring Boot 프로젝트입니다.

## 개발 환경

- Java 21
- Spring Boot 3.5.0
- Gradle 8.8 (Wrapper 사용)
- MySQL: `localhost:3306/umc_movie`, 사용자 `root`

Spring Boot 3.5의 Gradle 플러그인이 지원하는 8.x 버전으로 Wrapper를 설정했습니다.

## IntelliJ 설정 및 실행

1. 이 폴더를 Gradle 프로젝트로 엽니다.
2. Project SDK와 Gradle JVM을 JDK 21로 설정합니다.
3. Gradle을 새로고침합니다.
4. `MovieApplication`의 Run Configuration → Environment variables에
   `DB_PASSWORD=본인의_MySQL_비밀번호`를 입력합니다.
5. MySQL에 `umc_movie` 데이터베이스와 워크북의 테이블·시드 데이터를 준비한 뒤 실행합니다.

비밀번호는 실행 환경에만 설정합니다. `.env` 파일은 현재 구성에서 자동으로 읽지 않습니다.
`ddl-auto: validate`를 사용하므로 애플리케이션이 테이블을 자동 생성하지 않습니다.

## 빌드 확인

JDK 21이 설치된 환경에서 이 폴더를 기준으로 실행합니다.

```sh
./gradlew compileJava testClasses bootJar
```

Gradle 실행 JVM도 Java 21을 사용해야 합니다. macOS에서는 필요 시 다음과 같이 지정합니다.

```sh
export JAVA_HOME=$(/usr/libexec/java_home -v 21)
```

`./gradlew test`의 기본 `contextLoads` 테스트와 `./gradlew bootRun`은
실제 MySQL 및 `DB_PASSWORD` 설정이 필요합니다.

## 패키지

- `controller`: HTTP 요청과 응답
- `service`: 비즈니스 로직과 트랜잭션
- `repository`: DB 조회 및 저장
- `entity`: 테이블 매핑
- `dto`: 요청·응답 데이터 구조

워크북의 프로젝트 설정과 `BaseTimeEntity`, `Member`, `Rating` 엔티티 작성을 완료했습니다.
`MemberRepository`, `RatingRepository`와 응답 DTO 3개(`NicknameCheckResponse`, `EmailCheckResponse`,
`RatingResponse`)도 작성했습니다.

실습 1의 `MemberService`, `MemberController`를 작성했으며, 워크북 예제에 함께 포함된
닉네임·이메일 중복 체크를 모두 제공합니다.

| Method | URL | 응답 |
| --- | --- | --- |
| GET | `/members/nickname/{nickname}` | `{"available": true}` 또는 `{"available": false}` |
| GET | `/members/email/{email}` | `{"available": true}` 또는 `{"available": false}` |
| GET | `/members/{memberId}/ratings` | 평점 목록 (`ratingId` 내림차순) |

이미 등록된 값이면 `available: false`, 미등록 값이면 `available: true`를 반환합니다.
서버를 재시작한 뒤 Postman으로 확인합니다. 워크북 시드 데이터를 넣었다면
`GET http://localhost:8080/members/nickname/수현`과
`GET http://localhost:8080/members/email/noco@umc.com`은 모두 `available: false`가 예상됩니다.

실습 3의 `RatingService`, `RatingController`는 회원별 평점을 `RatingResponse` 배열로 반환합니다.
존재하는 회원에게 평점이 없으면 `[]`, 회원이 존재하지 않으면 404를 응답합니다.
워크북 시드 데이터 기준 `GET http://localhost:8080/members/1/ratings`는 평점 2건을
`ratingId` 내림차순으로 반환해야 합니다. 존재하지 않는 ID로 404도 확인합니다.

`WebConfig`에서 모든 경로에 대해 `http://localhost:5173` 출처를 허용합니다.
허용 메서드는 `GET`, `POST`, `PATCH`, `DELETE`이며 모든 요청 헤더를 허용합니다.
서버 재시작 후 `Agui/mock-frontend`를 5173 포트에서 실행하고 닉네임 중복 체크 버튼을 눌러
이전 CORS 오류 대신 `available` JSON이 화면에 표시되는지 확인합니다.
