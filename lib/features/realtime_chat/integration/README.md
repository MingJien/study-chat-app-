# Tích hợp TV2

Router dùng ChatArgs.direct(peerUid), ChatArgs.room(roomId) hoặc ChatArgs.existing(summary). Quyền đọc tin và danh tính người gửi do [Firebase Rules](../../../../firebase/database.rules.json) thực thi. Các thao tác cần trạng thái kết nối hiện tại của phiên.

TV3 đọc danh sách từ watchConversations(uid) và có thể ánh xạ ChatSummary sang kiểu tóm tắt của HomeScreen. Thông báo ghim đọc từ roomNotices/{roomId}. TV1 nhận UID khi người dùng chạm vào avatar hoặc tên.

[Hướng dẫn TV2](../../../../docs/members/tv2/README.md)
