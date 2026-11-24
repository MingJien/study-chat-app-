import 'package:flutter/material.dart';

import '../data/room_repository.dart';
import '../domain/study_room_models.dart';
import 'create_room_screen.dart';
import 'room_detail_screen.dart';

class RoomsScreen extends StatefulWidget {
  const RoomsScreen({
    super.key,
    required this.repository,
    required this.currentUserId,
    this.onOpenDiscussion,
  });

  final RoomRepository repository;
  final String currentUserId;
  final OpenRoomDiscussion? onOpenDiscussion;

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.repository.loadRooms();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openCreateRoom() {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => CreateRoomScreen(
          repository: widget.repository,
          currentUserId: widget.currentUserId,
          onOpenDiscussion: widget.onOpenDiscussion,
        ),
      ),
    );
  }

  void _openRoom(StudyRoom room) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => RoomDetailScreen(
          room: room,
          repository: widget.repository,
          currentUserId: widget.currentUserId,
          onOpenDiscussion: widget.onOpenDiscussion,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Khám phá phòng')),
      body: ListenableBuilder(
        listenable: widget.repository,
        builder: (context, child) {
          return switch (widget.repository.loadStatus) {
            RoomsLoadStatus.idle ||
            RoomsLoadStatus.loading => const _LoadingState(),
            RoomsLoadStatus.error => _ErrorState(
              onRetry: widget.repository.loadRooms,
            ),
            RoomsLoadStatus.loaded => _buildLoadedContent(),
          };
        },
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: widget.repository,
        builder: (context, child) {
          final showButton =
              widget.repository.loadStatus == RoomsLoadStatus.loaded &&
              widget.repository.rooms.isNotEmpty;
          if (!showButton) return const SizedBox.shrink();

          return SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Tạo phòng'),
              onPressed: _openCreateRoom,
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadedContent() {
    if (widget.repository.rooms.isEmpty) {
      return _EmptyState(onCreateRoom: _openCreateRoom);
    }

    final rooms = widget.repository.searchRooms(_searchController.text);
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm phòng theo tên hoặc môn học',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Xóa từ khóa',
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      ),
              ),
              textInputAction: TextInputAction.search,
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: rooms.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Không tìm thấy phòng phù hợp',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                    itemCount: rooms.length,
                    itemBuilder: (context, index) {
                      return _RoomCard(
                        room: rooms[index],
                        repository: widget.repository,
                        currentUserId: widget.currentUserId,
                        onTap: () => _openRoom(rooms[index]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({
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
    final roleLabel = switch (membership?.role) {
      RoomRole.owner => 'Chủ phòng',
      RoomRole.member => 'Đã tham gia',
      null => null,
    };

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(height: 6),
                Text(
                  room.subject,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              if (room.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  room.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Người tạo: ${repository.creatorNameOf(room)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                  if (roleLabel != null)
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
                        roleLabel,
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

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Đang tải danh sách phòng...'),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreateRoom});

  final VoidCallback onCreateRoom;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.meeting_room_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            const Text('Chưa có phòng học', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onCreateRoom,
              icon: const Icon(Icons.add),
              label: const Text('Tạo phòng'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

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
              'Không thể tải danh sách phòng.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Kiểm tra kết nối và thử lại.',
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
