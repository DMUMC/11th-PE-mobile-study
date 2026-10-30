// TMDB 값을 화면 표시용 문자열로 바꾸는 함수 모음.

/// `release_date`("2024-05-01")에서 연도만 꺼낸다. 값이 없거나 형식이 다르면 null.
String? releaseYearOf(String? releaseDate) {
  if (releaseDate == null || releaseDate.length < 4) return null;
  final year = releaseDate.substring(0, 4);
  return int.tryParse(year) == null ? null : year;
}

/// TMDB `vote_average`(10점 만점)를 MovieLog 별점(5점 만점) 문자열로 바꾼다.
String fivePointScoreOf(double voteAverage) {
  return (voteAverage / 2).toStringAsFixed(1);
}
