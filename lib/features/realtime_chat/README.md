# TV2 Realtime Chat và Presence

Nhánh: `tv2`. Source chỉ trong `lib/features/realtime_chat/`; test ở `test/realtime_chat/`; ghi chú tích hợp tại `docs/members/tv2/`.

Chat riêng, chat nhóm, danh sách hội thoại, gửi/nhận realtime, presence nhiều thiết bị, SQLite cache tối đa 30 tin mỗi hội thoại. Nhận peerUid hoặc roomId từ module khác; không quản lý thành viên phòng.

Màn hình bàn giao: ConversationsScreen, ChatScreen, MessageBubble, ô nhập tin; các trạng thái loading/empty/error/offline.

## Vị trí code

- `domain/`: model/interface và quy tắc nghiệp vụ.
- `data/`: repository, Firebase gateway, SQLite (nếu có).
- `presentation/`: màn hình/widget/state; thay placeholder khi ghép chức năng thật.
- `assets/`: tài nguyên riêng; đề nghị TV3 khai báo vào pubspec.
- `integration/`: adapter và Rules fragment cho node directChats, userDirectChats, messages, presence.
- `realtime_chat.dart`: export API công khai của module.

Không sửa module người khác hoặc ghi đè pubspec/main/router. Đề nghị thay đổi file chung trong ghi chú thành viên; người tích hợp ghép. Đọc docs/module_contracts.md và docs/FILE_OWNERSHIP.md trước khi code. Placeholder hiện chỉ giúp khung app chạy, chưa có nghiệp vụ.
