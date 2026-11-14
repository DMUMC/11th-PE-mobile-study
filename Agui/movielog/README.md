# movielog

A new Flutter project.

## 평점 화면 실행

프로젝트의 `.env`에 `TMDB_ACCESS_TOKEN`을 설정한 뒤 실행합니다.

```sh
flutter run --dart-define-from-file=.env
```

평점 화면은 워크북 API의 학습용 회원 1을 조회하고, TMDB에서 영화 제목·포스터를 가져옵니다.
TMDB 설정이 없거나 영화 조회가 실패하면 평점은 유지하고 영화 ID와 대체 포스터를 표시합니다.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
