# Quyền sửa file

| Đường dẫn | Chủ trì | Quy tắc |
| --- | --- | --- |
| lib/features/auth_contacts/** | TV1 | Tự phát triển, bao gồm assets, rule fragment, README |
| test/auth_contacts/** | TV1 | Test riêng |
| docs/members/tv1/** | TV1 | Đề nghị dependency/API/route và bằng chứng |
| lib/features/realtime_chat/** | TV2 | Tự phát triển, bao gồm presence, SQLite chat |
| test/realtime_chat/**, docs/members/tv2/** | TV2 | Test và yêu cầu tích hợp |
| lib/features/study_community/** | TV3 | Tự phát triển phòng, thành viên, thông báo |
| test/study_community/**, docs/members/tv3/** | TV3 | Test và yêu cầu tích hợp |
| lib/main.dart, lib/app/**, test/app/** | TV3 | Ghép module trong PR tích hợp riêng |
| lib/core/** | Cả nhóm thống nhất, TV3 ghép | Không tự đổi model/interface đang được module khác dùng |
| pubspec.yaml, pubspec.lock, analysis_options.yaml | TV3 ghép | Thành viên đề nghị package/version/assets trong docs/members của mình |
| android/**, .metadata, .github/**, .gitignore, .gitattributes | TV3 ghép | Thay đổi hạ tầng cần review |
| docs/*.md, README.md | Cả nhóm | Một người cập nhật phần chung trong mỗi PR |
| Firebase config và Rules chung khi thêm | TV3 ghép, TV1/TV2/TV3 review | Ghép từng node; không ghi đè rule của module khác |

Không đặt thư mục `tv1/`, `tv2/`, `tv3/` chứa ba bản Flutter độc lập tại gốc. Mã chạy chung đi vào `lib/features/`.

## Bên trong mỗi module

- `domain/`: model và interface riêng, quy tắc nghiệp vụ; tránh phụ thuộc UI.
- `data/`: Firebase gateway, SQLite, repository và migration của module.
- `presentation/`: màn hình/widget/state cho module.
- `assets/`: ảnh và tài nguyên của module; thêm khai báo pubspec qua người tích hợp.
- `integration/`: adapter, ghi chú và Firebase Rules fragment của module.
- File `auth_contacts.dart`, `realtime_chat.dart`, `study_community.dart`: điểm export API công khai.

Module khác gọi API đã công bố, không truy cập file data hay SQLite nội bộ. AppShell ghép qua file export; khi thay placeholder, báo TV3 cập nhật import và constructor trong cùng đợt tích hợp. Không giữ placeholder như tính năng đã hoàn thành.
