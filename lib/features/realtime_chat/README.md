# Realtime Chat và Presence

TV2 xuất ChatApi, ChatRepository, ChatArgs, ConversationsScreen và ChatScreen từ realtime_chat.dart. ChatApi định nghĩa sáu điểm tích hợp theo phân công. ChatRepository nhận FirebaseAuth, FirebaseDatabase, ChatCache và ChatRest của một phiên qua constructor.

- domain chứa định danh chat riêng, kiểu dữ liệu, kiểm tra nội dung và hợp đồng.
- data dùng FlutterFire để nhận sự kiện và quản lý presence. Gửi tin qua Firebase REST, xác nhận bằng server và lưu cửa sổ tin vào SQLite.
- presentation dùng StreamBuilder, ScrollController, hai loại bong bóng và điều khiển gửi. Nhấn ảnh hoặc tên để mở hồ sơ theo UID.

Xem [hướng dẫn chạy, route và nghiệm thu TV2](../../../docs/members/tv2/README.md).
