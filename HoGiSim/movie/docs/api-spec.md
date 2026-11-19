# MovieLog API 명세 · 5주차

Base URL: `http://localhost:3001` · 응답 Content-Type: application/json
현재 주차는 로그인 전 조회 실습이므로 인증을 적용하지 않는다.
회원가입/로그인/평점 CRUD와 TMDB 영화 조회 프록시는 구현 범위에 포함하지 않는다.

| API | Method + URL | Request | 200 응답 |
| --- | --- | --- | --- |
| 닉네임 중복 확인 | GET /members/nickname/{nickname} | Path nickname: string, 2~12자, 공백만 불가 | {"available":true} |
| 이메일 중복 확인 | GET /members/email/{email} | Path email: string, 이메일 형식, 최대 254자 | {"available":true} |
| 유저별 평점 목록 | GET /members/{memberId}/ratings | Path memberId: 양의 안전 정수 | RatingResponseDto 배열 |

중복이면 available=false, 미사용 값이면 true다. 중복은 오류가 아니므로 모두 200이다.
Path 값은 `encodeURIComponent`로 인코딩한다.

평점은 ratingId 내림차순으로 응답한다.
존재하는 회원의 평점이 없으면 200과 []를 반환하고, 없는 회원은 404다.
회원/비밀번호/이메일 엔티티 전체를 응답하지 않는다.
movieId는 TMDB의 ID를 그대로 사용하며 영화 테이블 FK가 아니다.

선택 페이지네이션:
`GET /members/1/ratings?page=0&size=10`
page는 0~100000의 정수, size는 1~100의 정수다.
둘 중 하나라도 전달하면 생략한 값은 page=0, size=10으로 채운다.
둘 다 생략하면 전체 목록을 반환한다. 페이지 결과도 배열 형식을 유지한다.

```json
[
  {
    "ratingId": 2,
    "movieId": 155,
    "score": 4,
    "comment": "다시 봐도 명작",
    "createdAt": "2026-10-29T01:00:00.000Z",
    "updatedAt": "2026-10-29T01:00:00.000Z"
  }
]
```

ratingId/movieId/score: number, comment: string|null, createdAt/updatedAt: ISO 8601 string.
ID는 JavaScript 안전 정수 범위(1~9007199254740991)로 제한한다.
DB BIGINT는 엔티티 내부에서 문자열로 유지하고 응답 DTO에서 안전하게 숫자로 변환한다.
잘못된 입력/페이지 조건은 400, 존재하지 않는 회원은 404다.

```json
{"message":"존재하지 않는 유저입니다.","error":"Not Found","statusCode":404}
```

CORS 기본 허용 출처는 `http://localhost:5173` 한 곳이다.
허용 메서드: GET, POST, PATCH, DELETE, OPTIONS.
현재 실제 구현된 API 메서드는 GET이며, credentials는 사용하지 않는다.
CORS 불허 출처도 서버는 GET을 처리할 수 있지만 브라우저가 응답 읽기를 막는다.
따라서 Postman/curl의 성공만으로 브라우저 CORS 성공을 판단하지 않는다.
