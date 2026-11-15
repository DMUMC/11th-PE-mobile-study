# MovieLog · Vector Week 04

3주차 영화 앱을 바탕으로 비동기 영화 로딩과 Loading·Empty·Error·Success 상태를 구현했습니다. 기존 회원가입 화면은 `/signup`에 남겨 두었습니다.

## Week 04 미션

- `FakeMovieService.fetchMovies()`가 `Future<List<Movie>>`를 반환하고 기본 1초 지연 후 Mock 데이터를 제공합니다.
- `FutureBuilder`로 Skeleton Loading, Empty, Error, Success 화면을 분기합니다.
- Error 화면의 `다시 시도` 버튼과 목록의 당겨서 새로고침을 지원합니다.
- 요청이 4초를 넘으면 Timeout 오류 화면을 표시합니다.
- 성공·빈 목록·실패·Timeout 모드를 제공해 각 상태를 재현할 수 있습니다.
- 마지막 장르 선택과 정렬 방식을 `shared_preferences`에 저장하고 앱 재실행 시 복원합니다.
- 영화 Grid와 상태별 Widget을 별도 파일로 분리했습니다.

## 실행

```sh
flutter pub get
flutter run
```

시작 화면은 `/home`입니다. 패키지 이름 `vector_week01`은 기존 프로젝트와의 호환성을 위해 유지했습니다.

## 화면

- **홈**: 추천 영화, 상세보기, 인기 영화, 전체보기
- **영화 목록**: 2열 포스터 목록, 영화 제목 검색, 오른쪽 장르 필터 버튼
- **영화 상세**: 포스터, 영화 정보, 시놉시스, 즐겨찾기, 평점 다이얼로그, 영화 정보 복사
- **마이페이지**: 프로필 사진, 닉네임과 소개 수정, 통계, 선호 장르

## Challenge Mission 구현

| 조건 | 구현 |
| --- | --- |
| 선택 장르를 Query Parameter에 표현 | `/movies?genre=드라마&genre=SF` 형식. Dart `Uri`가 인코딩하며 URL에서 선택 상태를 복원합니다. |
| 탭별 Navigation 상태 유지 | `lib/main.dart`의 `StatefulShellRoute.indexedStack`과 `goBranch`. 홈·영화·마이 탭마다 Navigator를 유지하며 목록 스크롤과 상세 경로를 보존합니다. |
| 영화 목록 장르 Chip 제거 | 목록 오른쪽 `Icons.filter_list` 버튼으로 교체했습니다. 프로필의 선호 장르 Chip은 유지합니다. |
| 드래그 가능한 BottomSheet | `showModalBottomSheet` + `DraggableScrollableSheet`. 처음 55%, 최소 35%, 최대 90% 높이입니다. 손잡이·제목 부분이나 목록을 위아래로 드래그할 수 있습니다. |
| Checkbox 다중 장르 선택 | 선택한 장르 중 하나 이상을 포함하는 영화를 표시합니다. |
| 목록 영역만 스크롤 | 제목 영역과 하단 확인 버튼은 고정하고 가운데 장르 목록만 스크롤합니다. |
| 고정된 ElevatedButton | 목록 바깥 하단에 배치하여 스크롤 중에도 확인 버튼을 표시합니다. |
| 확인 전에는 목록에 미반영 | 시트의 임시 `draft`만 변경합니다. 닫기·바깥 터치·뒤로 가기로 취소하면 기존 필터를 유지합니다. |
| 확인 시 필터 적용 및 시트 닫기 | 확인 결과를 URL에 반영하여 목록을 갱신합니다. |
| 선택 없이 확인하면 전체 표시 | 장르 Query Parameter를 제거하여 모든 영화를 표시합니다. |
| 평점 초기화와 다시 선택 | 다이얼로그의 초기화 버튼으로 별을 비우고 다시 선택할 수 있습니다. 저장 시 반영하며 취소 시 기존 평점을 유지합니다. 초기화 후 저장하면 기존 평점을 삭제합니다. |

## 코드 구성

- `lib/main.dart`: 앱 시작, 라우터, 탭 구성
- `lib/models/movie.dart`: 영화 데이터 및 앱 실행 중 공유 상태
- `lib/screens/home_screen.dart`: 홈 화면
- `lib/screens/movies_screen.dart`: 비동기 상태 분기, 검색, 장르·정렬 선택
- `lib/services/fake_movie_service.dart`: 성공·빈 목록·실패·Timeout Mock 서비스
- `lib/services/movie_preferences.dart`: 장르·정렬 로컬 저장
- `lib/widgets/movie_grid.dart`: 영화 목록과 당겨서 새로고침
- `lib/widgets/movie_state_views.dart`: Loading·Empty·Error 화면
- `lib/screens/movie_detail_screen.dart`: 영화 상세, 평점 다이얼로그
- `lib/profile_screen.dart`: 마이페이지, 프로필 편집
- `lib/widgets/movie_card.dart`: 공통 영화 카드
- `lib/theme/`: 색상 및 Material 테마
- `test/widget_test.dart`: 주요 흐름과 Challenge Mission 동작 테스트

## 디자인 및 데이터

프로젝트에 포함된 포스터·프로필 이미지와 Manrope 폰트를 사용합니다. 목록 참고 이미지의 첫 번째 영화 전용 세로 포스터는 기존 자산에 없어 같은 영화의 기존 `hero_under_the_starlight.jpg`를 사용했습니다. 참고 화면 사이에 다른 개봉 연도·상영 시간·평점은 상세 화면 기준(2024년, 124분, 4.5)으로 통일했습니다.

영화 및 기본 프로필 통계는 과제용 예시 데이터입니다. 장르와 정렬은 앱 종료 후에도 유지되며, 즐겨찾기·평점·프로필 수정은 앱 실행 중 유지합니다. 서버 연결은 포함하지 않습니다. 공유 아이콘은 영화 정보와 앱 내 경로를 클립보드에 복사합니다.

## 검증

```sh
flutter analyze
flutter test
```

테스트는 기존 화면 이동과 필터 흐름에 더해 Fake 서비스의 성공·빈 목록·실패, Loading·Empty·Error·Success·Timeout 화면, 장르·정렬 저장과 복원을 검증합니다.

사용 API 참고: [go_router StatefulShellRoute 공식 문서](https://pub.dev/documentation/go_router/latest/go_router/StatefulShellRoute-class.html)
