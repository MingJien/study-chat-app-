import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:rxdart/rxdart.dart';

import '../domain/chat.dart';
import 'chat_cache.dart';
import 'chat_rest.dart';

class ChatRepository implements ChatApi {
  ChatRepository(this.uid, this.auth, this.db, this.cache, this.rest) {
    connection = db
        .ref('.info/connected')
        .onValue
        .map((e) => e.snapshot.value == true)
        .distinct()
        .shareReplay(maxSize: 1);
    _presence = connection.listen(
      _onConnection,
      onError: (Object e) {
        _errors.add(e);
      },
    );
  }
  final String uid;
  final FirebaseAuth auth;
  final FirebaseDatabase db;
  final ChatCache cache;
  final ChatRest rest;
  late final Stream<bool> connection;
  late final StreamSubscription<bool> _presence;
  final _errors = StreamController<Object>.broadcast();
  Stream<Object> get errors => _errors.stream;
  bool online = false, _closed = false;
  int _generation = 0;
  DatabaseReference? _session;
  bool get active => !_closed && auth.currentUser?.uid == uid;

  void _check({bool network = false}) {
    if (!active) throw const ChatFailure('Phiên đăng nhập đã kết thúc.');
    if (network && !online) {
      throw const ChatFailure(
        'Bạn đang ngoại tuyến. Chỉ có thể xem tin đã lưu.',
      );
    }
  }

  Future<void> _onConnection(bool connected) async {
    final generation = ++_generation;
    online = connected;
    if (!connected || !active) return;
    final base = db.ref('presence/$uid');
    final session = base.child('sessions').push();
    _session = session;
    try {
      await base.onDisconnect().update({
        'sessions/${session.key}': null,
        'lastSeen': ServerValue.timestamp,
      });
      if (active && generation == _generation) await session.set(true);
    } catch (e) {
      if (active && generation == _generation) _errors.add(e);
    }
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _generation++;
    await _presence.cancel();
    try {
      if (online && auth.currentUser?.uid == uid && _session != null) {
        final base = db.ref('presence/$uid');
        await base
            .update({
              'sessions/${_session!.key}': null,
              'lastSeen': ServerValue.timestamp,
            })
            .timeout(const Duration(seconds: 3));
        await base.onDisconnect().cancel().timeout(const Duration(seconds: 3));
      }
    } finally {
      rest.client.close();
      await _errors.close();
    }
  }

  Stream<Object?> value(String path) =>
      db.ref(path).onValue.map((e) => e.snapshot.value);
  @override
  Stream<ChatPresence> watchPresence(String uid) =>
      value('presence/$uid').map((v) {
        final p = fields(v);
        return ChatPresence(
          fields(p['sessions']).isNotEmpty,
          p['lastSeen'] as int?,
        );
      });
  @override
  Future<String> openDirectConversation(String peerUid) async {
    _check(network: true);
    final id = directId(uid, peerUid);
    final pair = [uid, peerUid]..sort();
    await rest.request(uid, 'PATCH', '', {
      'directChats/$id': {'first': pair.first, 'second': pair.last},
      'userDirectChats/$uid/$id': true,
      'userDirectChats/$peerUid/$id': true,
    });
    return id;
  }

  String newMessageId(String id) => db.ref('messages/$id').push().key!;
  @override
  Future<void> sendMessage(
    String conversationId,
    String content, {
    String? messageId,
  }) async {
    _check(network: true);
    final clean = validateContent(content);
    final id = messageId ?? newMessageId(conversationId);
    final path = 'messages/$conversationId/$id';
    try {
      await rest.request(uid, 'PUT', path, {
        'senderId': uid,
        'content': clean,
        'createdAt': ServerValue.timestamp,
      });
    } on ChatFailure {
      // An earlier attempt can have reached the server before the reply was lost.
      if (!online || !active) rethrow;
      final existing = fields(await rest.request(uid, 'GET', path));
      if (existing['senderId'] != uid || existing['content'] != clean) rethrow;
    }
  }

  Stream<List<ChatMessage>> _recent(String id, int limit) => db
      .ref('messages/$id')
      .orderByChild('createdAt')
      .limitToLast(limit)
      .onValue
      .map((e) {
        final rows = <ChatMessage>[];
        for (final child in e.snapshot.children) {
          final message = ChatMessage.decode(child.key!, child.value);
          if (message != null) rows.add(message);
        }
        return rows..sort(ChatMessage.compare);
      });

  @override
  Future<List<ChatMessage>> getCachedMessages(String conversationId) async {
    _check();
    final rows = await cache.read(uid, conversationId);
    _check();
    return rows;
  }

  @override
  Stream<ChatPageData> watchMessages(String conversationId, ChatType type) {
    _check();
    Stream<ChatPageData> live() =>
        _recent(conversationId, 30).asyncMap((rows) async {
          _check();
          await cache.saveMessages(uid, conversationId, rows);
          return ChatPageData(rows, cached: false);
        });
    return connection.switchMap((connected) {
      if (!connected) {
        return Stream.fromFuture(
          getCachedMessages(conversationId)
              .then((r) => ChatPageData(r, cached: true)),
        );
      }
      if (type == ChatType.direct) return live();
      return value('roomMembers/$conversationId/$uid').switchMap((membership) {
        if (membership != null) return live();
        return Stream.fromFuture(
          cache
              .forget(uid, conversationId)
              .then<ChatPageData>(
                (_) => throw const ChatFailure(
                  'Bạn chưa tham gia hoặc đã rời phòng.',
                ),
              ),
        );
      });
    });
  }

  Stream<List<T>> _combine<T>(List<Stream<T>> streams) =>
      streams.isEmpty ? Stream.value(<T>[]) : Rx.combineLatestList(streams);

  Stream<ChatSummary> _summary(
    String id,
    String title,
    String? peer,
    String avatar,
  ) {
    final presence = peer == null
        ? Stream.value(const ChatPresence(false, null))
        : watchPresence(peer);
    return Rx.combineLatest2(_recent(id, 1), presence, (rows, p) {
      final last = rows.lastOrNull;
      return ChatSummary(
        id: id,
        title: title,
        peerUid: peer,
        avatar: avatar,
        last: last?.content ?? '',
        time: last?.createdAt ?? 0,
        online: p.online,
      );
    });
  }

  Stream<ChatSummary> _direct(String id) =>
      value('directChats/$id').switchMap((raw) {
        final d = fields(raw);
        final peer = (d['first'] == uid ? d['second'] : d['first']) as String;
        return value('profiles/$peer').switchMap((raw) {
          final p = fields(raw);
          return _summary(
            id,
            p['displayName'] as String? ?? peer,
            peer,
            p['avatarId'] as String? ?? '',
          );
        });
      });
  Stream<List<ChatSummary>> _rooms() => value('rooms').switchMap((raw) {
    final rooms = fields(raw);
    return _combine<ChatSummary?>([
      for (final entry in rooms.entries)
        value('roomMembers/${entry.key}/$uid').switchMap(
          (m) => m == null
              ? Stream<ChatSummary?>.value(null)
              : _summary(
                  entry.key,
                  fields(entry.value)['roomName'] as String? ?? entry.key,
                  null,
                  '',
                ),
        ),
    ]).map((rows) => rows.nonNulls.toList());
  });

  @override
  Stream<List<ChatSummary>> watchConversations(String uid) {
    _check();
    if (uid != this.uid) {
      throw const ChatFailure('Chỉ xem được hội thoại của chính mình.');
    }
    return connection.switchMap((connected) {
      if (!connected) return Stream.fromFuture(cache.summaries(uid));
      final direct = value('userDirectChats/$uid').switchMap(
        (raw) => _combine([for (final id in fields(raw).keys) _direct(id)]),
      );
      return Rx.combineLatest2(
        direct,
        _rooms(),
        (d, g) => [...d, ...g]
          ..sort((a, b) {
            final t = b.time.compareTo(a.time);
            return t == 0 ? a.id.compareTo(b.id) : t;
          }),
      ).asyncMap((rows) async {
        _check();
        await cache.saveSummaries(uid, rows);
        return rows;
      });
    });
  }
}
