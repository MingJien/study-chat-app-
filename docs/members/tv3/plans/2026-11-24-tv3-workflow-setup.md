# Thiết lập quy trình chuẩn Superpowers cho TV3 — Kế hoạch triển khai

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (hoặc superpowers:subagent-driven-development) để thực hiện từng bước theo đúng danh sách kiểm tra bên dưới.

**Goal:** Thiết lập bản clone chuẩn của `MingJien/study-chat-app-`, đồng bộ nhánh `tv3` với `origin/develop`, kiểm chứng baseline Flutter xanh và lưu bộ quy trình Superpowers riêng cho TV3 trong `docs/members/tv3/`.

**Architecture:** Toàn bộ tài liệu quy trình, thiết kế và kế hoạch của TV3 đặt trong `docs/members/tv3/` để không chạm các file dùng chung. Worktree cục bộ (`.worktrees/`) được ẩn qua `.git/info/exclude` thay vì sửa `.gitignore`.

**Tech Stack:** Git, GitHub CLI (`gh`), Flutter 3.47.7, Dart 3.13.5, Superpowers workflow.

**Spec:** [2026-11-24-tv3-workflow-design.md](../specs/2026-11-24-tv3-workflow-design.md)

## Global Constraints

- Chỉ tạo/sửa file trong `docs/members/tv3/**`.
- Không sửa `lib/main.dart`, `lib/app/**`, `lib/core/**`, `pubspec.yaml`, `pubspec.lock`, `.gitignore`, `docs/*.md`, `README.md` hoặc module của TV1/TV2.
- Không migrate code từ `classroom_chat_tv3_preview` trong đợt này và không xóa `classroom_chat_tv3_preview` hay `handoff/`.
- Không `git push` khi chưa có yêu cầu xác nhận.

---

### Task 1: Clone repo nhóm và đồng bộ nhánh `tv3`

- [x] Clone `https://github.com/MingJien/study-chat-app-.git` vào `d:\CNTT23A-CS\HK1 26-27\Mobile App\study-chat-app`.
- [x] `git fetch origin`, chuyển sang nhánh `tv3`, `git pull --ff-only origin tv3`, `git merge origin/develop`.
- [x] Xác nhận nhánh hiện tại là `tv3` và `HEAD` ở `3e8acb7` (khớp `origin/develop`).

### Task 2: Cấu hình ẩn `.worktrees/` cục bộ

- [x] Thêm `.worktrees/` vào `.git/info/exclude`.
- [x] Kiểm tra `git check-ignore -v .worktrees/` khớp rule trong `.git/info/exclude` và working tree sạch.

### Task 3: Kiểm chứng baseline Flutter trên nhánh `tv3`

- [x] Chạy `flutter pub get --enforce-lockfile` (exit code 0).
- [x] Chạy `dart format --output=none --set-exit-if-changed lib test` (13 files, 0 changed).
- [x] Chạy `flutter analyze --no-pub` (`No issues found!`).
- [x] Chạy `flutter test --no-pub` (`test/app/app_smoke_test.dart`: 1 test passed).

### Task 4: Viết tài liệu quy trình Superpowers cho TV3

- [x] Tạo `docs/members/tv3/specs/2026-11-24-tv3-workflow-design.md`.
- [x] Tạo `docs/members/tv3/plans/2026-11-24-tv3-workflow-setup.md`.
- [x] Tạo `docs/members/tv3/WORKFLOW.md`.
- [x] Cập nhật `docs/members/tv3/README.md` dẫn chiếu quy trình và ghi nhận kết quả baseline.

### Task 5: Kiểm tra phạm vi file và commit cục bộ trên `tv3`

- [x] Kiểm tra `git status --short` chỉ có các thay đổi trong `docs/members/tv3/`.
- [x] Stage riêng `docs/members/tv3` và kiểm tra `git diff --cached --stat`.
- [x] Chạy lại `flutter analyze --no-pub` và `flutter test --no-pub`.
- [x] Commit cục bộ lên nhánh `tv3` (không push).
