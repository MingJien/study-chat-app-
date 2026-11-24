import 'package:flutter/material.dart';

import '../features/realtime_chat/data/chat_repository.dart';
import '../features/realtime_chat/presentation/conversations_screen.dart';
import 'chat_directory.dart';

class AppShell extends StatefulWidget {
  const AppShell(
    this.repo, {
    super.key,
    required this.changeTheme,
    required this.logout,
  });
  final ChatRepository repo;
  final VoidCallback changeTheme, logout;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int tab = 0;
  @override
  Widget build(BuildContext context) {
    final repo = widget.repo;
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.forum_rounded),
            SizedBox(width: 10),
            Text('Study Chat', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Đổi sáng / tối',
            onPressed: widget.changeTheme,
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Tài khoản',
            onSelected: (v) {
              if (v == 'profile') {
                Navigator.pushNamed(context, '/profile', arguments: repo.uid);
              } else {
                widget.logout();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'profile',
                child: Text('Hồ sơ của tôi'),
              ),
              const PopupMenuItem(value: 'logout', child: Text('Đăng xuất')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 880),
            child: Column(
              children: [
                StreamBuilder(
                  stream: repo.connection,
                  builder: (_, s) => s.data == false
                      ? const ListTile(
                          dense: true,
                          leading: Icon(Icons.cloud_off),
                          title: Text('Ngoại tuyến · Chỉ xem hội thoại đã lưu'),
                        )
                      : const SizedBox.shrink(),
                ),
                Expanded(
                  child: switch (tab) {
                    0 => ConversationsScreen(
                      repo,
                      onNew: () => setState(() => tab = 2),
                    ),
                    _ => ChatDirectory(
                      repo,
                      key: ValueKey(tab),
                      rooms: tab == 1,
                    ),
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Tin nhắn',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: 'Phòng học',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Bạn học',
          ),
        ],
      ),
    );
  }
}
