import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/screens/sign_up_screen.dart';
import 'package:movielog/theme/app_theme.dart';

void main() {
  Future<void> openScreen(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const SignUpScreen()),
    );
    await tester.pumpAndSettle();
  }

  Finder field(int index) => find.byType(TextFormField).at(index);

  ElevatedButton submitButton(WidgetTester tester) =>
      tester.widget<ElevatedButton>(find.byType(ElevatedButton));

  testWidgets('입력 전에는 오류가 없고 약관과 가입 버튼이 비활성 상태다', (tester) async {
    await openScreen(tester);

    expect(find.byType(TextFormField), findsNWidgets(3));
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
    expect(submitButton(tester).onPressed, isNull);
    expect(find.text('닉네임을 입력해주세요.'), findsNothing);
    expect(find.text('이메일을 입력해주세요.'), findsNothing);
    expect(find.text('비밀번호를 입력해주세요.'), findsNothing);
  });

  testWidgets('잘못된 값에는 오류를 표시하고 모두 지우면 오류와 아이콘을 제거한다', (tester) async {
    await openScreen(tester);
    await tester.enterText(field(0), 'a');
    await tester.enterText(field(1), 'test@');
    await tester.enterText(field(2), '123');
    await tester.pumpAndSettle();

    expect(find.text('닉네임은 2자 이상이어야 합니다.'), findsOneWidget);
    expect(find.text('올바른 이메일 형식이 아닙니다.'), findsOneWidget);
    expect(find.text('비밀번호는 8자 이상이어야 합니다.'), findsOneWidget);
    final errorMessages = [
      '닉네임은 2자 이상이어야 합니다.',
      '올바른 이메일 형식이 아닙니다.',
      '비밀번호는 8자 이상이어야 합니다.',
    ];
    for (var index = 0; index < 3; index++) {
      expect(
        tester.getTopLeft(find.text(errorMessages[index])).dx,
        tester.getTopLeft(field(index)).dx,
      );
    }
    expect(submitButton(tester).onPressed, isNull);
    for (var index = 0; index < 3; index++) {
      final decoration = tester
          .widget<TextField>(find.byType(TextField).at(index))
          .decoration!;
      expect(decoration.fillColor, const Color(0xFFFFDAD6));
      expect(decoration.suffixIcon, isNotNull);
    }

    for (var index = 0; index < 3; index++) {
      await tester.enterText(field(index), '');
    }
    await tester.pumpAndSettle();
    expect(find.text('닉네임을 입력해주세요.'), findsNothing);
    expect(find.text('이메일을 입력해주세요.'), findsNothing);
    expect(find.text('비밀번호를 입력해주세요.'), findsNothing);
    expect(find.text('닉네임은 2자 이상이어야 합니다.'), findsNothing);
    expect(find.text('올바른 이메일 형식이 아닙니다.'), findsNothing);
    expect(find.text('비밀번호는 8자 이상이어야 합니다.'), findsNothing);
    expect(submitButton(tester).onPressed, isNull);
    for (var index = 0; index < 3; index++) {
      final decoration = tester
          .widget<TextField>(find.byType(TextField).at(index))
          .decoration!;
      expect(
        decoration.fillColor,
        AppTheme.light.colorScheme.surfaceContainerLow,
      );
      expect(decoration.suffixIcon, isNull);
      expect(decoration.errorText, isNull);
    }
  });

  testWidgets('모든 값과 약관이 유효해야 제출할 수 있고 수정하면 다시 비활성화된다', (tester) async {
    await openScreen(tester);
    await tester.enterText(field(0), '무비러버');
    await tester.enterText(field(1), 'movie@example.com');
    await tester.enterText(field(2), 'password123');
    await tester.pumpAndSettle();
    expect(submitButton(tester).onPressed, isNull);

    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(submitButton(tester).onPressed, isNotNull);

    await tester.enterText(field(1), 'invalid');
    await tester.pumpAndSettle();
    expect(submitButton(tester).onPressed, isNull);
    expect(find.text('올바른 이메일 형식이 아닙니다.'), findsOneWidget);
  });

  testWidgets('다음과 완료로 포커스를 이동하고 작은 화면의 키보드에서도 스크롤된다', (tester) async {
    await openScreen(tester);
    await tester.tap(field(0));
    await tester.enterText(field(0), '무비러버');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<EditableText>(find.byType(EditableText).at(1))
          .focusNode
          .hasFocus,
      isTrue,
    );

    await tester.enterText(field(1), 'movie@example.com');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<EditableText>(find.byType(EditableText).at(2))
          .focusNode
          .hasFocus,
      isTrue,
    );
    expect(
      tester.widget<EditableText>(find.byType(EditableText).at(2)).obscureText,
      isTrue,
    );

    tester.view.physicalSize = const Size(320, 568);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(ElevatedButton).hitTestable(), findsOneWidget);

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<EditableText>(find.byType(EditableText).at(2))
          .focusNode
          .hasFocus,
      isFalse,
    );

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
