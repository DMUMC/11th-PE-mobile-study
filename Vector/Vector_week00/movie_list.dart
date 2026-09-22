class Movie {
  String title;
  
  Movie(this.title);
}

void main() {
  List<Movie> movieList = [
    Movie('옵세션'),
    Movie('오디세이'),
    Movie('스파이더맨'),
  ];

  print('--- 영화 목록 출력 ---');
  for (var movie in movieList) {
    print(movie.title);
  }

  String? nickname; 

  String safeNickname = nickname ?? '익명';
  print('\n닉네임: $safeNickname');
}