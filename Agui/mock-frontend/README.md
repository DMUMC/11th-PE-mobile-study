# 5주차 간이 프론트 및 필수 미션

워크북의 `index.txt`에서 시작한 간이 프론트를 API 3개에 연결하는 웹 화면으로 확장했습니다.
백엔드 프로젝트인 `Agui/movie`와 별개인 폴더이며, Spring Boot의 8080 포트로 요청합니다.

1. IntelliJ에서 `MovieApplication`을 실행합니다. 백엔드는 8080 포트를 사용합니다.
2. 이 폴더에서 워크북의 명령으로 정적 서버를 실행합니다.

   ```sh
   npx serve -l 5173
   ```

3. 브라우저에서 `http://localhost:5173`에 접속합니다.
4. 닉네임·이메일·회원 ID를 입력하고 각 버튼을 누릅니다. 요청 URL, HTTP 상태와 실제 JSON이 표시됩니다.
5. CORS 설정 전 실습에서는 `blocked by CORS policy` 등의 오류를 확인했습니다.
   Chrome에서 구체적인 메시지가 보이지 않으면 Issues 패널에서 CORS 진단과
   `Access-Control-Allow-Origin`의 `Missing header`를 확인합니다.

아직 API가 없어도 워크북 안내대로 실습할 수 있습니다. 이때 서버 자체 응답은 404일 수 있으며,
이 단계는 닉네임 API의 정상 응답이 아닌 브라우저의 CORS 차단을 확인하는 단계입니다.
화면의 `Failed to fetch`만으로 CORS라고 단정하지 않고 Console의 구체적인 오류를 확인합니다.

현재는 API와 CORS 설정을 적용했으므로 모든 기능에서 실제 서버 응답을 읽을 수 있습니다.

| 기능 | 기본 입력 | 워크북 시드 데이터 기준 결과 |
| --- | --- | --- |
| 닉네임 확인 | 수현 | HTTP 200, `available: false` |
| 이메일 확인 | noco@umc.com | HTTP 200, `available: false` |
| 평점 조회 | 1 | HTTP 200, 평점 2건, `ratingId` 2 → 1 |

`미등록아귀`, `week05-unused@example.test`는 사용 가능(`true`) 응답을 확인했습니다.
회원 ID `999`는 HTTP 404와 존재하지 않는 회원 안내를 확인했습니다.
요청 중에는 버튼이 비활성화되며 실패 시 오류 메시지로 이전 결과를 교체합니다.
별도의 API 키나 로그인 없이 이번 주차의 조회 API만 사용합니다.

설정 전 인증 캡처: [CORS 오류 상세](captures/cors-before-issues.png)

전체 인증 자료와 실제 코드: [필수 미션 기록](../movie/mission-submission.md)
