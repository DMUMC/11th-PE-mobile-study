# ❗ 학습 목표

---

1. 프론트엔드와 함께 사용할 **API 명세**를 직접 작성할 수 있다.
2. **CORS**가 왜 필요한지 이해하고, Spring/NestJS에서 직접 설정할 수 있다.
3. 요구사항으로부터 **User, Rating 엔티티와 ERD**를 설계하고 새 프로젝트에 적용할 수 있다.
4. 닉네임/이메일 중복 체크, 유저별 평점 조회 API를 **DTO 응답**으로 구현할 수 있다.
5. 간이 프론트(브라우저 fetch)에서 실제로 서버 데이터를 불러오는 흐름을 눈으로 확인할 수 있다.

# 📸 잠깐 ! 스터디 인증샷은 찍으셨나요?📸

---

* 스터디리더께서 대표로 매 주차마다 한 장 남겨주시면 좋겠습니다!🙆💗
  (사진을 저장해서 이미지 임베드를 하셔도 좋고, 복사+붙여넣기 해서 넣어주셔도 좋습니다!)

[]()

# ✨ 5주차 주제

---

지난 0~4주차 동안 우리는 '도서 대여 서비스'를 만들며 HTTP 기초, ERD 설계, SQL, ORM까지 백엔드의 기본 뼈대를 탄탄히 쌓아왔습니다.

지금까지 만든 도서 대여 서비스가 기본기를 익히기 위한 '연습용 도면'이었다면, **이번 5주차부터는 본격적인 실전 개발이 시작됩니다.**

우선 연습용 도메인을 졸업하고 이번 기수의 최종 프로덕트인 **'영화 평점 서비스'**로 새롭게 전환합니다.
그리고 무엇보다 가장 중요한 변화는 **'화면과의 첫 연결'**입니다.

그동안 프론트 화면과 백엔드 API를 각자 따로 개발하며 Postman으로만 검증해 왔다면,

이제는 실제 브라우저에서 버튼을 누르고 내 서버의 데이터를 실시간으로 받아오는 경험을 하게 됩니다.

마침 이 시점이 되어야 프론트(웹/앱) 쪽도 화면다운 화면이 나오기 시작하니, 지금이 딱 손을 맞잡을 타이밍이기도 합니다.

주소가 다른 두 서버가 대화하기 위해 필요한 CORS 설정부터, 화면에 딱 맞는 DTO 설계까지 함께 다뤄보겠습니다.

<aside>
👉

**이번 주차부터 달라지는 것**

- **도메인 전환**: 도서 대여 서비스 → 영화 평점 서비스 (지금부터 10주차까지 완성해나갈 최종 프로젝트입니다)
- **새 프로젝트**: 3~4주차 프로젝트를 이어서 고치는 게 아니라, Spring/NestJS **새 프로젝트를 처음부터 생성**합니다.
- **프론트엔드 등장**: 오늘부터 여러분의 API를 실제로 호출하는 화면(프론트엔드)이 생깁니다. 그래서 **CORS**를 반드시 이해하고 넘어가야 합니다.
</aside>

영화 목록/상세/검색처럼 TMDB가 이미 잘 만들어 둔 데이터는 **프론트엔드가 TMDB API를 직접 호출**합니다.

우리 백엔드가 굳이 다시 감쌀 필요가 없는 데이터이기 때문입니다.

대신 우리 백엔드는 **"우리 서비스에만 존재하는 데이터"**, 즉 회원 정보와 사용자가 남긴 평점을 전담합니다.

>
>
>
> **이번 5주차에는 아래 3개의 API를 새로 만듭니다.**
>
> - 닉네임 중복 체크
> - 이메일 중복 체크
> - 유저별 평점 조회

세 API 모두 아직 회원가입/로그인 기능(6~7주차 예정)이 없는 상태에서 먼저 나온다는 점이 어색하게 느껴지실 수도 있을 것 같습니다.

하지만  이번 주차 목표는 **"프론트와 백엔드가 처음으로 실제 대화를 나누는 것"**이기 때문에

회원가입 폼을 만들기 전에 확인해야 하는 가장 간단한 조회성 API부터 프론트와 연결해보겠습니다!

# 📑 5주차 본문 들어가기 전

---

## 1. 영화 평점 서비스, 무엇을 만드는가?

본격적인 실습에 들어가기 전에, 6~10주차까지 이어질 최종 프로젝트의 전체 그림을 먼저 확인하고 갑니다.

| 주차 | 새로 연동하는 API |
| --- | --- |
| **5주차 (이번 주)** | 닉네임 중복 체크, 이메일 중복 체크, 유저별 평점 조회 |
| 6주차 | 회원가입 + 평점 CRUD (userId 파라미터 기반) |
| 7주차 | 로그인(JWT) + 평점 CRUD 리팩토링(토큰 기반) + 내 정보 조회/수정 |
| 8주차 | 영화 즐겨찾기 등록/해제/내 즐겨찾기 조회 |

!3ach.drawio.png

> 🤔 **영화 목록/상세/검색 API는 왜 우리가 안 만들까요?**
>
>
> 영화 목록 조회, 영화 상세 조회, 영화 검색은 TMDB가 이미 전 세계 개발자를 위해 공개해둔 Open API로 그대로 제공됩니다.
>
> 우리 백엔드가 굳이 TMDB 응답을 한 번 더 감싸서 내려줄 이유가 없기 때문에
>
> 우리는 **"우리 DB에만 존재하는 데이터"**(회원, 평점, 즐겨찾기)에 집중합니다.
>
> 대신 영화를 특정할 때는 TMDB가 부여한 movieId를 그대로 우리 DB에 저장해서 연결 고리로 사용합니다.
>

## 2. ERD 설계하기 : Member, Rating, Favorite

1주차에서 배웠던 순서를 그대로 다시 밟아봅니다.

**"화면/기능 요구사항 → 저장해야 할 정보 → 엔티티 → 관계"** 순서입니다.

1주차가 도서 대여 서비스의 ERD를 처음부터 전체로 설계했던 것처럼, 이번에도 5주차에서 당장 쓸 것만이 아니라 **8주차 즐겨찾기 기능까지 감안한 전체 ERD**를 미리 그려두고 시작합니다.

그래야 나중에 테이블을 다시 뜯어고치지 않아도 됩니다.

### 1) 요구사항 정리

- 사용자는 이메일과 닉네임으로 가입한다. (닉네임/이메일은 서로 중복되면 안 된다.)
- 사용자는 TMDB의 특정 영화에 별점(1~5)과 코멘트를 남길 수 있다.
- 한 사용자는 여러 개의 평점을 남길 수 있다.
- 사용자는 TMDB의 특정 영화를 즐겨찾기에 등록/해제할 수 있다. (같은 영화를 중복으로 즐겨찾기할 수는 없다.)
- 한 사용자는 여러 개의 영화를 즐겨찾기할 수 있다.
- 평점/즐겨찾기 모두 "어떤 영화(TMDB movieId)"에 대한 것인지 알아야 하지만, 영화 자체의 상세 정보는 우리 DB에 저장하지 않는다.

### 2) 엔티티와 관계 도출

- **Member**(회원), **Rating**(평점), **Favorite**(즐겨찾기) 세 개의 엔티티가 필요합니다.
- 한 명의 Member는 여러 개의 Rating과 여러 개의 Favorite을 남길 수 있으므로, **Member : Rating = 1 : N**, **Member : Favorite = 1 : N** 관계입니다.
- Rating과 Favorite이 가리키는 영화는 둘 다 TMDB의 데이터이지, 우리 DB의 테이블이 아닙니다.
- 그래서 두 테이블의 movieId는 **외래키(FK)가 아니라 TMDB의 식별자를 그대로 담아두는 일반 컬럼**입니다.
- Favorite은 같은 사용자가 같은 영화를 중복 등록하지 못하도록 (member_id, movie_id) 조합에 **UNIQUE 제약**을 겁니다.

- **토글을 열기 전에 꼭 한번 설계를 해보시는 것을 추천 드립니다!**
  - 우선 3개의 엔티티를 먼저 구성해봅시다.

  !image.png

  - 이제 각자 ID를 생성하고 연결해봅시다.

  !image.png

  - 이제 각 컬럼에 필요한 값을 넣어봅시다.

  !image.png

  - 영화 ID의 경우 TMDB에서 가져오기 때문에 굳이 테이블을 만들어줄 필요 없이 컬럼 하나면 충분합니다.
  - 만약, 백엔드에서 영화를 저장했다면 이렇게 되겠네요.

  !image.png


<aside>
👉

**password는 왜 벌써 넣고, Favorite은 왜 이번 주차에 쓰지도 않는데 미리 만드나요?**

로그인 기능은 7주차에 만들지만, Member 테이블을 나중에 다시 뜯어고치지 않도록 **회원가입 시점부터 필요한 컬럼을 미리 설계**해 둡니다.

6주차 회원가입 실습에서 이 컬럼에 암호화된 비밀번호가 채워질 예정입니다.

Favorite도 같은 이유입니다. **테이블 설계(스키마)는 지금 끝내두고, 실제 엔티티 코드와 API는 즐겨찾기 기능을 다루는 8주차에 작성**합니다.

이렇게 하면 8주차에 가서 "즐겨찾기를 저장하려면 테이블부터 새로 설계해야 하는" 상황을 피할 수 있습니다.

</aside>

### 3) 테이블 생성 SQL

2주차에서 실습했던 것처럼 로컬 MySQL에 아래 스키마를 먼저 만들어 둡니다.

```sql
CREATE TABLE member (
    member_id   BIGINT AUTO_INCREMENT PRIMARY KEY,
    email       VARCHAR(254) NOT NULL UNIQUE,
    password    VARCHAR(60)  NOT NULL,
    nickname    VARCHAR(50)  NOT NULL UNIQUE,
    created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE rating (
    rating_id   BIGINT AUTO_INCREMENT PRIMARY KEY,
    member_id   BIGINT   NOT NULL,
    movie_id    BIGINT   NOT NULL,
    score       TINYINT  NOT NULL,
    comment     TEXT,
    created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (member_id) REFERENCES member(member_id),
    UNIQUE KEY uk_rating_member_movie (member_id, movie_id)
);

-- 8주차 즐겨찾기 실습에서 사용할 테이블입니다. 이번 주차에는 스키마만 만들어 둡니다.
CREATE TABLE favorite (
    favorite_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    member_id   BIGINT   NOT NULL,
    movie_id    BIGINT   NOT NULL,
    created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (member_id) REFERENCES member(member_id),
    UNIQUE KEY uk_favorite_member_movie (member_id, movie_id)
);
```

<aside>
💡

**email VARCHAR(254), password VARCHAR(60)은 왜 이렇게 딱 떨어지는 숫자일까요?**

VARCHAR(255)를 습관적으로 쓰는 경우가 많지만, 근거를 따져보면 더 정확한 값이 있습니다.

- **email**
  - 이메일 주소의 최대 길이는 RFC 5321 표준에서 **254자**로 정의되어 있습니다.
- **password**
  - 이 컬럼에는 평문 비밀번호가 아니라 6주차에서 배울 **bcrypt 해시**가 저장됩니다.
  - bcrypt 해시는 항상 정확히 **60자**로 고정된 길이를 가지므로, 그보다 크게 잡을 이유가 없습니다.
</aside>

### 4) 더미 데이터로 확인해보기

닉네임 중복 체크나 유저별 평점 조회를 실습하려면 미리 데이터가 있어야 확인이 쉽습니다.

TMDB의 실제 영화 ID를 활용해 더미 데이터를 넣어봅니다.

```sql
INSERT INTO member (email, password, nickname) VALUES
('noco@umc.com', '$2a$10$dummyEncodedPasswordValue', '수현'),
('minseo@umc.com', '$2a$10$dummyEncodedPasswordValue', '민서');

INSERT INTO rating (member_id, movie_id, score, comment) VALUES
(1, 550, 5, '최고의 영화!'),
(1, 155, 4, '다시 봐도 명작'),
(2, 550, 3, '호불호가 갈릴 것 같아요');
```

<aside>
🚨

**password 컬럼에 실제 비밀번호를 넣지 마세요!**

6주차에 배울 **bcrypt**로 암호화하기 전까지는, 위 예시처럼 임의의 더미 문자열로만 채워둡니다.

평문 비밀번호를 DB에 저장하는 습관은 지금부터 들이지 않는 게 좋습니다.

</aside>

## 3. 새 프로젝트 생성하기

3주차 세팅 가이드처럼 화면을 하나하나 캡처하지 않고, **명령어 위주로 빠르게** 새 프로젝트를 만듭니다. 기존 3~4주차에서 사용하던 개발 환경(JDK, IntelliJ, Node.js, MySQL)은 그대로 재사용하면 됩니다.

### 🍃 Spring Boot

1. start.spring.io에서 아래 의존성만 체크하고 프로젝트를 내려받습니다. (Project: Gradle, Language: Java, Packaging: Jar)
  - Spring Web, Spring Data JPA, MySQL Driver, Lombok, Validation

   !image.png

2. 압축을 풀고 IntelliJ로 열어줍니다.
3. `build.gradle`을 열어 Spring Boot 버전을 **3.5.0**으로 고정하고, 의존성을 아래와 같이 맞춰줍니다.

    ```groovy
    plugins {
        id 'java'
        id 'org.springframework.boot' version '3.5.0'
        id 'io.spring.dependency-management' version '1.1.7'
    }

    group = 'com.umc'
    version = '0.0.1-SNAPSHOT'

    java {
        toolchain {
            languageVersion = JavaLanguageVersion.of(21)
        }
    }

    repositories {
        mavenCentral()
    }

    dependencies {
        implementation 'org.springframework.boot:spring-boot-starter-web'
        implementation 'org.springframework.boot:spring-boot-starter-data-jpa'
        implementation 'org.springframework.boot:spring-boot-starter-validation'
        compileOnly 'org.projectlombok:lombok'
        runtimeOnly 'com.mysql:mysql-connector-j'
        annotationProcessor 'org.projectlombok:lombok'

        testImplementation 'org.springframework.boot:spring-boot-starter-test'
        testCompileOnly 'org.projectlombok:lombok'
        testRuntimeOnly 'org.junit.platform:junit-platform-launcher'
        testAnnotationProcessor 'org.projectlombok:lombok'
    }

    tasks.named('test') {
        useJUnitPlatform()
    }
    ```

   수정 후에는 에디터 우측 상단에 뜨는 코끼리 모양 아이콘(Gradle 새로고침)을 눌러 동기화합니다.

4. `src/main/resources/application.yml`에 DB 정보를 작성해줍니다.

    ```yaml
    spring:
      datasource:
        url: jdbc:mysql://localhost:3306/umc_movie
        username: root
        password: ${DB_PASSWORD}
      jpa:
        hibernate:
          ddl-auto: validate
        open-in-view: false
    ```

5. 환경 변수도 추가해줍니다.

    ```yaml
    DB_PASSWORD={비밀번호 입력}
    ```

6. 아래처럼 **레이어 기준 패키지**를 미리 만들어 둡니다.

    ```
    src/main/java/com/umc/movie
    ├── controller
    ├── service
    ├── repository
    ├── entity
    └── dto
    ```


### 🐱 NestJS

```bash
# 프로젝트 생성 (Nest CLI는 3주차에서 이미 설치했습니다)
nest new movie

cd movie
npm install @nestjs/typeorm typeorm mysql2 @nestjs/config
```

그리고 새 프로젝트라 아직 .env 파일이 없습니다. 3주차와 같은 방식으로 프로젝트 루트에 .env 파일을 새로 만들고, 이번 프로젝트의 DB 접속 정보를 채워둡니다

```bash
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=본인_MySQL_비밀번호
DB_NAME=umc_movie
```

이번 주차는 Spring과 아키텍처 감각을 통일하기 위해, NestJS도 **도메인이 아니라 레이어 기준**으로 폴더를 나눕니다.

Nest CLI의 생성 명령어는 기본적으로 도메인 폴더를 만들어주므로, 이번에는 CLI 대신 아래처럼 레이어 폴더를 직접 만들고 그 안에 파일을 작성합니다.

```bash
cd src
mkdir controller
mkdir service
mkdir repository
mkdir entity
mkdir dto
```

```
src
├── controller
├── service
├── repository
├── entity
├── dto
├── app.module.ts      (nest new가 이미 만들어 둔 파일)
└── main.ts            (nest new가 이미 만들어 둔 파일)
```

<aside>
💡

**도메인 모듈 대신 레이어 폴더를 쓰면, app.module.ts가 모든 걸 직접 등록합니다**

NestJS 공식 스타일 가이드는 기능 단위 모듈로 나누는 것을 권장하지만, 이 워크북에서는 **Spring과 1:1로 비교하며 3계층 구조를 먼저 몸에 익히는 것**을 목표로 합니다.

그래서 도메인 모듈 없이 **`app.module.ts` 하나가 모든 Controller/Service/Entity를 직접 등록**하는 방식으로 진행합니다.

도메인 단위로 모듈을 나누는 패턴은 이후 **부록에서 DDD 등 다른 아키텍처 패턴**을 다룰 때 별도로 소개할 예정이니, 지금은 3계층 구조에 집중해주세요.

</aside>

## 4. API 명세 작성하기

프론트엔드 개발자와 손발을 맞추려면, 코드를 짜기 전에 **"이 API는 무엇을 받아서 무엇을 돌려주는지"**를 먼저 문서로 합의해야 합니다.

9주차에 Swagger로 자동화하기 전까지는, 아래처럼 표로 직접 API 명세를 작성하는 연습을 합니다.

### API 명세는 아래 4가지 질문에 대한 답입니다

API 하나를 명세로 옮길 때는, 항상 같은 4가지 질문에 순서대로 답한다고 생각하면 됩니다.

>
>
> 1. **이름**: 이 API가 하는 일을 한 줄로 표현하면?
     > (예: 닉네임 중복 체크)
> 2. **Method + URL**: 어떤 방식으로, 어느 주소를 호출하는가?
     > (예: GET /members/nickname/{nickname})
> 3. **Request**: 무엇을 받는가? Query/Path/Body 중 **어디에**, **어떤 타입의 값**을 담아 보내는가?
> 4. **Success Response**: 성공하면 어떤 JSON을 돌려주는가?
     > **필드 이름과 타입까지 구체적으로** 적는다.

이 4가지를 3개의 API에 각각 적용한 결과가 아래 표입니다.

새로운 API를 명세로 옮길 때도 이 순서 그대로 채워나가면 됩니다.

| API | Method | URL | Request | Success Response (200) |
| --- | --- | --- | --- | --- |
| 닉네임 중복 체크 | GET | /members/nickname/{nickname} | Path: nickname (string) | {
"available": true
} |
| 이메일 중복 체크 | GET | /members/email/{email} | Path: email (string) | {
"available": true
} |
| 유저별 평점 조회 | GET | /members/{memberId}/ratings | Path: memberId (number) | [
{
"ratingId": 1,
"movieId": 550,
"score": 5,
"comment": "최고의 영화!",
"createdAt": "2026-08-26T10:00:00",
"updatedAt": "2026-08-26T10:00:00"
}
] |

# 🔖 5주차 본문

---

새 프로젝트 세팅, API 명세 작성까지 준비를 마치셨나요?

이제부터는 그 설계를 실제로 동작하는 코드로 옮기는 시간입니다.

프론트와 처음 대화를 나누기 위해 CORS가 왜 필요한지부터 짚고 Member/Rating 엔티티를 코드로 옮긴 뒤 오늘의 목표인 3개의 API를 하나씩 완성해보겠습니다.

## 1. CORS란 무엇인가?

지금까지는 Postman으로만 API를 호출했습니다.

Postman은 브라우저가 아니기 때문에 이번 절에서 설명할 문제를 겪지 않았습니다.

하지만 오늘부터 등장하는 **브라우저 위의 프론트엔드**는 사정이 다릅니다.

<aside>
💡

**네이티브 앱에서 API를 호출한다면?**

아래에서 설명하는 CORS는 **브라우저**에서 실행되는 화면을 기준으로 한 이야기입니다.

Flutter 같은 네이티브 앱은 브라우저가 아니라서 이 정책의 적용을 받지 않는데, 왜 그런지는 9절 마지막에서 자세히 다룹니다.

지금은 "브라우저에서만 생기는 문제구나" 정도로 가볍게 읽고 넘어가도 됩니다.

</aside>

### 1) 🤔 브라우저는 왜 이렇게 예민할까?

브라우저에는 **동일 출처 정책(Same-Origin Policy, SOP)**이라는 기본 보안 규칙이 있습니다.

"지금 열려 있는 화면과 다른 곳으로 향하는 요청은 기본적으로 막는다"는 규칙입니다.

여기서 출처는 프로토콜 + 호스트 + 포트의 조합입니다.

0주차에서 배운 URL 구조를 다시 떠올려 보면, 아래 두 주소는 포트 번호 하나만 다른데도 **완전히 다른 출처**로 취급됩니다.

>
>
> - http://localhost:5173 (프론트엔드 개발 서버, Vite 기준)
> - http://localhost:8080 (Spring 백엔드) / http://localhost:3000 (NestJS 백엔드)

즉, 프론트엔드 화면에서 백엔드를 호출하는 순간, 브라우저 입장에서는 **"출처가 다른 서버로 향하는 수상한 요청"**이 됩니다.

### 2) CORS: 서버가 "이 출처는 믿을 만해"라고 허락해주는 장치

**CORS(Cross-Origin Resource Sharing)**는 서버가 응답 헤더에 "나는 이 출처(Origin)에서 오는 요청을 허용한다"는 표시를 함께 보내주는 약속입니다.

브라우저는 이 헤더를 확인하고 나서야 응답을 화면에서 사용할 수 있게 해줍니다.

<aside>
👉

**요청 자체는 서버에 도착합니다!**

CORS는 요청이 서버에 도달하는 것을 막는 게 아닙니다.

서버는 요청을 정상적으로 처리하고 응답까지 만들지만, **브라우저가 그 응답을 화면에 전달하기 직전에 가로막는 것**입니다.

그래서 서버 로그에는 정상 처리된 것으로 남는데, 프론트 화면에는 아무 데이터도 뜨지 않는 상황이 벌어집니다.

!cors.drawio.png

</aside>

<aside>
🚨

**중요: CORS 에러가 나면, 원인은 항상 백엔드에 있습니다!**

CORS 허용 여부는 오직 **서버가 응답 헤더에 무엇을 담아 보내는지**로 결정됩니다.

프론트엔드 개발자가 자기 쪽 코드를 아무리 고쳐도 이 에러는 절대 사라지지 않습니다.

그러니 프론트 팀원에게서 "API를 호출하면 CORS 에러가 난다"는 얘기를 듣는다면, 프론트 코드를 의심하기 전에 우리 서버의 CORS 설정부터 확인해야 합니다.

</aside>

### 3) 🤔 Same-Origin과 Same-Site, 이름이 비슷해서 헷갈리는 개념

CORS를 검색하다 보면 **Same-Site**라는 비슷한 단어도 자주 마주치게 됩니다. 이름은 비슷하지만, 브라우저가 **무엇을 판단하는지 자체가 다른 별개의 개념**이라 처음 접하면 헷갈리기 쉽습니다.

- **Same-Origin(동일 출처)**
  - 앞서 배운 것처럼 프로토콜 + 호스트 + 포트가 모두 같아야 합니다.
  - 브라우저가 **"이 응답을 JavaScript가 읽어도 되는가"**를 판단할 때 쓰는 기준이고, 이번 절에서 다루는 CORS가 바로 이 기준을 다룹니다.
- **Same-Site(동일 사이트)**
  - 등록 가능 도메인만 같으면 됩니다.
  - 포트나 서브도메인이 달라도 무방한, **Same-Origin보다 훨씬 느슨한 기준**입니다.
  - 브라우저가 **"이 요청에 쿠키를 자동으로 실어 보낼 것인가"**를 판단할 때 쓰입니다.

<aside>
💡

**지금 당장 Same-Site를 직접 설정할 일은 없습니다**

정규 커리큘럼의 로그인은 헤더 방식이기 때문에 Same-Site 속성을 실제로 건드리지 않습니다.

</aside>

## 2. [실습 0] CORS 에러를 직접 눈으로 확인해보기

설정을 하기 전에 에러가 실제로 어떻게 생겼는지부터 확인해봅시다.

여러분이 만든 실제 프론트엔드 화면을 붙이기 전에 fetch 한 줄짜리 간이 프론트 HTML로 CORS의 생김새를 확인해봅시다!

“어라? API를 만들지 않았는데 진행해도 되나요?”라고 의문이 드실 수 있을 것 같습니다.

이번 실습은 서버만 켜져있으면 되기 때문에 그냥 진행해주시면 됩니다!

### 1단계 : 백엔드 서버 실행하기

지금까지 만든 프로젝트를 그대로 실행합니다. 아직 우리가 만든 API가 없어도 괜찮습니다.

- **Spring**: IntelliJ 상단의 초록색 **Run** 버튼 클릭
- **NestJS**: 터미널에서 npm run start:dev 입력

### 2단계 : mock-frontend 폴더에 index.html 만들기

백엔드 프로젝트와 완전히 별개의 폴더에 아래 index.txt 파일을 index.html로 변경해서 폴더를 엽니다.

index.txt

!image.png

### 3단계 : 5173번 포트로 띄우기

프론트엔드 개발 서버의 기본 포트인 **5173번**에 맞춰서 정적 서버를 띄웁니다.

```bash
# mock-frontend 폴더 안에서 실행
npx serve -l 5173
```

!image.png

### 4단계 : 브라우저 개발자 도구로 에러 확인하기

1. http://localhost:5173으로 접속해 버튼을 눌러봅니다.
2. F12(개발자 도구) → **Console** 탭을 확인합니다.
3. 버튼을 클릭해줍니다.

```
Access to fetch at 'http://localhost:8080/members/nickname/noco' from origin 'http://localhost:5173' has been blocked by CORS policy: No 'Access-Control-Allow-Origin' header is present on the requested resource.
```

!image.png

이렇게 정상적(?)으로 CORS 에러가 뜬 것을 확인할 수 있습니다.

이 에러 메시지의 생김새를 눈에 익혀두는 것이 이번 실습의 목적입니다.

## 3. Member/Rating 엔티티 작성하기

2절에서 설계한 ERD를 그대로 코드로 옮깁니다.

Member, Rating, 그리고 8주차에 등장할 Favorite까지 세 엔티티가 모두 createdAt/updatedAt을 똑같은 방식으로 가지므로, 매번 반복해서 적지 않도록 두 스택 모두 **공통 부모 클래스**로 뽑아냅니다.

### **🍃 Spring Boot**

`@MappedSuperclass`는 "이 클래스는 그 자체로 테이블이 되지는 않지만, 상속하는 자식 엔티티에게 컬럼 정의를 물려준다"는 뜻입니다.

```java
// src/main/java/com/umc/movie/entity/BaseTimeEntity.java
package com.umc.movie.entity;

import jakarta.persistence.Column;
import jakarta.persistence.MappedSuperclass;
import lombok.Getter;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;

@Getter
@MappedSuperclass
public abstract class BaseTimeEntity {

    // 처음 저장될 때 Hibernate가 자동으로 채워줍니다. 이후에는 절대 바뀌지 않습니다.
    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    // 이 엔티티가 저장될 때마다 Hibernate가 현재 시각으로 자동 갱신합니다.
    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
```

```java
// src/main/java/com/umc/movie/entity/Member.java
package com.umc.movie.entity;

import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "member")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Member extends BaseTimeEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "member_id")
    private Long memberId;

    @Column(nullable = false, unique = true, length = 254)
    private String email;

    @Column(nullable = false, length = 60)
    private String password;

    @Column(nullable = false, unique = true, length = 50)
    private String nickname;

    public Member(String email, String password, String nickname) {
        this.email = email;
        this.password = password;
        this.nickname = nickname;
    }
}
```

```java
// src/main/java/com/umc/movie/entity/Rating.java
package com.umc.movie.entity;

import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "rating", uniqueConstraints = @UniqueConstraint(columnNames = {"member_id", "movie_id"}))
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Rating extends BaseTimeEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "rating_id")
    private Long ratingId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "member_id", nullable = false)
    private Member member;

    @Column(name = "movie_id", nullable = false)
    private Long movieId;

    @Column(nullable = false, columnDefinition = "TINYINT")
    private Integer score;

    @Column(columnDefinition = "TEXT")
    private String comment;
}
```

<aside>
💡

**알아두면 좋은 두 가지**

1. Lombok의 `@Getter`는 **그 클래스에 직접 선언된 필드**에만 getter를 만들어줍니다. BaseTimeEntity에도 `@Getter`를 따로 붙여야 member.getCreatedAt()처럼 상속받은 필드의 getter까지 쓸 수 있습니다.
2. `@CreationTimestamp`는 **INSERT** 시점에 한 번만 채워지고 이후 절대 바뀌지 않으며, `@UpdateTimestamp`는 **저장(INSERT/UPDATE)될 때마다** 현재 시각으로 다시 채워집니다.
   지금은 UPDATE API가 없어서 두 값이 같아 보이지만, 6~8주차 PATCH API부터 차이가 드러납니다.
</aside>

### **🐱 NestJS**

TypeORM도 클래스 상속으로 컬럼 정의를 물려줄 수 있습니다. `@Entity()`가 붙지 않은 일반 추상 클래스를 만들고, 실제 엔티티가 그 클래스를 `extends`하면 됩니다.

```tsx
// src/entity/base-time.entity.ts
import { CreateDateColumn, UpdateDateColumn } from "typeorm";

export abstract class BaseTimeEntity {
  // INSERT 시점에 한 번만 채워지고 이후 바뀌지 않습니다.
  @CreateDateColumn({ name: "created_at" })
  createdAt: Date;

  // 저장될 때마다 TypeORM이 현재 시각으로 다시 채워줍니다.
  @UpdateDateColumn({ name: "updated_at" })
  updatedAt: Date;
}
```

```tsx
// src/entity/member.entity.ts
import { Column, Entity, PrimaryGeneratedColumn } from "typeorm";
import { BaseTimeEntity } from "./base-time.entity";

@Entity("member")
export class Member extends BaseTimeEntity {
  @PrimaryGeneratedColumn({ name: "member_id" })
  memberId: number;

  @Column({ unique: true, length: 254 })
  email: string;

  @Column({ length: 60 })
  password: string;

  @Column({ unique: true, length: 50 })
  nickname: string;
}
```

```tsx
// src/entity/rating.entity.ts
import {
  Column,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from "typeorm";
import { BaseTimeEntity } from "./base-time.entity";
import { Member } from "./member.entity";

@Entity("rating")
export class Rating extends BaseTimeEntity {
  @PrimaryGeneratedColumn({ name: "rating_id" })
  ratingId: number;

  @ManyToOne(() => Member, { nullable: false })
  @JoinColumn({ name: "member_id" })
  member: Member;

  @Column({ name: "movie_id" })
  movieId: number;

  @Column()
  score: number;

  @Column({ type: "text", nullable: true })
  comment: string | null;
}
```

<aside>
💡

**알아두면 좋은 두 가지**

1. TypeORM 엔티티의 클래스 필드는 기본적으로 public이라,
   별도 getter 없이도 member.createdAt처럼 상속받은 필드에 바로 접근할 수 있습니다.
2. `@CreateDateColumn`은 **INSERT** 시점에 한 번만 채워지고 이후 절대 바뀌지 않으며, `@UpdateDateColumn`은 **저장(INSERT/UPDATE)될 때마다** 현재 시각으로 다시 채워집니다.
   지금은 UPDATE API가 없어서 두 값이 같아 보이지만, 6~8주차 PATCH API부터 차이가 드러납니다.
</aside>

## 4. Repository 등록하기

### **🍃 Spring Boot**

`existsByNickname`, `existsByEmail`처럼 메서드 이름만으로 쿼리를 자동 생성해주는 **Query Method**를 활용합니다.

```java
// src/main/java/com/umc/movie/repository/MemberRepository.java
package com.umc.movie.repository;

import com.umc.movie.entity.Member;
import org.springframework.data.jpa.repository.JpaRepository;

public interface MemberRepository extends JpaRepository<Member, Long> {
    boolean existsByNickname(String nickname);
    boolean existsByEmail(String email);
}
```

```java
// src/main/java/com/umc/movie/repository/RatingRepository.java
package com.umc.movie.repository;

import com.umc.movie.entity.Rating;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface RatingRepository extends JpaRepository<Rating, Long> {
    List<Rating> findByMember_MemberIdOrderByRatingIdDesc(Long memberId);
}
```

### **🐱 NestJS**

NestJS는 별도의 Repository 클래스를 만들지 않고
TypeORM이 제공하는 Repository<Entity>를 Service에서 바로 주입 받아 사용합니다.

도메인 모듈을 따로 두지 않기로 했으므로 TypeOrmModule.forFeature([Member, Rating])를 **app.module.ts 한 곳에만 등록**해서 두 엔티티의 Repository를 애플리케이션 전체에서 주입받을 수 있게 만듭니다.

아래 6, 8절에서 Controller와 Service를 작성한 뒤에는 controllers, providers 배열에도 반드시 등록해야 서버가 정상 동작합니다.

```tsx
// src/app.module.ts
import { Module } from "@nestjs/common";
import { ConfigModule } from "@nestjs/config";
import { TypeOrmModule } from "@nestjs/typeorm";
import { Member } from "./entity/member.entity";
import { Rating } from "./entity/rating.entity";
import { MemberController } from "./controller/member.controller";
import { RatingController } from "./controller/rating.controller";
import { MemberService } from "./service/member.service";
import { RatingService } from "./service/rating.service";

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    TypeOrmModule.forRoot({
      type: "mysql",
      host: process.env.DB_HOST,
      port: 3306,
      username: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      database: process.env.DB_NAME,
      autoLoadEntities: true,
      synchronize: false,
    }),
    TypeOrmModule.forFeature([Member, Rating]),
  ],
  controllers: [MemberController, RatingController],
  providers: [MemberService, RatingService],
})
export class AppModule {}
```

## 5. DTO로 응답 형태 만들기

4주차에서 이미 "Entity를 그대로 응답하면 DB 컬럼이 API 계약이 되어버린다"는 이유로 DTO를 배웠습니다.

이번 주차는 그 DTO가 **처음으로 화면 너머의 실제 사람을 위해 쓰인다**는 점이 다릅니다.

4절의 API 명세 표에서 합의한 응답 모양을 그대로 코드로 옮깁니다.

### **🍃 Spring Boot**

```java
// src/main/java/com/umc/movie/dto/NicknameCheckResponse.java
package com.umc.movie.dto;

public record NicknameCheckResponse(boolean available) {}
```

```java
// src/main/java/com/umc/movie/dto/EmailCheckResponse.java
package com.umc.movie.dto;

public record EmailCheckResponse(boolean available) {}
```

```java
// src/main/java/com/umc/movie/dto/RatingResponse.java
package com.umc.movie.dto;

import com.umc.movie.entity.Rating;

import java.time.LocalDateTime;

public record RatingResponse(
        Long ratingId,
        Long movieId,
        Integer score,
        String comment,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {
    public static RatingResponse from(Rating rating) {
        return new RatingResponse(
                rating.getRatingId(),
                rating.getMovieId(),
                rating.getScore(),
                rating.getComment(),
                rating.getCreatedAt(),
                rating.getUpdatedAt()
        );
    }
}
```

### **🐱 NestJS**

```tsx
// src/dto/check-response.dto.ts
export class CheckResponseDto {
  available: boolean;
}
```

```tsx
// src/dto/rating-response.dto.ts
import { Rating } from "../entity/rating.entity";

export class RatingResponseDto {
  ratingId: number;
  movieId: number;
  score: number;
  comment: string | null;
  createdAt: Date;
  updatedAt: Date;

  static from(rating: Rating): RatingResponseDto {
    return {
      ratingId: rating.ratingId,
      movieId: rating.movieId,
      score: rating.score,
      comment: rating.comment,
      createdAt: rating.createdAt,
      updatedAt: rating.updatedAt,
    };
  }
}
```

## 6. [실습 1] 닉네임 중복 체크 API (GET /members/nickname/{nickname})

### **🍃 Spring Boot**

```java
// src/main/java/com/umc/movie/service/MemberService.java
package com.umc.movie.service;

import com.umc.movie.dto.EmailCheckResponse;
import com.umc.movie.dto.NicknameCheckResponse;
import com.umc.movie.repository.MemberRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class MemberService {

    private final MemberRepository memberRepository;

    @Transactional(readOnly = true)
    public NicknameCheckResponse checkNickname(String nickname) {
        boolean exists = memberRepository.existsByNickname(nickname);
        return new NicknameCheckResponse(!exists);
    }

    @Transactional(readOnly = true)
    public EmailCheckResponse checkEmail(String email) {
        boolean exists = memberRepository.existsByEmail(email);
        return new EmailCheckResponse(!exists);
    }
}
```

```java
// src/main/java/com/umc/movie/controller/MemberController.java
package com.umc.movie.controller;

import com.umc.movie.dto.EmailCheckResponse;
import com.umc.movie.dto.NicknameCheckResponse;
import com.umc.movie.service.MemberService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@RestController
@RequiredArgsConstructor
@RequestMapping("/members")
public class MemberController {

    private final MemberService memberService;

    @GetMapping("/nickname/{nickname}")
    public NicknameCheckResponse checkNickname(@PathVariable String nickname) {
        return memberService.checkNickname(nickname);
    }

    @GetMapping("/email/{email}")
    public EmailCheckResponse checkEmail(@PathVariable String email) {
        return memberService.checkEmail(email);
    }
}
```

### **🐱 NestJS**

```tsx
// src/service/member.service.ts
import { Injectable } from "@nestjs/common";
import { InjectRepository } from "@nestjs/typeorm";
import { Repository } from "typeorm";
import { Member } from "../entity/member.entity";
import { CheckResponseDto } from "../dto/check-response.dto";

@Injectable()
export class MemberService {
  constructor(
    @InjectRepository(Member)
    private readonly memberRepository: Repository<Member>,
  ) {}

  async checkNickname(nickname: string): Promise<CheckResponseDto> {
    const exists = await this.memberRepository.exists({
      where: { nickname },
    });
    return { available: !exists };
  }

  async checkEmail(email: string): Promise<CheckResponseDto> {
    const exists = await this.memberRepository.exists({ where: { email } });
    return { available: !exists };
  }
}
```

```tsx
// src/controller/member.controller.ts
import { Controller, Get, Param } from "@nestjs/common";
import { MemberService } from "../service/member.service";

@Controller("members")
export class MemberController {
  constructor(private readonly memberService: MemberService) {}

  @Get("nickname/:nickname")
  checkNickname(@Param("nickname") nickname: string) {
    return this.memberService.checkNickname(nickname);
  }

  @Get("email/:email")
  checkEmail(@Param("email") email: string) {
    return this.memberService.checkEmail(email);
  }
}
```

### Postman으로 확인하기

- Method: **GET**
- URL
  - http://localhost:8080/members/nickname/수현 (Spring)
  - http://localhost:3000/members/nickname/수현 (NestJS)
- 이미 시드 데이터로 넣어둔 '수현'을 조회하면 → { "available": false }
- 존재하지 않는 닉네임을 조회하면 → { "available": true }

<aside>
💡

**한글 경로 변수가 인식되지 않는다면?**

브라우저 주소창이나 Postman에서 경로의 한글 문자열을 제대로 인식하지 못하는 경우가 있습니다.

이럴 때는 아래처럼 값을 큰따옴표로 감싸서 요청해보세요.

http://localhost:8080/members/nickname/"수현"

</aside>

## 7. [실습 2] 이메일 중복 체크 API (GET /members/email/{email})

바로 위 6절에서 MemberController, MemberService에 이미 checkEmail을 함께 구현했습니다.

Postman으로 http://localhost:8080/members/email/noco@umc.com을 호출해 { "available": false }가 나오는지 확인해보세요.

## 8. [실습 3] 유저별 평점 조회 API (GET /members/{memberId}/ratings)

### **🍃 Spring Boot**

```java
// src/main/java/com/umc/movie/service/RatingService.java
package com.umc.movie.service;

import com.umc.movie.dto.RatingResponse;
import com.umc.movie.repository.RatingRepository;
import com.umc.movie.repository.MemberRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@Service
@RequiredArgsConstructor
public class RatingService {

    private final RatingRepository ratingRepository;
    private final MemberRepository memberRepository;

    @Transactional(readOnly = true)
    public List<RatingResponse> getRatingsByMember(Long memberId) {
        if (!memberRepository.existsById(memberId)) {
            // @RestControllerAdvice로 예외를 한 곳에서 다루는 방법은 6주차에 배웁니다.
            // 지금은 Spring이 기본 제공하는 ResponseStatusException으로 404를 바로 응답합니다.
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "존재하지 않는 유저입니다.");
        }

        return ratingRepository.findByMember_MemberIdOrderByRatingIdDesc(memberId).stream()
                .map(RatingResponse::from)
                .toList();
    }
}
```

```java
// src/main/java/com/umc/movie/controller/RatingController.java
package com.umc.movie.controller;

import com.umc.movie.dto.RatingResponse;
import com.umc.movie.service.RatingService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequiredArgsConstructor
@RequestMapping("/members")
public class RatingController {

    private final RatingService ratingService;

    @GetMapping("/{memberId}/ratings")
    public List<RatingResponse> getMemberRatings(@PathVariable Long memberId) {
        return ratingService.getRatingsByMember(memberId);
    }
}
```

### **🐱 NestJS**

```tsx
// src/service/rating.service.ts
import { Injectable, NotFoundException } from "@nestjs/common";
import { InjectRepository } from "@nestjs/typeorm";
import { Repository } from "typeorm";
import { Rating } from "../entity/rating.entity";
import { Member } from "../entity/member.entity";
import { RatingResponseDto } from "../dto/rating-response.dto";

@Injectable()
export class RatingService {
  constructor(
    @InjectRepository(Rating)
    private readonly ratingRepository: Repository<Rating>,
    @InjectRepository(Member)
    private readonly memberRepository: Repository<Member>,
  ) {}

  async getRatingsByMember(memberId: number): Promise<RatingResponseDto[]> {
    const member = await this.memberRepository.findOneBy({ memberId });
    if (!member) {
      throw new NotFoundException("존재하지 않는 유저입니다.");
    }

    const ratings = await this.ratingRepository.find({
      where: { member: { memberId } },
      order: { ratingId: "DESC" },
    });

    return ratings.map(RatingResponseDto.from);
  }
}
```

```tsx
// src/controller/rating.controller.ts
import { Controller, Get, Param, ParseIntPipe } from "@nestjs/common";
import { RatingService } from "../service/rating.service";

@Controller("members")
export class RatingController {
  constructor(private readonly ratingService: RatingService) {}

  @Get(":memberId/ratings")
  getMemberRatings(@Param("memberId", ParseIntPipe) memberId: number) {
    return this.ratingService.getRatingsByMember(memberId);
  }
}
```

컨트롤러 두 개가 같은 /members 경로를 나눠 써도 괜찮습니다.

- MemberController는 /members/nickname/{nickname}, /members/email/{email}을
- RatingController는 /members/{memberId}/ratings를 담당합니다.
- 실제 서비스가 담당하는 **자원(Member vs Rating)** 기준으로 파일은 분리하되, URL 경로는 프론트가 이해하기 쉬운 모양(/members/...)으로 맞추는 것이 API 설계에서 흔히 있는 일입니다.

### Postman으로 확인하기

- Method: **GET**
- URL
  - http://localhost:8080/members/1/ratings (Spring)
  - http://localhost:3000/members/1/ratings (NestJS)
- 시드 데이터로 넣어둔 1번 유저('수현')의 평점 2건이 최신순으로 응답되는지 확인합니다.
- 존재하지 않는 memberId(예: 999)로 요청했을 때 **404 Not Found**가 응답되는지도 함께 확인해보세요.

## 9. CORS 설정 적용하고 다시 확인하기

이제 2절에서 겪었던 에러를 실제로 해결해봅니다.

### **🍃 Spring Boot**

WebMvcConfigurer를 구현한 설정 클래스를 만들어 등록합니다.

컨트롤러 클래스마다 `@CrossOrigin(origins = "...")`을 붙이는 방법도 있지만, 지금처럼 서비스 전체에 동일한 정책을 적용할 때는 이렇게 한 곳에서 설정하는 쪽이 유지보수하기 편합니다.

```java
// src/main/java/com/umc/movie/config/WebConfig.java
package com.umc.movie.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebConfig implements WebMvcConfigurer {

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/**") // 모든 경로에 대해
                .allowedOrigins("http://localhost:5173") // 이 출처에서 오는 요청만 허용
                .allowedMethods("GET", "POST", "PATCH", "DELETE")
                .allowedHeaders("*");
    }
}
```

### **🐱 NestJS**

NestJS에는 Spring의 `@CrossOrigin`처럼 컨트롤러마다 다르게 설정할 수 있는 공식 데코레이터가 따로 없습니다.

그래서 애초에 선택지를 고민할 것 없이, `main.ts`의 `bootstrap()`에서 `app.enableCors()`로 전역 설정 한 줄이면 끝입니다.

```tsx
// src/main.ts
import { NestFactory } from "@nestjs/core";
import { AppModule } from "./app.module";

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  app.enableCors({
    origin: "http://localhost:5173", // 이 출처에서 오는 요청만 허용
    methods: ["GET", "POST", "PATCH", "DELETE"],
  });

  await app.listen(process.env.PORT ?? 3000);
}
bootstrap();
```

### 다시 mock-frontend에서 확인해봅시다!

서버를 재시작한 뒤, 2절에서 만든 http://localhost:5173 페이지로 돌아가 버튼을 다시 눌러봅니다.

이번에는 Console 탭에 에러 없이, 화면에 { "available":false } 같은 응답이 그대로 찍히는 것을 확인할 수 있습니다.

!image.png

<aside>
👉

**네이티브 앱에서 호출한다면?**

CORS는 브라우저의 동일 출처 정책 때문에 생기는 문제입니다.

Flutter 같은 네이티브 앱은 브라우저가 아니므로 애초에 이 정책의 적용을 받지 않고, dio/http 패키지로 API를 호출해도 CORS 에러가 나지 않습니다.

이 경우에는 위 mock-frontend 대신 **앱에서 API를 직접 호출해 정상 응답이 오는지만 확인**하면 됩니다.

CORS는 서버가 브라우저 요청을 검사하는 것이 아니라 **브라우저 스스로에게 거는 제약**이기 때문에, 백엔드에 CORS를 설정해두어도 네이티브 앱의 요청은 전혀 간섭받지 않습니다.

그래서 같은 백엔드를 웹과 앱이 동시에 사용해도 문제없습니다.

</aside>

# 🎯 핵심 키워드

---

<aside>
💡 주요 내용들에 대해 조사해보고, 자신만의 생각을 통해 정리해보세요!
레퍼런스를 참고하여 정의, 속성, 장단점 등을 적어주셔도 됩니다.
조사는 공식 홈페이지 **Best**, 블로그(최신 날짜) **Not Bad**

</aside>

- SOP와 CORS
- Same-Origin과 Same-Site의 차이
- 쿠키의 SameSite 속성
- 복합 UNIQUE 제약을 사용하는 이유는?
- 외부 Open API 연동 시 API Key를 프론트/백엔드 중 어디에 두어야 안전한가?

# 📢 학습 후기

---

- 이번 주차 워크북을 해결해보면서 어땠는지 회고해봅시다.
- 핵심 키워드에 대해 완벽하게 이해했는지? 혹시 이해가 안 되는 부분은 뭐였는지?

<aside>
💡

</aside>

# ✅ 실습 체크리스트

---

- [ ]  로컬 MySQL에 member, rating, favorite 테이블이 생성되어 있고, member/rating에는 시드 데이터도 들어 있다.
- [ ]  Postman으로 GET /members/nickname/{nickname}, GET /members/email/{email}이 available 값을 올바르게 응답한다.
- [ ]  Postman으로 GET /members/{memberId}/ratings가 최신순으로 평점 목록을 응답한다.
- [ ]  CORS 설정 전, 간이 프론트에서 콘솔에 CORS 에러가 뜨는 것을 직접 확인했다.
- [ ]  CORS 설정 후, 같은 간이 프론트에서 정상 응답을 확인했다.

# ☑️ 실습 인증

---

# 🔥 미션

---

<aside>
💡

**미션 진행 및 인증 가이드**

- **1개 스택 선택:**
  - Spring Boot 또는 NestJS 중 **본인이 학습 중인 1개 스택으로만 구현**하시면 됩니다.
- **필수 인증 요소:**
  1. 직접 작성한 **핵심 코드**(Entity, DTO, Controller/Service)
  2. Postman에서 **요청(URL)**과 **응답 데이터(JSON)**가 한눈에 보이는 캡처 화면
  3. 본인이 만든 실제 웹 또는 앱 화면에서 이 API를 호출해 정상 응답을 받는 과정 캡처
- **트러블슈팅 기록:** 구현 중 에러가 발생했다면 하단 트러블슈팅 란에 해결 과정을 함께 남겨주세요!
</aside>

- (필수)
  - **실제 화면에서 확인하기!**
    - CORS를 설정 후, 본인이 만든 실제 웹 또는 앱 화면에서 이 API들을 호출해 정상 응답을 받는 것을 캡처합니다.
    - 현재 구현한 모든 API를 연결해야합니다.
- (선택)
  - **닉네임/이메일 형식 유효성 검증 추가하기**
    - 닉네임은 2~12자, 이메일은 이메일 형식을 만족하지 않으면 available 여부를 판단하기 전에 400 에러로 응답해보세요. (6주차에서 배울 검증의 맛보기입니다.)
  - **평점 목록에 페이지네이션 추가하기**
    - GET /members/{memberId}/ratings?page=0&size=10 형태로 Query Parameter를 받아, 페이지 단위로 잘라서 응답해보세요.
  - **CORS 허용 범위를 좁혀보고 이유 설명하기**
    - allowedOrigins("*")로 모든 출처를 허용했을 때와 특정 출처만 허용했을 때의 차이를, 실제 화면 캡처와 함께 3문장 이상으로 설명해보세요.

# 💪 미션 기록

---

<aside>
🍀 미션 기록의 경우, 아래 미션 기록 토글 속에 작성하시거나, 페이지를 새로 생성하여 해당 페이지에 기록하여도 좋습니다!

하지만, 결과물만 올리는 것이 아닌, **중간 과정 모두 기록하셔야 한다는 점!** 잊지 말아주세요.

</aside>

- **미션 기록**

# 📢 미션 제출 안내 & CodeRabbit 사용법 안내

---

<aside>
👊

미션을 마친 뒤 미션 기록이 포함된 Notion 페이지 URL을 https://umc.ai.kr/ 에 제출해 주세요.

Github에 올리신 코드는 하단의 CodeRabbit을 통해 직접 AI에게 피드백 받으실 수 있습니다!

</aside>

1. 개인 미션 페이지 오른쪽 위의 **공유** 버튼을 눌러 주세요.
2. **링크 복사**를 클릭해 주세요.
3. https://umc.ai.kr/ 에 제출해주세요.

   방법은 ‣ 에 적혀져 있습니다.

- 미션 제출 링크: 링크를 입력해 주시고, 하단의 CodeRabbit 설정으로 직접 AI를 통해 코드 피드백을 받아보세요!

‣

# 🍥 블로그 챌린지 안내

---

<aside>

☘️ 다음 활동들은 **권장 사항**이며 수행 시 챌린저 개인에게 상점이 부여됩니다.

‣

</aside>

> 가이드라인에 제시된 **카테고리 중 1개를 선택해** 블로그를 작성합니다.
본인이 작성한 블로그 URL를 노션 폼에 제출하면, 상점 `+3점` 이 부여됩니다. (주 1회 제출 제한)
>

<aside>

‣

</aside>

>
>
>
> 매주차별 챌린저분들이 작성해주신 블로그는 아래 아카이빙 페이지에서 확인 가능합니다!
>
> ‣
>

# ⚡ 트러블 슈팅

---

<aside>
💡 실습하면서 생긴 문제들에 대해서, **이슈 - 문제 - 해결** 순서로 작성해주세요.

</aside>

<aside>
💡 스스로 해결하기 어렵다면? 스터디원들에게 도움을 요청하거나 **너디너리의 지식IN 채널에 질문**해보세요!

</aside>

- ⚡이슈 작성 예시 (이슈가 생기면 아래를 복사해서 No.1, No.2, No3 … 으로 작성해서 트러블 슈팅을 꼭 해보세요!)

  **`이슈`**

  👉 런타임 단계에서 SQLException: Access denied for user 'root'@'localhost' (using password: YES) 이 발생했다

  **`문제`**

  👉 application.yml에 DB 부분에 username, password를 로컬 DB username, password와 일치하지 않았다

  **`해결`**

  👉  로컬 DB 접속할때 쓰는 username, password를 제대로 기입했다

  **`참고레퍼런스`**

  - 링크
- ⚡이슈 No.1

  **`이슈`**

  👉 [트러블이 생긴 상태 작성]

  **`문제`**

  👉 [어떤 이유로 해당 이슈가 일어났는지 작성]

  **`해결`**

  👉  [해결 방법 작성]

  **`참고레퍼런스`**

  - [문제 해결 시 참고한 링크]

# 🤔 참고 자료

---

<u>Copyright © 2026 박수현(노코) All rights reserved.</u>
