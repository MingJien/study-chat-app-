# Study Chat App

Khung Flutter Android cho nhóm 3 người, theo tài liệu phân công ngày 14/11/2026. Repository gốc khi tạo khung chỉ có README; các nhánh `main`, `develop`, `tv1`, `tv2`, `tv3` cùng ở commit `17823a6`. Cấu trúc bám theo Phụ lục A của tài liệu.

## Chia phần việc

| Thành viên | Nhánh GitHub | Source riêng | Test riêng |
| --- | --- | --- | --- |
| TV1 – Auth, hồ sơ, danh bạ | `tv1` | `lib/features/auth_contacts/` | `test/auth_contacts/` |
| TV2 – Chat, presence, cache tin nhắn | `tv2` | `lib/features/realtime_chat/` | `test/realtime_chat/` |
| TV3 – Phòng học, thông báo ghim | `tv3` | `lib/features/study_community/` | `test/study_community/` |

TV3 đồng thời tích hợp `main.dart`, `app/`, theme và router. Dependency, model/contract chung, cấu hình Android/Firebase cần cả nhóm thống nhất. Quy ước này giảm xung đột; thư mục và nhánh không tự ngăn người khác sửa cùng file.

## Cấu trúc

```text
study-chat-app-/
├── android/                         # Khung Android chung
├── lib/
│   ├── main.dart                    # Điểm chạy duy nhất, TV3 tích hợp
│   ├── app/                         # app.dart, app_router.dart, app_theme.dart, app_shell.dart
│   ├── core/
│   │   ├── models/                  # Model chung đã thống nhất
│   │   ├── contracts/               # Interface chung đã thống nhất
│   │   ├── navigation/              # Kiểu tham số route
│   │   └── widgets/                 # Widget dùng chung
│   └── features/
│       ├── auth_contacts/           # TV1
│       ├── realtime_chat/           # TV2
│       └── study_community/         # TV3
├── test/
│   ├── app/                         # Kiểm tra tích hợp, TV3
│   ├── auth_contacts/
│   ├── realtime_chat/
│   └── study_community/
├── docs/
│   ├── GIT_WORKFLOW.md
│   ├── FILE_OWNERSHIP.md
│   ├── requirements.md
│   ├── data_schema.md
│   ├── module_contracts.md
│   ├── firebase_rules.md
│   ├── test_cases.md
│   └── members/{tv1,tv2,tv3}/        # Yêu cầu tích hợp riêng
├── .github/                         # Mẫu PR và kiểm tra Flutter
├── pubspec.yaml                     # Dependency chung
└── pubspec.lock                     # Commit để nhóm dùng cùng phiên bản
```

Mỗi feature có `data/`, `domain/`, `presentation/`, `assets/`, `integration/` và file export. Thư mục chưa có code giữ bằng `.gitkeep` để Git đưa lên đầy đủ.

## Chạy khung ứng dụng

Mốc công cụ: Flutter **3.47.7**, Dart **3.13.5**, Android SDK tương thích Flutter. Nên clone vào đường dẫn không dấu, ví dụ `C:/projects/study-chat-app`.

```powershell
flutter pub get
flutter analyze
flutter test
flutter run
```

App có 5 tab để kiểm tra kết nối module; từng tab ghi rõ chức năng chưa triển khai. Khung chưa đăng nhập, chưa kết nối Firebase và chưa có dữ liệu thật. Chỉ route `/` đã nối; route nghiệp vụ chờ tích hợp. Theme theo hệ thống; chức năng chọn/lưu theme do TV3 triển khai sau.

Đã kiểm tra khung bằng `dart format`, `flutter analyze` (không có lỗi) và `flutter test` (1 smoke test chuyển đủ 5 tab). Analyzer Flutter 3.47.7 gặp `FormatException` khi chạy trong đường dẫn có dấu tiếng Việt của workspace; analyze/test đã chạy đạt trên bản sao tạm có đường dẫn ASCII. Nếu gặp lỗi tương tự, dùng bản clone trong đường dẫn không dấu như gợi ý trên. Chưa kiểm tra build APK hoặc nghiệp vụ Firebase.

## Bắt đầu làm nhóm

1. Kiểm tra `main` và `develop` đã có khung trước khi ba người bắt đầu. Nếu đã có, bỏ qua bước khởi tạo trong [quy trình Git](docs/GIT_WORKFLOW.md).
2. Mỗi người dùng nhánh `tv1`, `tv2` hoặc `tv3` đã có, cập nhật từ `develop` rồi làm trong module của mình.
3. Chỉ stage đường dẫn mình phụ trách. Tạo PR vào `develop`, người khác review; đưa bản chạy được từ `develop` sang `main`.
4. Đề nghị thêm package/assets/route trong `docs/members/tvN/`; TV3 ghép file chung trong PR riêng.

Tên `feature/auth-contacts`, `feature/realtime-chat`, `feature/study-community` trong tài liệu tương ứng `tv1`, `tv2`, `tv3` trên repo. Dùng một bộ tên, không cần thêm ba nhánh song song.

Đọc [quyền sửa file](docs/FILE_OWNERSHIP.md), [hợp đồng module](docs/module_contracts.md), [schema dữ liệu](docs/data_schema.md) trước khi code. Source TV1 hiện có ở workspace bên ngoài bản clone chưa được chép vào khung này. Khi ghép, đưa source/test vào đúng module, thay placeholder và đối chiếu dependency/API; không chép cả app dev hay đè `pubspec.yaml`.
