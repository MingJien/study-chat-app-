# Chuyển TV3-02/03/04 từ preview vào `study_community` — Kế hoạch

> **For agentic workers:** Thực hiện theo từng bước, kiểm tra `dart format`, `flutter analyze` và `flutter test` trước khi commit.

**Goal:** Chuyển mã nguồn TV3-02/03/04 và 21 test từ `classroom_chat_tv3_preview` sang `lib/features/study_community/` và `test/study_community/` trên nhánh `tv3`, đảm bảo toàn bộ 22 test pass.

**Architecture:** Tách model/typedef vào `domain/`, repository và dữ liệu preview vào `data/`, các màn hình vào `presentation/`, giữ `community_placeholder.dart` để không ảnh hưởng `AppShell`.

**Tech Stack:** Flutter 3.47.7, Dart 3.13.5, `flutter_test`.

**Spec:** [2026-11-24-migrate-tv3-preview-design.md](../specs/2026-11-24-migrate-tv3-preview-design.md)

## Global Constraints

- Chỉ sửa/tạo/xóa file trong `lib/features/study_community/**`, `test/study_community/**`, `docs/members/tv3/**`.
- Giữ nguyên `community_placeholder.dart` và `test/app/app_smoke_test.dart`.
- Không xóa hoặc sửa `classroom_chat_tv3_preview` và `handoff/`.

---

### Task 1: Đẩy nhánh `tv3` hiện tại lên `origin/tv3`
- [x] `git push origin tv3` (đưa `a03670c` lên remote).

### Task 2: Chuyển mã nguồn TV3-02/03/04 vào `lib/features/study_community/`
- [x] Tạo `domain/study_room_models.dart`, `data/room_repository.dart`, `data/preview_room_repository.dart`.
- [x] Tạo `presentation/rooms_screen.dart`, `presentation/create_room_screen.dart`, `presentation/room_detail_screen.dart`.
- [x] Cập nhật `study_community.dart` (giữ export `community_placeholder.dart`).
- [x] Xóa `.gitkeep` thừa ở `domain/`, `data/`, `test/study_community/`.

### Task 3: Chuyển 21 test vào `test/study_community/`
- [x] Tạo `membership_test.dart`, `rooms_screen_test.dart`, `create_room_test.dart`, `room_detail_test.dart`.

### Task 4: Cập nhật tài liệu tiến độ TV3
- [x] Tạo spec và plan chuyển đổi trong `docs/members/tv3/`.
- [x] Cập nhật kết quả kiểm chứng thực tế vào `docs/members/tv3/README.md`.

### Task 5: Kiểm chứng, commit và push `tv3`
- [x] Chạy `dart format`, `flutter analyze --no-pub`, `flutter test --no-pub` (22/22 pass).
- [x] Kiểm tra `git status` chỉ có file thuộc TV3, commit và `git push origin tv3`.
