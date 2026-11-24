import 'package:flutter_test/flutter_test.dart';
import 'package:study_chat_app/features/realtime_chat/domain/chat.dart';

void main() {
  test(
    'T05/T06 · ID đối xứng và không nhập nhằng khi UID chứa dấu phân cách',
    () {
      expect(directId('b', 'a'), directId('a', 'b'));
      expect(directId('a', 'b|c'), isNot(directId('a|b', 'c')));
      expect(directId('a|b', 'c'), isNot(directId('a%7Cb', 'c')));
      expect(() => directId('a', 'a'), throwsA(isA<ChatFailure>()));
    },
  );
  test('T08 · chuẩn hóa khoảng trắng và giới hạn 500', () {
    expect(validateContent('  chào\n'), 'chào');
    expect(validateContent('a' * 500).length, 500);
    for (final v in ['', ' \t\n', 'x' * 501]) {
      expect(() => validateContent(v), throwsA(isA<ChatFailure>()));
    }
  });
  test('Hai tin cùng mili-giây sắp theo messageId; bỏ bản ghi thiếu', () {
    final a = ChatMessage('a', 'u', '1', 10),
        b = ChatMessage('b', 'u', '2', 10);
    expect(ChatMessage.compare(a, b), lessThan(0));
    expect(ChatMessage.decode('x', {'senderId': 'u'}), isNull);
  });
}
