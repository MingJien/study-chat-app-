import 'package:flutter/material.dart';

import '../domain/study_room_models.dart';

class _AvatarPreset {
  const _AvatarPreset({required this.background, required this.foreground});

  final Color background;
  final Color foreground;
}

class MemberAvatar extends StatelessWidget {
  const MemberAvatar({
    super.key,
    required this.avatarId,
    required this.displayName,
    this.radius = 20,
    this.useAssetImage = false,
  });

  final String avatarId;
  final String displayName;
  final double radius;
  final bool useAssetImage;

  static const Map<String, _AvatarPreset> _presets = {
    'avatar_tv3': _AvatarPreset(
      background: Color(0xFFD8E6FF),
      foreground: Color(0xFF1A4B9C),
    ),
    'avatar_linh': _AvatarPreset(
      background: Color(0xFFFCE2E9),
      foreground: Color(0xFF9C2550),
    ),
    'avatar_minh': _AvatarPreset(
      background: Color(0xFFDDF3E4),
      foreground: Color(0xFF1B6B3A),
    ),
    'avatar_1': _AvatarPreset(
      background: Color(0xFFFFE8D6),
      foreground: Color(0xFF9C4212),
    ),
    'avatar_2': _AvatarPreset(
      background: Color(0xFFE9E2FC),
      foreground: Color(0xFF513199),
    ),
    'avatar_3': _AvatarPreset(
      background: Color(0xFFDDF4F7),
      foreground: Color(0xFF0E6470),
    ),
    UserProfile.defaultAvatarId: _AvatarPreset(
      background: Color(0xFFE6E8EE),
      foreground: Color(0xFF3E4756),
    ),
  };

  static String normalizeAvatarId(String avatarId) {
    final trimmed = avatarId.trim();
    return trimmed.isEmpty ? UserProfile.defaultAvatarId : trimmed;
  }

  static String assetPathFor(String avatarId) =>
      'lib/features/study_community/assets/avatars/${normalizeAvatarId(avatarId)}.png';

  static String _initialsFor(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.characters.first.toUpperCase();
    }
    return '${parts.first.characters.first}${parts.last.characters.first}'
        .toUpperCase();
  }

  _AvatarPreset _presetFor(String id) {
    final normalized = normalizeAvatarId(id);
    return _presets[normalized] ?? _presets[UserProfile.defaultAvatarId]!;
  }

  @override
  Widget build(BuildContext context) {
    final preset = _presetFor(avatarId);
    final initials = _initialsFor(displayName);
    final size = radius * 2;
    final fallback = CircleAvatar(
      radius: radius,
      backgroundColor: preset.background,
      foregroundColor: preset.foreground,
      child: Text(
        initials,
        style: TextStyle(fontSize: radius * 0.72, fontWeight: FontWeight.w700),
      ),
    );

    return Semantics(
      label: 'Avatar $displayName',
      child: useAssetImage
          ? ClipOval(
              child: Image.asset(
                assetPathFor(avatarId),
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => fallback,
              ),
            )
          : fallback,
    );
  }
}
