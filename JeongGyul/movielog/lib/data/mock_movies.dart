import '../models/movie.dart';

const movies = [
  Movie(
    id: 1,
    title: '별빛 아래 우리',
    genre: '드라마',
    year: 2024,
    posterAsset: 'assets/images/posters/poster_under_the_starlight.jpg',
    heroAsset: 'assets/images/posters/hero_under_the_starlight.jpg',
    averageRating: 4.5,
    durationMinutes: 124,
    tags: ['로맨스', '드라마', '감동적인'],
    synopsis:
        '바쁜 현대 사회 속에서 서로의 존재를 잊고 살아가던 두 남녀가 우연한 계기로 작은 천문대에서 만나게 됩니다. 매일 밤 별을 관측하며 서로의 상처를 치유하고, 잊고 있던 꿈과 사랑을 다시금 깨닫게 되는 따뜻한 이야기입니다.\n\n'
        '과거의 아픔으로 인해 사람에게 마음을 열지 못하던 여주인공은, 별자리처럼 변함없는 모습으로 자신을 기다려주는 남주인공을 통해 서서히 마음의 문을 열게 됩니다. 하지만 두 사람 앞에 놓인 현실적인 장벽들은 그들의 관계를 시험하게 되는데...\n\n'
        '별이 쏟아지는 밤하늘 아래, 그들이 나눈 조용한 약속들은 과연 영원할 수 있을까요? 눈부신 영상미와 감성적인 OST가 어우러져 깊은 여운을 남기는 올 겨울 최고의 로맨스 영화.\n\n'
        '잔잔한 감동과 함께 삶의 의미를 다시 한번 되돌아보게 만드는 수작입니다.',
  ),
  Movie(
    id: 2,
    title: '우주의 끝에서',
    genre: 'SF',
    year: 2024,
    posterAsset: 'assets/images/posters/poster_echoes_of_the_void.jpg',
    averageRating: 4.2,
    durationMinutes: 132,
    tags: ['SF', '모험'],
    synopsis: '우주의 끝에서 들려오는 신호를 따라 떠난 탐사대. 미지의 행성에서 발견한 흔적은 인류의 미래와 연결되어 있습니다.',
  ),
  Movie(
    id: 3,
    title: '기억의 숲',
    genre: '애니메이션',
    year: 2022,
    posterAsset: 'assets/images/posters/poster_whispering_woods.jpg',
    averageRating: 4.9,
    durationMinutes: 98,
    tags: ['애니메이션', '판타지'],
    synopsis:
        '잃어버린 기억을 찾기 위해 신비로운 숲으로 들어간 아이. 숲속 친구들과 함께 자신에게 소중한 것이 무엇인지 배워갑니다.',
  ),
  Movie(
    id: 4,
    title: '밤의 그림자',
    genre: '스릴러',
    year: 2024,
    posterAsset: 'assets/images/posters/poster_night_shadows.jpg',
    averageRating: 3.8,
    durationMinutes: 112,
    tags: ['스릴러', '미스터리'],
    synopsis: '밤마다 같은 골목에서 사라지는 사람들. 사건을 추적하던 형사는 도시가 감추고 있던 비밀과 마주합니다.',
  ),
  Movie(
    id: 5,
    title: '봄날의 커피',
    genre: '로맨스',
    year: 2021,
    posterAsset: 'assets/images/posters/poster_fourth_afternoon.jpg',
    averageRating: 4.5,
    durationMinutes: 106,
    tags: ['로맨스', '드라마'],
    synopsis: '작은 카페에서 우연히 만난 두 사람. 한 잔의 커피와 함께 시작된 대화가 서로의 일상을 조금씩 바꿔갑니다.',
  ),
  Movie(
    id: 6,
    title: '도시의 선',
    genre: '다큐멘터리',
    year: 2023,
    posterAsset: 'assets/images/posters/poster_city_lines.jpg',
    averageRating: 4.1,
    durationMinutes: 98,
    tags: ['다큐멘터리', '건축'],
    synopsis: '도시를 이루는 건축과 그 안에서 살아가는 사람들의 이야기. 익숙한 거리의 풍경을 새로운 시선으로 바라봅니다.',
  ),
  Movie(
    id: 7,
    title: '마션 레스큐',
    genre: 'SF',
    year: 2024,
    posterAsset: 'assets/images/posters/poster_martian_rescue.jpg',
    averageRating: 4.8,
    durationMinutes: 128,
    tags: ['SF', '모험'],
    isPopular: true,
    synopsis: '먼 행성에 홀로 남겨진 탐사원. 동료들은 그를 구하기 위해 불가능해 보이는 구조 작전을 시작합니다.',
  ),
  Movie(
    id: 8,
    title: '스파이 코드',
    genre: '액션',
    year: 2024,
    posterAsset: 'assets/images/posters/poster_spy_code.jpg',
    averageRating: 4.6,
    durationMinutes: 118,
    tags: ['액션', '코미디'],
    isPopular: true,
    synopsis:
        '비밀 암호를 손에 넣은 스파이가 세계를 지키기 위한 작전에 뛰어듭니다. 예상하지 못한 동료와 함께 펼치는 유쾌한 추격전.',
  ),
  Movie(
    id: 9,
    title: '비오는 날의 그림자',
    genre: '드라마',
    year: 2023,
    posterAsset: 'assets/images/posters/poster_rainy_day.jpg',
    averageRating: 4.45,
    durationMinutes: 110,
    tags: ['드라마', '미스터리'],
    isPopular: true,
    synopsis: '비가 내리는 도시에서 다시 만난 오랜 친구들. 미처 전하지 못했던 마음과 과거의 기억이 천천히 드러납니다.',
  ),
];

Movie? findMovieById(int? id) {
  for (final movie in movies) {
    if (movie.id == id) return movie;
  }
  return null;
}
