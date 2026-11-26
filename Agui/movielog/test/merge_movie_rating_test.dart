import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/rating_request.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/movie/movie_detail_loader.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/data/services/auth_api_service.dart';
import 'package:movielog/data/services/member_api_service.dart';
import 'package:movielog/core/storage/token_storage.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:provider/provider.dart';
import 'package:movielog/core/session/session_guard.dart';
import 'package:movielog/data/models/member_info.dart';
import 'package:movielog/data/models/favorite_check_dto.dart';
import 'package:movielog/data/services/favorite_api_service.dart';

class FakeFavorites extends FavoriteApiService {
  FakeFavorites() : super(Dio());
  @override
  Future<FavoriteCheckDto> checkFavorite({required int movieId}) async =>
      FavoriteCheckDto(movieId: movieId, isFavorite: false);
}

class FakeRatings extends RatingApiService {
  FakeRatings() : super(Dio(), Dio());
  CreateRatingRequest? request;
  @override
  Future<RatingDto> createRating(CreateRatingRequest request) async {
    this.request = request;
    return RatingDto(
      ratingId: 1,
      movieId: request.movieId,
      score: request.score,
      comment: request.comment,
      createdAt: DateTime(2026),
    );
  }
}

class MemoryTokenStorage implements TokenStorage {
  @override
  Future<void> deleteAccessToken() async {}
  @override
  Future<String?> readAccessToken() async => null;
  @override
  Future<void> saveAccessToken(String token) async {}
}

class FakeMovies extends TmdbMovieService {
  FakeMovies() : super(Dio());
  @override
  Future<TmdbMovieDto> fetchMovieDetail(int movieId) async =>
      TmdbMovieDto(id: movieId, title: '테스트 영화', posterPath: null);
}

void main() {
  testWidgets('영화 상세에서 TMDB ID를 등록하고 결과를 현재 세션에 저장한다', (tester) async {
    final ratings = FakeRatings();
    final session =
        AuthViewModel(
            AuthApiService(Dio()),
            MemberApiService(Dio()),
            MemoryTokenStorage(),
          )
          ..status = AuthStatus.signedIn
          ..member = MemberInfo(
            email: 'test@example.com',
            nickname: 'tester',
            createdAt: DateTime(2026),
          );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<RatingApiService>.value(value: ratings),
          Provider<TmdbMovieService>(create: (_) => FakeMovies()),
          ChangeNotifierProvider<AuthViewModel>.value(value: session),
          Provider<SessionGuard>(
            create: (_) => SessionGuard()..startSession('test@example.com'),
          ),
          Provider<FavoriteApiService>(create: (_) => FakeFavorites()),
        ],
        child: const MaterialApp(home: MovieDetailLoader(movieId: 550)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('테스트 영화'), findsOneWidget);
    await tester.tap(find.text('평점 남기기'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.star_border).last);
    await tester.pump();
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(session.sessionRatings.single.rating.movieId, 550);
    expect(ratings.request?.movieId, 550);
    expect(ratings.request?.score, 5);
  });
}
