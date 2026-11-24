enum RoomRole { owner, member }

enum RoomsLoadStatus { idle, loading, loaded, error }

class RoomMembershipException implements Exception {
  const RoomMembershipException(this.message);
  final String message;
}

class UserProfile {
  static const String defaultAvatarId = 'avatar_default';

  const UserProfile({
    required this.uid,
    required this.displayName,
    this.avatarId = defaultAvatarId,
  });

  final String uid;
  final String displayName;
  final String avatarId;
}

class StudyRoom {
  const StudyRoom({
    required this.roomId,
    required this.roomName,
    required this.subject,
    required this.description,
    required this.ownerId,
    required this.createdAt,
  });

  final String roomId;
  final String roomName;
  final String subject;
  final String description;
  final String ownerId;
  final DateTime createdAt;
}

class RoomMember {
  const RoomMember({required this.uid, required this.role});

  final String uid;
  final RoomRole role;
}

/// TV2 supplies ChatScreen navigation. Firebase read/write rules still need
/// integration verification with TV2; this callback is only a UI entry guard.
typedef OpenRoomDiscussion = Future<void> Function({
  required String roomId,
  required String type,
});

/// TV1 supplies ProfileScreen navigation by UID.
typedef OpenUserProfile = Future<void> Function({required String uid});

/// TV2 supplies direct chat navigation via openDirectConversation(peerUid).
typedef OpenDirectMessage = Future<void> Function({required String peerUid});
