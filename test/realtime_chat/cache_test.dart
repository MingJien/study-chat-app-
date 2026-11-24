import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:study_chat_app/features/realtime_chat/data/chat_cache.dart';
import 'package:study_chat_app/features/realtime_chat/domain/chat.dart';

void main() {
  test('T10/T12/T21 · SQLite upsert, giới hạn 30, tách tài khoản và thu hồi cache phòng', () async {
    sqfliteFfiInit();
    final factory = databaseFactoryFfi;
    await factory.deleteDatabase('study_chat_tv2.db');
    addTearDown(() => factory.deleteDatabase('study_chat_tv2.db'));
    final cache = ChatCache(factory);
    final batch = [
      for (var i = 0; i < 35; i++) ChatMessage('m$i', 'a', 'tin $i', i),
    ];
    await cache.saveMessages('a', 'room_one', batch);
    await cache.saveMessages('a', 'room_one', [
      const ChatMessage('m34', 'a', 'confirmed', 34),
    ]);
    await cache.saveMessages('b', 'room_one', [batch.first]);
    await cache.saveMessages('a', 'room_two', [
      const ChatMessage('other', 'a', 'khác', 1),
    ]);
    final rows = await cache.read('a', 'room_one');
    expect(rows.length, 30);
    expect(rows.first.id, 'm5');
    expect(rows.last.content, 'confirmed');
    expect((await cache.read('b', 'room_one')).single.id, 'm0');
    const summary = ChatSummary(id: 'room_one', title: 'Mobile');
    await cache.saveSummaries('a', [summary]);
    await cache.saveSummaries('b', [summary]);
    await cache.saveSummaries('a', []);
    expect(await cache.read('a', 'room_one'), isEmpty);
    expect((await cache.read('a', 'room_two')).length, 1);
    expect((await cache.summaries('b')).single.id, 'room_one');
    expect((await cache.read('b', 'room_one')).length, 1);
  });
}
