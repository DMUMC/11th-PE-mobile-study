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
import 'package:movielog/data/services/movie_record_api_service.dart';
import 'package:movielog/data/models/movie_record_request.dart';
import 'package:movielog/data/models/movie_record_response.dart';
import 'package:movielog/data/models/favorite_response_dto.dart';

class FakeRecords extends MovieRecordApiService {
  FakeRecords(this.favorites) : super(Dio());
  final FakeFavorites favorites;
  CreateMovieRecordRequest? request;
  @override
  Future<MovieRecordResponseDto> createMovieRecord(
    CreateMovieRecordRequest request,
  ) async {
    this.request = request;
    favorites.favorite = request.addToFavorites;
    return MovieRecordResponseDto(
      rating: RatingDto(
        ratingId: 1,
        movieId: request.movieId,
        score: request.score,
        comment: request.comment,
        createdAt: DateTime(2026),
      ),
      favorite: request.addToFavorites
          ? FavoriteResponseDto(
              favoriteId: 1,
              movieId: request.movieId,
              createdAt: DateTime(2026),
            )
          : null,
    );
  }
}

class FakeFavorites extends FavoriteApiService {
  FakeFavorites() : super(Dio());
  bool favorite = false;
  int checks = 0;
  @override
  Future<FavoriteCheckDto> checkFavorite({required int movieId}) async {
    checks++;
    return FavoriteCheckDto(movieId: movieId, isFavorite: favorite);
  }
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
  for (final alreadyFavorite in [false, true]) {
    testWidgets('상세 저장은 즐겨찾기 상태 $alreadyFavorite에 따라 API를 선택하고 북마크를 다시 조회한다', (
      tester,
    ) async {
      final ratings = FakeRatings();
      final favorites = FakeFavorites()..favorite = alreadyFavorite;
      final records = FakeRecords(favorites);
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
            Provider<MovieRecordApiService>.value(value: records),
            Provider<TmdbMovieService>(create: (_) => FakeMovies()),
            ChangeNotifierProvider<AuthViewModel>.value(value: session),
            ChangeNotifierProvider<SessionGuard>(
              create: (_) => SessionGuard()..startSession('test@example.com'),
            ),
            Provider<FavoriteApiService>.value(value: favorites),
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
      if (!alreadyFavorite) {
        expect(find.byType(CheckboxListTile), findsOneWidget);
        await tester.tap(find.byType(CheckboxListTile));
        await tester.pump();
      } else {
        expect(find.byType(CheckboxListTile), findsNothing);
      }
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();
      expect(session.sessionRatings.single.rating.movieId, 550);
      if (alreadyFavorite) {
        expect(records.request, isNull);
        expect(ratings.request?.movieId, 550);
        expect(ratings.request?.score, 5);
      } else {
        expect(ratings.request, isNull);
        expect(records.request?.movieId, 550);
        expect(records.request?.score, 5);
        expect(records.request?.addToFavorites, isTrue);
      }
      expect(favorites.checks, 2);
      expect(find.byIcon(Icons.bookmark), findsOneWidget);
      expect(find.text('평점을 저장했습니다.'), findsOneWidget);
    });
  }
}
