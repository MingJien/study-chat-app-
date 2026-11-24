import 'study_room_models.dart';

class CreateRoomInput {
  const CreateRoomInput({
    required this.roomName,
    required this.subject,
    required this.description,
    required this.ownerId,
  });

  final String roomName;
  final String subject;
  final String description;
  final String ownerId;
}

abstract interface class StudyCommunityContract {
  Stream<List<StudyRoom>> watchRooms();
  Future<StudyRoom?> getRoom(String roomId);
  Future<StudyRoom> createRoomAsync(CreateRoomInput input);
  Future<void> joinRoom(String roomId, {required String currentUserId});
  Future<void> leaveRoom(String roomId, {required String currentUserId});
  Stream<List<RoomMember>> watchRoomMembers(String roomId);
  Stream<RoomNotice?> watchPinnedNotice(String roomId);
  Future<void> updatePinnedNotice(
    String roomId, {
    required String currentUserId,
    required String content,
  });
}
