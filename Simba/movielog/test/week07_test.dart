import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/common_response.dart';
import 'package:movielog/data/models/create_member_request.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/models/rating_request.dart';
import 'package:movielog/data/models/sign_up_models.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/sign_up_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/view_models/movie_detail_view_model.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';
import 'package:movielog/view_models/sign_up_view_model.dart';
import 'package:movielog/widgets/rating_dialog.dart';

/// v6 공통 오류 응답을 가진 DioException
DioException apiError(int status, String code, String message) {
  final options = RequestOptions(path: '/');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response(
      requestOptions: options,
      statusCode: status,
      data: {
        'isSuccess': false,
        'code': code,
        'message': message,
        'result': null,
      },
    ),
  );
}

DioException networkError() => DioException(
  requestOptions: RequestOptions(path: '/'),
  type: DioExceptionType.connectionError,
);

class FakeSignUpService implements SignUpService {
  Future<CommonResponse<SignUpResult>> Function()? onSignUp;
  int signUpCalls = 0;

  @override
  Future<CommonResponse<SignUpResult>> signUp(CreateMemberRequest request) {
    signUpCalls++;
    return onSignUp!();
  }

  @override
  Future<bool> checkNickname(String nickname) async => true;

  @override
  Future<bool> checkEmail(String email) async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeRatingApiService implements RatingApiService {
  List<RatingDto> serverRatings = [];
  Object? fetchError;
  Object? Function(int ratingId)? deleteError;
  Object? updateError;
  final updates = <Map<String, dynamic>>[];
  final created = <Map<String, dynamic>>[];
  Object? createError;

  @override
  Future<List<RatingDto>> fetchMyRatings(int memberId) async {
    if (fetchError != null) throw fetchError!;
    return List.of(serverRatings);
  }

  @override
  Future<void> createRating({
    required int memberId,
    required CreateRatingRequest request,
  }) async {
    if (createError != null) throw createError!;
    created.add({'memberId': memberId, ...request.toJson()});
  }

  @override
  Future<void> updateRating({
    required int memberId,
    required int ratingId,
    required UpdateRatingRequest request,
  }) async {
    if (updateError != null) throw updateError!;
    updates.add({'ratingId': ratingId, ...request.toJson()});
  }

  @override
  Future<void> deleteRating({
    required int memberId,
    required int ratingId,
  }) async {
    final error = deleteError?.call(ratingId);
    if (error != null) throw error;
    serverRatings.removeWhere((r) => r.ratingId == ratingId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeTmdb implements TmdbMovieService {
  @override
  Future<TmdbMovieDto?> findMovieById(int movieId) async =>
      TmdbMovieDto.fromJson({'id': movieId, 'title': '영화 $movieId'});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

RatingDto rating(int id, {int movieId = 550, String? comment}) =>
    RatingDto.fromJson({
      'ratingId': id,
      'movieId': movieId,
      'score': 4,
      'comment': comment,
      'createdAt': '2026-11-15T10:00:00.000Z',
    });

void main() {
  group('요청·응답 Model', () {
    test('CommonResponse가 result payload를 제네릭으로 파싱한다', () {
      final response = CommonResponse<SignUpResult>.fromJson({
        'isSuccess': true,
        'code': 'COMMON201',
        'message': '회원가입에 성공했습니다.',
        'result': {'memberId': 7, 'email': 'a@b.com', 'nickname': '심바'},
      }, (value) => SignUpResult.fromJson(value as Map<String, dynamic>));
      expect(response.result?.memberId, 7);
      expect(response.code, 'COMMON201');
    });

    test('CreateMemberRequest는 password를 trim하지 않는다', () {
      final json = const CreateMemberRequest(
        email: ' a@b.com ',
        password: ' Pw1! ',
        nickname: ' 심바 ',
      ).toJson();
      expect(json, {
        'email': 'a@b.com',
        'password': ' Pw1! ',
        'nickname': '심바',
      });
    });

    test('등록 요청은 빈 comment를 생략하고, 수정 요청은 comment를 항상 보낸다', () {
      expect(
        const CreateRatingRequest(
          movieId: 550,
          score: 5,
          comment: '  ',
        ).toJson(),
        {'movieId': 550, 'score': 5},
      );
      expect(const UpdateRatingRequest(score: 3, comment: null).toJson(), {
        'score': 3,
        'comment': null,
      });
      expect(const UpdateRatingRequest(score: 3, comment: ' 좋아요 ').toJson(), {
        'score': 3,
        'comment': '좋아요',
      });
    });

    test('validateServerScore는 반 점과 범위 밖 값을 막는다', () {
      expect(validateServerScore(4.0), 4);
      expect(() => validateServerScore(3.5), throwsArgumentError);
      expect(() => validateServerScore(0), throwsArgumentError);
      expect(() => validateServerScore(6), throwsArgumentError);
    });

    test('같은 COMMON404라도 서버 message를 그대로 쓰고, 403·404만 재조회한다', () {
      final userMissing = apiError(404, 'COMMON404', '존재하지 않는 유저입니다.');
      final conflict = apiError(409, 'COMMON409', '이미 이 영화에 평점을 남기셨습니다.');
      expect(writeErrorMessage(userMissing), '존재하지 않는 유저입니다.');
      expect(shouldRefreshAfterRatingError(userMissing), isTrue);
      expect(shouldRefreshAfterRatingError(conflict), isFalse);
      expect(writeErrorMessage(networkError()), contains('요청에 실패했습니다'));
    });
  });

  group('SignUpViewModel.submit', () {
    late FakeSignUpService service;
    late SignUpViewModel vm;
    const request = CreateMemberRequest(
      email: 'a@b.com',
      password: 'Umc1234!',
      nickname: '심바',
    );

    setUp(() {
      service = FakeSignUpService();
      vm = SignUpViewModel(service);
    });

    test('성공하면 result.memberId를 저장한다', () async {
      service.onSignUp = () async => const CommonResponse(
        isSuccess: true,
        code: 'COMMON201',
        message: '회원가입에 성공했습니다.',
        result: SignUpResult(memberId: 42, email: 'a@b.com', nickname: '심바'),
      );
      await vm.submit(request);
      expect(vm.submitStatus, SubmitStatus.success);
      expect(vm.createdMemberId, 42);
    });

    test('result가 없으면 가입 완료로 표시하지 않는다', () async {
      service.onSignUp = () async => const CommonResponse<SignUpResult>(
        isSuccess: true,
        code: 'COMMON201',
        message: 'ok',
      );
      await vm.submit(request);
      expect(vm.submitStatus, SubmitStatus.error);
      expect(vm.createdMemberId, isNull);
    });

    test('비밀번호 400은 비밀번호 칸, 409는 Snackbar + 해당 칸 중복 상태', () async {
      service.onSignUp = () async => throw apiError(
        400,
        'COMMON400',
        '비밀번호는 대문자/소문자/숫자/특수문자를 포함한 8자 이상이어야 합니다.',
      );
      await vm.submit(request);
      expect(vm.passwordErrorText, contains('비밀번호'));
      expect(vm.snackbarMessage, isNull);

      vm.onEmailChanged('a@b.com');
      service.onSignUp = () async =>
          throw apiError(409, 'COMMON409', '이미 사용 중인 이메일입니다.');
      await vm.submit(request);
      expect(vm.passwordErrorText, isNull);
      expect(vm.snackbarMessage, '이미 사용 중인 이메일입니다.');
      expect(vm.emailCheckStatus, CheckStatus.duplicated);
    });

    test('제출 중에는 두 번째 요청을 보내지 않는다', () async {
      service.onSignUp = () => Future.delayed(
        const Duration(milliseconds: 10),
        () => const CommonResponse(
          isSuccess: true,
          code: 'COMMON201',
          message: 'ok',
          result: SignUpResult(memberId: 1, email: 'a', nickname: 'b'),
        ),
      );
      final first = vm.submit(request);
      await vm.submit(request);
      await first;
      expect(service.signUpCalls, 1);
    });
  });

  group('MovieDetailViewModel.createRating', () {
    final movie = TmdbMovieDto.fromJson({'id': 550, 'title': '파이트 클럽'});

    test('회원가입 전이면 요청하지 않고 안내한다', () async {
      final api = FakeRatingApiService();
      final vm = MovieDetailViewModel(api, null, movie);
      await vm.createRating(score: 5);
      expect(vm.submitStatus, SubmitStatus.error);
      expect(api.created, isEmpty);
    });

    test('TMDB id를 movieId로 보내고, 409는 서버 문구로 실패한다', () async {
      final api = FakeRatingApiService();
      final vm = MovieDetailViewModel(api, 9, movie);
      await vm.createRating(score: 5, comment: '최고');
      expect(vm.submitStatus, SubmitStatus.success);
      expect(api.created.single, {
        'memberId': 9,
        'movieId': 550,
        'score': 5,
        'comment': '최고',
      });

      api.createError = apiError(409, 'COMMON409', '이미 이 영화에 평점을 남기셨습니다.');
      await vm.createRating(score: 4);
      expect(vm.submitStatus, SubmitStatus.error);
      expect(vm.submitMessage, '이미 이 영화에 평점을 남기셨습니다.');
    });
  });

  group('MyRatingsViewModel 수정·삭제', () {
    late FakeRatingApiService api;
    late MyRatingsViewModel vm;

    setUp(() async {
      api = FakeRatingApiService()
        ..serverRatings = [rating(1), rating(2, movieId: 680), rating(3)];
      vm = MyRatingsViewModel(api, FakeTmdb(), 9);
      await vm.load();
    });

    test('수정은 comment를 명시적으로 보내고 성공 뒤 목록을 다시 읽는다', () async {
      api.serverRatings = [rating(1, comment: '바뀜')];
      await vm.updateRating(ratingId: 1, score: 2, comment: null);
      expect(api.updates.single, {'ratingId': 1, 'score': 2, 'comment': null});
      expect(vm.ratings.single.rating.comment, '바뀜');
    });

    test('저장 성공 뒤 GET만 실패하면 저장 실패로 던지지 않고 경고만 남긴다', () async {
      api.fetchError = networkError();
      await vm.updateRating(ratingId: 1, score: 2); // 예외 없음
      expect(vm.status, MyRatingsLoadStatus.error);
      expect(vm.refreshWarning, contains('저장은 완료됐지만'));

      api.fetchError = null;
      await vm.load(); // 조회만 다시 시도
      expect(vm.status, MyRatingsLoadStatus.success);
      expect(vm.refreshWarning, isNull);
    });

    test('404 쓰기 실패는 다시 던지고 목록을 재조회한다', () async {
      api.updateError = apiError(404, 'COMMON404', '존재하지 않는 평점입니다.');
      api.serverRatings = [rating(2, movieId: 680)];
      await expectLater(
        vm.updateRating(ratingId: 1, score: 3),
        throwsA(isA<DioException>()),
      );
      expect(vm.ratings.map((e) => e.rating.ratingId), [2]);
    });

    test('마지막 항목을 삭제하면 Empty', () async {
      api.serverRatings = [rating(1)];
      await vm.load();
      await vm.deleteRating(1);
      expect(vm.status, MyRatingsLoadStatus.empty);
    });

    test('다중 삭제 일부 실패: 성공한 것만 사라지고 실패한 것은 선택 유지', () async {
      api.deleteError = (id) => id == 2 ? networkError() : null;
      vm.enterEditMode();
      vm.toggleSelection(1);
      vm.toggleSelection(2);
      final failed = await vm.deleteSelectedRatings();
      expect(failed, 1);
      expect(vm.ratings.map((e) => e.rating.ratingId), [2, 3]);
      expect(vm.selectedRatingIds, {2});
      expect(vm.isEditMode, isTrue);
      expect(vm.isDeletingSelected, isFalse);
    });

    test('다중 삭제 전부 성공하면 편집 모드를 끝낸다', () async {
      vm.enterEditMode();
      vm.toggleSelection(1);
      vm.toggleSelection(3);
      expect(await vm.deleteSelectedRatings(), 0);
      expect(vm.ratings.map((e) => e.rating.ratingId), [2]);
      expect(vm.isEditMode, isFalse);
    });
  });

  group('RatingDialog', () {
    Future<void> openDialog(
      WidgetTester tester,
      Future<void> Function(int, String?) onSubmit, {
      int initialScore = 0,
      String? initialComment,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showDialog<bool>(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => RatingDialog(
                    initialScore: initialScore,
                    initialComment: initialComment,
                    onSubmit: onSubmit,
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    ElevatedButton confirmButton(WidgetTester tester) => tester.widget(
      find.ancestor(of: find.text('확인'), matching: find.byType(ElevatedButton)),
    );

    testWidgets('별점을 고르기 전에는 확인 버튼이 비활성', (tester) async {
      await openDialog(tester, (_, _) async {});
      await tester.enterText(find.byType(TextField), '코멘트만 입력');
      await tester.pump();
      expect(confirmButton(tester).onPressed, isNull);
    });

    testWidgets('수정 Dialog는 기존 별점·코멘트로 채워진다', (tester) async {
      await openDialog(
        tester,
        (_, _) async {},
        initialScore: 3,
        initialComment: '다시 봐도 좋다',
      );
      expect(find.text('다시 봐도 좋다'), findsOneWidget);
      expect(confirmButton(tester).onPressed, isNotNull);
    });

    testWidgets('저장 실패하면 닫히지 않고 입력과 서버 문구를 보여준다', (tester) async {
      await openDialog(
        tester,
        (_, _) async =>
            throw apiError(409, 'COMMON409', '이미 이 영화에 평점을 남기셨습니다.'),
        initialScore: 4,
        initialComment: '유지되어야 함',
      );
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('이미 이 영화에 평점을 남기셨습니다.'), findsOneWidget);
      expect(find.text('유지되어야 함'), findsOneWidget);
    });

    testWidgets('취소하면 onSubmit을 부르지 않는다', (tester) async {
      var called = false;
      await openDialog(tester, (_, _) async => called = true, initialScore: 5);
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      expect(called, isFalse);
      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}
