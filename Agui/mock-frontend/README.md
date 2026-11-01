# 실습 0: CORS 오류 확인

워크북의 `index.txt` 내용을 바탕으로, Spring Boot에 맞춰 요청 포트를 8080으로 설정했습니다.
백엔드 프로젝트인 `Agui/movie`와 별개인 폴더입니다.

1. IntelliJ에서 `MovieApplication`을 실행합니다. 백엔드는 8080 포트를 사용합니다.
2. 이 폴더에서 워크북의 명령으로 정적 서버를 실행합니다.

   ```sh
   npx serve -l 5173
   ```

3. 브라우저에서 `http://localhost:5173`에 접속합니다.
4. 개발자 도구의 Console 탭을 열고 **'noco'으로 중복 체크** 버튼을 누릅니다.
5. CORS 설정 전에는 `blocked by CORS policy` 등의 오류를 확인합니다.
   Chrome에서 구체적인 메시지가 보이지 않으면 Issues 패널에서 CORS 진단과
   `Access-Control-Allow-Origin`의 `Missing header`를 확인합니다.

아직 API가 없어도 워크북 안내대로 실습할 수 있습니다. 이때 서버 자체 응답은 404일 수 있으며,
이 단계는 닉네임 API의 정상 응답이 아닌 브라우저의 CORS 차단을 확인하는 단계입니다.
화면의 `Failed to fetch`만으로 CORS라고 단정하지 않고 Console의 구체적인 오류를 확인합니다.

현재는 API와 CORS 설정을 적용했으므로 같은 버튼을 누르면 `available` 응답이 표시됩니다.
실제 브라우저에서 `{"available":true}`가 표시되는 것을 확인했습니다.
`noco` 닉네임이 DB에 추가되면 결과는 `false`로 바뀝니다.

설정 전 인증 캡처: [CORS 오류 상세](captures/cors-before-issues.png)
