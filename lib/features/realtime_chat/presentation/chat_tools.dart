part of 'chat_screen.dart';

class _ImagePreview extends StatefulWidget {
  const _ImagePreview({
    super.key,
    required this.repo,
    required this.cid,
    required this.message,
    required this.onTap,
  });
  final ChatRepository repo;
  final String cid;
  final ChatMessage message;
  final VoidCallback onTap;
  @override
  State<_ImagePreview> createState() => _ImagePreviewState();
}

class _ImagePreviewState extends State<_ImagePreview> {
  late final bytes = widget.repo.rest
      .request(
        widget.repo.uid,
        'GET',
        'attachments/${widget.cid}/${widget.message.id}',
      )
      .then((v) => base64Decode(v as String));
  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: bytes,
    builder: (_, s) {
      if (!s.hasData) return const SizedBox.shrink();
      return InkWell(
        onTap: widget.onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.memory(
            s.requireData,
            semanticLabel: widget.message.content,
            width: 180,
            height: 140,
            fit: BoxFit.contain,
            cacheWidth: 360,
            errorBuilder: (_, e, stack) =>
                const Icon(Icons.broken_image_outlined),
          ),
        ),
      );
    },
  );
}

extension _ChatTools on _ChatScreenState {
  Future<void> perform(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (mounted) refresh(() => error = readableError(e));
    }
  }

  Future<String?> choose(String title, List<(String, String)> options) =>
      showModalBottomSheet<String>(
        context: context,
        showDragHandle: true,
        builder: (sheet) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Text(title, style: Theme.of(sheet).textTheme.titleLarge),
              ),
              for (final (key, label) in options)
                ListTile(
                  title: Text(label),
                  onTap: () => Navigator.pop(sheet, key),
                ),
            ],
          ),
        ),
      );

  Future<void> composeTool(String action) async {
    if (action == 'question') {
      refresh(() {
        question = true;
        replying = null;
      });
      return;
    }
    if (action == 'stickers') {
      final custom = fields(
        await repo.rest.request(repo.uid, 'GET', 'stickers/${repo.uid}'),
      );
      if (!mounted) return;
      final choice = await choose('Sticker học tập', [
        for (final s in {
          '📚 Đang ôn bài',
          '💡 Hiểu rồi!',
          '☕ Nghỉ 5 phút',
          '🎯 Chốt đáp án',
          ...custom.values.whereType<String>(),
        })
          (s, s),
        for (final entry in custom.entries.where((e) => e.value is Map))
          ('art:${entry.key}', '🖼 ${fields(entry.value)['label']}'),
        ('+', 'Tạo sticker chữ và emoji'),
        ('+art', 'Tạo sticker từ ảnh'),
      ]);
      if (choice == null) return;
      if (choice == '+art' || choice.startsWith('art:')) {
        String encoded, label;
        if (choice == '+art') {
          final file = await FilePicker.pickFile(
            type: FileType.custom,
            allowedExtensions: ['png', 'jpg', 'jpeg', 'webp', 'gif'],
          );
          if (file == null) return;
          final size = await file.length();
          if (size == null || size == 0 || size > 131072) {
            throw const ChatFailure('Sticker ảnh tối đa 128 KiB.');
          }
          encoded = base64Encode(await file.readAsBytes());
          label = file.name;
          if (label.length > 80) {
            throw const ChatFailure('Tên ảnh tối đa 80 ký tự.');
          }
          final id = repo.db.ref().push().key!;
          await repo.rest.request(repo.uid, 'PATCH', '', {
            'stickers/${repo.uid}/$id': {'label': label},
            'stickerArt/${repo.uid}/$id': encoded,
          });
        } else {
          final id = choice.substring(4);
          label = fields(custom[id])['label'] as String;
          encoded = await repo.rest.request(
            repo.uid,
            'GET',
            'stickerArt/${repo.uid}/$id',
          ) as String;
        }
        await repo.sendMessage(
          chat.id,
          label,
          kind: 'image',
          attachment: encoded,
          replyTo: replying?.id,
        );
        if (mounted) {
          refresh(() {
            replying = null;
            question = false;
          });
        }
        return;
      }
      var sticker = choice;
      if (choice == '+') {
        if (!mounted) return;
        final label = await askText(context, 'Nội dung sticker riêng', 40);
        if (label == null || label.isEmpty) return;
        sticker = label;
        await repo.write(
          'stickers/${repo.uid}/${repo.db.ref().push().key}',
          label,
        );
      }
      await repo.sendMessage(
        chat.id,
        sticker,
        kind: 'sticker',
        replyTo: replying?.id,
      );
    } else {
      final file = await FilePicker.pickFile();
      if (file == null) return;
      final length = await file.length();
      if (length == null || length < 1 || length > 1048576) {
        throw const ChatFailure('Chọn tệp từ 1 byte đến 1 MiB.');
      }
      final bytes = await file.readAsBytes();
      if (bytes.length != length) {
        throw const ChatFailure('Tệp đã thay đổi. Hãy chọn lại.');
      }
      final isImage = {
        'png',
        'jpg',
        'jpeg',
        'webp',
        'gif',
      }.contains(file.extension?.toLowerCase());
      await repo.sendMessage(
        chat.id,
        file.name,
        kind: isImage ? 'image' : 'file',
        attachment: base64Encode(bytes),
        replyTo: replying?.id,
      );
    }
    if (mounted) {
      refresh(() {
        replying = null;
        question = false;
      });
    }
  }

  Future<void> openAttachment(ChatMessage m) async {
    final encoded = await repo.rest.request(
      repo.uid,
      'GET',
      'attachments/${chat.id}/${m.id}',
    );
    if (encoded is! String) throw const ChatFailure('Tệp đã được thu hồi.');
    final bytes = base64Decode(encoded);
    if (!mounted) return;
    if (m.kind == 'image') {
      final save = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(m.content),
          content: Image.memory(
            bytes,
            cacheWidth: 800,
            errorBuilder: (_, e, s) =>
                const Text('Trình duyệt chưa đọc được ảnh này.'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('Đóng'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Tải ảnh'),
            ),
          ],
        ),
      );
      if (save != true) return;
    }
    final name = m.content.replaceAll(RegExp(r'[/\\:*?"<>|]'), '_');
    final hasExtension = name.lastIndexOf('.') > 0 && !name.endsWith('.');
    await FilePicker.saveFile(
      fileName: hasExtension ? name : '$name.bin',
      bytes: bytes,
    );
  }

  Future<void> messageTools(
    ChatMessage m,
    Map<String, dynamic> info,
    List<ChatMessage> rows,
  ) async {
    final parent = m.replyTo == null
        ? null
        : await replyTarget(m.replyTo!, rows);
    if (!mounted) return;
    final pick = await choose('Tùy chọn tin nhắn', [
      if (!m.recalled) ...[
        ('reply', 'Trả lời'),
        for (final s in ['👍', '❤️', '💡', '🎉']) (s, s),
        ('pin', info['pinned'] == true ? 'Bỏ ghim tin' : 'Ghim tin nhắn'),
        if (parent?.kind == 'question' && parent?.senderId == repo.uid)
          ('answer', 'Chốt làm đáp án cho câu hỏi'),
        if (m.senderId == repo.uid) ('recall', 'Thu hồi với mọi người'),
      ],
      ('hide', 'Xóa ở phía tôi'),
    ]);
    if (pick == null || !mounted) return;
    final path = 'interactions/${chat.id}/${m.id}';
    switch (pick) {
      case 'reply':
        refresh(() {
          replying = m;
          question = false;
        });
        break;
      case 'pin':
        await repo.write('$path/pinned', info['pinned'] == true ? null : true);
        break;
      case 'answer':
        await repo.write('interactions/${chat.id}/${parent!.id}/answer', m.id);
        break;
      case 'hide':
        await repo.preference(chat.id, 'hidden/${m.id}', true);
        break;
      case 'recall':
        if (await choose('Thu hồi tin này cho tất cả thành viên?', [
              ('yes', 'Thu hồi'),
              ('no', 'Hủy'),
            ]) ==
            'yes') {
          await repo.recall(chat.id, m);
        }
        break;
      default:
        await repo.write(
          '$path/reactions/${repo.uid}',
          fields(info['reactions'])[repo.uid] == pick ? null : pick,
        );
    }
  }

  Future<ChatMessage?> replyTarget(String id, List<ChatMessage> rows) async {
    final recent = rows.where((r) => r.id == id).firstOrNull;
    if (recent != null || !repo.online) return recent;
    final raw = await repo.rest.request(
      repo.uid,
      'GET',
      'messages/${chat.id}/$id',
    );
    final message = ChatMessage.decode(id, raw);
    if (message == null) return null;
    final prefs = fields(
      await repo.rest.request(
        repo.uid,
        'GET',
        'chatPrefs/${repo.uid}/${chat.id}',
      ),
    );
    return repo.visible([message], prefs).firstOrNull;
  }

  Future<void> showOriginal(String id, List<ChatMessage> rows) async {
    final original = await replyTarget(id, rows);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Tin nhắn được trả lời'),
        content: SelectableText(
          original?.content ?? 'Tin gốc không có trong lịch sử hiện tại.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Future<void> chatTool(
    String key,
    Map<String, dynamic> meta,
    Map<String, dynamic> prefs,
  ) async {
    if (key == 'following') {
      FollowedQuestionsPage.open(context, repo, cid: chat.id);
      return;
    }
    if (key == 'profile') {
      await Navigator.pushNamed(context, '/profile', arguments: chat.peerUid);
      return;
    }
    if (key == 'nick' || key == 'self') {
      final name = await askText(
        context,
        'Biệt danh riêng · để trống để đặt lại',
        50,
      );
      if (name != null) {
        await repo.preference(
          chat.id,
          key == 'self' ? 'selfName' : 'nickname',
          name.isEmpty ? null : name,
        );
      }
      return;
    }
    var keyword = '';
    if (key == 'search') {
      final text = await askText(context, 'Tìm trong lịch sử tin nhắn', 100);
      if (text == null || text.isEmpty) return;
      keyword = text;
    }
    final cached = await repo.getCachedMessages(chat.id);
    final List<ChatMessage> found;
    if (key == 'pins' && repo.online) {
      found = [];
      for (final e in meta.entries.where(
        (e) => fields(e.value)['pinned'] == true,
      )) {
        final msg = ChatMessage.decode(
          e.key,
          await repo.rest.request(
            repo.uid,
            'GET',
            'messages/${chat.id}/${e.key}',
          ),
        );
        if (msg != null && !msg.recalled) {
          found.addAll(repo.visible([msg], prefs));
        }
      }
    } else {
      found = repo.online
          ? await repo.search(
              chat.id,
              keyword,
              kind: (key == 'study' || key == 'review') ? 'question' : null,
            )
          : cached.reversed
                .where(
                  (r) =>
                      !r.recalled &&
                      r.content.toLowerCase().contains(keyword.toLowerCase()),
                )
                .toList();
    }
    if (!mounted) return;
    final answers = <String, String>{};
    if (key == 'study' || key == 'review') {
      for (final m in found.where((r) => r.kind == 'question')) {
        final id = fields(meta[m.id])['answer'];
        if (id is! String) continue;
        var a = cached.where((r) => r.id == id).firstOrNull;
        if (repo.online) {
          a = ChatMessage.decode(
            id,
            await repo.rest.request(repo.uid, 'GET', 'messages/${chat.id}/$id'),
          );
        }
        if (a != null &&
            !a.recalled &&
            a.replyTo == m.id &&
            repo.visible([a], prefs).isNotEmpty) {
          answers[m.id] = a.content;
        }
      }
    }
    if (!mounted) return;
    if (key == 'review') {
      final cards = found.where((m) => answers.containsKey(m.id)).toList();
      if (cards.isEmpty) {
        throw const ChatFailure(
          'Chốt một đáp án trong hội thoại để tạo thẻ tự ôn.',
        );
      }
      var index = 0, known = 0, revealed = false;
      await showDialog<void>(
        context: context,
        builder: (d) => StatefulBuilder(
          builder: (c, change) => AlertDialog(
            title: Text(
              index == cards.length
                  ? 'Hoàn thành lượt ôn'
                  : 'Thẻ tự ôn · ${index + 1}/${cards.length}',
            ),
            content: SingleChildScrollView(
              child: Text(
                index == cards.length
                    ? 'Bạn nhớ $known/${cards.length} đáp án.'
                    : revealed
                    ? answers[cards[index].id]!
                    : cards[index].content,
              ),
            ),
            actions: index == cards.length
                ? [
                    FilledButton(
                      onPressed: () => Navigator.pop(c),
                      child: const Text('Hoàn tất'),
                    ),
                  ]
                : revealed
                ? [
                    for (final (label, score) in [
                      ('Cần ôn lại', 0),
                      ('Đã nhớ', 1),
                    ])
                      TextButton(
                        onPressed: () => change(() {
                          index++;
                          known += score;
                          revealed = false;
                        }),
                        child: Text(label),
                      ),
                  ]
                : [
                    FilledButton(
                      onPressed: () => change(() => revealed = true),
                      child: const Text('Lật xem đáp án'),
                    ),
                  ],
          ),
        ),
      );
      return;
    }
    final shown = found.where(
      (m) => key == 'study'
          ? m.kind == 'question'
          : key != 'pins' || fields(meta[m.id])['pinned'] == true,
    );
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              key == 'study'
                  ? 'Sổ đáp án'
                  : key == 'pins'
                  ? 'Tin đã ghim'
                  : 'Kết quả tìm kiếm',
              style: Theme.of(c).textTheme.titleLarge,
            ),
            if (shown.isEmpty)
              const ListTile(title: Text('Chưa có tin phù hợp.')),
            for (final m in shown)
              ListTile(
                title: Text(m.content),
                subtitle: Text(
                  key == 'study'
                      ? (answers[m.id] ?? 'Chưa có đáp án hiển thị')
                      : timeLabel(m.createdAt, full: true),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
