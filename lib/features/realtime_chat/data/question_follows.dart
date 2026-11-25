part of 'chat_repository.dart';

class FollowedQuestion {
  const FollowedQuestion(
    this.chat,
    this.question,
    this.answer,
    this.seen,
    this.reviewAt,
  );
  final ChatSummary chat;
  final ChatMessage question;
  final ChatMessage? answer;
  final String? seen;
  final int? reviewAt;
  bool get unread => answer != null && answer!.id != seen;
  bool get due =>
      answer != null &&
      reviewAt != null &&
      reviewAt! <= DateTime.now().millisecondsSinceEpoch;
}

extension QuestionFollows on ChatRepository {
  String _followPath(String cid, String mid) =>
      'questionFollows/$uid/$cid/$mid';

  Future<void> followQuestion(String cid, String mid, bool follow) async {
    _check(network: true);
    final path = _followPath(cid, mid);
    await rest.request(uid, 'PATCH', '', {
      'interactions/$cid/$mid/followers/$uid': follow ? true : null,
      (follow ? '$path/active' : path): follow ? true : null,
    });
  }

  Future<void> readSolution(FollowedQuestion item) => write(
    '${_followPath(item.chat.id, item.question.id)}/seen',
    item.answer!.id,
  );

  Future<void> scheduleReview(FollowedQuestion item, DateTime? date) => write(
    '${_followPath(item.chat.id, item.question.id)}/reviewAt',
    date?.millisecondsSinceEpoch,
  );

  Stream<List<FollowedQuestion>> _watchFollowedQuestions() =>
      connection.switchMap((connected) {
        if (!connected) return Stream.value(<FollowedQuestion>[]);
        return value('questionFollows/$uid')
            .switchMap(
              (raw) =>
                  _combine([
                    for (final e in fields(raw).entries)
                      _followedInChat(e.key, fields(e.value)),
                  ]).map(
                    (groups) => groups.expand((rows) => rows).toList()
                      ..sort(
                        (a, b) => ChatMessage.compare(b.question, a.question),
                      ),
                  ),
            )
            .switchMap(_notifyWhenDue);
      });

  Stream<List<FollowedQuestion>> _notifyWhenDue(List<FollowedQuestion> rows) =>
      Stream.multi((out) {
        Timer? timer;
        void emit() {
          final now = DateTime.now().millisecondsSinceEpoch;
          out.add(rows);
          final dates = rows
              .where((r) => r.answer != null)
              .map((r) => r.reviewAt)
              .nonNulls
              .where((ms) => ms > now);
          if (dates.isEmpty) {
            out.close();
            return;
          }
          final next = dates.reduce((a, b) => a < b ? a : b);
          timer = Timer(
            Duration(milliseconds: (next - now).clamp(1, 86400000)),
            emit,
          );
        }

        emit();
        out.onCancel = () => timer?.cancel();
      });

  Stream<List<FollowedQuestion>> _followedInChat(
    String cid,
    Map<String, dynamic> entries,
  ) {
    final Stream<ChatSummary?> chat;
    if (cid.startsWith('room_')) {
      chat = value('roomMembers/$cid/$uid').switchMap(
        (membership) => membership == null
            ? Stream<ChatSummary?>.value(null)
            : value('rooms/$cid/roomName').map(
                (name) =>
                    ChatSummary(id: cid, title: name as String? ?? 'Phòng học'),
              ),
      );
    } else {
      chat = value('directChats/$cid').switchMap((raw) {
        final pair = fields(raw);
        final peer = pair['first'] == uid ? pair['second'] : pair['first'];
        if (peer is! String) return Stream<ChatSummary?>.value(null);
        return value('profiles/$peer/displayName').map(
          (name) => ChatSummary(
            id: cid,
            title: name as String? ?? 'Chat riêng',
            peerUid: peer,
          ),
        );
      });
    }
    return chat.switchMap((summary) {
      if (summary == null) return Stream.value(<FollowedQuestion>[]);
      return Rx.combineLatest2(
        value('chatPrefs/$uid/$cid'),
        _combine([
          for (final e in entries.entries)
            _followedPair(summary, e.key, fields(e.value)),
        ]),
        (pref, rows) {
          final settings = fields(pref);
          return [
            for (final row in rows.nonNulls)
              if (visible([row.question], settings).isNotEmpty)
                if (row.answer != null &&
                    visible([row.answer!], settings).isEmpty)
                  FollowedQuestion(
                    summary,
                    row.question,
                    null,
                    row.seen,
                    row.reviewAt,
                  )
                else
                  row,
          ];
        },
      );
    });
  }

  Stream<FollowedQuestion?> _followedPair(
    ChatSummary chat,
    String mid,
    Map<String, dynamic> entry,
  ) {
    final path = 'messages/${chat.id}';
    final answer = value('interactions/${chat.id}/$mid/answer').switchMap(
      (id) => id is String
          ? value('$path/$id').map((v) => ChatMessage.decode(id, v))
          : Stream<ChatMessage?>.value(null),
    );
    return Rx.combineLatest2(value('$path/$mid'), answer, (raw, reply) {
      final question = ChatMessage.decode(mid, raw);
      if (question == null ||
          question.recalled ||
          question.kind != 'question') {
        return null;
      }
      return FollowedQuestion(
        chat,
        question,
        reply != null && !reply.recalled && reply.replyTo == mid ? reply : null,
        entry['seen'] as String?,
        entry['reviewAt'] as int?,
      );
    });
  }
}
