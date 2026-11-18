# movielog

A new Flutter project.

## 평점 화면 실행

프로젝트의 `.env`에 `TMDB_ACCESS_TOKEN`을 설정한 뒤 실행합니다.

```sh
flutter run --dart-define-from-file=.env
```

평점 화면은 워크북 API의 학습용 회원 1을 조회하고, TMDB에서 영화 제목·포스터를 가져옵니다.
TMDB 설정이 없거나 영화 조회가 실패하면 평점은 유지하고 영화 ID와 대체 포스터를 표시합니다.

## Required Mission 기능 확인

```sh
flutter run -t lib/dev/required_mission_main.dart --dart-define-from-file=.env
```

별도의 개발용 실행 화면에서 버튼 너비, 평점 빈 목록·오류 후 재시도·영화 정보 누락,
회원가입 확인 상태를 재현할 수 있습니다. 평점과 중복 확인 응답은 로컬 개발용 데이터이며
실제 서버를 변경하지 않습니다. 영화 정보는 기존 TMDB 설정을 사용합니다.
회원가입 예시 값은 중복, 끝에 `a`를 붙인 값은 사용 가능, 끝에 `e`를 붙인 값은 통신 실패로 응답합니다.
일반 `lib/main.dart` 실행 화면에는 개발용 메뉴가 포함되지 않습니다.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
