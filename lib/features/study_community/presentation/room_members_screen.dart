import 'package:flutter/material.dart';

import '../data/room_repository.dart';
import '../domain/study_room_models.dart';
import 'member_avatar.dart';

class RoomMembersScreen extends StatefulWidget {
  const RoomMembersScreen({
    super.key,
    required this.room,
    required this.repository,
    required this.currentUserId,
    this.onOpenProfile,
    this.onOpenDirectMessage,
  });

  final StudyRoom room;
  final RoomRepository repository;
  final String currentUserId;
  final OpenUserProfile? onOpenProfile;
  final OpenDirectMessage? onOpenDirectMessage;

  @override
  State<RoomMembersScreen> createState() => _RoomMembersScreenState();
}

class _RoomMembersScreenState extends State<RoomMembersScreen> {
  bool _busy = false;

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _perform(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (_) {
      _message('Không thể thực hiện thao tác. Vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openProfile(String uid) => _perform(() async {
    final openProfile = widget.onOpenProfile;
    if (openProfile == null) {
      _message(
        'Bản preview chưa hỗ trợ mở hồ sơ. Chờ tích hợp ProfileScreen TV1.',
      );
      return;
    }
    await openProfile(uid: uid);
  });

  Future<void> _openDirectMessage(String peerUid) => _perform(() async {
    final openDirectMessage = widget.onOpenDirectMessage;
    if (openDirectMessage == null) {
      _message(
        'Bản preview chưa hỗ trợ nhắn tin riêng. Chờ tích hợp ChatScreen TV2.',
      );
      return;
    }
    await openDirectMessage(peerUid: peerUid);
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Thành viên phòng')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.repository,
          builder: (context, child) {
            final room = widget.repository.roomOf(widget.room.roomId);
            if (room == null) {
              return const Center(child: Text('Phòng không còn tồn tại.'));
            }

            final members = widget.repository.membersOf(room.roomId);
            if (members.isEmpty) {
              return const Center(child: Text('Chưa có thành viên nào.'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: members.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          room.roomName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${members.length} thành viên',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                }

                final member = members[index - 1];
                final isSelf = member.uid == widget.currentUserId;
                final isOwner =
                    member.role == RoomRole.owner || member.uid == room.ownerId;
                final displayName = widget.repository.displayNameOf(member.uid);
                final avatarId = widget.repository.avatarIdOf(member.uid);

                return _MemberCard(
                  displayName: displayName,
                  avatarId: avatarId,
                  isSelf: isSelf,
                  isOwner: isOwner,
                  busy: _busy,
                  onOpenProfile: () => _openProfile(member.uid),
                  onOpenDirectMessage: isSelf
                      ? null
                      : () => _openDirectMessage(member.uid),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.displayName,
    required this.avatarId,
    required this.isSelf,
    required this.isOwner,
    required this.busy,
    required this.onOpenProfile,
    this.onOpenDirectMessage,
  });

  final String displayName;
  final String avatarId;
  final bool isSelf;
  final bool isOwner;
  final bool busy;
  final VoidCallback onOpenProfile;
  final VoidCallback? onOpenDirectMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roleLabel = isOwner ? 'Chủ phòng' : 'Thành viên';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: busy ? null : onOpenProfile,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  MemberAvatar(avatarId: avatarId, displayName: displayName),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isSelf ? '$displayName (Bạn)' : displayName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isOwner
                                ? theme.colorScheme.primaryContainer
                                : theme.colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            roleLabel,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: isOwner
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (!isSelf && onOpenDirectMessage != null) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: busy ? null : onOpenDirectMessage,
                      icon: const Icon(Icons.chat_bubble_outline, size: 18),
                      label: const Text('Nhắn tin'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
