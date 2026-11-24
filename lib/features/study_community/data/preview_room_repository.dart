import '../domain/study_room_models.dart';
import 'room_repository.dart';

const String tv3PreviewUserId = 'tv3_preview_uid';

RoomRepository createPreviewRoomRepository() {
  const previewUid = tv3PreviewUserId;
  const linhUid = 'preview_linh_uid';
  const minhUid = 'preview_minh_uid';

  return RoomRepository(
    profiles: const {
      previewUid: UserProfile(
        uid: previewUid,
        displayName: 'Bạn (TV3)',
        avatarId: 'avatar_tv3',
      ),
      linhUid: UserProfile(
        uid: linhUid,
        displayName: 'Nguyễn Khánh Linh',
        avatarId: 'avatar_linh',
      ),
      minhUid: UserProfile(
        uid: minhUid,
        displayName: 'Trần Nhật Minh',
        avatarId: 'avatar_minh',
      ),
    },
    initialRooms: [
      StudyRoom(
        roomId: 'room_preview_mobile',
        roomName: 'Mobile',
        subject: 'Lập trình ứng dụng di động',
        description:
            'Trao đổi Flutter, Dart và bài tập thực hành trên Android.',
        ownerId: previewUid,
        createdAt: DateTime.utc(2026, 11, 21, 8),
      ),
      StudyRoom(
        roomId: 'room_preview_database',
        roomName: 'Ôn tập Cơ sở dữ liệu',
        subject: 'Cơ sở dữ liệu',
        description: 'Cùng ôn SQL, chuẩn hóa dữ liệu và thiết kế mô hình ERD.',
        ownerId: linhUid,
        createdAt: DateTime.utc(2026, 11, 20, 14),
      ),
      StudyRoom(
        roomId: 'room_preview_web',
        roomName: 'Frontend căn bản',
        subject: 'Lập trình Web',
        description: 'Chia sẻ tài liệu HTML, CSS và JavaScript cho người mới.',
        ownerId: minhUid,
        createdAt: DateTime.utc(2026, 11, 19, 9),
      ),
    ],
    initialMembers: const {
      'room_preview_mobile': [
        RoomMember(uid: previewUid, role: RoomRole.owner),
      ],
      'room_preview_database': [
        RoomMember(uid: linhUid, role: RoomRole.owner),
        RoomMember(uid: previewUid, role: RoomRole.member),
      ],
      'room_preview_web': [RoomMember(uid: minhUid, role: RoomRole.owner)],
    },
  );
}
