# Tích hợp TV3

Đặt adapter và Rules fragment cho rooms, roomMembers, roomNotices ở đây. Chỉ là phần Rules của module; không deploy đè Rules chung. Ghi schema, dependency, route và cách kiểm tra trong docs/members/tv3/ trước khi nhờ TV3 ghép.

## Firebase Rules Fragment (`study_community.rules.json`)

- File [study_community.rules.json](study_community.rules.json) chứa phần Rules cho 3 node do TV3 sở hữu:
  - `rooms/{roomId}`: chỉ tài khoản đã đăng nhập đọc; chỉ `ownerId == auth.uid` tạo mới; kiểm tra độ dài `roomName` (1..60), `subject` (0..60), `description` (0..200) và `createdAt` dạng số.
  - `roomMembers/{roomId}/{uid}`: chỉ tự ghi bản ghi của chính `auth.uid`; không tự gán `owner` nếu không phải chủ phòng; chặn chủ phòng tự rời phòng.
  - `roomNotices/{roomId}`: chỉ thành viên phòng mới đọc; chỉ chủ phòng (`ownerId == auth.uid`) mới tạo/sửa/bỏ ghim; nội dung tối đa 300 ký tự.
- **Lưu ý tích hợp:** Khi ghép với TV1 (`profiles`, `userContacts`) và TV2 (`directChats`, `userDirectChats`, `messages`, `presence`), gộp 3 node này vào file `database.rules.json` chung và kiểm thử bằng Firebase Emulator trước khi deploy.
