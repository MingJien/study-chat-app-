# TV3 Study Community và App UI

Nhánh: `tv3`. Source chỉ trong `lib/features/study_community/`; test ở `test/study_community/`; ghi chú tích hợp tại `docs/members/tv3/`.

Trang chủ, tạo/tìm/tham gia/rời phòng, danh sách thành viên và thông báo ghim. Dùng profile TV1, chat TV2. Đồng thời phụ trách tích hợp AppShell/router/theme ở lib/app trong PR riêng.

Màn hình bàn giao: HomeScreen, RoomsScreen, CreateRoomScreen, RoomDetailScreen, RoomMembersScreen, SettingsScreen; AppShell/router/theme nằm ở lib/app.

## Vị trí code

- `domain/`: model/interface và quy tắc nghiệp vụ.
- `data/`: repository, Firebase gateway, SQLite (nếu có).
- `presentation/`: màn hình/widget/state; thay placeholder khi ghép chức năng thật.
- `assets/`: tài nguyên riêng; đề nghị TV3 khai báo vào pubspec.
- `integration/`: adapter và Rules fragment cho node rooms, roomMembers, roomNotices.
- `study_community.dart`: export API công khai của module.

Không sửa module người khác hoặc ghi đè pubspec/main/router. Đề nghị thay đổi file chung trong ghi chú thành viên; người tích hợp ghép. Đọc docs/module_contracts.md và docs/FILE_OWNERSHIP.md trước khi code. Placeholder hiện chỉ giúp khung app chạy, chưa có nghiệp vụ.
