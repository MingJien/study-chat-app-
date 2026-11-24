# Hợp đồng giữa các module

Danh mục dưới đây theo tài liệu phân công. TV2 đã công bố [ChatApi](../lib/features/realtime_chat/domain/chat.dart) và [hướng dẫn ghép với TV1, TV3](members/tv2/README.md). Hai module còn lại tiếp tục dùng hợp đồng của nhóm.

| Module | API cần công bố |
| --- | --- |
| TV1 | currentUser, watchAuthState(), getUserProfile(uid), watchUserProfile(uid), searchStudents(keyword), getContacts(uid), addContact(contactUid), removeContact(contactUid) |
| TV2 | openDirectConversation(peerUid), watchConversations(uid), watchMessages(conversationId, type), sendMessage(conversationId, content), watchPresence(uid), getCachedMessages(conversationId) |
| TV3 | watchRooms(), getRoom(roomId), createRoom(data), joinRoom(roomId), leaveRoom(roomId), watchRoomMembers(roomId), watchPinnedNotice(roomId), updatePinnedNotice(roomId, content) |

Đăng ký/đăng nhập/đăng xuất và chỉnh hồ sơ cũng do TV1 cung cấp; đối chiếu `AuthContactsApi` trong source TV1 có sẵn khi ghép. Không tự sao chép StudentProfile/AuthIdentity vào core nếu module đã có kiểu tương ứng; thống nhất một nơi định nghĩa rồi sửa import hoặc dùng adapter.

## Luồng ghép

1. TV1 bấm Nhắn tin → chuyển `peerUid` → TV2 gọi `openDirectConversation`; TV1 không tự sinh conversationId.
2. TV3 mở thảo luận phòng → truyền `roomId` và loại nhóm → TV2 dùng conversationId = roomId, kiểm tra membership và Rules.
3. TV2 bấm avatar → chuyển `uid` → màn hình hồ sơ TV1.
4. TV3 cập nhật notice; TV2 hiển thị notice trong ChatScreen qua API hoặc widget/callback đã thống nhất.
5. Đăng xuất/đổi UID → AppShell bỏ navigator cũ; từng module hủy listener và chỉ đọc cache của UID hiện tại.

Điểm vào ứng dụng khởi tạo Firebase một lần. TV2 nhận Auth, Database, SQLite và REST client qua constructor. Nhánh `tv2` dùng Firebase Emulator theo mặc định.

## Route dự kiến

| Route | Phụ trách | Tham số cần thống nhất |
| --- | --- | --- |
| /login, /register | TV1 | Không |
| /home | TV3 | Không |
| /contacts | TV1 | UID từ phiên hiện tại |
| /chats | TV2 | UID từ phiên hiện tại |
| /chat | TV2 + TV3 ghép | peerUid cho mở DM; hoặc roomId + type=group; hội thoại có sẵn dùng conversationId + type |
| /rooms | TV3 | Không |
| /room-detail | TV3 | roomId |
| /profile | TV1 | uid |
| /settings | TV3 | Không |

Trên nhánh `tv2`, các route `/home`, `/chats`, `/rooms`, `/contacts`, `/settings`, `/chat` và `/profile` nằm trong Navigator theo phiên đã xác thực. Route `/chat` nhận ChatArgs, route `/profile` nhận UID. Màn đăng nhập/đăng ký đi qua Auth gate. Route chi tiết phòng thuộc bàn giao TV3.
