import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../features/realtime_chat/data/chat_repository.dart';
import '../features/realtime_chat/domain/chat.dart';
import '../features/realtime_chat/presentation/chat_widgets.dart';
import 'contacts.dart';

class CommunityFeed extends StatefulWidget {
  const CommunityFeed(this.repo, {super.key});
  final ChatRepository repo;
  @override
  State<CommunityFeed> createState() => _CommunityFeedState();
}

class _CommunityFeedState extends State<CommunityFeed> {
  bool stories = false;
  late Stream<DatabaseEvent> feed = source();
  late final profiles = widget.repo.value('profiles');
  late final Timer timer;
  int get cutoff =>
      DateTime.now().subtract(const Duration(hours: 24)).millisecondsSinceEpoch;
  Stream<DatabaseEvent> source() {
    Query q = widget.repo.db
        .ref(stories ? 'stories' : 'posts')
        .orderByChild('createdAt');
    if (stories) q = q.startAt(cutoff);
    return q.limitToLast(50).onValue;
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
    var style = 'note', body = '';
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
                TextField(
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
    await socialAction(
      context,
      () => r.write('${story ? 'stories' : 'posts'}/${r.db.ref().push().key}', {
        'author': r.uid,
        'text': body,
        'style': style,
        'createdAt': ServerValue.timestamp,
      }),
    );
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
          final entries =
              s.data?.snapshot.children.toList().reversed.toList() ?? [];
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
                          subtitle: Text(
                            style == 'checklist'
                                ? body.split('\n').map((v) => '☐ $v').join('\n')
                                : body,
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
                                      await widget.repo.write(
                                        '${stories ? 'stories' : 'posts'}/${e.key}',
                                        null,
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
