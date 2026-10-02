import 'package:movielog/movie/model/movie.dart';

const movies = <Movie>[
  Movie(
    id: 1,
    title: '속삭이는 숲',
    genre: '판타지',
    year: 2024,
    posterAsset: 'assets/images/posters/poster_whispering_woods.jpg',
    rating: 8.7,
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
    rating: 8.5,
  ),
  Movie(
    id: 5,
    title: '밤의 그림자',
    genre: '미스터리',
    year: 2022,
    posterAsset: 'assets/images/posters/poster_night_shadows.jpg',
  ),
  Movie(
    id: 6,
    title: '별빛 아래 우리',
    genre: '로맨스 · 드라마',
    year: 2025,
    posterAsset: 'assets/images/posters/hero_under_the_starlight.jpg',
  ),
  Movie(
    id: 7,
    title: '마션 레스큐',
    genre: 'SF',
    year: 2025,
    posterAsset: 'assets/images/posters/poster_echoes_of_the_void.jpg',
    rating: 9.6,
  ),
  Movie(
    id: 8,
    title: '스파이 코드',
    genre: '액션',
    year: 2025,
    posterAsset: 'assets/images/posters/poster_abyss_walker.jpg',
    rating: 9.2,
  ),
  Movie(
    id: 9,
    title: '비오는 날의 그림자',
    genre: '스릴러',
    year: 2024,
    posterAsset: 'assets/images/posters/poster_night_shadows.jpg',
    rating: 8.9,
  ),
  // Curated catalog records are part of the same canonical mock collection.
  Movie(
    id: 10,
    title: '별빛 아래 우리',
    genre: '드라마',
    year: 2023,
    posterAsset: 'assets/images/posters/poster_under_the_starlight.png',
    rating: 4.8,
  ),
  Movie(
    id: 11,
    title: '우주의 끝에서',
    genre: 'SF',
    year: 2024,
    posterAsset: 'assets/images/posters/poster_echoes_of_the_void.jpg',
    rating: 4.2,
  ),
  Movie(
    id: 12,
    title: '기억의 숲',
    genre: '애니메이션',
    year: 2022,
    posterAsset: 'assets/images/posters/poster_whispering_woods.jpg',
    rating: 4.9,
  ),
  Movie(
    id: 13,
    title: '밤의 그림자',
    genre: '스릴러',
    year: 2024,
    posterAsset: 'assets/images/posters/poster_night_shadows.jpg',
    rating: 3.8,
  ),
  Movie(
    id: 14,
    title: '봄날의 커피',
    genre: '로맨스',
    year: 2021,
    posterAsset: 'assets/images/posters/poster_fourth_afternoon.jpg',
    rating: 4.5,
  ),
  Movie(
    id: 15,
    title: '도시의 선',
    genre: '다큐멘터리',
    year: 2023,
    posterAsset: 'assets/images/posters/poster_city_lines.png',
    rating: 4.1,
  ),
];

/// Movie list screen ordering; the movie records themselves stay in [movies].
const catalogMovieIds = [10, 11, 12, 13, 14, 15];

Movie? findMovieById(int? id) {
  for (final movie in movies) {
    if (movie.id == id) return movie;
  }
  return null;
}
