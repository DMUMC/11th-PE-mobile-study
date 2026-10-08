import '../models/movie.dart';

const mockMovies = <Movie>[
  Movie(
    id: 'under-the-starlight',
    title: '별빛 아래 우리',
    genres: ['로맨스', '드라마'],
    year: 2023,
    posterAsset: 'assets/images/posters/hero_under_the_starlight.jpg',
    overview: '바쁜 현대 사회 속에서 서로의 존재를 잊고 살아가던 두 남녀가 우연한 계기로 작은 천문대에서 만나게 됩니다. 매일 밤 별을 관측하며 서로의 상처를 치유하고, 잊고 있던 꿈과 사랑을 다시금 깨닫게 되는 따뜻한 이야기입니다.\n\n과거의 아픔으로 인해 사람에게 마음을 열지 못하던 여주인공은 별자리처럼 변함없는 모습으로 자신을 기다려주는 남주인공을 통해 서서히 마음의 문을 열게 됩니다. 하지만 두 사람 앞에 놓인 현실적인 장벽들은 그들의 관계를 시험하게 되는데...\n\n별이 쏟아지는 밤하늘 아래, 그들이 나눈 조용한 약속들은 과연 영원할 수 있을까요? 눈부신 영상미와 감성적인 OST가 어우러져 깊은 여운을 남기는 올겨울 최고의 로맨스 영화.',
    director: 'Cinema Archive',
    runtime: 124,
    averageRating: 4.5,
    reviewCount: 1245,
  ),
  Movie(
    id: 'edge-of-space',
    title: '우주의 끝에서',
    genres: ['SF'],
    year: 2024,
    posterAsset: 'assets/images/posters/poster_echoes_of_the_void.jpg',
    overview: '우주 끝에서 반복되는 정체불명의 신호를 발견한 연구팀이 감춰진 진실에 다가갑니다.',
    director: '엘라라 밴스',
    runtime: 128,
    averageRating: 4.2,
    reviewCount: 892,
  ),
  Movie(
    id: 'memory-woods',
    title: '기억의 숲',
    genres: ['애니메이션'],
    year: 2022,
    posterAsset: 'assets/images/posters/poster_whispering_woods.jpg',
    overview: '숲의 목소리를 들을 수 있는 아이가 사라진 계절을 되찾기 위해 특별한 여행을 시작합니다.',
    director: '한지우',
    runtime: 109,
    averageRating: 4.9,
    reviewCount: 2018,
  ),
  Movie(
    id: 'night-shadows',
    title: '밤의 그림자',
    genres: ['스릴러'],
    year: 2024,
    posterAsset: 'assets/images/posters/poster_night_shadows.jpg',
    overview: '잠들지 않는 도시에서 연이어 사라지는 사람들과 한 형사의 집요한 추적을 그립니다.',
    director: '박찬욱',
    runtime: 115,
    averageRating: 3.8,
    reviewCount: 756,
  ),
  Movie(
    id: 'spring-coffee',
    title: '봄날의 커피',
    genres: ['로맨스'],
    year: 2021,
    posterAsset: 'assets/images/posters/poster_fourth_afternoon.jpg',
    overview: '봄날의 작은 카페에서 다시 만난 두 사람이 오래전 전하지 못했던 마음을 꺼내놓습니다.',
    director: '정우성',
    runtime: 103,
    averageRating: 4.5,
    reviewCount: 1184,
  ),
  Movie(
    id: 'rhythm-of-the-city',
    title: '도시의 리듬',
    genres: ['다큐멘터리'],
    year: 2023,
    posterAsset: 'assets/images/posters/poster_abyss_walker.jpg',
    overview: '도시를 움직이는 사람들과 건축, 소리의 리듬을 따라가는 감각적인 다큐멘터리입니다.',
    director: '이도윤',
    runtime: 96,
    averageRating: 4.1,
    reviewCount: 643,
  ),
];

const movieGenres = ['드라마', 'SF', '애니메이션', '스릴러', '로맨스', '코미디', '판타지', '다큐멘터리'];

Movie? findMovieById(String id) {
  for (final movie in mockMovies) {
    if (movie.id == id) return movie;
  }
  return null;
}
