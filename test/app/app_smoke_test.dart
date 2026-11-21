import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_chat_app/app/app.dart';

void main() {
  testWidgets('AppShell opens all five module entry points', (tester) async {
    await tester.pumpWidget(const StudyChatApp());
    expect(find.text('Không gian học tập'), findsOneWidget);

    const expectedTitles = [
      'Không gian học tập',
      'Phòng thảo luận',
      'Hội thoại',
      'Danh bạ bạn học',
      'Tài khoản và hồ sơ',
    ];

    for (var index = 0; index < expectedTitles.length; index++) {
      await tester.tap(find.byType(NavigationDestination).at(index));
      await tester.pumpAndSettle();
      expect(find.text(expectedTitles[index]), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
