# TV3-05 `RoomMembersScreen` — Kế hoạch triển khai

> **For agentic workers:** Thực hiện tuần tự các bước bên dưới trong phạm vi TV3, chạy `dart format`, `flutter analyze` và `flutter test` trước khi commit cục bộ.

**Goal:** Triển khai TV3-05 (`RoomMembersScreen`), API `membersOf` / `watchRoomMembers`, `MemberAvatar`, nút **Xem thành viên** trên `RoomDetailScreen`, cùng đầu nối TV1/TV2 và bộ test đầy đủ.

**Architecture:** Mở rộng `UserProfile` (`avatarId`) và typedefs trong `domain/`, bổ sung `membersOf`, `watchRoomMembers`, `displayNameOf`, `avatarIdOf` trong `data/room_repository.dart`, tạo `MemberAvatar` và `RoomMembersScreen` trong `presentation/`, truyền callback xuyên suốt từ `RoomsScreen` và `CreateRoomScreen`.

**Tech Stack:** Flutter 3.47.7, Dart 3.13.5, `flutter_test`.

**Spec:** [2026-11-24-tv3-05-room-members-design.md](../specs/2026-11-24-tv3-05-room-members-design.md)

## Global Constraints

- Chỉ tạo/sửa file trong `lib/features/study_community/**`, `test/study_community/**`, `docs/members/tv3/**`.
- Không sửa `pubspec.yaml`, `lib/main.dart`, `lib/app/**`, `lib/core/**`, `test/app/**`, `community_placeholder.dart`.
- Toàn bộ 22 test hiện có phải tiếp tục pass.
- Chỉ commit cục bộ trên `tv3` (không tự `git push`).

---

### Task 1: Lưu design doc & plan trong `docs/members/tv3/`
- [x] Tạo `specs/2026-11-24-tv3-05-room-members-design.md` và `plans/2026-11-24-tv3-05-room-members.md`.

### Task 2: Cập nhật `domain/` và `data/`
- [x] Thêm `avatarId` (mặc định `'avatar_default'`) vào `UserProfile`, thêm `OpenUserProfile` và `OpenDirectMessage` trong `domain/study_room_models.dart`.
- [x] Bổ sung `displayNameOf`, `avatarIdOf`, `membersOf`, `watchRoomMembers` vào `data/room_repository.dart`.
- [x] Gán `avatarId` nhất quán cho 3 hồ sơ mẫu trong `data/preview_room_repository.dart`.

### Task 3: Tạo `MemberAvatar` và `RoomMembersScreen`
- [x] Tạo `presentation/member_avatar.dart` với bảng preset theo `avatarId` và `assetPathFor`.
- [x] Tạo `presentation/room_members_screen.dart` hiển thị danh sách thành viên, nhãn `(Bạn)`, vai trò, ẩn `Nhắn tin` ở chính mình, phản hồi preview khi thiếu TV1/TV2, khóa thao tác khi callback bất đồng bộ đang chạy.

### Task 4: Nối màn hình và export công khai
- [x] Cập nhật `presentation/room_detail_screen.dart`, `create_room_screen.dart`, `rooms_screen.dart` và `study_community.dart`.

### Task 5: Viết unit & widget tests cho TV3-05
- [x] Tạo `test/study_community/room_members_test.dart` phủ đầy đủ API repository, cập nhật live, điều hướng từ `RoomDetailScreen`, truyền callback từ `RoomsScreen`/`CreateRoomScreen`, preview/error SnackBar, phòng không tồn tại, và màn hình hẹp 320x640 với textScaler 1.5x.

### Task 6: Kiểm chứng, cập nhật `README.md` và commit cục bộ
- [x] Chạy `dart format`, `flutter analyze --no-pub`, `flutter test --no-pub`.
- [x] Cập nhật `docs/members/tv3/README.md`, đánh dấu hoàn tất plan và commit cục bộ lên `tv3`.
