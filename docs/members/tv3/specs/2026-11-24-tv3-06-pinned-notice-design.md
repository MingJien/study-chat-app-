# Thiết kế: TV3-06 Thông báo ghim (`roomNotices`)

Ngày: 24/11/2026  
Nhánh làm việc: `tv3`

## 1. Mục tiêu và quy tắc nghiệp vụ

- Mỗi phòng học có **tối đa 1 thông báo ghim** tương ứng node `/roomNotices/{roomId}`, tách biệt khỏi luồng tin nhắn thường.
- **Giới hạn độ dài:** Tối đa **300 ký tự** (đo theo grapheme `characters.length` sau khi `trim()`).
- **Phân quyền (T17 & T18):**
  - Chỉ **chủ phòng (`owner`)** được tạo, sửa hoặc bỏ ghim (chặn cả trên giao diện lẫn trong `RoomRepository`).
  - Thành viên thường chỉ được xem; gọi API sửa hoặc bỏ ghim sẽ ném `RoomNoticeException`.
  - Người chưa tham gia phòng không xem thông báo ghim trên `RoomDetailScreen` (chỉ thành viên và chủ phòng thấy).
- **Đầu nối TV2 (`ChatScreen`):** Cung cấp đồng thời API stream `watchPinnedNotice(roomId)` và widget dùng lại `PinnedNoticeBanner` qua `study_community.dart`.

### Ràng buộc phạm vi
- Chỉ tạo/sửa file trong `lib/features/study_community/**`, `test/study_community/**`, `docs/members/tv3/**`.
- Không sửa `pubspec.yaml`, `lib/main.dart`, `lib/app/**`, `lib/core/**`, `test/app/**` hay `community_placeholder.dart`.

## 2. Thiết kế kỹ thuật

- **`domain/study_room_models.dart`:** Thêm `RoomNoticeException` và `RoomNotice` (`maxContentLength = 300`).
- **`data/room_repository.dart`:** Thêm `initialNotices`, `pinnedNoticeOf`, `watchPinnedNotice`, `updatePinnedNotice` (chuỗi rỗng = bỏ ghim) và `clearPinnedNotice`.
- **`data/preview_room_repository.dart`:** Thêm 1 thông báo ghim mẫu cho phòng `room_preview_mobile`.
- **`presentation/pinned_notice_banner.dart`:** Widget dùng chung cho `RoomDetailScreen` và TV2 `ChatScreen`, dùng `BoxDecoration` và `ListenableBuilder`.
- **`presentation/room_detail_screen.dart`:** Hiển thị `PinnedNoticeBanner` cho thành viên/chủ phòng; thêm nút **Ghim thông báo** / **Sửa ghim** / **Bỏ ghim** (có xác nhận) cho chủ phòng.
