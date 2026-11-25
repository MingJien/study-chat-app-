import 'dart:async';

import 'package:flutter/material.dart';

import '../features/realtime_chat/domain/chat.dart';
import '../features/realtime_chat/presentation/chat_widgets.dart' show ChatArgs;
import 'contacts.dart';

import '../features/realtime_chat/data/chat_repository.dart';
import '../features/realtime_chat/presentation/conversations_screen.dart';
import 'chat_directory.dart';
import 'chat_home.dart';

class AppShell extends StatefulWidget {
  const AppShell(
    this.repo, {
    super.key,
    required this.changeTheme,
    required this.logout,
    this.initialTab = 2,
  });
  final ChatRepository repo;
  final int initialTab;
  final VoidCallback changeTheme, logout;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int tab = widget.initialTab;
  Map<String, int>? seen;
  late final StreamSubscription<List<ChatSummary>> notices;
  @override
  void initState() {
    super.initState();
    final invite = Uri.base.queryParameters['invite'];
    if (invite != null &&
        invite != widget.repo.uid &&
        RegExp(r'^[a-zA-Z0-9_-]{1,128}$').hasMatch(invite)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushNamed(context, '/profile', arguments: invite);
        }
      });
    }
    notices = widget.repo.watchConversations(widget.repo.uid).listen((rows) {
      if (!mounted || !widget.repo.online) return;
      final old = seen;
      seen = {for (final r in rows) r.id: r.time};
      if (old == null || ModalRoute.of(context)?.isCurrent != true) return;
      for (final r in rows) {
        if (r.time > (old[r.id] ?? 0) &&
            r.lastSender != null &&
            r.lastSender != widget.repo.uid &&
            !r.archived) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tin mới từ ${r.title}'),
              duration: const Duration(seconds: 2),
              action: SnackBarAction(
                label: 'Mở',
                onPressed: () => Navigator.pushNamed(
                  context,
                  '/chat',
                  arguments: ChatArgs.existing(r),
                ),
              ),
            ),
          );
          break;
        }
      }
    }, onError: (Object _) {});
  }

  @override
  void dispose() {
    notices.cancel();
    super.dispose();
  }

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
                    0 => ChatHome(repo, (i) => setState(() => tab = i)),
                    2 => ConversationsScreen(
                      repo,
                      onNew: () => setState(() => tab = 3),
                    ),
                    4 => ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        Text(
                          'Cá nhân',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        ListTile(
                          leading: const Icon(Icons.person_outline),
                          title: Text(
                            repo.auth.currentUser?.displayName ??
                                'Hồ sơ của tôi',
                          ),
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/profile',
                            arguments: repo.uid,
                          ),
                        ),
                        SwitchListTile(
                          title: const Text('Giao diện tối'),
                          value:
                              Theme.of(context).brightness == Brightness.dark,
                          onChanged: (_) => widget.changeTheme(),
                        ),
                        ListTile(
                          leading: const Icon(Icons.logout),
                          title: const Text('Đăng xuất'),
                          onTap: widget.logout,
                        ),
                      ],
                    ),
                    3 => ContactsPage(repo),
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
            icon: Icon(Icons.home_outlined),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: 'Phòng học',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Tin nhắn',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Bạn học',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }
}
