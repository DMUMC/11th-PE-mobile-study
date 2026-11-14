# MovieLog 5주차 프론트엔드

## 실행

프로젝트 폴더에서 다음을 실행합니다.

```sh
flutter pub get
cp config/tmdb.example.json config/tmdb.local.json
```

`config/tmdb.local.json`의 `TMDB_READ_ACCESS_TOKEN`에 TMDB **API Read Access Token**을 입력합니다. API key(v3)와 구분합니다. 이 파일은 Git에서 제외됩니다.

```sh
flutter run --dart-define-from-file=config/tmdb.local.json
```

토큰 없이 4주차 가짜 데이터로 UI를 확인하려면 명시적으로 다음을 실행합니다.

```sh
flutter run --dart-define=USE_FAKE_MOVIES=true
```

기본 실행은 실제 TMDB를 사용하며 토큰이 없으면 설정 안내와 재시도 창을 표시합니다. 홈 탭의 기존 샘플 콘텐츠는 유지되며 실제 Discover 데이터는 영화 탭에서 확인합니다.

## 구현

- `MovieService` 인터페이스로 Fake와 TMDB 구현을 교체합니다.
- `TmdbMovieService`: Discover page 1부터 순차 호출, ID 중복 제거, 최대 30개, 마지막 페이지/빈 페이지 종료. 페이지 중간 실패는 부분 성공으로 취급하지 않습니다.
- 장르 상태는 `List<int>?`. 선택한 ID는 `18|878`처럼 OR로 연결하고, 전체 선택에서는 `with_genres`를 생략합니다. URL/로컬 설정도 ID로 저장하며 4주차 이름 기반 설정과 링크는 마이그레이션해서 읽습니다.
- 기존 BottomSheet는 확인 시 적용하고, 닫기/뒤로 가기는 변경을 버립니다. 선택 변경 시 page 1부터 새 목록을 요청합니다.
- `RefreshIndicator`와 `AlwaysScrollableScrollPhysics`로 짧은 목록/빈 목록에서도 당겨서 갱신합니다. 초기 Loading에는 제스처가 없으며 요청 중에는 notificationPredicate와 controller 양쪽에서 중복 새로고침을 막습니다.
- `MoviesController`: 마지막 성공 목록과 요청 상태를 별도로 유지합니다. 갱신 중/실패/취소에 기존 목록을 보존하고 전체 성공 시 교체합니다. 연속 장르 변경에서는 이전 응답을 무시합니다.
- 실패 Dialog의 재시도는 마지막 장르 ID 목록을 유지한 채 page 1부터 최대 30개를 다시 요청합니다. 취소는 요청하지 않습니다.
- 네트워크 이미지와 누락 이미지 대체 화면을 지원하며 API 영화도 상세 화면으로 이동합니다. Discover 응답에 없는 상영 시간은 임의로 표시하지 않습니다.
- `NetworkLogger`는 `kDebugMode`에서만 URL·상태 코드·안전한 오류 메시지를 출력합니다. 헤더/응답 본문/원본 예외를 출력하지 않고 민감 쿼리를 가립니다.

## 검증 결과 — 2026-11-01

- 변경 전 4주차 원본의 기존 테스트: **14개 통과**.
- 변경 후 기존 회귀 + API + controller + 실제 새로고침 제스처/취소/재시도 테스트: **24개 통과**.
- `dart analyze lib test`: 오류/경고 없음.
- 앱의 Flutter debug bundle 컴파일 성공.
- 현재 작업 환경에서는 `flutter test`가 사용하는 localhost 서버 생성이 제한됩니다. 동일 테스트를 Flutter 엔진과 test_api로 직접 실행하는 임시 검증 runner를 사용했습니다. 배포 소스의 테스트는 표준 `flutter test`로 실행할 수 있습니다.

```sh
flutter analyze
flutter test
```

## 트러블슈팅 기록

### 인증 실패 로그 (MockClient 401 재현, 실제 출력)

```text
[network] GET https://api.themoviedb.org/3/discover/movie?language=ko-KR&include_adult=false&sort_by=popularity.desc&page=1&with_genres=18%7C878 ERROR HTTP 401: 인증에 실패했습니다. API 토큰을 확인해주세요.
kDebugMode=true; emittedLogs=1
```

### 실제 HTTP 요청 실패 (네트워크 접근이 제한된 작업 환경)

잘못된 검증용 토큰으로 실제 TMDB 요청을 시도했으나 네트워크 연결 단계에서 실패했습니다. 실제 TMDB 서버가 401을 반환했다고 주장하는 기록은 아닙니다.

```text
[network] GET https://api.themoviedb.org/3/discover/movie?language=ko-KR&include_adult=false&sort_by=popularity.desc&page=1&with_genres=18%7C878 ERROR NETWORK: 네트워크 연결을 확인해주세요.
HTTP probe result: 네트워크 연결을 확인해주세요.
```

두 출력 모두 Authorization 헤더와 토큰 원문이 없습니다.

### 로그 비활성화

같은 오류 재현 프로그램을 `dart.vm.product=true`로 컴파일해서 실행한 결과입니다. 실제 기기 release 설치 검증과는 구분합니다.

```text
kDebugMode=false; emittedLogs=0
```

### 실기기에서 남은 확인

유효한 토큰은 프로젝트에 제공되지 않아 실제 API 성공 응답과 기기 네트워크 OFF/ON은 검증하지 못했습니다.

1. 유효한 토큰으로 영화 탭을 열어 목록을 불러옵니다.
2. 드라마/SF 선택 후 확인 → 두 장르 조건으로 최대 30개 표시.
3. 기기 네트워크를 끄고 당겨서 갱신 → 기존 목록 위에 실패 Dialog 표시.
4. 취소 → 기존 목록 유지. 다시 갱신 후 네트워크를 켜고 재시도 → Dialog 닫힘, 같은 조건으로 page 1부터 다시 요청해 최신 목록으로 교체.
5. `flutter run --release --dart-define-from-file=config/tmdb.local.json`으로 네트워크 로그가 없는지 확인합니다.

## 참고 문서

- https://developer.themoviedb.org/reference/discover-movie
- https://developer.themoviedb.org/docs/authentication-application
- https://api.flutter.dev/flutter/material/RefreshIndicator-class.html
