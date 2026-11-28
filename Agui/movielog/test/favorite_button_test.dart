import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:movielog/core/session/session_guard.dart';
import 'package:movielog/data/models/favorite_check_dto.dart';
import 'package:movielog/data/models/favorite_response_dto.dart';
import 'package:movielog/data/services/favorite_api_service.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:movielog/view_models/favorite_detail_view_model.dart';
import 'package:movielog/widgets/favorite_button.dart';

class _Favorites extends FavoriteApiService {
  _Favorites() : super(Dio());
  late final saving = Completer<FavoriteResponseDto>();
  bool failCheck = false;
  @override
  Future<FavoriteCheckDto> checkFavorite({required int movieId}) async {
    if (failCheck) throw StateError('check failed');
    return FavoriteCheckDto(movieId: movieId, isFavorite: false);
  }

  @override
  Future<FavoriteResponseDto> addFavorite({required int movieId}) =>
      saving.future;
}

void main() {
  late _Favorites api;
  late SessionGuard guard;
  late FavoriteDetailViewModel vm;

  setUp(() {
    api = _Favorites();
    guard = SessionGuard()..startSession('a@example.com');
    vm = FavoriteDetailViewModel(
      movieId: 550,
      favoriteApi: api,
      sessionGuard: guard,
      accountId: 'a@example.com',
    );
  });
  tearDown(() => vm.dispose());

  Future<void> showButton(WidgetTester tester) => tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: vm,
      child: MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: Row(
            children: [
              Expanded(child: Text('영화 제목과 상세 정보')),
              FavoriteButton(),
            ],
          ),
        ),
      ),
    ),
  );

  testWidgets(
    'only the bookmark shows a spinner, then success icon and Snackbar',
    (tester) async {
      await vm.load();
      await showButton(tester);
      await tester.tap(find.byTooltip('즐겨찾기 등록'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('영화 제목과 상세 정보'), findsOneWidget);
      expect(find.byIcon(Icons.bookmark), findsNothing);
      api.saving.complete(
        FavoriteResponseDto(
          favoriteId: 3,
          movieId: 550,
          createdAt: DateTime(2026),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byIcon(Icons.bookmark), findsOneWidget);
      expect(find.text('즐겨찾기에 추가했습니다.'), findsOneWidget);
    },
  );

  testWidgets('failed save keeps the previous icon and reports failure', (
    tester,
  ) async {
    await vm.load();
    await showButton(tester);
    await tester.tap(find.byTooltip('즐겨찾기 등록'));
    await tester.pump();
    api.saving.completeError(
      DioException(
        requestOptions: RequestOptions(path: '/v8/favorites'),
        type: DioExceptionType.connectionError,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
    expect(find.text('즐겨찾기 등록에 실패했습니다.'), findsOneWidget);
  });

  testWidgets(
    'initial failure disables the bookmark and offers a status retry',
    (tester) async {
      api.failCheck = true;
      await vm.load();
      await showButton(tester);
      expect(
        tester
            .widget<IconButton>(
              find.widgetWithIcon(IconButton, Icons.bookmark_border),
            )
            .onPressed,
        isNull,
      );
      expect(find.text('조회 실패'), findsOneWidget);
      api.failCheck = false;
      await tester.tap(find.byTooltip('즐겨찾기 여부 다시 확인'));
      await tester.pumpAndSettle();
      expect(find.text('조회 실패'), findsNothing);
      expect(
        tester
            .widget<IconButton>(
              find.widgetWithIcon(IconButton, Icons.bookmark_border),
            )
            .onPressed,
        isNotNull,
      );
    },
  );

  testWidgets('an old account cannot show feedback after the session changes', (
    tester,
  ) async {
    await vm.load();
    await showButton(tester);
    await tester.tap(find.byTooltip('즐겨찾기 등록'));
    await tester.pump();
    guard.invalidate();
    guard.startSession('b@example.com');
    api.saving.complete(
      FavoriteResponseDto(
        favoriteId: 3,
        movieId: 550,
        createdAt: DateTime(2026),
      ),
    );
    await tester.pump();
    expect(find.byType(SnackBar), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
