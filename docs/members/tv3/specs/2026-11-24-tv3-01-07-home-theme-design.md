# Thiết kế: TV3-01 (`HomeScreen`) & TV3-07 (`ThemeController`, `SettingsScreen`)

Ngày: 24/11/2026  
Nhánh làm việc: `tv3` (Hướng A — gọn trong phạm vi module TV3 trước khi tách nhánh `integration/tv3-app-shell` làm TV3-08)

## 1. Mục tiêu và phạm vi

- **TV3-07 (`ThemeController`, `ThemeModeStore`, `SettingsScreen`, style `BoxDecoration`):**
  - Cho phép chuyển chế độ giao diện **Theo hệ thống / Sáng / Tối**, cập nhật tức thì qua `ThemeController` (`ChangeNotifier`), khôi phục lại chế độ cũ và báo lỗi nếu lưu thất bại.
  - Chuẩn bị interface `ThemeModeStore` + `InMemoryThemeModeStore` trên nhánh `tv3` để PR tích hợp TV3-08 gắn `SharedPreferences` (`shared_preferences`) mà không đụng `pubspec.yaml` hay `lib/app/` trong PR module.
  - Cung cấp helper `studyCommunityCardDecoration` dùng `BoxDecoration` đồng bộ cho thẻ Light/Dark Mode.
  - `SettingsScreen` có thẻ tài khoản (`MemberAvatar`, đầu nối hồ sơ TV1) và nút **Đăng xuất** (xác nhận trước khi gọi đầu nối Auth TV1).
- **TV3-01 (`HomeScreen`):**
  - Hiển thị lời chào sinh viên (từ hồ sơ TV1 hoặc preview), lối điều hướng nhanh tới 4 khu vực (`Phòng học`, `Tin nhắn`, `Bạn học`, `Cá nhân`) và `Cài đặt`, danh sách **Phòng đã tham gia** (có empty state + nút **Khám phá phòng**), **Phòng mới & nổi bật**, và **Hội thoại gần đây** (nhận `RecentConversationSummary` từ TV2).
  - Có đủ trạng thái loading, error và nút thử lại.

### Ràng buộc phạm vi
- Chỉ tạo/sửa file trong `lib/features/study_community/**`, `test/study_community/**`, `docs/members/tv3/**`.
- Không sửa `pubspec.yaml`, `lib/main.dart`, `lib/app/**`, `lib/core/**`, `test/app/**` hay `community_placeholder.dart`.
