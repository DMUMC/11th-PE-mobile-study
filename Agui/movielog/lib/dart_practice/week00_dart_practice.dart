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

  for (int i = 0; i < titles.length; i++) {
    movies.add(Movie(id: i + 1, title: displayName(titles[i])));
  }

  movies.map((movie) => movie.title).forEach(print);
}
