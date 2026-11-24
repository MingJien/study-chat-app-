# Ghi chú tích hợp TV3

Chủ trì: TV3 Study Community và App UI. Mỗi người chỉ cập nhật thư mục ghi chú của mình để giảm đụng cùng file.

## Quy trình chuẩn TV3

- Sổ tay quy trình làm việc: [WORKFLOW.md](WORKFLOW.md) (kết hợp Superpowers với `docs/GIT_WORKFLOW.md`, `docs/FILE_OWNERSHIP.md` và CI).
- Thiết kế từng đợt: [specs/](specs/)
- Kế hoạch triển khai: [plans/](plans/)

## Tiến độ tổng hợp TV3

| Hạng mục | Nội dung | Trạng thái trên `tv3` | Phần còn lại / Phụ thuộc |
| --- | --- | --- | --- |
| **TV3-01** | `HomeScreen` | `[x]` Xong module + test | Nối vào `AppShell` (TV3-08), nhận profile TV1 & hội thoại TV2 thật |
| **TV3-02** | `CreateRoomScreen` | `[x]` Xong module + test | Nối Firebase Realtime Database (server timestamp, multi-location update) |
| **TV3-03** | `RoomsScreen` | `[x]` Xong module + test | Nối stream danh sách realtime Firebase & Auth thật |
| **TV3-04** | `RoomDetailScreen` (tham gia/rời) | `[x]` Xong module + test | Nối Firebase Rules & `ChatScreen` TV2 |
| **TV3-05** | `RoomMembersScreen` | `[x]` Xong module + test | Nối `ProfileScreen` TV1, DM TV2 & khai báo `assets/avatars/` ở PR tích hợp |
| **TV3-06** | Thông báo ghim (`roomNotices`) | `[x]` Xong module + test | Nối Firebase `/roomNotices/{roomId}` & gắn `PinnedNoticeBanner` vào `ChatScreen` TV2 |
| **TV3-07** | Theme sáng/tối & `SettingsScreen` | `[x]` Xong module + test | Thêm `shared_preferences` ở PR TV3-08 để lưu bền vững qua lần mở lại app (T22) |
| **TV3-08** | Điều hướng chung (`AppShell`, `AppRouter`, auth guard) | `[ ]` Chưa làm | Thực hiện trên nhánh tích hợp riêng `integration/tv3-app-shell` (sửa `lib/app/**`) |
| **TV3-10** | Interface chuẩn & Firebase Rules fragment | `[x]` Xong `StudyCommunityContract` & `study_community.rules.json` | Chờ thống nhất `lib/core/contracts/`, viết Firebase gateway & test với Emulator |
| **Nghiệm thu** | Tích hợp 3 module, T01–T24, APK | `[ ]` Chưa làm | Ghép TV1/TV2, chạy thử Android thật, T01–T24, quay minh chứng, APK & hỏi giảng viên REST API |

## Yêu cầu đang chờ

- **Assets avatar dựng sẵn (chờ PR tích hợp dùng chung):** Sau khi TV1 và TV3 thống nhất bộ file ảnh PNG avatar dùng chung, đề nghị khai báo `lib/features/study_community/assets/avatars/` (hoặc thư mục assets chung đã thống nhất) trong `pubspec.yaml` ở PR tích hợp riêng. Hiện tại `MemberAvatar` dùng `avatarId` với fallback an toàn theo màu/ký tự đại diện nên không sửa `pubspec.yaml` trên nhánh `tv3`.
- **Lưu lựa chọn Dark/Light Mode bền vững (`shared_preferences`, chờ PR TV3-08):** Đề nghị thêm dependency `shared_preferences` vào `pubspec.yaml` trên nhánh tích hợp `integration/tv3-app-shell` để triển khai `ThemeModeStore` lưu `ThemeMode` xuống thiết bị khi tắt/mở lại app (T22). Hiện tại `ThemeController` dùng `InMemoryThemeModeStore` trên nhánh `tv3`.

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

### 24/11/2026 — TV3-06 Thông báo ghim
- **Phạm vi:** Thêm `RoomNotice` (tối đa 300 ký tự) và `RoomNoticeException`, hỗ trợ `initialNotices`, `pinnedNoticeOf`, `watchPinnedNotice`, `updatePinnedNotice` và `clearPinnedNotice` (chỉ `owner` được sửa/bỏ ghim) trong `RoomRepository`, dựng `PinnedNoticeBanner` dùng chung cho `RoomDetailScreen` và TV2 `ChatScreen`, cùng nút **Ghim thông báo** / **Sửa ghim** / **Bỏ ghim** cho chủ phòng.
- **Kiểm chứng đã chạy:**
  - `dart format --output=none --set-exit-if-changed lib/features/study_community test/study_community`: `Formatted 17 files (0 changed)` (exit code 0).
  - `flutter analyze --no-pub`: `No issues found!` (exit code 0).
  - `flutter test --no-pub`: `38 tests passed` (`1` test trong `test/app/app_smoke_test.dart` + `37` tests trong `test/study_community/`, gồm 8 test mới ở `pinned_notice_test.dart`, exit code 0).
- **Giới hạn hiện tại:** Dữ liệu ghim vẫn nằm trong bộ nhớ (`RoomRepository`, `createPreviewRoomRepository()`), chưa nối Firebase Realtime Database `/roomNotices/{roomId}` / Security Rules và chờ gắn `PinnedNoticeBanner` hoặc `watchPinnedNotice` vào `ChatScreen` TV2 khi tích hợp. Chưa kiểm thử trực tiếp trên emulator trong đợt này.

### 24/11/2026 — TV3-01 `HomeScreen` & TV3-07 Theme/`SettingsScreen`
- **Phạm vi:** Thêm `RecentConversationSummary` và `OpenConversationSummary` trong `domain/`, triển khai `ThemeModeStore`, `InMemoryThemeModeStore` và `ThemeController` trong `data/theme_controller.dart`, tạo `studyCommunityCardDecoration` (`BoxDecoration` dùng chung Light/Dark), `SettingsScreen` (chuyển Hệ thống/Sáng/Tối, đầu nối hồ sơ & đăng xuất TV1) và `HomeScreen` (lời chào sinh viên, lối tắt 4 khu vực, phòng đã tham gia + empty state, phòng mới/nổi bật, hội thoại gần đây từ TV2, trạng thái loading/error/retry).
- **Kiểm chứng đã chạy:**
  - `dart format --output=none --set-exit-if-changed lib/features/study_community test/study_community`: `Formatted 23 files (0 changed)` (exit code 0).
  - `flutter analyze --no-pub`: `No issues found!` (exit code 0).
  - `flutter test --no-pub`: `48 tests passed` (`1` test trong `test/app/app_smoke_test.dart` + `47` tests trong `test/study_community/`, gồm 10 test mới ở `theme_settings_test.dart` và `home_screen_test.dart`, exit code 0).
- **Giới hạn hiện tại:** `ThemeController` dùng `InMemoryThemeModeStore` trên nhánh `tv3` (chờ gắn `shared_preferences` ở PR TV3-08); `AppShell` / `AppRouter` (`lib/app/**`) chưa chỉnh trên `tv3` theo đúng quy ước phân quyền file; hội thoại gần đây và hồ sơ/đăng xuất nhận qua đầu nối TV1/TV2. Chưa kiểm thử trực tiếp trên emulator trong đợt này.

### 24/11/2026 — TV3-10 Contract & Firebase Rules fragment
- **Phạm vi:** Tạo interface `StudyCommunityContract` và `CreateRoomInput` trong `domain/study_community_contract.dart`, triển khai `watchRooms()`, `getRoom()`, `createRoomAsync()` trên `RoomRepository`, và bổ sung Security Rules fragment cho 3 node `/rooms`, `/roomMembers`, `/roomNotices` tại `lib/features/study_community/integration/study_community.rules.json`.
- **Kiểm chứng đã chạy:**
  - `dart format --output=none --set-exit-if-changed lib/features/study_community test/study_community`: `Formatted 25 files (0 changed)` (exit code 0).
  - `flutter analyze --no-pub`: `No issues found!` (exit code 0).
  - `flutter test --no-pub`: `50 tests passed` (`1` test trong `test/app/app_smoke_test.dart` + `49` tests trong `test/study_community/`, gồm 2 test mới ở `contract_test.dart`, exit code 0).
- **Giới hạn hiện tại:** `RoomRepository` vẫn lưu dữ liệu trong bộ nhớ; `study_community.rules.json` mới kiểm tra cú pháp JSON, chưa test chạy thực tế trên Firebase Emulator hay triển khai Firebase project chung. Chưa kiểm thử trên emulator Android thật (`flutter devices` hiện chỉ có Windows/Chrome/Edge).
