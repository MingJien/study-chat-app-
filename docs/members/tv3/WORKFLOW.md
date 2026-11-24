# Quy trình chuẩn TV3 (Superpowers + Quy ước nhóm)

Tài liệu này cụ thể hóa quy trình làm việc hằng ngày cho **Thành viên 3 (TV3 – Study Community & App UI)** trên nhánh `tv3`, kết hợp giữa **Superpowers** và các quy định trong [GIT_WORKFLOW.md](../../GIT_WORKFLOW.md), [FILE_OWNERSHIP.md](../../FILE_OWNERSHIP.md) và CI [flutter.yml](../../../.github/workflows/flutter.yml).

## 1. Phạm vi nhánh và quyền sửa file

| Loại công việc | Nhánh làm việc | Đường dẫn được phép sửa | Đường dẫn không tự sửa |
| --- | --- | --- | --- |
| Tính năng module TV3 | `tv3` | `lib/features/study_community/**`, `test/study_community/**`, `docs/members/tv3/**` | `lib/main.dart`, `lib/app/**`, `lib/core/**`, `pubspec.yaml`, `.gitignore`, `docs/*.md`, module TV1/TV2 |
| Tích hợp dùng chung (AppShell, router, theme, dependency, Rules chung) | Nhánh riêng tạo từ `develop` (vd: `integration/tv3-app-shell`) | File chung đã thống nhất trong PR tích hợp riêng | Code nội bộ chưa chốt của TV1/TV2 |

### Quy ước cấu trúc trong `lib/features/study_community/`
- `domain/`: model, interface, quy tắc nghiệp vụ (không phụ thuộc UI).
- `data/`: repository, nguồn dữ liệu Firebase/cục bộ.
- `presentation/`: màn hình, widget, state (`HomeScreen`, `RoomsScreen`, `CreateRoomScreen`, `RoomDetailScreen`, `RoomMembersScreen`, `SettingsScreen`).
- `assets/`: tài nguyên dựng sẵn riêng của module (khai báo vào `pubspec.yaml` qua PR tích hợp).
- `integration/`: adapter và Firebase Security Rules fragment cho `rooms`, `roomMembers`, `roomNotices`.
- `study_community.dart`: file export API công khai của module.

---

## 2. Chu trình 7 bước cho mỗi đầu việc TV3

### Bước 1 — Chốt thiết kế (`superpowers:brainstorming`)
- Đọc lại code hiện tại, đặc tả [requirements.md](../../requirements.md), [data_schema.md](../../data_schema.md) và [module_contracts.md](../../module_contracts.md).
- Thảo luận làm rõ các điểm còn mở và thống nhất phương án.
- Lưu bản thiết kế tại:
  `docs/members/tv3/specs/YYYY-MM-DD-<topic>-design.md`

### Bước 2 — Lập kế hoạch thực thi (`superpowers:writing-plans`)
- Chia nhỏ thành các task độc lập có kiểm thử đi kèm, ghi rõ file tạo/sửa và interface.
- Lưu kế hoạch tại:
  `docs/members/tv3/plans/YYYY-MM-DD-<topic>.md`

### Bước 3 — Cô lập môi trường làm việc (tùy chọn với `superpowers:using-git-worktrees`)
- Nếu cần thử nghiệm tách nhánh từ `tv3`, tạo worktree bên trong `.worktrees/`.
- Thư mục `.worktrees/` đã được ẩn cục bộ trong `.git/info/exclude` — **không sửa `.gitignore` chung** trên nhánh `tv3`.

### Bước 4 — Triển khai theo TDD (`superpowers:test-driven-development`)
- Viết test kiểm chứng hành vi mong đợi trong `test/study_community/` trước (hoặc song song từng bước nhỏ theo plan), chạy để thấy fail đúng lý do, rồi viết code tối thiểu trong `lib/features/study_community/` để pass và refactor sạch.
- Giữ ranh giới dữ liệu thật vs dữ liệu mẫu: không giả vờ đã nối Firebase/TV1/TV2 nếu vẫn đang chạy repository trong bộ nhớ.

### Bước 5 — Kiểm chứng bắt buộc trước khi hoàn thành (`superpowers:verification-before-completion`)
Chạy tuần tự các lệnh khớp CI của repo (lưu ý: chỉ chạy `dart format` trong phạm vi TV3 để tránh sửa file của TV1/TV2):

```powershell
dart format lib/features/study_community test/study_community
dart format --output=none --set-exit-if-changed lib/features/study_community test/study_community
flutter analyze --no-pub
flutter test --no-pub
```

- Khi có thiết bị/emulator Android, chạy kiểm thử giao diện thực tế (`flutter run`) cho các luồng vừa làm và ghi chú rõ vào `docs/members/tv3/README.md`.

### Bước 6 — Stage đúng phạm vi và commit
```powershell
git status
git add lib/features/study_community test/study_community docs/members/tv3
git diff --cached --stat
```
- Xác nhận trong `git diff --cached --stat` **không có bất kỳ file nào ngoài 3 thư mục của TV3**.
- Commit theo chuẩn thông điệp rõ nghĩa:
  ```powershell
  git commit -m "<type>(study_community|tv3): <mô tả ngắn>"
  ```

### Bước 7 — Đồng bộ và mở Pull Request (`tv3 → develop`)
1. Cập nhật mới nhất từ `origin/develop`:
   ```powershell
   git fetch origin
   git switch tv3
   git pull --ff-only origin tv3
   git merge origin/develop
   flutter pub get --enforce-lockfile
   flutter analyze --no-pub
   flutter test --no-pub
   ```
2. Chỉ `git push origin tv3` khi kiểm tra xanh và sẵn sàng đưa lên nhóm.
3. Tạo PR `tv3 → develop` theo mẫu [.github/pull_request_template.md](../../../.github/pull_request_template.md), ghi rõ phạm vi file, lệnh đã chạy, kết quả thực tế và phần còn phụ thuộc TV1/TV2.

---

## 3. Lộ trình TV3 tiếp theo

1. **Chuyển code preview TV3-02/03/04:** Đưa mã nguồn tạo phòng, khám phá, tham gia/rời phòng và 21 unit/widget test từ `classroom_chat_tv3_preview` vào đúng cấu trúc `lib/features/study_community/` và `test/study_community/` trên nhánh `tv3`.
2. **TV3-05 `RoomMembersScreen`:** Hiển thị tên, avatar dựng sẵn từ assets, vai trò (`Chủ phòng` / `Thành viên`), cập nhật khi tham gia/rời và cung cấp đầu nối mở hồ sơ (`uid`) cho TV1, chat riêng (`peerUid`) cho TV2.
3. **TV3-06 Thông báo ghim:** Một thông báo/phòng tối đa 300 ký tự, phân quyền chỉ `owner` tạo/sửa/bỏ ghim, có stream cho TV2 hiển thị trong `ChatScreen`.
4. **TV3-07, TV3-08 & TV3-01:** Theme sáng/tối lưu lựa chọn trên thiết bị, `SettingsScreen`, `AppShell` và `HomeScreen` (phần sửa `lib/app/**`, `lib/main.dart`, `pubspec.yaml` thực hiện trên nhánh `integration/...` riêng).
5. **Tích hợp & nghiệm thu:** Nối Firebase Realtime Database, Firebase Auth, Security Rules cho `rooms` / `roomMembers` / `roomNotices`, ghép với TV1 và TV2, rồi chạy đủ bộ kiểm thử T01–T24.
