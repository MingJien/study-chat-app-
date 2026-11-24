# Phạm vi và phân công

Nguồn: “Phân công đề tài mobile ( dự án webchat ).docx”, phiên bản 1.0 ngày 14/11/2026 trong workspace. Tài liệu gốc là bản phân công đề xuất; các chữ ký xác nhận chưa được điền. Đây là bản tóm tắt để tổ chức source, không phải xác nhận mọi nghiệp vụ đã triển khai.

Nền tảng Android bằng Flutter/Dart, Firebase Authentication, Realtime Database và SQLite (sqflite). Ứng dụng có Trang chủ, Phòng học, Tin nhắn, Bạn học, Cá nhân.

| Thành viên | Việc cần bàn giao |
| --- | --- |
| TV1 | Đăng ký/đăng nhập/đăng xuất, hồ sơ, avatar có sẵn, tìm sinh viên, danh bạ một chiều, cache danh bạ theo owner_uid |
| TV2 | Hội thoại riêng duy nhất theo cặp UID, chat nhóm nhận roomId, stream tin nhắn, tự cuộn hợp lý, presence nhiều thiết bị, cache 30 tin/hội thoại |
| TV3 | Tạo/tìm/tham gia/rời phòng, danh sách thành viên, thông báo ghim, Home, AppShell, router, theme sáng/tối và lưu lựa chọn |

Bản đầu chỉ nhắn văn bản tối đa 500 ký tự; offline chỉ xem cache, không gửi tin hay thêm/xóa danh bạ. Phòng công khai nhưng phải là thành viên mới đọc/gửi chat. Chủ phòng chưa được rời vì chưa có chuyển quyền. Mỗi phòng có một thông báo tối đa 300 ký tự do owner quản lý.

Chưa triển khai ảnh/file trong chat, gọi thoại/video, mạng xã hội, AI chatbot, thông báo đẩy, sửa/xóa/thu hồi tin nhắn, chuyển quyền hoặc xóa phòng.

Trên nhánh `tv2`, module hội thoại chạy với Firebase Auth, Realtime Database, REST API của RTDB và SQLite. Hai điểm ghép hồ sơ và phòng cho phép demo độc lập trước khi tích hợp phiên bản đầy đủ của TV1 và TV3. [Hồ sơ bàn giao và kết quả kiểm thử TV2](members/tv2/README.md).
