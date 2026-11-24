# Hợp đồng dữ liệu

Mọi ID là String, không dùng displayName làm khóa. UID do Firebase Auth tạo. Thời gian Firebase là số nguyên mili-giây theo server.

| Firebase path | Chủ sở hữu | Nội dung |
| --- | --- | --- |
| /profiles/{uid} | TV1 | uid, displayName, email, avatarId, className, bio |
| /userContacts/{uid}/{contactUid} | TV1 | Liên hệ một chiều theo UID chủ |
| /rooms/{roomId} | TV3 | roomId, roomName, subject, description, ownerId, createdAt |
| /roomMembers/{roomId}/{uid} | TV3 | Thành viên và vai trò |
| /roomNotices/{roomId} | TV3 | Một thông báo ghim |
| /directChats/{conversationId} | TV2 | Hai thành viên chat riêng |
| /userDirectChats/{uid}/{conversationId} | TV2 | Chỉ mục cho cả hai người |
| /messages/{conversationId}/{messageId} | TV2 | senderId, content, createdAt; cùng schema cho DM/nhóm |
| /presence/{uid} | TV2 | Các phiên/thiết bị và lần hoạt động gần nhất |

TV3 tạo roomId có tiền tố `room_`; chat nhóm dùng conversationId = roomId. TV2 tạo ID chat riêng có tiền tố `dm_` từ cặp UID theo thứ tự cố định. Chốt cách mã hóa để không có hai cặp UID khác nhau tạo cùng ID; có test tính đối xứng và tránh trùng. Không tự ghép chuỗi UID rời rạc tại nhiều màn hình.

Nhánh TV2 dùng `directChats/{cid} = {first, second}` với hai UID đã sắp và `userDirectChats/{uid}/{cid} = true` cho mỗi người. Mỗi session ghi true tại `presence/{uid}/sessions/{key}` và cập nhật `lastSeen` khi ngắt kết nối. Rules kiểm tra truy vấn tin theo `createdAt`, giới hạn tối đa 30. Đối chiếu [bộ Rules](../firebase/database.rules.json) khi tích hợp.

## SQLite

| Module | Khóa chính | Cột |
| --- | --- | --- |
| TV1 – contacts | (owner_uid, contact_uid) | owner_uid, contact_uid, display_name, avatar_id, class_name, updated_at |
| TV2 – messages | (owner_uid, message_id) | owner_uid, conversation_id, message_id, sender_id, content, created_at |

Mỗi module quản lý schema/migration riêng. Không dùng chung bảng hoặc tự nâng version database của module khác. Phân vùng theo UID, không lộ dữ liệu A khi đăng nhập B. TV2 giữ tối đa 30 tin gần nhất mỗi hội thoại, upsert messageId trùng. Firebase là nguồn chính; cache chỉ nhận dữ liệu đã xác nhận.

Dùng multi-location update cho thay đổi nhiều path liên quan khi phù hợp; giới hạn query tin nhắn và khai báo index sau khi thống nhất query.
