import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/movie/widgets/movie_rating_dialog.dart';
import 'package:movielog/movie/widgets/movie_rating_input.dart';
import 'package:movielog/view_models/movie_detail_view_model.dart';

Future<void> _open(
  WidgetTester tester, {
  bool show = true,
  required Future<void> Function(int, String?, bool) submit,
  void Function(Object?)? closed,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              final result = await showDialog<Object>(
                context: context,
                barrierDismissible: false,
                builder: (_) => MovieRatingDialog(
                  initialScore: 4,
                  showAddToFavorite: show,
                  onSubmit: submit,
                ),
              );
              closed?.call(result);
            },
            child: const Text('열기'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('열기'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('hidden checkbox always submits false for rating edits', (
    tester,
  ) async {
    bool? added;
    await _open(tester, show: false, submit: (_, _, add) async => added = add);
    expect(find.byType(CheckboxListTile), findsNothing);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(added, isFalse);
  });

  testWidgets('input errors preserve score, comment and checkbox for retry', (
    tester,
  ) async {
    var attempts = 0;
    final inputs = <(int, String?, bool)>[];
    await _open(
      tester,
      submit: (score, comment, add) async {
        inputs.add((score, comment, add));
        if (++attempts == 1) {
          throw const RatingSubmissionException('입력값을 확인해 주세요.');
        }
      },
    );
    await tester.enterText(find.byType(TextField), '내 코멘트');
    await tester.tap(find.byType(CheckboxListTile));
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.byType(MovieRatingDialog), findsOneWidget);
    expect(find.text('입력값을 확인해 주세요.'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '내 코멘트',
    );
    expect(
      tester.widget<MovieRatingInput>(find.byType(MovieRatingInput)).rating,
      4,
    );
    expect(
      tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
      isTrue,
    );
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(inputs, [(4, '내 코멘트', true), (4, '내 코멘트', true)]);
    expect(find.byType(MovieRatingDialog), findsNothing);
  });

  testWidgets('fatal conflict closes dialog and returns its message', (
    tester,
  ) async {
    Object? result;
    await _open(
      tester,
      submit: (_, _, _) async => throw const RatingSubmissionException(
        '이미 즐겨찾기한 영화입니다.',
        closeDialog: true,
      ),
      closed: (value) => result = value,
    );
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.byType(MovieRatingDialog), findsNothing);
    expect(
      result,
      isA<RatingSubmissionException>().having(
        (e) => e.message,
        'message',
        '이미 즐겨찾기한 영화입니다.',
      ),
    );
  });

  testWidgets('pending save disables checkbox and prevents back dismissal', (
    tester,
  ) async {
    final gate = Completer<void>();
    var requests = 0;
    await _open(
      tester,
      submit: (_, _, _) {
        requests++;
        return gate.future;
      },
    );
    await tester.tap(find.text('확인'));
    await tester.pump();
    expect(
      tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).onChanged,
      isNull,
    );
    final context = tester.element(find.byType(MovieRatingDialog));
    await Navigator.of(context).maybePop();
    await tester.pump();
    expect(find.byType(MovieRatingDialog), findsOneWidget);
    expect(requests, 1);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byType(MovieRatingDialog), findsNothing);
  });
}
