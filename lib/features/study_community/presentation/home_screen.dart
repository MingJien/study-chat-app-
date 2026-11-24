import 'package:flutter/material.dart';

import '../data/room_repository.dart';
import '../domain/study_room_models.dart';
import 'member_avatar.dart';
import 'room_detail_screen.dart';
import 'rooms_screen.dart';
import 'study_community_decorations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.repository,
    required this.currentUserId,
    this.currentUserProfile,
    this.recentConversations = const [],
    this.onNavigateToRooms,
    this.onNavigateToChats,
    this.onNavigateToContacts,
    this.onNavigateToProfile,
    this.onNavigateToSettings,
    this.onOpenDiscussion,
    this.onOpenProfile,
    this.onOpenDirectMessage,
    this.onOpenConversation,
  });

  final RoomRepository repository;
  final String currentUserId;
  final UserProfile? currentUserProfile;
  final List<RecentConversationSummary> recentConversations;
  final VoidCallback? onNavigateToRooms;
  final VoidCallback? onNavigateToChats;
  final VoidCallback? onNavigateToContacts;
  final VoidCallback? onNavigateToProfile;
  final VoidCallback? onNavigateToSettings;
  final OpenRoomDiscussion? onOpenDiscussion;
  final OpenUserProfile? onOpenProfile;
  final OpenDirectMessage? onOpenDirectMessage;
  final OpenConversationSummary? onOpenConversation;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.repository.loadStatus == RoomsLoadStatus.idle) {
      widget.repository.loadRooms();
    }
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  void _openRooms() {
    final navigate = widget.onNavigateToRooms;
    if (navigate != null) {
      navigate();
      return;
    }
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => RoomsScreen(
          repository: widget.repository,
          currentUserId: widget.currentUserId,
          onOpenDiscussion: widget.onOpenDiscussion,
          onOpenProfile: widget.onOpenProfile,
          onOpenDirectMessage: widget.onOpenDirectMessage,
        ),
      ),
    );
  }

  void _openRoomDetail(StudyRoom room) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => RoomDetailScreen(
          room: room,
          repository: widget.repository,
          currentUserId: widget.currentUserId,
          onOpenDiscussion: widget.onOpenDiscussion,
          onOpenProfile: widget.onOpenProfile,
          onOpenDirectMessage: widget.onOpenDirectMessage,
        ),
      ),
    );
  }

  void _invokeOrPreview(VoidCallback? callback, String previewMessage) {
    if (callback != null) {
      callback();
      return;
    }
    _message(previewMessage);
  }

  Future<void> _openConversation(RecentConversationSummary summary) async {
    final open = widget.onOpenConversation;
    if (open == null) {
      _message(
        'Bản preview chưa hỗ trợ mở hội thoại. Chờ tích hợp ChatScreen TV2.',
      );
      return;
    }
    try {
      await open(summary);
    } catch (_) {
      _message('Không thể mở hội thoại. Vui lòng thử lại.');
    }
  }

  bool _isJoinedOrOwned(StudyRoom room) {
    return room.ownerId == widget.currentUserId ||
        widget.repository.memberOf(room.roomId, widget.currentUserId) != null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile =
        widget.currentUserProfile ??
        widget.repository.profileOf(widget.currentUserId);
    final displayName =
        profile?.displayName ??
        widget.repository.displayNameOf(widget.currentUserId);
    final avatarId = profile?.avatarId ?? UserProfile.defaultAvatarId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang chủ'),
        actions: [
          IconButton(
            tooltip: 'Cài đặt',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _invokeOrPreview(
              widget.onNavigateToSettings,
              'Bản preview chưa nối màn hình Cài đặt.',
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.repository,
          builder: (context, child) {
            return switch (widget.repository.loadStatus) {
              RoomsLoadStatus.idle ||
              RoomsLoadStatus.loading => const _HomeLoadingState(),
              RoomsLoadStatus.error => _HomeErrorState(
                onRetry: widget.repository.loadRooms,
              ),
              RoomsLoadStatus.loaded => _buildLoaded(
                theme,
                displayName: displayName,
                avatarId: avatarId,
              ),
            };
          },
        ),
      ),
    );
  }

  Widget _buildLoaded(
    ThemeData theme, {
    required String displayName,
    required String avatarId,
  }) {
    final allRooms = widget.repository.rooms;
    final joinedRooms = allRooms.where(_isJoinedOrOwned).toList();
    final featuredRooms = allRooms
        .where((room) => !_isJoinedOrOwned(room))
        .take(3)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: studyCommunityCardDecoration(theme, highlighted: true),
          child: Row(
            children: [
              MemberAvatar(
                avatarId: avatarId,
                displayName: displayName,
                radius: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Xin chào, $displayName',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Không gian học tập của bạn',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _openRooms,
              icon: const Icon(Icons.school_outlined, size: 18),
              label: const Text('Phòng học'),
            ),
            OutlinedButton.icon(
              onPressed: () => _invokeOrPreview(
                widget.onNavigateToChats,
                'Bản preview chưa nối danh sách Tin nhắn TV2.',
              ),
              icon: const Icon(Icons.chat_outlined, size: 18),
              label: const Text('Tin nhắn'),
            ),
            OutlinedButton.icon(
              onPressed: () => _invokeOrPreview(
                widget.onNavigateToContacts,
                'Bản preview chưa nối danh bạ Bạn học TV1.',
              ),
              icon: const Icon(Icons.contacts_outlined, size: 18),
              label: const Text('Bạn học'),
            ),
            OutlinedButton.icon(
              onPressed: () => _invokeOrPreview(
                widget.onNavigateToProfile,
                'Bản preview chưa nối màn hình Cá nhân TV1.',
              ),
              icon: const Icon(Icons.person_outline, size: 18),
              label: const Text('Cá nhân'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Phòng đã tham gia',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (joinedRooms.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: studyCommunityCardDecoration(theme),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Bạn chưa tham gia phòng học nào'),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _openRooms,
                  icon: const Icon(Icons.explore_outlined),
                  label: const Text('Khám phá phòng'),
                ),
              ],
            ),
          )
        else
          for (final room in joinedRooms) ...[
            _HomeRoomTile(
              room: room,
              repository: widget.repository,
              currentUserId: widget.currentUserId,
              onTap: () => _openRoomDetail(room),
            ),
            const SizedBox(height: 8),
          ],
        const SizedBox(height: 16),
        Text(
          'Phòng mới & nổi bật',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (featuredRooms.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: studyCommunityCardDecoration(theme),
            child: const Text('Bạn đã tham gia tất cả phòng hiện có.'),
          )
        else
          for (final room in featuredRooms) ...[
            _HomeRoomTile(
              room: room,
              repository: widget.repository,
              currentUserId: widget.currentUserId,
              onTap: () => _openRoomDetail(room),
            ),
            const SizedBox(height: 8),
          ],
        const SizedBox(height: 16),
        Text(
          'Hội thoại gần đây',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (widget.recentConversations.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: studyCommunityCardDecoration(theme),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Chưa có hội thoại gần đây.'),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _invokeOrPreview(
                    widget.onNavigateToChats,
                    'Bản preview chưa nối danh sách Tin nhắn TV2.',
                  ),
                  icon: const Icon(Icons.chat_outlined),
                  label: const Text('Mở Tin nhắn'),
                ),
              ],
            ),
          )
        else
          for (final conversation in widget.recentConversations) ...[
            _ConversationTile(
              conversation: conversation,
              onTap: () => _openConversation(conversation),
            ),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}

class _HomeRoomTile extends StatelessWidget {
  const _HomeRoomTile({
    required this.room,
    required this.repository,
    required this.currentUserId,
    required this.onTap,
  });

  final StudyRoom room;
  final RoomRepository repository;
  final String currentUserId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final membership = repository.memberOf(room.roomId, currentUserId);
    final isOwner =
        room.ownerId == currentUserId || membership?.role == RoomRole.owner;
    final badge = isOwner
        ? 'Chủ phòng'
        : membership != null
        ? 'Đã tham gia'
        : null;

    return Container(
      decoration: studyCommunityCardDecoration(theme),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      room.roomName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right),
                ],
              ),
              if (room.subject.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  room.subject,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '${repository.memberCountOf(room.roomId)} thành viên',
                    style: theme.textTheme.bodySmall,
                  ),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        badge,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation, required this.onTap});

  final RecentConversationSummary conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: studyCommunityCardDecoration(theme),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              MemberAvatar(
                avatarId: conversation.avatarId,
                displayName: conversation.title,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conversation.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      conversation.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  conversation.isGroup ? 'Nhóm' : 'Cá nhân',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeLoadingState extends StatelessWidget {
  const _HomeLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Đang tải trang chủ...'),
        ],
      ),
    );
  }
}

class _HomeErrorState extends StatelessWidget {
  const _HomeErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            const Text(
              'Không thể tải dữ liệu trang chủ.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
