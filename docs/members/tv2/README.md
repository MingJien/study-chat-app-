# TV2 · Hội thoại và trạng thái hoạt động

Nhánh giao bài và cập nhật của TV2 là `tv2`. Mở thư mục gốc trong VS Code, chọn **Run and Debug → TV2 · Mở Study Chat trong trình duyệt** rồi nhấn **F5**. Task phục vụ bản Flutter Web do CI biên dịch và bật Firebase Auth, Realtime Database Emulator ở máy local. Giao diện dùng cùng mã Dart với ứng dụng mobile.

## Chạy và đăng nhập

- Cần Python 3.9+, Node.js 22+ có `npx`, Java 21+ và Edge. Lần đầu cần Internet để lấy Firebase CLI và Database Emulator. Các lần sau dùng cache của công cụ. Java của Database Emulator có giới hạn heap mặc định 192 MB.
- Có thể chạy `python tools/preview.py` trong terminal VS Code rồi mở <http://127.0.0.1:8765>. Cổng Auth là 9099, Database là 9000 và Emulator Hub là 4400. Khi đóng demo bằng Ctrl+C, CLI xuất dữ liệu vào `.local-data/firebase` để nhập lại lần sau.
- Chọn **Đăng ký**, nhập email thử nghiệm, mật khẩu ít nhất sáu ký tự và tên hiển thị. Tạo tài khoản thứ hai trong cửa sổ InPrivate hoặc một hồ sơ trình duyệt khác. Hai tab thường dùng cùng phiên Auth.
- Trong **Bạn học**, bấm biểu tượng nhắn tin của bạn đối thoại. Trong **Phòng học**, nút **+** tạo phòng, chạm vào tên phòng để tham gia và mở chat. Chủ phòng quản lý thông báo ghim qua menu của phòng. Thành viên dùng menu để rời phòng.
- Dùng menu tài khoản để xem hồ sơ hoặc đăng xuất. Nút mặt trăng/mặt trời đổi và lưu giao diện. Danh sách tin có tìm kiếm theo tên và lọc chat riêng/phòng.
- Khi đang ở màn chat, ngắt kết nối RTDB để xem nhãn **Ngoại tuyến** và tối đa 30 tin đã lưu. Thiết bị cần có ít nhất một lần nhận dữ liệu online. Sau khi có mạng, màn hình cập nhật từ Firebase.

## Tích hợp với nhóm

- [Biên bản kiểm thử và kết quả F5](nghiem-thu.md)
- [Bản Flutter Web dùng để chạy F5](../../../preview/study-chat-web.zip)

| Nhu cầu | Điểm vào |
| --- | --- |
| TV1 mở chat với một UID | `Navigator.pushNamed(context, '/chat', arguments: ChatArgs.direct(peerUid))` |
| TV3 mở phòng | `ChatArgs.room(roomId)` cho route `/chat`. Thành viên được xác minh tại RTDB. |
| Mở từ danh sách gần đây | `ChatArgs.existing(summary)`. Có thể mở từ cache khi offline. |
| Chat mở hồ sơ | Route `/profile` nhận UID. Tên và avatar đọc từ `/profiles`. |
| Tích hợp dữ liệu | `ChatApi` trong `domain/chat.dart`, hiện thực qua `ChatRepository`. |
| Kết thúc phiên | Gọi và chờ `repo.close()` trước `signOut()`. Navigator con có key theo UID. |

Nhánh dùng hai màn hình tích hợp tối thiểu cho hồ sơ và phòng, giúp chạy các điểm vào TV2 trước khi ghép các module đầy đủ. Khi TV1 và TV3 ghép vào `develop`, giữ `ChatApi`, `ChatArgs` và các Rules TV2, thay phần chọn bạn/phòng bằng màn hình chính thức của từng thành viên. Rules trong `firebase/database.rules.json` được thiết kế cho môi trường Emulator của nhánh này. Nhóm đối chiếu quyền ghi các node TV1, TV3 khi tích hợp.

## Kiểm tra lại

- Với Firebase Emulator đang chạy, dùng `node --test test/emulator/chat.test.mjs`. Test tạo ba tài khoản tạm với email thuộc `example.test`.
- Workflow **TV2 web** trên GitHub thực hiện kiểm tra định dạng, Flutter analyze, Flutter test, kiểm thử Rules thực tế, tạo worker SQLite WebAssembly và build web release. Artifact tên `study-chat-tv2-web` có thể dùng với `python tools/preview.py --archive <duong-dan-zip>`.
- Tài khoản và dữ liệu lớp thật không nằm trong mã nguồn. Bản web đóng gói sử dụng project demo `demo-classroom-tv2`. Để build cho một dự án Firebase thật, nhóm cấu hình `FIREBASE_EMULATOR=false` cùng các biến `FIREBASE_*` đọc ở `lib/main.dart`, bật Email/Password, cấu hình RTDB và kiểm tra bộ Rules tích hợp trước khi phát hành.
