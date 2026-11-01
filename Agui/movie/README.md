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

현재는 워크북의 프로젝트 설정 단계까지 준비했으며 엔티티와 API는 다음 실습에서 구현합니다.
