# Phối hợp Firebase và Security Rules

Khung chưa có Firebase project, file cấu hình hay Rules deploy. Mỗi thành viên đặt Rules fragment và hướng dẫn kiểm tra của mình trong `lib/features/<module>/integration/`. TV3 ghép thành Rules chung sau khi ba người review, không triển khai nguyên file Rules test của một module đè toàn bộ database.

| Thành viên | Node phụ trách |
| --- | --- |
| TV1 | profiles, userContacts |
| TV2 | directChats, userDirectChats, messages, presence |
| TV3 | rooms, roomMembers, roomNotices |

Trước khi ghép: chốt schema chi tiết, quyền từng path, index query và kiểm tra với Firebase Emulator. Auth UID phải khớp chủ dữ liệu/senderId. Chat riêng giới hạn hai người; chat nhóm kiểm tra membership, kể cả khi người ngoài nhập roomId thủ công. Chỉ owner được chỉnh thông báo ghim; thành viên rời phòng không đọc/gửi tin mới.

Không dùng Rules mở toàn cục để chữa lỗi permission. Firebase config được người tích hợp tạo khi đã chọn project; `firebase_options.dart`, `google-services.json` và file sinh trên máy đã được ignore theo quy ước repo. Các file này không phải mọi trường hợp đều là bí mật, nhưng phải phân biệt với private key của service account và thống nhất cách cấp cấu hình dev cho nhóm. Không commit mật khẩu, service-account private key, keystore hoặc .env thật.

Dependency Firebase/SQLite thêm vào pubspec ở PR tích hợp. Không chạy FlutterFire configure độc lập trên ba nhánh rồi chép đè cấu hình Android.
