class Movie {
  const Movie({required this.id, required this.title});

  final int id;
  final String title;
}

String displayName(String? nickname) {
  return nickname?.trim().isNotEmpty == true ? nickname! : '이름 없음';
}

void main() {
  // 영화 3개를 List<Movie>에 넣기
  final movies = <Movie>[
    const Movie(id: 1, title: '인터스텔라'),
    const Movie(id: 2, title: '기생충'),
    const Movie(id: 3, title: '어벤져스'),
  ];

  // for를 사용해 영화 제목 출력
  for (final movie in movies) {
    print(movie.title);
  }

  // nullable 닉네임을 안전한 기본값으로 변환
  String? nickname;

  final name = displayName(nickname);
  print(name);
}
