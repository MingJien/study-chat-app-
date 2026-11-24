# Thiết kế: Thiết lập quy trình chuẩn Superpowers cho TV3

Ngày: 24/11/2026  
Nhánh làm việc: `tv3` (đồng bộ từ `origin/develop` tại commit `3e8acb7`)

## 1. Mục tiêu và bối cảnh

- Chuyển môi trường làm việc của Thành viên 3 (TV3 – Study Community & App UI) từ bản preview rời `classroom_chat_tv3_preview` sang repository chung của nhóm tại `https://github.com/MingJien/study-chat-app-`.
- Đồng bộ nhánh `tv3` lên khung Flutter 5 tab mới nhất từ `origin/develop` (`3e8acb7`) và xác minh baseline chạy sạch trên máy phát triển (Flutter 3.47.7, Dart 3.13.5).
- Chuẩn hóa quy trình phát triển **Superpowers** (brainstorming, viết design doc, lập plan, worktree, TDD, kiểm chứng trước hoàn thành) tương thích tuyệt đối với `docs/GIT_WORKFLOW.md`, `docs/FILE_OWNERSHIP.md` và CI `.github/workflows/flutter.yml`.

## 2. Phạm vi và ràng buộc

### Trong phạm vi (được phép sửa)
- Chỉ tạo và cập nhật tài liệu thuộc quyền sở hữu của TV3 trong `docs/members/tv3/**`.
- Cấu hình loại trừ cục bộ `.worktrees/` trong `.git/info/exclude` (không đưa vào Git).

### Ngoài phạm vi (tuyệt đối không chạm trong đợt này)
- Không sửa bất kỳ file dùng chung nào: `lib/main.dart`, `lib/app/**`, `lib/core/**`, `pubspec.yaml`, `pubspec.lock`, `.gitignore`, `docs/*.md`, `README.md`, `android/**` hay thư mục của TV1/TV2.
- Chưa chuyển mã nguồn hoặc test từ `classroom_chat_tv3_preview` sang `lib/features/study_community/` (sẽ thực hiện ở đợt kế tiếp theo quy trình vừa thiết lập).
- Không xóa hoặc sửa thư mục `classroom_chat_tv3_preview` và `handoff/`.
- Không chạy `git push` khi chưa có xác nhận từ người dùng; giữ commit ở cục bộ.

## 3. Phương án đã cân nhắc

- **Phương án A (Được chọn):** Lưu toàn bộ tài liệu quy trình, spec và plan của Superpowers trong `docs/members/tv3/` (`WORKFLOW.md`, `specs/`, `plans/`) và ẩn `.worktrees/` bằng `.git/info/exclude` cục bộ.
  - *Ưu điểm:* Tuân thủ 100% `docs/FILE_OWNERSHIP.md`, không phát sinh xung đột file chung khi mở PR `tv3 → develop`, không cần xin PR tích hợp riêng chỉ để thiết lập quy trình.
- **Phương án B (Loại):** Dùng đường dẫn mặc định của Superpowers (`docs/superpowers/` và thêm `.worktrees/` vào `.gitignore` gốc).
  - *Lý do loại:* Sửa trực tiếp file/thư mục dùng chung của cả nhóm, vi phạm quy tắc phân quyền nhánh `tv3` và dễ gây xung đột khi ghép nhánh với TV1/TV2.

## 4. Đầu ra và tiêu chí nghiệm thu

1. Clone repo vào đường dẫn không dấu `d:\CNTT23A-CS\HK1 26-27\Mobile App\study-chat-app` (tránh lỗi analyzer Flutter 3.47.7 với đường dẫn có dấu tiếng Việt).
2. Nhánh `tv3` fast-forward/merge sạch lên commit `3e8acb7` của `origin/develop`.
3. Kiểm tra baseline đạt exit code 0:
   - `flutter pub get --enforce-lockfile`
   - `dart format --output=none --set-exit-if-changed lib test`
   - `flutter analyze --no-pub` (`No issues found!`)
   - `flutter test --no-pub` (`test/app/app_smoke_test.dart` pass)
4. Hoàn thiện bộ tài liệu trong `docs/members/tv3/` (`WORKFLOW.md`, `README.md`, `specs/`, `plans/`) và commit cục bộ trên nhánh `tv3` với diff chỉ nằm trong `docs/members/tv3/`.
