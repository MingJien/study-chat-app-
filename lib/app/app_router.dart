import 'package:flutter/material.dart';

import '../features/realtime_chat/data/chat_repository.dart';
import '../features/realtime_chat/domain/chat.dart';
import '../features/realtime_chat/presentation/chat_screen.dart';
import '../features/realtime_chat/presentation/chat_widgets.dart';
import 'app_shell.dart';
import 'chat_directory.dart';

class AppRouter {
  AppRouter(this.repo, this.changeTheme, this.logout);
  final ChatRepository repo;
  final VoidCallback changeTheme, logout;
  Route<dynamic> route(RouteSettings settings) => MaterialPageRoute(
    settings: settings,
    builder: (_) {
      final args = settings.arguments;
      const tabs = {
        '/': 2,
        '/chats': 2,
        '/home': 0,
        '/rooms': 1,
        '/contacts': 3,
        '/settings': 4,
      };
      final tab = tabs[settings.name];
      if (tab != null) {
        return AppShell(
          repo,
          changeTheme: changeTheme,
          logout: logout,
          initialTab: tab,
        );
      }
      if (settings.name == '/profile' && args is String) {
        return PublicProfile(repo, args);
      }
      if (settings.name == '/chat' && args is ChatArgs) {
        if (args.summary != null) return ChatScreen(repo, args.summary!);
        return _OpenChat(repo, args);
      }
      return const Scaffold(body: StatePanel('Đường dẫn không hợp lệ.'));
    },
  );
}

class _OpenChat extends StatefulWidget {
  const _OpenChat(this.repo, this.args);
  final ChatRepository repo;
  final ChatArgs args;
  @override
  State<_OpenChat> createState() => _OpenChatState();
}

class _OpenChatState extends State<_OpenChat> {
  late var chat = open();
  Future<ChatSummary> open() async {
    final repo = widget.repo, peer = widget.args.peerUid;
    if (peer != null) {
      final id = await repo.openDirectConversation(peer);
      final profile = fields(
        await repo.rest.request(repo.uid, 'GET', 'profiles/$peer'),
      );
      return ChatSummary(
        id: id,
        title: profile['displayName'] as String? ?? peer,
        peerUid: peer,
        avatar: profile['avatarId'] as String? ?? '',
      );
    }
    final id = widget.args.roomId;
    if (id == null || !id.startsWith('room_')) {
      throw const ChatFailure('Mã phòng không hợp lệ.');
    }
    final room = fields(await repo.rest.request(repo.uid, 'GET', 'rooms/$id'));
    return ChatSummary(id: id, title: room['roomName'] as String? ?? id);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: chat,
    builder: (_, s) => s.hasData
        ? ChatScreen(widget.repo, s.requireData)
        : Scaffold(
            appBar: AppBar(),
            body: s.hasError
                ? StatePanel(
                    readableError(s.error),
                    action: TextButton(
                      onPressed: () => setState(() => chat = open()),
                      child: const Text('Thử lại'),
                    ),
                  )
                : const Center(child: CircularProgressIndicator()),
          ),
  );
}
