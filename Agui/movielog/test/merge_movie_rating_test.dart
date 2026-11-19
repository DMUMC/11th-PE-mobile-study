import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/rating_request.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/movie/movie_detail_loader.dart';
import 'package:movielog/view_models/learning_member_session.dart';
import 'package:provider/provider.dart';

class FakeRatings extends RatingApiService {
  FakeRatings() : super(Dio());
  int? member;
  CreateRatingRequest? request;
  @override
  Future<void> createRating({required int memberId, required CreateRatingRequest request}) async {
    member = memberId;
    this.request = request;
  }
}

class FakeMovies extends TmdbMovieService {
  FakeMovies() : super(Dio());
  @override
  Future<TmdbMovieDto> fetchMovieDetail(int movieId) async => TmdbMovieDto(id: movieId, title: '테스트 영화', posterPath: null);
}

void main() {
  testWidgets('영화 상세에서 회원과 TMDB ID를 평점 등록에 전달한다', (tester) async {
    final ratings = FakeRatings();
    final session = LearningMemberSession()..memberId = 7;
    await tester.pumpWidget(MultiProvider(
      providers: [
        Provider<RatingApiService>.value(value: ratings),
        Provider<TmdbMovieService>(create: (_) => FakeMovies()),
        ChangeNotifierProvider<LearningMemberSession>.value(value: session),
      ],
      child: const MaterialApp(home: MovieDetailLoader(movieId: 550)),
    ));
    await tester.pumpAndSettle();
    expect(find.text('테스트 영화'), findsOneWidget);
    await tester.tap(find.text('평점 남기기'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.star_border).last);
    await tester.pump();
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(ratings.member, 7);
    expect(ratings.request?.movieId, 550);
    expect(ratings.request?.score, 5);
  });
}
