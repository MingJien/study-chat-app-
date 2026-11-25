import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../app/chat_directory.dart' show askText;

import 'package:rxdart/rxdart.dart';

import '../data/chat_repository.dart';
import '../domain/chat.dart';
import 'chat_widgets.dart';

part 'chat_tools.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen(this.repo, this.chat, {super.key});
  final ChatRepository repo;
  final ChatSummary chat;
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final input = TextEditingController(), scroll = ScrollController();
  late Stream<ChatPageData> feed;
  late final Stream<Object?>? notice;
  late final Stream<ChatPresence>? presence;
  final profiles = <String, Stream<Object?>>{};
  late final details = repo.value('interactions/${chat.id}');
  late final preferences = repo.value('chatPrefs/${repo.uid}/${chat.id}');
  ChatMessage? replying;
  bool question = false;
  bool sending = false, showJump = false;
  String? error, lastId, retryId, retryText;
  ChatRepository get repo => widget.repo;
  ChatSummary get chat => widget.chat;
  @override
  void initState() {
    super.initState();
    feed = repo.watchMessages(chat.id, chat.type);
    notice = chat.type == ChatType.group
        ? repo.value('roomNotices/${chat.id}')
        : null;
    presence = chat.peerUid == null ? null : repo.watchPresence(chat.peerUid!);
  }

  @override
  void dispose() {
    input.dispose();
    scroll.dispose();
    super.dispose();
  }

  void refresh(VoidCallback change) => setState(change);
  void jump() {
    if (scroll.hasClients) scroll.jumpTo(scroll.position.maxScrollExtent);
    if (showJump) setState(() => showJump = false);
  }

  void arrived(List<ChatMessage> rows) {
    final next = rows.lastOrNull?.id;
    if (next == null || next == lastId) return;
    final near =
        lastId == null ||
        !scroll.hasClients ||
        scroll.position.extentAfter < 96;
    lastId = next;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (near) {
        jump();
      } else {
        setState(() => showJump = true);
      }
    });
  }

  Future<void> send() async {
    if (sending) return;
    final content = input.text;
    try {
      validateContent(content);
      if (retryId == null || retryText != content) {
        retryId = repo.newMessageId(chat.id);
        retryText = content;
      }
      setState(() {
        sending = true;
        error = null;
      });
      await repo.sendMessage(
        chat.id,
        content,
        messageId: retryId,
        kind: question ? 'question' : null,
        replyTo: replying?.id,
      );
      if (!mounted) return;
      input.clear();
      replying = null;
      question = false;
      retryId = null;
      retryText = null;
    } catch (e) {
      if (mounted) setState(() => error = readableError(e));
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder(
    stream: details,
    builder: (_, d) => StreamBuilder(
      stream: preferences,
      builder: (_, p) => buildChat(context, fields(d.data), fields(p.data)),
    ),
  );
  Widget buildChat(
    BuildContext context,
    Map<String, dynamic> meta,
    Map<String, dynamic> prefs,
  ) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Công cụ hội thoại',
            onSelected: (v) => perform(() => chatTool(v, meta, prefs)),
            itemBuilder: (_) => [
              for (final (key, label) in [
                ('search', 'Tìm tin nhắn'),
                ('pins', 'Tin nhắn đã ghim'),
                ('study', 'Sổ đáp án'),
                ('nick', 'Biệt danh đối phương / phòng'),
                ('self', 'Biệt danh của tôi'),
                if (chat.peerUid != null) ('profile', 'Xem hồ sơ'),
              ])
                PopupMenuItem(value: key, child: Text(label)),
            ],
          ),
        ],
        title: Row(
          children: [
            ChatAvatar(
              chat.title,
              group: chat.type == ChatType.group,
              avatar: chat.avatar,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prefs['nickname'] as String? ?? chat.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (presence != null)
                    StreamBuilder(
                      stream: presence,
                      builder: (_, s) {
                        final p = s.data;
                        return Text(
                          p == null
                              ? 'Chat riêng'
                              : p.online
                              ? 'Đang trực tuyến'
                              : p.lastSeen == null
                              ? 'Ngoại tuyến'
                              : 'Hoạt động ${timeLabel(p.lastSeen!, full: true)}',
                          style: Theme.of(context).textTheme.labelSmall,
                        );
                      },
                    )
                  else
                    Text(
                      'Phòng thảo luận',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 850),
            child: StreamBuilder(
              stream: feed,
              builder: (context, s) {
                final data = s.data;
                final cached = data?.cached ?? false;
                final enabled =
                    !s.hasError &&
                    data != null &&
                    !cached &&
                    repo.online &&
                    !sending;
                return Column(
                  children: [
                    if (cached)
                      const ListTile(
                        dense: true,
                        leading: Icon(Icons.cloud_off),
                        title: Text('Ngoại tuyến · Đang xem tin đã lưu'),
                      ),
                    if (notice != null && !cached && !s.hasError)
                      StreamBuilder(
                        stream: notice,
                        builder: (_, snap) {
                          final text = fields(snap.data)['content'];
                          return text is String
                              ? ListTile(
                                  leading: const Icon(Icons.push_pin_outlined),
                                  tileColor: colors.tertiaryContainer,
                                  title: Text(
                                    text,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )
                              : const SizedBox.shrink();
                        },
                      ),
                    Expanded(
                      child: s.hasError
                          ? StatePanel(
                              readableError(s.error),
                              icon: Icons.lock_outline,
                              action: TextButton(
                                onPressed: () => setState(
                                  () => feed = repo.watchMessages(
                                    chat.id,
                                    chat.type,
                                  ),
                                ),
                                child: const Text('Thử lại'),
                              ),
                            )
                          : data == null
                          ? const Center(child: CircularProgressIndicator())
                          : data.messages.isEmpty
                          ? StatePanel(
                              cached ? 'Chưa có tin đã lưu trên thiết bị này.' : 'Chưa có tin nhắn. Hãy bắt đầu cuộc thảo luận.',
                            )
                          : Builder(
                              builder: (_) {
                                arrived(data.messages);
                                return Stack(
                                  children: [
                                    ListView.builder(
                                      controller: scroll,
                                      padding: const EdgeInsets.all(16),
                                      itemCount: data.messages.length,
                                      itemBuilder: (_, i) {
                                        final m = data.messages[i];
                                        final own = m.senderId == repo.uid;
                                        final stream = profiles.putIfAbsent(
                                          m.senderId,
                                          () => repo
                                              .value('profiles/${m.senderId}')
                                              .shareReplay(maxSize: 1),
                                        );
                                        // Share a profile subscription through a single header per sender run.
                                        final first =
                                            i == 0 ||
                                            data.messages[i - 1].senderId !=
                                                m.senderId;
                                        final info = fields(meta[m.id]);
                                        final target = data.messages
                                            .where((row) => row.id == m.replyTo)
                                            .firstOrNull;
                                        return Column(
                                          crossAxisAlignment: own
                                              ? CrossAxisAlignment.end
                                              : CrossAxisAlignment.start,
                                          children: [
                                            if (m.replyTo != null)
                                              Text(
                                                '↳ ${target?.content ?? "Trả lời tin nhắn trước"}',
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            if (m.kind == 'question')
                                              Text(
                                                info['answer'] == null
                                                    ? '❓ Câu hỏi đang mở'
                                                    : '✅ Đã chốt đáp án',
                                              ),
                                            if (info['pinned'] == true &&
                                                !m.recalled)
                                              const Text('📌 Đã ghim'),
                                            MessageBubble(
                                              message: m,
                                              nickname:
                                                  (own
                                                          ? prefs['selfName']
                                                          : (m.senderId ==
                                                                    chat.peerUid
                                                                ? prefs['nickname']
                                                                : null))
                                                      as String?,
                                              own: own,
                                              showAuthor: first,
                                              profile: first && !cached
                                                  ? stream
                                                  : null,
                                              fallback: own
                                                  ? 'Bạn'
                                                  : chat.peerUid == m.senderId
                                                  ? chat.title
                                                  : 'Bạn học',
                                              onProfile: () =>
                                                  Navigator.pushNamed(
                                                    context,
                                                    '/profile',
                                                    arguments: m.senderId,
                                                  ),
                                            ),
                                            Wrap(
                                              crossAxisAlignment:
                                                  WrapCrossAlignment.center,
                                              children: [
                                                if (!m.recalled)
                                                  for (final emoji in fields(
                                                    info['reactions'],
                                                  ).values.toSet())
                                                    Text(
                                                      '$emoji ${fields(info['reactions']).values.where((e) => e == emoji).length} ',
                                                    ),
                                                if (!cached &&
                                                    !m.recalled &&
                                                    (m.kind == 'file' ||
                                                        m.kind == 'image'))
                                                  TextButton.icon(
                                                    onPressed: () => perform(
                                                      () => openAttachment(m),
                                                    ),
                                                    icon: const Icon(
                                                      Icons.download,
                                                    ),
                                                    label: Text(
                                                      m.kind == 'image'
                                                          ? 'Xem ảnh'
                                                          : 'Tải tệp',
                                                    ),
                                                  ),
                                                IconButton(
                                                  tooltip: 'Tùy chọn tin nhắn',
                                                  icon: const Icon(
                                                    Icons.more_horiz,
                                                  ),
                                                  onPressed: cached
                                                      ? null
                                                      : () => perform(
                                                          () => messageTools(
                                                            m,
                                                            info,
                                                            data.messages,
                                                          ),
                                                        ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                    if (showJump)
                                      Positioned(
                                        bottom: 8,
                                        right: 12,
                                        child: FilledButton.tonalIcon(
                                          onPressed: jump,
                                          icon: const Icon(
                                            Icons.arrow_downward,
                                          ),
                                          label: const Text('Tin mới'),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                    ),
                    if (replying != null || question)
                      ListTile(
                        dense: true,
                        title: Text(
                          replying != null
                              ? '↳ ${replying!.content}'
                              : '❓ Đặt câu hỏi cho sổ đáp án',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() {
                            replying = null;
                            question = false;
                          }),
                        ),
                      ),
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          error!,
                          style: TextStyle(color: colors.error),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          PopupMenuButton<String>(
                            enabled: enabled,
                            tooltip: 'Thêm vào tin nhắn',
                            icon: const Icon(Icons.add_circle_outline),
                            onSelected: (v) => perform(() => composeTool(v)),
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'question',
                                child: Text('Đặt câu hỏi học tập'),
                              ),
                              PopupMenuItem(
                                value: 'stickers',
                                child: Text('Bộ sticker'),
                              ),
                              PopupMenuItem(
                                value: 'file',
                                child: Text('Gửi tệp hoặc ảnh · tối đa 1 MiB'),
                              ),
                            ],
                          ),
                          Expanded(
                            child: TextField(
                              controller: input,
                              readOnly: !enabled,
                              minLines: 1,
                              maxLines: 3,
                              maxLength: 500,
                              decoration: InputDecoration(
                                hintText: cached
                                    ? 'Đang ngoại tuyến'
                                    : 'Nhập tin nhắn…',
                                counterText: '',
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            tooltip: 'Gửi tin nhắn',
                            onPressed: enabled ? send : null,
                            icon: sending
                                ? const SizedBox.square(
                                    dimension: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.send_rounded),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.own,
    required this.showAuthor,
    required this.profile,
    required this.fallback,
    required this.onProfile,
    this.nickname,
  });
  final ChatMessage message;
  final bool own, showAuthor;
  final Stream<Object?>? profile;
  final String fallback;
  final String? nickname;
  final VoidCallback onProfile;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Align(
      alignment: own ? Alignment.centerRight : Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: .86,
        alignment: own ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: own
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (showAuthor)
              StreamBuilder(
                stream: profile,
                builder: (_, s) {
                  final p = fields(s.data),
                      name = p['displayName'] as String? ?? fallback;
                  return TextButton.icon(
                    onPressed: onProfile,
                    icon: ChatAvatar(
                      name,
                      avatar: p['avatarId'] as String? ?? '',
                    ),
                    label: Text(nickname ?? (own ? 'Bạn' : name)),
                  );
                },
              ),
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: own
                    ? colors.primaryContainer
                    : colors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    message.content,
                    style: message.kind == 'sticker'
                        ? Theme.of(context).textTheme.headlineMedium
                        : null,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    timeLabel(message.createdAt, full: true),
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
