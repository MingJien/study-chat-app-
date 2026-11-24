import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_chat_app/features/realtime_chat/domain/chat.dart';
import 'package:study_chat_app/features/realtime_chat/presentation/chat_screen.dart';

void main() {
  testWidgets('T24 · bong bóng tin dài vừa màn hình hẹp, chạm tên mở hồ sơ', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var opened = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MessageBubble(
              message: ChatMessage('m', 'u', 'a' * 500, 100),
              own: false,
              showAuthor: true,
              profile: null,
              fallback: 'Minh',
              onProfile: () => opened = true,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Minh'));
    expect(opened, true);
    expect(tester.takeException(), isNull);
  });
}
