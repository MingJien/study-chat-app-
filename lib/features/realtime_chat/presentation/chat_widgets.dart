import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../domain/chat.dart';

String readableError(Object? error) {
  if (error is ChatFailure) return error.message;
  if (error is FirebaseException) {
    return switch (error.code.toLowerCase().replaceAll('_', '-')) {
      'permission-denied' => 'Bạn không còn quyền truy cập dữ liệu này.',
      'email-already-in-use' => 'Email này đã được đăng ký.',
      'invalid-email' => 'Email chưa đúng định dạng.',
      'weak-password' => 'Mật khẩu phải có ít nhất 6 ký tự.',
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' => 'Email hoặc mật khẩu chưa đúng.',
      'network-request-failed' =>
        'Chưa kết nối được Firebase. Kiểm tra mạng hoặc Firebase Emulator.',
      _ => 'Firebase chưa hoàn thành thao tác. Hãy thử lại.',
    };
  }
  return 'Không tải được dữ liệu. Kiểm tra kết nối rồi thử lại.';
}

String timeLabel(int ms, {bool full = false}) {
  if (ms == 0) return '';
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  final now = DateTime.now();
  final hm =
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  if (!full && DateUtils.isSameDay(d, now)) return hm;
  return '${d.day}/${d.month}${full ? ' · $hm' : ''}';
}

class ChatAvatar extends StatelessWidget {
  const ChatAvatar(
    this.name, {
    super.key,
    this.group = false,
    this.online = false,
    this.avatar = '',
  });
  final String name, avatar;
  final bool group, online;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList();
    final initials = words.isEmpty
        ? '?'
        : '${words.first.characters.first}${words.length > 1 ? words.last.characters.first : ''}'
              .toUpperCase();
    final alt =
        avatar.isNotEmpty && avatar.codeUnits.fold(0, (a, b) => a + b).isOdd;
    return Stack(
      children: [
        CircleAvatar(
          backgroundColor: group || alt
              ? colors.tertiaryContainer
              : colors.secondaryContainer,
          foregroundColor: group || alt
              ? colors.onTertiaryContainer
              : colors.onSecondaryContainer,
          child: group
              ? const Icon(Icons.forum_outlined)
              : Text(
                  initials,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
        ),
        if (online)
          Positioned(
            right: 0,
            bottom: 0,
            child: Semantics(
              label: 'Đang trực tuyến',
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green,
                  border: Border.all(color: colors.surface, width: 2),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class StatePanel extends StatelessWidget {
  const StatePanel(
    this.text, {
    super.key,
    this.icon = Icons.chat_bubble_outline,
    this.action,
  });
  final String text;
  final IconData icon;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 36, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 14),
          Text(text, textAlign: TextAlign.center),
          if (action != null)
            Padding(padding: const EdgeInsets.only(top: 12), child: action),
        ],
      ),
    ),
  );
}

class ChatArgs {
  const ChatArgs.direct(this.peerUid) : roomId = null, summary = null;
  const ChatArgs.room(this.roomId) : peerUid = null, summary = null;
  const ChatArgs.existing(this.summary) : peerUid = null, roomId = null;
  final String? peerUid, roomId;
  final ChatSummary? summary;
}
