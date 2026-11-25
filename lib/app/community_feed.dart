import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:file_picker/file_picker.dart';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../features/realtime_chat/data/chat_repository.dart';
import '../features/realtime_chat/domain/chat.dart';
import '../features/realtime_chat/presentation/chat_widgets.dart';
import 'contacts.dart';

class FeedPhoto extends StatefulWidget {
  const FeedPhoto({super.key, required this.repo, required this.path});
  final ChatRepository repo;
  final String path;
  @override
  State<FeedPhoto> createState() => _FeedPhotoState();
}

class _FeedPhotoState extends State<FeedPhoto> {
  String? photo;
  bool loading = false;
  @override
  Widget build(BuildContext context) {
    final data = photo;
    if (data != null) {
      return Image.memory(
        base64Decode(data),
        height: 180,
        cacheWidth: 540,
        fit: BoxFit.contain,
        errorBuilder: (_, e, stack) => const Icon(Icons.broken_image_outlined),
      );
    }
    return TextButton.icon(
      icon: const Icon(Icons.image_outlined),
      label: Text(loading ? 'Đang tải ảnh…' : 'Xem ảnh'),
      onPressed: loading
          ? null
          : () => socialAction(context, () async {
              setState(() => loading = true);
              try {
                final value = await widget.repo.rest.request(
                  widget.repo.uid,
                  'GET',
                  widget.path,
                );
                if (value is! String) {
                  throw const ChatFailure('Ảnh không còn khả dụng.');
                }
                if (mounted) setState(() => photo = value);
              } finally {
                if (mounted) setState(() => loading = false);
              }
            }),
    );
  }
}

class CommunityFeed extends StatefulWidget {
  const CommunityFeed(this.repo, {super.key});
  final ChatRepository repo;
  @override
  State<CommunityFeed> createState() => _CommunityFeedState();
}

class _CommunityFeedState extends State<CommunityFeed> {
  bool stories = false;
  late Stream<List<DataSnapshot>> feed = source();
  late final profiles = widget.repo.value('profiles');
  late final Timer timer;
  int get cutoff =>
      DateTime.now().subtract(const Duration(hours: 24)).millisecondsSinceEpoch;
  Stream<List<DataSnapshot>> source() {
    final db = widget.repo.db;
    if (!stories) {
      return db
          .ref('posts')
          .orderByChild('createdAt')
          .limitToLast(50)
          .onValue
          .map((s) => s.snapshot.children.toList().reversed.toList());
    }
    return db
        .ref('storyIndex')
        .orderByValue()
        .startAt(cutoff)
        .limitToLast(50)
        .onValue
        .asyncMap((event) async {
          final rows = await Future.wait(
            event.snapshot.children.map((item) async {
              try {
                return await db.ref('stories/${item.key}').get();
              } on FirebaseException catch (e) {
                if (e.code == 'permission-denied') return null;
                rethrow;
              }
            }),
          );
          return rows.nonNulls
              .where((s) => s.exists)
              .toList()
              .reversed
              .toList();
        });
  }

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (stories) setState(() => feed = source());
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  Future<void> compose() async {
    var style = 'note', body = '', bold = false, italic = false;
    String? photo, fileError;
    final story = stories;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (c, change) => AlertDialog(
          title: Text(story ? 'Story trong 24 giờ' : 'Viết bài đăng'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<String>(
                  value: style,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'note', child: Text('Ghi chú')),
                    DropdownMenuItem(
                      value: 'question',
                      child: Text('Hỏi cộng đồng'),
                    ),
                    DropdownMenuItem(
                      value: 'checklist',
                      child: Text('Danh sách ôn tập'),
                    ),
                  ],
                  onChanged: (v) => change(() => style = v!),
                ),
                Wrap(
                  spacing: 6,
                  children: [
                    FilterChip(
                      label: const Text('Đậm'),
                      selected: bold,
                      onSelected: (v) => change(() => bold = v),
                    ),
                    FilterChip(
                      label: const Text('Nghiêng'),
                      selected: italic,
                      onSelected: (v) => change(() => italic = v),
                    ),
                    IconButton(
                      tooltip: photo == null ? 'Thêm ảnh · 128 KiB' : 'Gỡ ảnh',
                      icon: Icon(
                        photo == null
                            ? Icons.add_photo_alternate_outlined
                            : Icons.hide_image_outlined,
                      ),
                      onPressed: () async {
                        if (photo != null) {
                          change(() => photo = null);
                          return;
                        }
                        try {
                          final f = await FilePicker.pickFile(
                            type: FileType.custom,
                            allowedExtensions: [
                              'png',
                              'jpg',
                              'jpeg',
                              'webp',
                              'gif',
                            ],
                          );
                          if (f == null) return;
                          final len = await f.length();
                          if (len == null || len < 1 || len > 131072) {
                            throw const ChatFailure(
                              'Ảnh bài đăng tối đa 128 KiB.',
                            );
                          }
                          final data = await f.readAsBytes();
                          if (c.mounted) {
                            change(() {
                              photo = base64Encode(data);
                              fileError = null;
                            });
                          }
                        } catch (e) {
                          if (c.mounted) {
                            change(() => fileError = readableError(e));
                          }
                        }
                      },
                    ),
                  ],
                ),
                if (fileError != null) Text(fileError!),
                if (photo != null)
                  Image.memory(
                    base64Decode(photo!),
                    height: 75,
                    cacheWidth: 180,
                    errorBuilder: (_, e, stack) =>
                        const Icon(Icons.broken_image),
                  ),
                TextField(
                  style: TextStyle(
                    fontWeight: bold ? FontWeight.bold : null,
                    fontStyle: italic ? FontStyle.italic : null,
                  ),
                  maxLength: 1000,
                  minLines: 3,
                  maxLines: 6,
                  decoration: InputDecoration(
                    labelText: style == 'checklist'
                        ? 'Mỗi dòng một mục'
                        : 'Nội dung',
                  ),
                  onChanged: (v) => change(() => body = v.trim()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: body.isEmpty ? null : () => Navigator.pop(c, true),
              child: const Text('Đăng'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    final r = widget.repo;
    final id = r.db.ref().push().key!;
    await socialAction(context, () async {
      await r.rest.request(r.uid, 'PATCH', '', {
        if (story) 'storyIndex/$id': ServerValue.timestamp,
        'feedMedia/${story ? 'stories' : 'posts'}/$id': ?photo,
        '${story ? 'stories' : 'posts'}/$id': {
          'author': r.uid,
          'text': body,
          'style': style,
          if (bold) 'bold': true,
          if (italic) 'italic': true,
          if (photo != null) 'hasImage': true,
          'createdAt': ServerValue.timestamp,
        },
      });
    });
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final (value, label) in [
            (false, 'Bài đăng'),
            (true, 'Story 24 giờ'),
          ])
            ChoiceChip(
              label: Text(label),
              selected: stories == value,
              onSelected: (_) => setState(() {
                stories = value;
                feed = source();
              }),
            ),
          IconButton.filledTonal(
            tooltip: stories ? 'Tạo story' : 'Viết bài',
            onPressed: compose,
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      StreamBuilder(
        key: ValueKey(stories),
        stream: feed,
        builder: (_, s) {
          if (s.hasError) return StatePanel(readableError(s.error));
          final entries = s.data ?? <DataSnapshot>[];
          if (entries.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                stories ? 'Chưa có story hôm nay.' : 'Chưa có bài đăng.',
              ),
            );
          }
          return StreamBuilder(
            stream: profiles,
            builder: (_, p) => Column(
              children: [
                for (final e in entries)
                  Builder(
                    builder: (c) {
                      final post = fields(e.value),
                          author = post['author'] as String,
                          name =
                              fields(fields(p.data)[author])['displayName'] ??
                              'Bạn học';
                      if (stories && post['createdAt'] < cutoff) {
                        return const SizedBox.shrink();
                      }
                      final style = post['style'],
                          body = post['text'] as String;
                      return Card(
                        color: stories
                            ? Theme.of(c).colorScheme.tertiaryContainer
                            : null,
                        child: ListTile(
                          leading: Icon(
                            style == 'question'
                                ? Icons.help_outline
                                : style == 'checklist'
                                ? Icons.checklist
                                : Icons.article_outlined,
                          ),
                          title: Text(
                            '$name · ${timeLabel(post['createdAt'])}',
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (post['hasImage'] == true)
                                FeedPhoto(
                                  key: ValueKey(e.key),
                                  repo: widget.repo,
                                  path:
                                      'feedMedia/${stories ? 'stories' : 'posts'}/${e.key}',
                                ),
                              Text(
                                style == 'checklist'
                                    ? body
                                          .split('\n')
                                          .map((v) => '☐ $v')
                                          .join('\n')
                                    : body,
                                style: TextStyle(
                                  fontWeight: post['bold'] == true
                                      ? FontWeight.bold
                                      : null,
                                  fontStyle: post['italic'] == true
                                      ? FontStyle.italic
                                      : null,
                                ),
                              ),
                            ],
                          ),
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/profile',
                            arguments: author,
                          ),
                          trailing: author != widget.repo.uid
                              ? null
                              : IconButton(
                                  tooltip: 'Xóa bài của tôi',
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => socialAction(c, () async {
                                    final yes = await showDialog<bool>(
                                      context: c,
                                      builder: (d) => AlertDialog(
                                        title: const Text('Xóa bài này?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(d),
                                            child: const Text('Hủy'),
                                          ),
                                          FilledButton(
                                            onPressed: () =>
                                                Navigator.pop(d, true),
                                            child: const Text('Xóa'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (yes == true) {
                                      await widget.repo.rest.request(
                                        widget.repo.uid,
                                        'PATCH',
                                        '',
                                        {
                                          '${stories ? 'stories' : 'posts'}/${e.key}':
                                              null,
                                          if (stories)
                                            'storyIndex/${e.key}': null,
                                          if (post['hasImage'] == true)
                                            'feedMedia/${stories ? 'stories' : 'posts'}/${e.key}':
                                                null,
                                        },
                                      );
                                    }
                                  }),
                                ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    ],
  );
}
