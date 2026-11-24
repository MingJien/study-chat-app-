import 'package:flutter/material.dart';

import '../data/room_repository.dart';
import '../domain/study_room_models.dart';
import 'room_members_screen.dart';

class RoomDetailScreen extends StatefulWidget {
  const RoomDetailScreen({
    super.key,
    required this.room,
    required this.repository,
    required this.currentUserId,
    this.onOpenDiscussion,
    this.onOpenProfile,
    this.onOpenDirectMessage,
  });

  final StudyRoom room;
  final RoomRepository repository;
  final String currentUserId;
  final OpenRoomDiscussion? onOpenDiscussion;
  final OpenUserProfile? onOpenProfile;
  final OpenDirectMessage? onOpenDirectMessage;

  RoomMember? get creator => repository.memberOf(room.roomId, room.ownerId);

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  bool _busy = false;
  bool _confirming = false;

  bool get _locked => _busy || _confirming;

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
    } on RoomMembershipException catch (error) {
      _message(error.message);
    } catch (_) {
      _message('Không thể thực hiện thao tác. Vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _leave() async {
    if (_locked) return;
    setState(() => _confirming = true);
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Rời phòng?'),
          content: const Text(
            'Sau khi rời phòng, bạn cần tham gia lại để vào thảo luận.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xác nhận rời phòng'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      await _perform(
        () => widget.repository.leaveRoom(
          widget.room.roomId,
          currentUserId: widget.currentUserId,
        ),
      );
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  Future<void> _openDiscussion() => _perform(() async {
    widget.repository.requireMembership(
      widget.room.roomId,
      currentUserId: widget.currentUserId,
    );
    final open = widget.onOpenDiscussion;
    if (open == null) {
      _message('Bản preview chưa hỗ trợ mở chat. Chờ tích hợp ChatScreen TV2.');
      return;
    }
    await open(roomId: widget.room.roomId, type: 'group');
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết phòng')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.repository,
          builder: (context, child) {
            final repository = widget.repository;
            final room = repository.roomOf(widget.room.roomId);
            if (room == null) {
              return const Center(child: Text('Phòng không còn tồn tại.'));
            }
            final member = repository.memberOf(
              room.roomId,
              widget.currentUserId,
            );
            final isOwner =
                room.ownerId == widget.currentUserId ||
                member?.role == RoomRole.owner;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(room.roomName, style: theme.textTheme.headlineMedium),
                if (room.subject.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Môn học', style: theme.textTheme.titleSmall),
                  Text(room.subject),
                ],
                if (room.description.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Mô tả', style: theme.textTheme.titleSmall),
                  Text(room.description),
                ],
                const SizedBox(height: 24),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Người tạo'),
                  subtitle: Text(repository.creatorNameOf(room)),
                  trailing: const Text('Chủ phòng'),
                ),
                Text('${repository.memberCountOf(room.roomId)} thành viên'),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _locked
                      ? null
                      : () {
                          Navigator.of(context).push<void>(
                            MaterialPageRoute(
                              builder: (context) => RoomMembersScreen(
                                room: room,
                                repository: repository,
                                currentUserId: widget.currentUserId,
                                onOpenProfile: widget.onOpenProfile,
                                onOpenDirectMessage: widget.onOpenDirectMessage,
                              ),
                            ),
                          );
                        },
                  icon: const Icon(Icons.group_outlined),
                  label: const Text('Xem thành viên'),
                ),
                const SizedBox(height: 16),
                if (isOwner) const Text('Bạn là chủ phòng'),
                if (member != null && !isOwner) const Text('Đã tham gia'),
                const SizedBox(height: 8),
                if (member == null && !isOwner)
                  FilledButton(
                    onPressed: _locked
                        ? null
                        : () => _perform(
                            () => repository.joinRoom(
                              room.roomId,
                              currentUserId: widget.currentUserId,
                            ),
                          ),
                    child: const Text('Tham gia phòng'),
                  ),
                if (member != null || isOwner)
                  FilledButton(
                    onPressed: _locked ? null : _openDiscussion,
                    child: const Text('Vào thảo luận'),
                  ),
                if (member != null && !isOwner)
                  TextButton(
                    onPressed: _locked ? null : _leave,
                    child: const Text('Rời phòng'),
                  ),
                if (_busy) ...[
                  const SizedBox(height: 12),
                  const Center(child: CircularProgressIndicator()),
                  const Center(child: Text('Đang xử lý...')),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
