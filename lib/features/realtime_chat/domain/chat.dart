enum ChatType { direct, group }

class ChatFailure implements Exception {
  const ChatFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

String directId(String uid, String peerUid) {
  if (uid == peerUid ||
      [uid, peerUid].any(
        (s) => s.isEmpty || RegExp(r'[.#$\[\]/\x00-\x1f\x7f]').hasMatch(s),
      )) {
    throw const ChatFailure('Bạn cần chọn một bạn học khác có UID hợp lệ.');
  }
  final pair = [uid, peerUid]..sort();
  return 'dm_${pair.map((s) => s.replaceAll('%', '%25').replaceAll('|', '%7C')).join('|')}';
}

String validateContent(String value) {
  final text = value.trim();
  if (text.isEmpty || text.length > 500) {
    throw const ChatFailure('Nhập từ 1 đến 500 ký tự cho mỗi tin nhắn.');
  }
  return text;
}

Map<String, dynamic> fields(Object? raw) =>
    raw is Map ? Map<String, dynamic>.from(raw) : {};

class ChatMessage {
  const ChatMessage(this.id, this.senderId, this.content, this.createdAt);
  final String id, senderId, content;
  final int createdAt;

  static ChatMessage? decode(String id, Object? value) {
    final m = fields(value);
    if (m['senderId'] is! String ||
        m['content'] is! String ||
        m['createdAt'] is! int) {
      return null;
    }
    return ChatMessage(id, m['senderId'], m['content'], m['createdAt']);
  }

  static int compare(ChatMessage a, ChatMessage b) {
    final byTime = a.createdAt.compareTo(b.createdAt);
    return byTime == 0 ? a.id.compareTo(b.id) : byTime;
  }
}

class ChatPresence {
  const ChatPresence(this.online, this.lastSeen);
  final bool online;
  final int? lastSeen;
}

class ChatSummary {
  const ChatSummary({
    required this.id,
    required this.title,
    this.peerUid,
    this.avatar = '',
    this.last = '',
    this.time = 0,
    this.online = false,
  });
  final String id, title, avatar, last;
  final String? peerUid;
  final int time;
  final bool online;
  ChatType get type => peerUid == null ? ChatType.group : ChatType.direct;
}

class ChatPageData {
  const ChatPageData(this.messages, {required this.cached});
  final List<ChatMessage> messages;
  final bool cached;
}

abstract interface class ChatApi {
  Future<String> openDirectConversation(String peerUid);
  Stream<List<ChatSummary>> watchConversations(String uid);
  Stream<ChatPageData> watchMessages(String conversationId, ChatType type);
  Future<void> sendMessage(
    String conversationId,
    String content, {
    String? messageId,
  });
  Stream<ChatPresence> watchPresence(String uid);
  Future<List<ChatMessage>> getCachedMessages(String conversationId);
}
