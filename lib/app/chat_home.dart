import 'package:flutter/material.dart';

import 'community_feed.dart';

import '../features/realtime_chat/data/chat_repository.dart';
import '../features/realtime_chat/domain/chat.dart';
import '../features/realtime_chat/presentation/chat_widgets.dart';

class ChatHome extends StatefulWidget {
  const ChatHome(this.repo, this.selectTab, {super.key});
  final ChatRepository repo;
  final ValueChanged<int> selectTab;
  @override
  State<ChatHome> createState() => _ChatHomeState();
}

class _ChatHomeState extends State<ChatHome> {
  late final rows = widget.repo.watchConversations(widget.repo.uid);
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Text(
        'Không gian học tập',
        style: Theme.of(context).textTheme.headlineMedium
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          FilledButton.tonalIcon(
            onPressed: () => widget.selectTab(1),
            icon: const Icon(Icons.school_outlined),
            label: const Text('Khám phá phòng'),
          ),
          FilledButton.tonalIcon(
            onPressed: () => widget.selectTab(3),
            icon: const Icon(Icons.people_outline),
            label: const Text('Tìm bạn học'),
          ),
        ],
      ),
      const SizedBox(height: 24),
      CommunityFeed(widget.repo),
      const SizedBox(height: 24),
      Text('Hội thoại gần đây', style: Theme.of(context).textTheme.titleLarge),
      StreamBuilder(
        stream: rows,
        builder: (_, s) {
          if (s.hasError) return StatePanel(readableError(s.error));
          if (!s.hasData) return const LinearProgressIndicator();
          if (s.requireData.isEmpty) {
            return const StatePanel(
              'Tham gia phòng học hoặc nhắn tin với một bạn học để bắt đầu.',
            );
          }
          return Column(
            children: [
              for (final r in s.requireData.where((r) => !r.archived).take(5))
                ListTile(
                  leading: ChatAvatar(
                    r.title,
                    group: r.type == ChatType.group,
                    online: r.online,
                  ),
                  title: Text(r.title),
                  subtitle: Text(
                    r.last,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/chat',
                    arguments: ChatArgs.existing(r),
                  ),
                ),
            ],
          );
        },
      ),
    ],
  );
}
