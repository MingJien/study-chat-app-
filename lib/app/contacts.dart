import 'package:flutter/material.dart';

import '../features/realtime_chat/data/chat_repository.dart';
import '../features/realtime_chat/domain/chat.dart';
import '../features/realtime_chat/presentation/chat_widgets.dart';
import 'chat_directory.dart';

Future<void> socialAction(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(readableError(e))));
    }
  }
}

class ContactButton extends StatefulWidget {
  const ContactButton(this.repo, this.peer, {super.key});
  final ChatRepository repo;
  final String peer;
  @override
  State<ContactButton> createState() => _ContactButtonState();
}

class _ContactButtonState extends State<ContactButton> {
  late final state = widget.repo.value(
    'contacts/${widget.repo.uid}/${widget.peer}',
  );
  Future<void> update(String? mine, String? theirs) async {
    final r = widget.repo, p = widget.peer;
    await r.rest.request(r.uid, 'PATCH', '', {
      'contacts/${r.uid}/$p': mine,
      'contacts/$p/${r.uid}': theirs,
    });
  }

  @override
  Widget build(BuildContext context) => StreamBuilder(
    stream: state,
    builder: (context, s) {
      final status = s.data;
      if (s.hasError) return Text(readableError(s.error));
      if (s.connectionState == ConnectionState.waiting) {
        return const LinearProgressIndicator();
      }
      return Wrap(
        alignment: WrapAlignment.center,
        children: [
          if (status == null)
            FilledButton.tonal(
              onPressed: () =>
                  socialAction(context, () => update('sent', 'received')),
              child: const Text('Gửi lời mời kết bạn'),
            ),
          if (status == 'received')
            FilledButton(
              onPressed: () =>
                  socialAction(context, () => update('friends', 'friends')),
              child: const Text('Chấp nhận kết bạn'),
            ),
          if (status != null)
            TextButton(
              onPressed: () => socialAction(context, () async {
                if (status == 'friends') {
                  final yes = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text('Hủy kết bạn?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(c),
                          child: const Text('Giữ lại'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(c, true),
                          child: const Text('Hủy kết bạn'),
                        ),
                      ],
                    ),
                  );
                  if (yes != true) return;
                }
                await update(null, null);
              }),
              child: Text(
                status == 'received'
                    ? 'Từ chối'
                    : status == 'sent'
                    ? 'Rút lời mời'
                    : 'Hủy kết bạn',
              ),
            ),
        ],
      );
    },
  );
}

class ContactsPage extends StatefulWidget {
  const ContactsPage(this.repo, {super.key});
  final ChatRepository repo;
  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  int tab = 0;
  late final links = widget.repo.value('contacts/${widget.repo.uid}');
  late final directory = widget.repo.value('profiles');
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('Tìm bạn')),
            ButtonSegment(value: 1, label: Text('Bạn bè')),
            ButtonSegment(value: 2, label: Text('Lời mời')),
          ],
          selected: {tab},
          onSelectionChanged: (v) => setState(() => tab = v.first),
        ),
      ),
      if (tab == 0)
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            icon: const Icon(Icons.link),
            label: const Text('Mở mã hoặc link mời'),
            onPressed: () async {
              final input = await askText(
                context,
                'Dán mã hoặc liên kết mời',
                350,
              );
              if (input == null || input.isEmpty || !context.mounted) return;
              final id =
                  Uri.tryParse(input)?.queryParameters['invite'] ?? input;
              if (!RegExp(r'^[a-zA-Z0-9_-]{1,128}$').hasMatch(id)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mã mời không hợp lệ.')),
                );
                return;
              }
              await Navigator.pushNamed(context, '/profile', arguments: id);
            },
          ),
        ),
      Expanded(
        child: tab == 0
            ? ChatDirectory(widget.repo, rooms: false)
            : StreamBuilder(
                stream: links,
                builder: (_, s) => StreamBuilder(
                  stream: directory,
                  builder: (_, p) {
                    if (s.hasError || p.hasError) {
                      return StatePanel(readableError(s.error ?? p.error));
                    }
                    final items = fields(s.data).entries.where(
                      (e) => tab == 1
                          ? e.value == 'friends'
                          : e.value != 'friends',
                    );
                    if (items.isEmpty) {
                      return StatePanel(
                        tab == 1 ? 'Chưa có bạn bè.' : 'Chưa có lời mời.',
                      );
                    }
                    return ListView(
                      children: [
                        for (final e in items)
                          ListTile(
                            leading: const Icon(Icons.person),
                            title: Text(
                              fields(fields(p.data)[e.key])['displayName']
                                      as String? ??
                                  'Bạn học',
                            ),
                            subtitle: Text(
                              e.value == 'friends'
                                  ? 'Bạn bè'
                                  : e.value == 'sent'
                                  ? 'Đã gửi lời mời'
                                  : 'Đã gửi lời mời cho bạn',
                            ),
                            onTap: () => Navigator.pushNamed(
                              context,
                              '/profile',
                              arguments: e.key,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
      ),
    ],
  );
}
