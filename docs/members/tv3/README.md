# Ghi chú tích hợp TV3

Chủ trì: TV3 Study Community và App UI. Mỗi người chỉ cập nhật thư mục ghi chú của mình để giảm đụng cùng file.

## Quy trình chuẩn TV3

- Sổ tay quy trình làm việc: [WORKFLOW.md](WORKFLOW.md) (kết hợp Superpowers với `docs/GIT_WORKFLOW.md`, `docs/FILE_OWNERSHIP.md` và CI).
- Thiết kế từng đợt: [specs/](specs/)
- Kế hoạch triển khai: [plans/](plans/)

## Yêu cầu đang chờ

- **Assets avatar dựng sẵn (chờ PR tích hợp dùng chung):** Sau khi TV1 và TV3 thống nhất bộ file ảnh PNG avatar dùng chung, đề nghị khai báo `lib/features/study_community/assets/avatars/` (hoặc thư mục assets chung đã thống nhất) trong `pubspec.yaml` ở PR tích hợp riêng. Hiện tại `MemberAvatar` dùng `avatarId` với fallback an toàn theo màu/ký tự đại diện nên không sửa `pubspec.yaml` trên nhánh `tv3`.

## Bàn giao

Ghi PR/Issue, chức năng hoàn thành, lệnh kiểm tra và kết quả thật, ảnh/video minh chứng, phần còn thiếu. Không ghi “đã kiểm tra” khi mới có khung.

### 24/11/2026 — Thiết lập quy trình chuẩn TV3 trên nhánh `tv3`
- **Phạm vi:** Đồng bộ nhánh `tv3` từ `origin/develop` (`3e8acb7`), cấu hình `.worktrees/` trong `.git/info/exclude` cục bộ và thiết lập tài liệu quy trình trong `docs/members/tv3/`. Chưa chuyển code tính năng từ `classroom_chat_tv3_preview`.
- **Kiểm chứng baseline đã chạy:**
  - `flutter pub get --enforce-lockfile`: thành công (exit code 0).
  - `dart format --output=none --set-exit-if-changed lib test`: `Formatted 13 files (0 changed)` (exit code 0).
  - `flutter analyze --no-pub`: `No issues found!` (exit code 0).
  - `flutter test --no-pub`: `test/app/app_smoke_test.dart` pass (`1 test passed`, 0 failures).
- **Chưa thực hiện:** Chuyển mã nguồn TV3-02/03/04 sang `lib/features/study_community/`, kiểm thử trên emulator/Firebase, `git push` lên remote.

### 24/11/2026 — Chuyển TV3-02/03/04 từ preview vào module `study_community`
- **Phạm vi:** Đưa mã nguồn tạo phòng (TV3-02), khám phá/tìm kiếm phòng (TV3-03), tham gia/rời phòng + callback mở thảo luận (TV3-04) và 21 test từ `classroom_chat_tv3_preview` sang `lib/features/study_community/{domain,data,presentation}/` và `test/study_community/`, giữ nguyên `community_placeholder.dart` cho `AppShell`.
- **Kiểm chứng đã chạy:**
  - `dart format --output=none --set-exit-if-changed lib/features/study_community test/study_community`: `Formatted 12 files (0 changed)` (exit code 0).
  - `flutter analyze --no-pub`: `No issues found!` (exit code 0).
  - `flutter test --no-pub`: `22 tests passed` (`1` test trong `test/app/app_smoke_test.dart` + `21` test trong `test/study_community/`, exit code 0).
- **Giới hạn hiện tại (chưa tích hợp):** Dữ liệu vẫn dùng bản mẫu trong bộ nhớ (`RoomRepository`, `createPreviewRoomRepository()`); chưa nối Firebase Realtime Database, Firebase Auth, Security Rules hay module TV1/TV2; `AppShell` vẫn giữ placeholder tới PR tích hợp riêng. Chưa kiểm thử lại trực tiếp trên emulator trong đợt chuyển đổi này.

### 24/11/2026 — TV3-05 `RoomMembersScreen`
- **Phạm vi:** Thêm `avatarId` vào `UserProfile`, typedef `OpenUserProfile` / `OpenDirectMessage`, `membersOf` / `watchRoomMembers` / `displayNameOf` / `avatarIdOf` trong `RoomRepository`, `MemberAvatar`, `RoomMembersScreen`, nối nút **Xem thành viên** trên `RoomDetailScreen` và truyền callback xuyên suốt từ `RoomsScreen` / `CreateRoomScreen`.
- **Kiểm chứng đã chạy:**
  - `dart format --output=none --set-exit-if-changed lib/features/study_community test/study_community`: `Formatted 15 files (0 changed)` (exit code 0).
  - `flutter analyze --no-pub`: `No issues found!` (exit code 0).
  - `flutter test --no-pub`: `30 tests passed` (`1` test trong `test/app/app_smoke_test.dart` + `29` tests trong `test/study_community/`, gồm 8 test mới ở `room_members_test.dart`, exit code 0).
- **Giới hạn hiện tại:** Dữ liệu vẫn dùng bản mẫu trong bộ nhớ (`RoomRepository`, `createPreviewRoomRepository()`); mở hồ sơ (TV1) và nhắn tin riêng (TV2) kết nối qua callback (`OpenUserProfile`, `OpenDirectMessage`) và hiển thị thông báo preview khi chưa ghép module thật. Chưa kiểm thử trực tiếp trên emulator trong đợt này.
