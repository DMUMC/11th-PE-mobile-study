void main() {
  const movies= <Movie>[
    Movie(id: 1, title: "오디세이"),
    Movie(id: 2, title: "스파이더맨"),
    Movie(id: 3, title: "호프")
  ];

  for(final movie in movies) {
    print(movie.title);
  }
  print(displayName("  "));
}

class Movie {
  const Movie({required this.id, required this.title});

  final int id;
  final String title;
}

String displayName(String? nickname) {
  return nickname?.trim().isNotEmpty == true ? nickname! : '이름 없음';
}
