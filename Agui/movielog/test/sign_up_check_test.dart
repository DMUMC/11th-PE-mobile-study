import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/services/member_check_service.dart';
import 'package:movielog/main.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:movielog/widgets/movielog_button.dart';

void main() {
  testWidgets(
    'signup connects loading, server errors, form validity, and input invalidation',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final service = _ControlledService();
      AppRouter.router.go('/register');
      await tester.pumpWidget(MovieLogApp(memberCheckService: service));
      await tester.pumpAndSettle();
      expect(find.text('닉네임 중복 확인을 해주세요.'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      final check = find.byKey(const Key('nickname-check'));
      await tester.tap(check);
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final button = tester.widget<ElevatedButton>(
        find.descendant(of: check, matching: find.byType(ElevatedButton)),
      );
      expect(button.onPressed, isNull);
      expect(
        button.style!.backgroundColor!.resolve({WidgetState.disabled}),
        AppTheme.light.colorScheme.outline,
      );

      service.result.complete(false);
      await tester.pumpAndSettle();
      expect(find.text('이미 사용 중인 닉네임입니다.'), findsOneWidget);
      expect(tester.state<FormState>(find.byType(Form)).validate(), isFalse);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '새닉네임');
      await tester.pumpAndSettle();
      expect(find.text('이미 사용 중인 닉네임입니다.'), findsNothing);
      expect(find.text('닉네임 중복 확인을 해주세요.'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, '영화광');
      await tester.pumpAndSettle();
      expect(find.text('이미 사용 중인 닉네임입니다.'), findsOneWidget);
      expect(service.calls, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'button width supports content, full width, and an explicit size',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: MovieLogButton(
                        key: const Key('content'),
                        label: '확인',
                        onPressed: () {},
                      ),
                    ),
                    MovieLogButton(
                      key: const Key('full'),
                      label: '가입하기',
                      width: double.infinity,
                      onPressed: () {},
                    ),
                    MovieLogButton(
                      key: const Key('fixed'),
                      label: '확인',
                      width: 96,
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      expect(
        tester.getSize(find.byKey(const Key('content'))).width,
        lessThan(96),
      );
      expect(tester.getSize(find.byKey(const Key('full'))).width, 300);
      expect(tester.getSize(find.byKey(const Key('fixed'))).width, 96);
      expect(tester.takeException(), isNull);
    },
  );
}

class _ControlledService extends MemberCheckService {
  _ControlledService() : super(Dio());
  final result = Completer<bool>();
  int calls = 0;

  @override
  Future<bool> checkNickname(String nickname) {
    calls++;
    return result.future;
  }
}
