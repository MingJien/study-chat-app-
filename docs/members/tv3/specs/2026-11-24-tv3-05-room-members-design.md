# Thiết kế: TV3-05 `RoomMembersScreen`

Ngày: 24/11/2026  
Nhánh làm việc: `tv3`

## 1. Mục tiêu và phạm vi

- Triển khai **TV3-05 (`RoomMembersScreen`)** để hiển thị danh sách thành viên phòng học gồm **tên hiển thị, avatar dựng sẵn và vai trò** (`Chủ phòng` / `Thành viên`), tự cập nhật khi có người tham gia hoặc rời phòng.
- Bổ sung API lấy và theo dõi danh sách thành viên (`membersOf`, `watchRoomMembers`) trên `RoomRepository`.
- Cung cấp đầu nối callback cho các module nhóm:
  - Chạm vào thành viên → `OpenUserProfile({required String uid})` (TV1 `ProfileScreen`).
  - Bấm nút **Nhắn tin** → `OpenDirectMessage({required String peerUid})` (TV2 `openDirectConversation` / `ChatScreen`).
  - Ẩn nút **Nhắn tin** ở dòng của chính `currentUserId`, gắn nhãn `(Bạn)` để phân biệt.
- Nối lối mở `RoomMembersScreen` từ `RoomDetailScreen` qua nút **Xem thành viên** và truyền tiếp callback từ `RoomsScreen`, `CreateRoomScreen`.

### Ràng buộc phạm vi
- Chỉ tạo/sửa file trong `lib/features/study_community/**`, `test/study_community/**`, `docs/members/tv3/**`.
- Không sửa `pubspec.yaml`, `lib/main.dart`, `lib/app/**`, `lib/core/**`, `test/app/**` hay `community_placeholder.dart`.

## 2. Xử lý avatar dựng sẵn không đụng `pubspec.yaml`

- Vì `pubspec.yaml` dùng chung chưa khai báo `assets:` và nhánh `tv3` không sửa file chung, `UserProfile` bổ sung trường `avatarId` (mặc định `'avatar_default'` để tương thích ngược toàn bộ test cũ).
- Widget `MemberAvatar` ánh xạ `avatarId` sang bộ màu/ký tự dựng sẵn (`avatar_tv3`, `avatar_linh`, `avatar_minh`, `avatar_1`–`avatar_3`, `avatar_default`) và chuẩn bị sẵn `assetPathFor(avatarId)` (`lib/features/study_community/assets/avatars/<id>.png`) kèm fallback an toàn khi chưa khai báo asset ảnh.
- Ghi đề nghị khai báo `assets/avatars/` vào mục `Yêu cầu đang chờ` của `docs/members/tv3/README.md` cho PR tích hợp.
