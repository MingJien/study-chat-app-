part of 'chat_screen.dart';

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
        ('+', 'Tạo sticker chữ và emoji'),
      ]);
      if (choice == null) return;
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
    await FilePicker.saveFile(
      fileName: m.content.replaceAll(RegExp(r'[/\\:*?"<>|]'), '_'),
      bytes: bytes,
    );
  }

  Future<void> messageTools(
    ChatMessage m,
    Map<String, dynamic> info,
    List<ChatMessage> rows,
  ) async {
    final parent = rows.where((r) => r.id == m.replyTo).firstOrNull;
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

  Future<void> chatTool(
    String key,
    Map<String, dynamic> meta,
    Map<String, dynamic> prefs,
  ) async {
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
          ? await repo.search(chat.id, keyword)
          : cached.reversed
                .where(
                  (r) =>
                      !r.recalled &&
                      r.content.toLowerCase().contains(keyword.toLowerCase()),
                )
                .toList();
    }
    if (!mounted) return;
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
                      ? (found
                                .where(
                                  (r) => r.id == fields(meta[m.id])['answer'],
                                )
                                .firstOrNull
                                ?.content ??
                            'Chưa có đáp án hiển thị')
                      : timeLabel(m.createdAt, full: true),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
