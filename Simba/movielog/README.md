# movielog

UMC 11th PE Flutter 스터디 MovieLog 프로젝트 (Simba)

## 실행 준비 (5주차 TMDB 연동)

1. TMDB 설정 > API에서 **API Read Access Token**(긴 문자열)을 발급합니다.
2. `.env.example`을 복사해 같은 위치(`pubspec.yaml` 옆)에 `.env`를 만들고 Token을 입력합니다.
   ```
   TMDB_ACCESS_TOKEN=발급받은_READ_ACCESS_TOKEN
   ```
   `.env`는 `.gitignore`에 등록되어 있어 커밋되지 않습니다. `pubspec.yaml`에 asset으로 등록되어 있으므로 파일이 없으면 빌드가 실패합니다.
3. MovieLog 자체 API는 워크북 서버(`https://workbook.devnoco.com`, v5)를 사용합니다. 별도 설정이 필요 없습니다.
   - 내가 등록한 평점은 학습용 memberId 1을 조회합니다. Empty/Error 화면 확인 시에만 `--dart-define=SAMPLE_MEMBER_ID=3`(빈 배열) 또는 `=999999`(404)로 실행합니다.
   - 중복 확인 테스트 값: 닉네임 `영화광`, 이메일 `movie@umc.com` (중복)
4. 패키지를 설치하고 실행합니다.
   ```bash
   flutter pub get
   flutter analyze
   flutter run
   ```

## 구조

```
lib/
├─ main.dart                      # .env 로드 후 runApp
├─ app/movie_log_app.dart         # MultiProvider(TmdbMovieService) + MaterialApp.router
├─ router/app_router.dart         # 화면별 ChangeNotifierProvider(ViewModel) 연결
├─ core/
│  ├─ config/tmdb_config.dart     # .env의 TMDB_ACCESS_TOKEN 읽기
│  └─ network/
│     ├─ tmdb_client.dart         # TMDB 전용 Dio Client
│     └─ tmdb_logging_interceptor.dart  # 요청/응답/오류 로그 (Authorization 마스킹, debug 전용)
├─ data/
│  ├─ models/                     # TmdbMovieDto, TmdbMoviePageDto, TmdbGenreDto
│  └─ services/tmdb_movie_service.dart  # Popular / Discover / Genre API
├─ view_models/                   # MovieHomeViewModel(인기 5개), MovieListViewModel(최대 30개)
├─ screens/                       # View
├─ widgets/                       # TmdbPosterImage, MovieCard, GenreFilterBottomSheet, MovieLoadFailureDialog
└─ utils/movie_format.dart        # 출시 연도, 5점 만점 점수 표시
```
