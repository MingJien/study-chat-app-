# TV1 Auth và Contacts

Nhánh: `tv1`. Source chỉ trong `lib/features/auth_contacts/`; test ở `test/auth_contacts/`; ghi chú tích hợp tại `docs/members/tv1/`.

Đăng ký/đăng nhập/đăng xuất, hồ sơ, avatar, tìm sinh viên, danh bạ một chiều và SQLite cache. Chuyển peerUid cho TV2 khi nhấn Nhắn tin; không sinh conversationId.

Màn hình bàn giao: LoginScreen, RegisterScreen, ProfileScreen, EditProfileScreen, ContactsScreen, SearchStudentsScreen, ContactDetailScreen (hoặc tái dùng ProfileScreen).

## Vị trí code

- `domain/`: model/interface và quy tắc nghiệp vụ.
- `data/`: repository, Firebase gateway, SQLite (nếu có).
- `presentation/`: màn hình/widget/state; thay placeholder khi ghép chức năng thật.
- `assets/`: tài nguyên riêng; đề nghị TV3 khai báo vào pubspec.
- `integration/`: adapter và Rules fragment cho node profiles, userContacts.
- `auth_contacts.dart`: export API công khai của module.

Không sửa module người khác hoặc ghi đè pubspec/main/router. Đề nghị thay đổi file chung trong ghi chú thành viên; người tích hợp ghép. Đọc docs/module_contracts.md và docs/FILE_OWNERSHIP.md trước khi code. Placeholder hiện chỉ giúp khung app chạy, chưa có nghiệp vụ.
