# Thiết kế: Chuyển TV3-02/03/04 từ preview vào module `study_community`

Ngày: 24/11/2026  
Nhánh làm việc: `tv3`

## 1. Mục tiêu và bối cảnh

- Đưa toàn bộ mã nguồn và kiểm thử đã hoàn thành ở bản `classroom_chat_tv3_preview` (TV3-02 Tạo phòng, TV3-03 Khám phá/tìm kiếm phòng, TV3-04 Tham gia/rời phòng và callback mở thảo luận) vào đúng cấu trúc module TV3 trong repo chung `study-chat-app`.
- Tách code phẳng thành đúng các lớp `domain/`, `data/`, `presentation/` và export công khai qua `lib/features/study_community/study_community.dart`.

## 2. Phạm vi và ràng buộc

### Trong phạm vi
- Tạo mã nguồn TV3-02/03/04 trong `lib/features/study_community/{domain,data,presentation}/` và cập nhật `lib/features/study_community/study_community.dart`.
- Chuyển toàn bộ 4 file test (21 test) sang `test/study_community/`.
- Cập nhật tài liệu tiến độ trong `docs/members/tv3/`.

### Ngoài phạm vi
- Giữ nguyên `presentation/community_placeholder.dart` và tiếp tục export qua `study_community.dart` để `AppShell` và `test/app/app_smoke_test.dart` chạy bình thường cho tới đợt tích hợp PR riêng.
- Không chạm bất kỳ file chung nào (`lib/main.dart`, `lib/app/**`, `lib/core/**`, `pubspec.yaml`, `.gitignore`, `docs/*.md`, `test/app/**`).
- Không xóa hoặc chỉnh sửa `classroom_chat_tv3_preview/` và `handoff/`.
- Dữ liệu vẫn là bản mẫu trong bộ nhớ (`RoomRepository`, `createPreviewRoomRepository()`); chưa nối Firebase, Firebase Auth hay TV1/TV2.

## 3. Phân rã cấu trúc file

- `domain/study_room_models.dart`: `RoomRole`, `RoomsLoadStatus`, `RoomMembershipException`, `UserProfile`, `StudyRoom`, `RoomMember`, `OpenRoomDiscussion`.
- `data/room_repository.dart`: `RoomRepository` (`ChangeNotifier`) quản lý phòng, thành viên và tìm kiếm.
- `data/preview_room_repository.dart`: `tv3PreviewUserId` và `createPreviewRoomRepository()`.
- `presentation/rooms_screen.dart`, `create_room_screen.dart`, `room_detail_screen.dart`: 3 màn hình nghiệp vụ TV3-02/03/04.
- `study_community.dart`: export đầy đủ API và màn hình TV3 cùng `community_placeholder.dart`.
