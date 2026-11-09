import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../data/models/rating_dto.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/movielog_member_service.dart';
import '../data/services/tmdb_movie_service.dart';

enum MyRatingsLoadStatus { idle, loading, success, empty, error }

/// 평점 한 건 + 그 평점의 movieId(TMDB id)로 조회한 영화 정보
class MyRatingItem {
  const MyRatingItem({required this.rating, this.movie});

  final RatingDto rating;

  /// TMDB 조회에 실패하면 null (평점은 그대로 보여준다)
  final TmdbMovieDto? movie;
}

class MyPageViewModel extends ChangeNotifier {
  MyPageViewModel({
    required MovieLogMemberService memberService,
    required TmdbMovieService tmdbService,
    required this.memberId,
  }) : _memberService = memberService,
       _tmdbService = tmdbService;

  final MovieLogMemberService _memberService;
  final TmdbMovieService _tmdbService;

  /// 조회할 회원 id (로그인 전까지는 시드 데이터의 회원 id를 사용)
  final int memberId;

  List<MyRatingItem> ratings = const [];
  MyRatingsLoadStatus status = MyRatingsLoadStatus.idle;
  String? message;

  bool _disposed = false;

  Future<void> loadRatings() async {
    if (status == MyRatingsLoadStatus.loading) return;

    status = MyRatingsLoadStatus.loading;
    message = null;
    notifyListeners();

    try {
      // 1) MovieLog 서버: 이 회원이 남긴 평점 (최신순)
      final fetched = await _memberService.fetchMemberRatings(memberId);
      // 2) TMDB: 평점의 movieId로 영화 제목/포스터를 함께 조회 (병렬)
      final items = await Future.wait(fetched.map(_attachMovie));
      if (_disposed) return;

      ratings = items;
      status = items.isEmpty
          ? MyRatingsLoadStatus.empty
          : MyRatingsLoadStatus.success;
    } on DioException catch (error) {
      if (_disposed) return;
      status = MyRatingsLoadStatus.error;
      message = switch (error.response?.statusCode) {
        404 => serverMessageOf(error) ?? '존재하지 않는 유저예요.',
        _ when isConnectionProblem(error) =>
          'MovieLog 서버에 연결할 수 없어요.\n서버가 켜져 있는지, 주소가 맞는지 확인해 주세요.',
        _ => '평점을 불러오지 못했어요.',
      };
    } catch (error) {
      if (_disposed) return;
      debugPrint('[MyPage] 응답 변환 실패: $error');
      status = MyRatingsLoadStatus.error;
      message = '평점 정보를 읽지 못했어요.';
    }

    notifyListeners();
  }

  Future<MyRatingItem> _attachMovie(RatingDto rating) async {
    try {
      final movie = await _tmdbService.fetchMovieDetail(rating.movieId);
      return MyRatingItem(rating: rating, movie: movie);
    } catch (error) {
      // 영화 정보가 없어도 평점 목록은 보여줄 수 있으므로 실패를 삼킨다.
      debugPrint('[MyPage] TMDB 영화 조회 실패 movieId=${rating.movieId}: $error');
      return MyRatingItem(rating: rating);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
