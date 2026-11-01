import 'package:flutter/foundation.dart';

const movieGenres = [
  '드라마',
  'SF',
  '애니메이션',
  '스릴러',
  '로맨스',
  '판타지',
  '모험',
  '코미디',
  '액션',
  '미스터리',
  '공포',
  '다큐멘터리',
];

class Movie {
  const Movie({
    required this.id,
    required this.title,
    required this.year,
    required this.genres,
    required this.minutes,
    required this.rating,
    required this.image,
    required this.synopsis,
  });
  final String id, title, image, synopsis;
  final int year, minutes;
  final List<String> genres;
  final double rating;
}

const movies = <Movie>[
  Movie(
    id: 'starlight',
    title: '별빛 아래 우리',
    year: 2024,
    genres: ['로맨스', '드라마'],
    minutes: 124,
    rating: 4.5,
    image: 'assets/images/posters/hero_under_the_starlight.jpg',
    synopsis: '바쁜 현대 사회 속에서 서로의 존재를 잊고 살아가던 두 남녀가 우연한 계기로 작은 천문대에서 만나게 됩니다. 매일 밤 별을 관측하며 서로의 상처를 치유하고, 잊고 있던 꿈과 사랑을 다시금 깨닫게 되는 따뜻한 이야기입니다.\n\n과거의 아픔으로 인해 사람에게 마음을 열지 못하던 여주인공은, 별자리처럼 변함없는 모습으로 자신을 기다려주는 남주인공을 통해 서서히 마음의 문을 열게 됩니다. 하지만 두 사람 앞에 놓인 현실적인 장벽들은 그들의 관계를 시험하게 되는데...\n\n별이 쏟아지는 밤하늘 아래, 그들이 나눈 조용한 약속들은 과연 영원할 수 있을까요? 눈부신 영상미와 감성적인 OST가 어우러져 깊은 여운을 남기는 올 겨울 최고의 로맨스 영화.\n\n잔잔한 감동과 함께 삶의 의미를 다시 한번 되돌아보게 만드는 수작입니다.',
  ),
  Movie(
    id: 'void',
    title: '우주의 끝에서',
    year: 2024,
    genres: ['SF', '모험'],
    minutes: 138,
    rating: 4.2,
    image: 'assets/images/posters/poster_echoes_of_the_void.jpg',
    synopsis: '우주의 끝에서 수신된 낯선 신호. 홀로 탐사에 나선 우주비행사는 미지의 행성에서 인류의 기원을 뒤바꿀 비밀을 마주합니다.\n\n끝없는 고요 속에서 그가 찾아야 할 것은 새로운 세계일까요, 돌아갈 집일까요?',
  ),
  Movie(
    id: 'woods',
    title: '기억의 숲',
    year: 2023,
    genres: ['애니메이션', '판타지'],
    minutes: 102,
    rating: 4.9,
    image: 'assets/images/posters/poster_whispering_woods.jpg',
    synopsis: '잊힌 기억들이 잠들어 있는 숲에 작은 빛이 찾아옵니다. 숲의 정령과 함께 길을 떠난 아이는 소중한 추억을 되찾기 위한 모험을 시작합니다.\n\n아름다운 숲을 배경으로 펼쳐지는 따뜻한 우정과 성장의 이야기.',
  ),
  Movie(
    id: 'night',
    title: '밤의 그림자',
    year: 2024,
    genres: ['스릴러', '미스터리'],
    minutes: 116,
    rating: 3.8,
    image: 'assets/images/posters/poster_night_shadows.jpg',
    synopsis: '비 내리는 도시, 사라진 사람들의 흔적을 쫓는 한 형사. 아무도 말하지 않는 진실에 가까워질수록 도시의 그림자는 짙어집니다.\n\n단 한 번의 선택이 모든 것을 바꾸는 밤이 시작됩니다.',
  ),
  Movie(
    id: 'afternoon',
    title: '네 번째 오후',
    year: 2023,
    genres: ['드라마', '로맨스'],
    minutes: 108,
    rating: 4.3,
    image: 'assets/images/posters/poster_fourth_afternoon.jpg',
    synopsis: '같은 카페에서 우연히 마주친 두 사람. 네 번의 오후가 지나며 평범했던 일상에 작은 변화가 찾아옵니다.\n\n스쳐 지나가는 순간 속에서 발견하는 사랑과 삶의 이야기.',
  ),
  Movie(
    id: 'abyss',
    title: '심연의 방랑자',
    year: 2024,
    genres: ['SF', '액션'],
    minutes: 132,
    rating: 4.1,
    image: 'assets/images/posters/poster_abyss_walker.jpg',
    synopsis: '빛이 닿지 않는 심연을 탐험하는 대원들. 마지막 구조 신호를 따라 내려간 곳에서 상상하지 못한 세계를 발견합니다.\n\n서로를 믿고 나아가야만 살아 돌아올 수 있는 여정이 펼쳐집니다.',
  ),
];

Movie? movieById(String id) {
  for (final movie in movies) {
    if (movie.id == id) return movie;
  }
  return null;
}

// 화면을 이동해도 사용자가 작성한 정보는 앱 실행 중 유지합니다.
class MovieLogStore extends ChangeNotifier {
  final Set<String> favorites = {};
  final Map<String, int> ratings = {};
  String nickname = '무비러버';
  String bio = '매주 주말엔 영화관으로 출근하는 프로 관람객. 좋은 영화를 보고 기록하는 것을 좋아합니다.';

  void toggleFavorite(String id) {
    if (!favorites.remove(id)) favorites.add(id);
    notifyListeners();
  }

  void rate(String id, int rating) {
    if (rating == 0) {
      ratings.remove(id);
    } else {
      ratings[id] = rating;
    }
    notifyListeners();
  }

  void updateProfile(String name, String introduction) {
    nickname = name;
    bio = introduction;
    notifyListeners();
  }
}
