import 'package:flutter/material.dart';

import '../data/chat_repository.dart';
import '../domain/chat.dart';
import 'chat_widgets.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen(this.repo, {super.key, required this.onNew});
  final ChatRepository repo;
  final VoidCallback onNew;
  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  late var rows = widget.repo.watchConversations(widget.repo.uid);
  String keyword = '';
  ChatType? filter;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Hội thoại',
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'Trò chuyện mới',
                onPressed: widget.onNew,
                icon: const Icon(Icons.edit_square),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Tìm hội thoại',
            ),
            onChanged: (v) => setState(() => keyword = v.trim().toLowerCase()),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
          child: Row(
            spacing: 8,
            children: [
              for (final (value, name) in [
                (null, 'Tất cả'),
                (ChatType.direct, 'Chat riêng'),
                (ChatType.group, 'Phòng học'),
              ])
                ChoiceChip(
                  label: Text(name),
                  selected: filter == value,
                  onSelected: (_) => setState(() => filter = value),
                ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder(
            stream: rows,
            builder: (_, s) {
              if (s.hasError) {
                return StatePanel(
                  readableError(s.error),
                  action: TextButton(
                    onPressed: () => setState(
                      () => rows = widget.repo.watchConversations(
                        widget.repo.uid,
                      ),
                    ),
                    child: const Text('Thử lại'),
                  ),
                );
              }
              if (!s.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final items = s.data!
                  .where(
                    (r) =>
                        (filter == null || r.type == filter) &&
                        r.title.toLowerCase().contains(keyword),
                  )
                  .toList();
              if (items.isEmpty) {
                return StatePanel(
                  s.data!.isEmpty
                      ? 'Chưa có hội thoại. Chọn một bạn học để gửi tin đầu tiên.'
                      : 'Không tìm thấy hội thoại phù hợp.',
                  action: s.data!.isEmpty
                      ? FilledButton.tonal(
                          onPressed: widget.onNew,
                          child: const Text('Tìm bạn học'),
                        )
                      : null,
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 7),
                itemBuilder: (_, i) {
                  final r = items[i];
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: colors.shadow.withValues(alpha: .05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      leading: ChatAvatar(
                        r.title,
                        group: r.type == ChatType.group,
                        online: r.online,
                        avatar: r.avatar,
                      ),
                      title: Text(
                        r.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        r.last.isEmpty ? 'Chưa có tin nhắn' : r.last,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        timeLabel(r.time),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/chat',
                        arguments: ChatArgs.existing(r),
                      ),
                    ),
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
