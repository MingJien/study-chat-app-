import 'package:flutter/material.dart';

import '../data/room_repository.dart';
import '../data/theme_controller.dart';
import '../domain/study_room_models.dart';
import 'member_avatar.dart';
import 'study_community_decorations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.themeController,
    required this.currentUserId,
    this.currentUserProfile,
    this.repository,
    this.onOpenProfile,
    this.onSignOut,
  });

  final ThemeController themeController;
  final String currentUserId;
  final UserProfile? currentUserProfile;
  final RoomRepository? repository;
  final OpenUserProfile? onOpenProfile;
  final Future<void> Function()? onSignOut;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _busy = false;
  bool _confirming = false;

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
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

  Future<void> _openProfile() => _perform(() async {
    final openProfile = widget.onOpenProfile;
    if (openProfile == null) {
      _message(
        'Bản preview chưa hỗ trợ mở hồ sơ. Chờ tích hợp ProfileScreen TV1.',
      );
      return;
    }
    await openProfile(uid: widget.currentUserId);
  });

  Future<void> _selectTheme(ThemeMode mode) async {
    if (_busy || _confirming || widget.themeController.isSaving) return;
    final ok = await widget.themeController.setThemeMode(mode);
    if (!ok && mounted) {
      _message(
        widget.themeController.lastError ??
            'Không thể lưu chế độ giao diện. Vui lòng thử lại.',
      );
    }
  }

  Future<void> _signOut() async {
    if (_busy || _confirming) return;
    setState(() => _confirming = true);
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Đăng xuất?'),
          content: const Text('Bạn sẽ quay lại màn hình đăng nhập.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xác nhận đăng xuất'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      await _perform(() async {
        final onSignOut = widget.onSignOut;
        if (onSignOut == null) {
          _message('Bản preview chưa hỗ trợ đăng xuất. Chờ tích hợp Auth TV1.');
          return;
        }
        await onSignOut();
      });
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile =
        widget.currentUserProfile ??
        widget.repository?.profileOf(widget.currentUserId);
    final displayName =
        profile?.displayName ??
        widget.repository?.displayNameOf(widget.currentUserId) ??
        'Người dùng ẩn danh';
    final avatarId = profile?.avatarId ?? UserProfile.defaultAvatarId;

    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.themeController,
          builder: (context, child) {
            final currentMode = widget.themeController.themeMode;
            final disabled =
                _busy || _confirming || widget.themeController.isSaving;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: studyCommunityCardDecoration(theme),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
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
                                  displayName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Tài khoản sinh viên',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: disabled ? null : _openProfile,
                        icon: const Icon(Icons.person_outline),
                        label: const Text('Xem hồ sơ'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Giao diện ứng dụng',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: studyCommunityCardDecoration(theme),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      _ThemeOptionRow(
                        mode: ThemeMode.system,
                        label: 'Theo hệ thống',
                        subtitle: 'Tự động theo cài đặt Android',
                        selected: currentMode == ThemeMode.system,
                        disabled: disabled,
                        onTap: () => _selectTheme(ThemeMode.system),
                      ),
                      const Divider(height: 1),
                      _ThemeOptionRow(
                        mode: ThemeMode.light,
                        label: 'Chế độ sáng',
                        subtitle: 'Nền sáng, dễ đọc ban ngày',
                        selected: currentMode == ThemeMode.light,
                        disabled: disabled,
                        onTap: () => _selectTheme(ThemeMode.light),
                      ),
                      const Divider(height: 1),
                      _ThemeOptionRow(
                        mode: ThemeMode.dark,
                        label: 'Chế độ tối',
                        subtitle: 'Dịu mắt khi học buổi tối',
                        selected: currentMode == ThemeMode.dark,
                        disabled: disabled,
                        onTap: () => _selectTheme(ThemeMode.dark),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: disabled ? null : _signOut,
                  icon: const Icon(Icons.logout),
                  label: const Text('Đăng xuất'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ThemeOptionRow extends StatelessWidget {
  const _ThemeOptionRow({
    required this.mode,
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  final ThemeMode mode;
  final String label;
  final String subtitle;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: disabled ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                    Text(
                      subtitle,
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
      ),
    );
  }
}
