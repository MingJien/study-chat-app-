# Study Chat App

Ứng dụng thảo luận học tập bằng Flutter và Firebase. Nhánh `tv2` triển khai chat riêng, chat phòng, trạng thái hoạt động và lịch sử SQLite trên bộ khung chung ở `develop`.

## Chạy TV2 trong VS Code

Mở thư mục này, chọn **Run and Debug → TV2 · Mở Study Chat trong trình duyệt** và nhấn **F5**. Bản web đã biên dịch dùng Firebase Emulator trên máy. Có thể chạy cùng cấu hình bằng `python tools/preview.py` rồi mở <http://127.0.0.1:8765>.

Xem [hướng dẫn TV2 và tài liệu bàn giao](docs/members/tv2/README.md) để tạo hai tài khoản thử, mở phòng và kiểm tra khi mất mạng.

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

## Phát triển mã Flutter của nhóm

Mốc công cụ: Flutter **3.47.7**, Dart **3.13.5**, Android SDK tương thích Flutter. Nên clone vào đường dẫn không dấu, ví dụ `C:/projects/study-chat-app`.

```powershell
flutter pub get
flutter analyze
flutter test
flutter run
```

Các lệnh Flutter ở trên dành cho máy phát triển của nhóm. Quy trình F5 ở đầu trang dùng bản web đóng gói. GitHub Actions xây dựng và kiểm tra bản web từ mã Dart.

## Bắt đầu làm nhóm

1. Kiểm tra `main` và `develop` đã có khung trước khi ba người bắt đầu. Nếu đã có, bỏ qua bước khởi tạo trong [quy trình Git](docs/GIT_WORKFLOW.md).
2. Mỗi người dùng nhánh `tv1`, `tv2` hoặc `tv3` đã có, cập nhật từ `develop` rồi làm trong module của mình.
3. Chỉ stage đường dẫn mình phụ trách. Tạo PR vào `develop`, người khác review; đưa bản chạy được từ `develop` sang `main`.
4. Đề nghị thêm package/assets/route trong `docs/members/tvN/`; TV3 ghép file chung trong PR riêng.

Tên `feature/auth-contacts`, `feature/realtime-chat`, `feature/study-community` trong tài liệu tương ứng `tv1`, `tv2`, `tv3` trên repo. Dùng một bộ tên, không cần thêm ba nhánh song song.

Đọc [quyền sửa file](docs/FILE_OWNERSHIP.md), [hợp đồng module](docs/module_contracts.md), [schema dữ liệu](docs/data_schema.md) trước khi code. Source TV1 hiện có ở workspace bên ngoài bản clone chưa được chép vào khung này. Khi ghép, đưa source/test vào đúng module, thay placeholder và đối chiếu dependency/API; không chép cả app dev hay đè `pubspec.yaml`.
