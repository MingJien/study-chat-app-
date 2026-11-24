# Phối hợp Firebase và Security Rules

Nhánh `tv2` dùng [Rules cho Firebase Emulator](../firebase/database.rules.json) cùng project `demo-classroom-tv2`. Bộ [kiểm thử Auth và RTDB](../test/emulator/chat.test.mjs) thực hiện các thao tác bằng tài khoản thử. Khi ghép ứng dụng, TV3 tổng hợp quyền của ba module và chạy lại các ca kiểm thử trên Rules cuối.

| Thành viên | Node phụ trách |
| --- | --- |
| TV1 | profiles, userContacts |
| TV2 | directChats, userDirectChats, messages, presence |
| TV3 | rooms, roomMembers, roomNotices |

Trước khi ghép: chốt schema chi tiết, quyền từng path, index query và kiểm tra với Firebase Emulator. Auth UID phải khớp chủ dữ liệu/senderId. Chat riêng giới hạn hai người; chat nhóm kiểm tra membership, kể cả khi người ngoài nhập roomId thủ công. Chỉ owner được chỉnh thông báo ghim; thành viên rời phòng không đọc/gửi tin mới.

Không dùng Rules mở toàn cục để chữa lỗi permission. Firebase config được người tích hợp tạo khi đã chọn project; `firebase_options.dart`, `google-services.json` và file sinh trên máy đã được ignore theo quy ước repo. Các file này không phải mọi trường hợp đều là bí mật, nhưng phải phân biệt với private key của service account và thống nhất cách cấp cấu hình dev cho nhóm. Không commit mật khẩu, service-account private key, keystore hoặc .env thật.

Phiên bản FlutterFire và SQLite của TV2 đã có trong pubspec.lock. Nhóm thống nhất cấu hình Firebase thật khi tích hợp.
