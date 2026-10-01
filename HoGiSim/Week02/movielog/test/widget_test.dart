import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/main.dart';

void main() {
  testWidgets('잘못된 값에는 한국어 오류 메시지를 표시한다', (tester) async {
    await tester.pumpWidget(const MovieLogApp());

    await tester.enterText(find.byKey(const Key('nicknameField')), 'a');
    await tester.enterText(find.byKey(const Key('emailField')), 'test@');
    await tester.enterText(find.byKey(const Key('passwordField')), '123');
    await tester.pump();

    expect(find.text('닉네임은 2자 이상이어야 합니다.'), findsOneWidget);
    expect(find.text('올바른 이메일 형식이 아닙니다.'), findsOneWidget);
    expect(find.text('비밀번호는 8자 이상이어야 합니다.'), findsOneWidget);
  });

  testWidgets('모든 조건을 만족할 때만 가입 버튼이 활성화된다', (tester) async {
    await tester.pumpWidget(const MovieLogApp());

    ElevatedButton button() =>
        tester.widget(find.widgetWithText(ElevatedButton, '가입하기'));

    expect(button().onPressed, isNull);
    await tester.enterText(find.byKey(const Key('nicknameField')), '무비러버');
    await tester.enterText(
      find.byKey(const Key('emailField')),
      'movie@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('passwordField')),
      'password123',
    );
    await tester.ensureVisible(find.byKey(const Key('termsCheckbox')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('termsCheckbox')));
    await tester.pump();

    expect(button().onPressed, isNotNull);
  });

  testWidgets('700px 이상의 화면에서 Form 너비를 560px로 제한한다', (tester) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MovieLogApp());

    expect(
      tester.getSize(find.byKey(const Key('signUpFormContent'))).width,
      560,
    );
    expect(find.text('MovieLog에 오신 것을 환영합니다!'), findsOneWidget);
  });
}
