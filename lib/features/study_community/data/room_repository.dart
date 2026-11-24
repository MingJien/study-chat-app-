import 'package:flutter/foundation.dart';

import '../domain/study_room_models.dart';

class RoomRepository extends ChangeNotifier {
  RoomRepository({
    List<StudyRoom> initialRooms = const [],
    Map<String, List<RoomMember>> initialMembers = const {},
    Map<String, UserProfile> profiles = const {},
    this.onLoad,
  }) : _rooms = List.of(initialRooms),
       _profiles = Map.of(profiles) {
    for (final entry in initialMembers.entries) {
      _membersByRoom[entry.key] = {
        for (final member in entry.value) member.uid: member,
      };
    }
  }

  final List<StudyRoom> _rooms;
  final _membersByRoom = <String, Map<String, RoomMember>>{};
  final Map<String, UserProfile> _profiles;
  final Future<void> Function()? onLoad;
  int _nextRoomNumber = 1;
  RoomsLoadStatus _loadStatus = RoomsLoadStatus.idle;

  List<StudyRoom> get rooms => List.unmodifiable(_rooms);
  RoomsLoadStatus get loadStatus => _loadStatus;

  RoomMember? memberOf(String roomId, String uid) =>
      _membersByRoom[roomId]?[uid];

  StudyRoom? roomOf(String roomId) {
    for (final room in _rooms) {
      if (room.roomId == roomId) return room;
    }
    return null;
  }

  int memberCountOf(String roomId) => _membersByRoom[roomId]?.length ?? 0;

  StudyRoom _requireRoom(String roomId, String uid) {
    final room = roomOf(roomId);
    if (room == null) {
      throw const RoomMembershipException('Phòng không còn tồn tại.');
    }
    if (uid.trim().isEmpty) {
      throw const RoomMembershipException('Không xác định được tài khoản.');
    }
    return room;
  }

  // UID comes from the active preview session. A Firebase implementation must
  // use Auth UID and enforce /roomMembers/{roomId}/{uid} in security rules.
  Future<void> joinRoom(String roomId, {required String currentUserId}) async {
    final room = _requireRoom(roomId, currentUserId);
    final members = _membersByRoom.putIfAbsent(roomId, () => {});
    if (members.containsKey(currentUserId)) return;
    members[currentUserId] = RoomMember(
      uid: currentUserId,
      role: room.ownerId == currentUserId ? RoomRole.owner : RoomRole.member,
    );
    notifyListeners();
  }

  Future<void> leaveRoom(String roomId, {required String currentUserId}) async {
    final room = _requireRoom(roomId, currentUserId);
    if (room.ownerId == currentUserId ||
        memberOf(roomId, currentUserId)?.role == RoomRole.owner) {
      throw const RoomMembershipException('Chủ phòng không thể rời phòng.');
    }
    if (_membersByRoom[roomId]?.remove(currentUserId) != null) {
      notifyListeners();
    }
  }

  void requireMembership(String roomId, {required String currentUserId}) {
    _requireRoom(roomId, currentUserId);
    if (memberOf(roomId, currentUserId) == null) {
      throw const RoomMembershipException(
        'Bạn cần tham gia phòng trước khi vào thảo luận.',
      );
    }
  }

  UserProfile? profileOf(String uid) => _profiles[uid];

  String creatorNameOf(StudyRoom room) =>
      profileOf(room.ownerId)?.displayName ?? 'Người dùng ẩn danh';

  List<StudyRoom> searchRooms(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return rooms;

    return List.unmodifiable(
      _rooms.where((room) {
        return room.roomName.toLowerCase().contains(normalizedQuery) ||
            room.subject.toLowerCase().contains(normalizedQuery);
      }),
    );
  }

  Future<void> loadRooms() async {
    _loadStatus = RoomsLoadStatus.loading;
    notifyListeners();

    try {
      await onLoad?.call();
      _loadStatus = RoomsLoadStatus.loaded;
    } catch (_) {
      _loadStatus = RoomsLoadStatus.error;
    }
    notifyListeners();
  }

  StudyRoom createRoom({
    required String roomName,
    required String subject,
    required String description,
    required String ownerId,
  }) {
    late String roomId;
    do {
      roomId = 'room_${_nextRoomNumber++}';
    } while (_rooms.any((room) => room.roomId == roomId));

    final room = StudyRoom(
      roomId: roomId,
      roomName: roomName.trim(),
      subject: subject.trim(),
      description: description.trim(),
      ownerId: ownerId,
      createdAt: DateTime.now().toUtc(),
    );

    _membersByRoom[room.roomId] = {
      ownerId: RoomMember(uid: ownerId, role: RoomRole.owner),
    };
    _rooms.insert(0, room);
    _loadStatus = RoomsLoadStatus.loaded;
    notifyListeners();
    return room;
  }
}
