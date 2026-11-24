# TV3-06 Thông báo ghim (`roomNotices`) — Kế hoạch triển khai

> **For agentic workers:** Thực hiện tuần tự các bước bên dưới trong phạm vi TV3, chạy `dart format`, `flutter analyze` và `flutter test` trước khi commit cục bộ.

**Goal:** Triển khai TV3-06 (1 thông báo ghim/phòng, tối đa 300 ký tự, phân quyền owner, thành viên xem, người ngoài ẩn, stream `watchPinnedNotice` và widget `PinnedNoticeBanner` cho TV2) cùng bộ test đầy đủ.

**Architecture:** Thêm `RoomNotice` và `RoomNoticeException` trong `domain/`, lưu và phát thay đổi thông báo trong `RoomRepository`, dựng `PinnedNoticeBanner` dùng chung cho `RoomDetailScreen` và `ChatScreen` TV2.

**Tech Stack:** Flutter 3.47.7, Dart 3.13.5, `flutter_test`.

**Spec:** [2026-11-24-tv3-06-pinned-notice-design.md](../specs/2026-11-24-tv3-06-pinned-notice-design.md)

## Global Constraints

- Chỉ tạo/sửa file trong `lib/features/study_community/**`, `test/study_community/**`, `docs/members/tv3/**`.
- Không sửa `pubspec.yaml`, `lib/main.dart`, `lib/app/**`, `lib/core/**`, `test/app/**`, `community_placeholder.dart`.
- Giữ toàn bộ 30 test hiện có tiếp tục pass.
- Chỉ commit cục bộ trên `tv3` (không tự `git push`).

---

### Task 1: Lưu design doc & plan trong `docs/members/tv3/`
- [x] Tạo `specs/2026-11-24-tv3-06-pinned-notice-design.md` và `plans/2026-11-24-tv3-06-pinned-notice.md`.

### Task 2: Cập nhật `domain/` và `data/`
- [x] Thêm `RoomNoticeException` và `RoomNotice` (`maxContentLength = 300`) vào `domain/study_room_models.dart`.
- [x] Bổ sung `initialNotices`, `pinnedNoticeOf`, `watchPinnedNotice`, `updatePinnedNotice` và `clearPinnedNotice` vào `data/room_repository.dart`.
- [x] Gắn thông báo ghim mẫu cho `room_preview_mobile` trong `data/preview_room_repository.dart`.

### Task 3: Tạo `PinnedNoticeBanner` và nối `RoomDetailScreen`
- [x] Tạo `presentation/pinned_notice_banner.dart` (`BoxDecoration`, `ListenableBuilder`).
- [x] Cập nhật `presentation/room_detail_screen.dart` và export trong `study_community.dart`.

### Task 4: Viết unit & widget tests cho TV3-06
- [x] Tạo `test/study_community/pinned_notice_test.dart` kiểm thử T17/T18, 300 ký tự, UI owner/member/non-member, `PinnedNoticeBanner` cho TV2, lỗi bất đồng bộ và màn hình hẹp 320x640 phóng chữ 1.5x.

### Task 5: Kiểm chứng, cập nhật `README.md` và commit cục bộ
- [x] Chạy `dart format`, `flutter analyze --no-pub`, `flutter test --no-pub`.
- [x] Cập nhật `docs/members/tv3/README.md`, đánh dấu hoàn tất plan và commit cục bộ lên `tv3`.
