class Movie {
  const Movie({required this.id, required this.title});

  final int id;
  final String title;
}

String displayName(String? nickname) {
  return nickname?.trim().isNotEmpty == true ? nickname! : '이름 없음';
}

void main() {
  final titles = <String?>['인터스텔라', null, '어벤져스'];

  final movies = <Movie>[];

  // for문으로 Movie 인스턴스 추가 + Null Safety
  for (int i = 0; i < titles.length; i++) {
    final title = titles[i] ?? '제목 없음';

    movies.add(Movie(id: i + 1, title: title));
  }

  // map을 사용해서 영화 제목 출력
  movies.map((movie) => movie.title).forEach(print);
}
