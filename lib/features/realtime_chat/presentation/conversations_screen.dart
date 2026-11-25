import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

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
  bool archived = false, pinned = false;
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
                  selected: !archived && !pinned && filter == value,
                  onSelected: (_) => setState(() {
                    filter = value;
                    archived = false;
                    pinned = false;
                  }),
                ),
              ChoiceChip(
                label: const Text("Đã ghim"),
                selected: pinned,
                onSelected: (_) => setState(() {
                  pinned = true;
                  archived = false;
                  filter = null;
                }),
              ),
              ChoiceChip(
                label: const Text("Lưu trữ"),
                selected: archived,
                onSelected: (_) => setState(() {
                  archived = true;
                  pinned = false;
                  filter = null;
                }),
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
                        r.archived == archived &&
                        (!pinned || r.pinned) &&
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
                      trailing: PopupMenuButton<String>(
                        tooltip: 'Quản lý hội thoại',
                        onSelected: (action) async {
                          try {
                            if (action == 'clear') {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (c) => AlertDialog(
                                  title: const Text('Xóa lịch sử ở phía bạn?'),
                                  content: const Text(
                                    'Tin mới sau thời điểm này vẫn xuất hiện.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(c),
                                      child: const Text('Hủy'),
                                    ),
                                    FilledButton(
                                      onPressed: () => Navigator.pop(c, true),
                                      child: const Text('Xóa lịch sử'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                await widget.repo.preference(
                                  r.id,
                                  'clearedAt',
                                  ServerValue.timestamp,
                                );
                              }
                            } else {
                              await widget.repo.preference(
                                r.id,
                                action,
                                action == 'pinned'
                                    ? (r.pinned ? null : true)
                                    : (r.archived ? null : true),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(readableError(e))),
                              );
                            }
                          }
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'pinned',
                            child: Text(
                              r.pinned ? 'Bỏ ghim hội thoại' : 'Ghim hội thoại',
                            ),
                          ),
                          PopupMenuItem(
                            value: 'archived',
                            child: Text(
                              r.archived
                                  ? 'Đưa về hộp thư'
                                  : 'Lưu trữ hội thoại',
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'clear',
                            child: Text('Xóa hội thoại phía tôi'),
                          ),
                        ],
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
