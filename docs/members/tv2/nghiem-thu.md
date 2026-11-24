# Biên bản kiểm thử TV2

Ngày kiểm tra 24/11/2026. Đối tượng kiểm thử là mã nguồn trên nhánh `tv2`, Firebase Auth và Realtime Database Emulator, SQLite và bản Flutter Web release. Các tài khoản thử được tạo ở thời điểm chạy. Máy phát triển dùng Edge và Chrome, hai hồ sơ trình duyệt độc lập và một tab bổ sung để mô phỏng nhiều kết nối của cùng UID.

| Hạng mục | Thao tác và kết quả quan sát | Bằng chứng |
| --- | --- | --- |
| T05–T06 · Định danh | A và B đồng thời mở DM từ hai phía. Cùng ID, cả hai chỉ mục tồn tại. Ký tự phân cách trong UID không tạo va chạm. | Domain test, RTDB test |
| T07–T09 · Gửi nhận | Hai tài khoản gửi hai chiều. Stream của người nhận nhận đủ hai tin. Empty, whitespace, 501 ký tự bị chặn, 500 ký tự hợp lệ. | RTDB test, Edge |
| T10–T12 · Ngoại tuyến | Ghi 35 tin vào SQLite còn đúng 30. Sau upsert tin cuối chỉ có một bản. Ngắt RTDB ở A, A thấy nhãn cache, nút gửi bị khóa. B gửi khi A mất kết nối, A nhận sau khi nối lại. | SQLite test, Edge |
| T13, T15, T17 · Phòng | A tạo phòng, B tham gia, hai tài khoản trao đổi. Ghim từ chủ phòng xuất hiện ở cả hai màn hình. | RTDB test, Edge |
| T16, T18 · Phân quyền | C ngoài phòng bị từ chối đọc và ghi. Thành viên rời phòng mất quyền. Thành viên thường bị từ chối ghi ghim. Tin giả senderId, xóa/sửa tin và truy vấn thiếu giới hạn đều bị Rules từ chối. | RTDB test |
| T19 · Nhiều phiên | Cùng UID có hai tab tạo hai session. Đóng tab phụ còn một session. Đăng xuất phiên cuối đưa số session về 0. | Edge và giá trị RTDB |
| T20, T22 · Theme và phiên | Chuyển sang tối, tải lại trang, ứng dụng khôi phục tài khoản và giao diện. | Edge, Chrome |
| T21 · Tách tài khoản | Sau khi đăng xuất A, C đăng nhập trên cùng trình duyệt. Ngắt RTDB ở C, danh sách C trống, không lộ phòng của A. SQLite test kiểm tra tách hàng theo owner_uid. | SQLite test, Edge |
| T23 · Lỗi | Giao diện giữ được phiên khi mất kết nối. Bộ Rules kiểm tra thao tác bị từ chối. Bài test trình duyệt chặn cả hai máy chủ Auth production để phát hiện cấu hình demo bị sai. | RTDB test, Edge |
| T24 · Màn hẹp | Widget test dùng màn rộng 320 px và tin dài 500 ký tự. Edge rộng 390 px nhận/gửi chat phòng. Vùng soạn tin đã chừa chỗ cho banner Emulator. | Widget test, Edge |

## Môi trường và cách tái hiện

- [CI cho mã nguồn bàn giao](https://github.com/MingJien/study-chat-app-/actions/runs/45408826744) kiểm tra khóa dependency, format, analyzer, unit/widget, SQLite, Rules, build Web và Android. Kết quả từng job có ở mục **Actions** của repo.
- [Bộ test Firebase](../../../test/emulator/chat.test.mjs) chạy với `node --test test/emulator/chat.test.mjs` khi Emulator đang hoạt động. Các assertion kiểm cả kết quả ghi và từ chối từ server.
- [Bộ test trình duyệt](../../../test/browser/chat.cjs) dùng Playwright. CI cài trình điều khiển vào thư mục tạm của runner. Có thể đặt `TV2_PLAYWRIGHT` trỏ đến gói Playwright đã cài, rồi chạy `node test/browser/chat.cjs` khi bản web đang mở cổng 8765. Thêm `--record` để tái hiện kịch bản có phụ đề và lưu video vào `.local-data/evidence`.
- Job Android của workflow CI build APK release cho ARM64 thành công.
- Trên Windows, lần khởi động đầu gặp lỗi chờ preLaunchTask. Sau khi chỉnh bộ khởi động, `python -u tools/preview.py` bật cả hai Emulator và trả `TV2 READY`. Bộ test Firebase đạt đủ 6/6. Nhấn F5 trong VS Code khi dịch vụ đang chạy đã mở cửa sổ Study Chat trong Edge. Luồng hai tài khoản đã được kiểm tra trên Edge và tự động chạy lại trên Chrome trong CI.
- Kiểm thử bàn phím Android thật, xoay máy, lifecycle hệ điều hành và toàn bộ T01–T24 sau khi merge là việc nghiệm thu bản tích hợp của nhóm. Bảng trên ghi rõ phần đã quan sát trên nhánh TV2.

## Hai lỗi được phát hiện trong kiểm thử trình duyệt

1. Banner Auth Emulator che vùng chạm ở màn hẹp. Bản sửa dành riêng 32 px cho banner và giữ nút gửi trong vùng thao tác.
2. Khi tải lại phiên rồi đổi tài khoản, bản web release từng khởi tạo Auth trước khi gắn Emulator. Bản sửa gắn Emulator ngay tại `initializeAuth` của Firebase JS đối với project demo. Kịch bản hồi quy đăng nhập tài khoản thứ ba và chặn mọi request tới Auth production.
