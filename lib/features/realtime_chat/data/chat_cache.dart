import 'package:sqflite/sqflite.dart';

import '../domain/chat.dart';

class ChatCache {
  ChatCache(this.factory);
  final DatabaseFactory factory;
  Future<Database>? _database;
  Future<Database> get _db => _database ??= factory.openDatabase(
    'study_chat_tv2.db',
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, _) async {
        await db.execute(
          'CREATE TABLE messages(owner_uid TEXT NOT NULL, conversation_id TEXT NOT NULL, message_id TEXT NOT NULL, sender_id TEXT NOT NULL, content TEXT NOT NULL, created_at INTEGER NOT NULL, PRIMARY KEY(owner_uid, message_id))',
        );
        await db.execute(
          'CREATE INDEX recent ON messages(owner_uid, conversation_id, created_at DESC, message_id DESC)',
        );
        await db.execute(
          'CREATE TABLE conversations(owner_uid TEXT NOT NULL, conversation_id TEXT NOT NULL, title TEXT NOT NULL, peer_uid TEXT, avatar TEXT NOT NULL, last TEXT NOT NULL, time INTEGER NOT NULL, PRIMARY KEY(owner_uid, conversation_id))',
        );
      },
    ),
  );

  Future<void> saveMessages(
    String uid,
    String cid,
    List<ChatMessage> messages,
  ) async {
    final db = await _db;
    await db.transaction((tx) async {
      final batch = tx.batch();
      for (final m in messages) {
        batch.insert('messages', {
          'owner_uid': uid,
          'conversation_id': cid,
          'message_id': m.id,
          'sender_id': m.senderId,
          'content': m.content,
          'created_at': m.createdAt,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      batch.rawDelete(
        'DELETE FROM messages WHERE owner_uid=? AND conversation_id=? AND message_id NOT IN (SELECT message_id FROM messages WHERE owner_uid=? AND conversation_id=? ORDER BY created_at DESC,message_id DESC LIMIT 30)',
        [uid, cid, uid, cid],
      );
      await batch.commit(noResult: true);
    });
  }

  Future<List<ChatMessage>> read(String uid, String cid) async {
    final rows = await (await _db).query(
      'messages',
      where: 'owner_uid=? AND conversation_id=?',
      whereArgs: [uid, cid],
      orderBy: 'created_at ASC,message_id ASC',
    );
    return [
      for (final r in rows)
        ChatMessage(
          r['message_id'] as String,
          r['sender_id'] as String,
          r['content'] as String,
          r['created_at'] as int,
        ),
    ];
  }

  Future<void> saveSummaries(String uid, List<ChatSummary> rows) async {
    final db = await _db;
    await db.transaction((tx) async {
      final ids = rows.map((r) => r.id).toSet();
      final old = await tx.query(
        'conversations',
        columns: ['conversation_id'],
        where: 'owner_uid=?',
        whereArgs: [uid],
      );
      for (final r in old) {
        final id = r['conversation_id'] as String;
        if (!ids.contains(id)) await _forget(tx, uid, id);
      }
      final batch = tx.batch();
      for (final r in rows) {
        batch.insert('conversations', {
          'owner_uid': uid,
          'conversation_id': r.id,
          'title': r.title,
          'peer_uid': r.peerUid,
          'avatar': r.avatar,
          'last': r.last,
          'time': r.time,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    });
  }

  Future<List<ChatSummary>> summaries(String uid) async {
    final rows = await (await _db).query(
      'conversations',
      where: 'owner_uid=?',
      whereArgs: [uid],
      orderBy: 'time DESC,conversation_id',
    );
    return [
      for (final r in rows)
        ChatSummary(
          id: r['conversation_id'] as String,
          title: r['title'] as String,
          peerUid: r['peer_uid'] as String?,
          avatar: r['avatar'] as String,
          last: r['last'] as String,
          time: r['time'] as int,
        ),
    ];
  }

  Future<void> _forget(DatabaseExecutor db, String uid, String cid) async {
    for (final table in ['messages', 'conversations']) {
      await db.delete(
        table,
        where: 'owner_uid=? AND conversation_id=?',
        whereArgs: [uid, cid],
      );
    }
  }

  Future<void> forget(String uid, String cid) async =>
      (await _db).transaction((tx) => _forget(tx, uid, cid));
}
