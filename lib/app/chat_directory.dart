import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'contacts.dart';

import '../features/realtime_chat/data/chat_repository.dart';
import '../features/realtime_chat/domain/chat.dart';
import '../features/realtime_chat/presentation/chat_widgets.dart';

Future<String?> askText(BuildContext context, String title, int limit) async {
  var text = '';
  return showDialog<String>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: TextField(
        autofocus: true,
        maxLength: limit,
        onChanged: (v) => text = v.trim(),
        onSubmitted: (v) => Navigator.pop(c, v.trim()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text('Hủy')),
        FilledButton(
          onPressed: () => Navigator.pop(c, text),
          child: const Text('Lưu'),
        ),
      ],
    ),
  );
}

/// Integration entry points backed by TV1 profiles and TV3 rooms on the TV2 branch.
class ChatDirectory extends StatefulWidget {
  const ChatDirectory(this.repo, {super.key, required this.rooms});
  final ChatRepository repo;
  final bool rooms;
  @override
  State<ChatDirectory> createState() => _ChatDirectoryState();
}

class _ChatDirectoryState extends State<ChatDirectory> {
  late final source = widget.repo.value(widget.rooms ? 'rooms' : 'profiles');
  final memberships = <String, Stream<Object?>>{};
  String search = '';
  bool busy = false;
  Future<void> run(Future<void> Function() task) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      if (!widget.repo.online) {
        throw const ChatFailure('Cần kết nối Firebase để thực hiện thao tác.');
      }
      await task();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(readableError(e))));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> createRoom() async {
    final name = await askText(context, 'Tên phòng học', 60);
    if (name == null || name.isEmpty || !mounted) return;
    final r = widget.repo, id = 'room_${r.db.ref('rooms').push().key}';
    await r.rest.request(r.uid, 'PATCH', '', {
      'rooms/$id': {
        'roomId': id,
        'roomName': name,
        'ownerId': r.uid,
        'subject': name,
        'description': '',
        'createdAt': ServerValue.timestamp,
      },
      'roomMembers/$id/${r.uid}': {'uid': r.uid, 'role': 'owner'},
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = widget.repo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.rooms ? 'Phòng học' : 'Bạn học',
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              if (widget.rooms)
                IconButton.filledTonal(
                  tooltip: 'Tạo phòng',
                  onPressed: busy ? null : () => run(createRoom),
                  icon: const Icon(Icons.add),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: TextField(
            decoration: InputDecoration(
              hintText: widget.rooms ? 'Tìm phòng học' : 'Tìm sinh viên',
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: (v) => setState(() => search = v.trim().toLowerCase()),
          ),
        ),
        Expanded(
          child: StreamBuilder(
            stream: source,
            builder: (_, s) {
              if (s.hasError) return StatePanel(readableError(s.error));
              if (s.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final list = fields(s.data).entries
                  .where(
                    (e) =>
                        e.key != repo.uid &&
                        ((fields(e.value)[widget.rooms
                                        ? 'roomName'
                                        : 'displayName']
                                    as String? ??
                                '')
                            .toLowerCase()
                            .contains(search)),
                  )
                  .toList();
              if (list.isEmpty) {
                return StatePanel(
                  widget.rooms
                      ? 'Chưa tìm thấy phòng học.'
                      : 'Chưa tìm thấy bạn học.',
                  icon: widget.rooms
                      ? Icons.school_outlined
                      : Icons.people_outline,
                );
              }
              return ListView.builder(
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final id = list[i].key, d = fields(list[i].value);
                  if (!widget.rooms) {
                    final name = d['displayName'] as String? ?? id;
                    return ListTile(
                      leading: ChatAvatar(
                        name,
                        avatar: d['avatarId'] as String? ?? '',
                      ),
                      title: Text(name),
                      subtitle: Text(d['className'] as String? ?? 'Sinh viên'),
                      trailing: IconButton(
                        tooltip: 'Nhắn tin với $name',
                        icon: const Icon(Icons.chat_bubble_outline),
                        onPressed: () => Navigator.pushNamed(
                          context,
                          '/chat',
                          arguments: ChatArgs.direct(id),
                        ),
                      ),
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/profile',
                        arguments: id,
                      ),
                    );
                  }
                  final name = d['roomName'] as String,
                      memberPath = 'roomMembers/$id/${repo.uid}';
                  return StreamBuilder(
                    stream: memberships.putIfAbsent(
                      id,
                      () => repo.value(memberPath),
                    ),
                    builder: (_, m) {
                      final joined = m.data != null;
                      final owner = d['ownerId'] == repo.uid;
                      return ListTile(
                        leading: ChatAvatar(name, group: true),
                        title: Text(name),
                        subtitle: Text(
                          joined ? 'Đã tham gia' : 'Phòng công khai',
                        ),
                        onTap: busy
                            ? null
                            : () => run(() async {
                                if (!joined) {
                                  await repo.rest.request(
                                    repo.uid,
                                    'PUT',
                                    memberPath,
                                    {
                                      'uid': repo.uid,
                                      'role': owner ? 'owner' : 'member',
                                    },
                                  );
                                }
                                if (context.mounted) {
                                  await Navigator.pushNamed(
                                    context,
                                    '/chat',
                                    arguments: ChatArgs.room(id),
                                  );
                                }
                              }),
                        trailing: !joined
                            ? const Icon(Icons.group_add_outlined)
                            : PopupMenuButton<String>(
                                tooltip: 'Tùy chọn phòng',
                                onSelected: (v) => run(() async {
                                  if (v == 'rename') {
                                    final name = await askText(
                                      context,
                                      'Tên mới của phòng',
                                      60,
                                    );
                                    if (name != null && name.isNotEmpty) {
                                      await repo.write(
                                        'rooms/$id/roomName',
                                        name,
                                      );
                                    }
                                    return;
                                  }
                                  if (v == 'leave') {
                                    await repo.rest.request(
                                      repo.uid,
                                      'DELETE',
                                      memberPath,
                                    );
                                    return;
                                  }
                                  if (v == 'unpin') {
                                    await repo.rest.request(
                                      repo.uid,
                                      'DELETE',
                                      'roomNotices/$id',
                                    );
                                    return;
                                  }
                                  final content = await askText(
                                    context,
                                    'Thông báo ghim',
                                    300,
                                  );
                                  if (content != null && content.isNotEmpty) {
                                    await repo.rest.request(
                                      repo.uid,
                                      'PUT',
                                      'roomNotices/$id',
                                      {
                                        'roomId': id,
                                        'content': content,
                                        'updatedBy': repo.uid,
                                        'updatedAt': ServerValue.timestamp,
                                      },
                                    );
                                  }
                                }),
                                itemBuilder: (_) => [
                                  if (owner) ...[
                                    const PopupMenuItem(
                                      value: "rename",
                                      child: Text("Đổi tên phòng"),
                                    ),
                                    const PopupMenuItem(
                                      value: 'pin',
                                      child: Text('Ghim thông báo'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'unpin',
                                      child: Text('Bỏ ghim'),
                                    ),
                                  ] else
                                    const PopupMenuItem(
                                      value: 'leave',
                                      child: Text('Rời phòng'),
                                    ),
                                ],
                              ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class PublicProfile extends StatefulWidget {
  const PublicProfile(this.repo, this.uid, {super.key});
  final ChatRepository repo;
  final String uid;
  @override
  State<PublicProfile> createState() => _PublicProfileState();
}

class _PublicProfileState extends State<PublicProfile> {
  late final profile = widget.repo.value('profiles/${widget.uid}');
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Hồ sơ sinh viên')),
    body: StreamBuilder(
      stream: profile,
      builder: (_, s) {
        if (s.hasError) return StatePanel(readableError(s.error));
        if (s.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final p = fields(s.data);
        if (p.isEmpty) return const StatePanel('Không tìm thấy hồ sơ.');
        final name = p['displayName'] as String;
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ChatAvatar(name, avatar: p['avatarId'] as String? ?? ''),
              const SizedBox(height: 12),
              Text(name, style: Theme.of(context).textTheme.headlineSmall),
              if (p['className'] != null) Text(p['className']),
              if (p['bio'] != null) Text(p['bio']),
              if (widget.uid == widget.repo.uid) ...[
                TextButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text('Chỉnh sửa hồ sơ'),
                  onPressed: () async {
                    final field = await showModalBottomSheet<String>(
                      context: context,
                      builder: (c) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final (key, label) in [
                            ('displayName', 'Tên hiển thị'),
                            ('className', 'Lớp học'),
                            ('bio', 'Giới thiệu'),
                          ])
                            ListTile(
                              title: Text(label),
                              onTap: () => Navigator.pop(c, key),
                            ),
                        ],
                      ),
                    );
                    if (field == null || !context.mounted) return;
                    final text = await askText(
                      context,
                      'Cập nhật hồ sơ',
                      field == 'bio' ? 150 : 50,
                    );
                    if (text == null || text.isEmpty || !context.mounted) {
                      return;
                    }
                    await socialAction(context, () async {
                      await widget.repo.write(
                        'profiles/${widget.uid}/$field',
                        text,
                      );
                      if (field == 'displayName') {
                        await widget.repo.auth.currentUser?.updateDisplayName(
                          text,
                        );
                      }
                    });
                  },
                ),
                TextButton.icon(
                  icon: const Icon(Icons.link),
                  label: const Text('Sao chép liên kết kết bạn'),
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(
                        text: !['http', 'https'].contains(Uri.base.scheme)
                            ? widget.uid
                            : Uri.base
                                  .replace(
                                    queryParameters: {'invite': widget.uid},
                                    fragment: '',
                                  )
                                  .toString(),
                      ),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã sao chép liên kết mời.'),
                        ),
                      );
                    }
                  },
                ),
              ] else
                ContactButton(widget.repo, widget.uid),
              if (widget.uid != widget.repo.uid)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      '/chat',
                      arguments: ChatArgs.direct(widget.uid),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Nhắn tin'),
                  ),
                ),
            ],
          ),
        );
      },
    ),
  );
}
