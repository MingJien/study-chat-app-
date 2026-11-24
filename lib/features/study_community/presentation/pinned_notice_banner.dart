import 'package:flutter/material.dart';

import '../data/room_repository.dart';

/// Reusable pinned notice banner for RoomDetailScreen (TV3) and ChatScreen (TV2).
class PinnedNoticeBanner extends StatelessWidget {
  const PinnedNoticeBanner({
    super.key,
    required this.roomId,
    required this.repository,
    this.trailing,
  });

  final String roomId;
  final RoomRepository repository;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: repository,
      builder: (context, child) {
        final notice = repository.pinnedNoticeOf(roomId);
        if (notice == null) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.45),
            border: Border.all(color: theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.push_pin_outlined,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Thông báo ghim',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ?trailing,
                ],
              ),
              const SizedBox(height: 6),
              Text(notice.content, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 6),
              Text(
                'Cập nhật bởi ${repository.displayNameOf(notice.updatedBy)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
