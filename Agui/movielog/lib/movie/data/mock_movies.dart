import 'package:movielog/movie/model/movie.dart';

const movies = <Movie>[
  Movie(
    id: 1,
    title: '속삭이는 숲',
    genre: '판타지',
    year: 2024,
    posterAsset: 'assets/images/posters/poster_whispering_woods.jpg',
  ),
  Movie(
    id: 2,
    title: '공허의 메아리',
    genre: 'SF',
    year: 2024,
    posterAsset: 'assets/images/posters/poster_echoes_of_the_void.jpg',
  ),
  Movie(
    id: 3,
    title: '심연의 방랑자',
    genre: '스릴러',
    year: 2023,
    posterAsset: 'assets/images/posters/poster_abyss_walker.jpg',
  ),
  Movie(
    id: 4,
    title: '네 번째 오후',
    genre: '드라마',
    year: 2025,
    posterAsset: 'assets/images/posters/poster_fourth_afternoon.jpg',
  ),
  Movie(
    id: 5,
    title: '밤의 그림자',
    genre: '미스터리',
    year: 2022,
    posterAsset: 'assets/images/posters/poster_night_shadows.jpg',
  ),
];

Movie? findMovieById(int? id) {
  for (final movie in movies) {
    if (movie.id == id) return movie;
  }
  return null;
}
