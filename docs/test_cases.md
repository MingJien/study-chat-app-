# Kiểm thử tích hợp

Chuẩn bị ba tài khoản A/B/C, ít nhất hai thiết bị hoặc emulator. Các trường hợp dưới đây lấy từ phân công, **chưa được nghiệm thu**; smoke test hiện chỉ kiểm tra khung 5 tab.

| Mã | Tình huống | Kết quả cần đạt |
| --- | --- | --- |
| T01 | A đăng ký | Auth và profile tạo thành công |
| T02 | A đổi tên/avatar | Module khác nhận thay đổi |
| T03 | A thêm B | Không trùng liên hệ |
| T04 | Mở danh bạ offline | Hiện SQLite cache |
| T05 | A mở chat B | Một hội thoại |
| T06 | B mở chat A | Cùng conversationId |
| T07 | A gửi B | B nhận realtime |
| T08 | Gửi tin rỗng | Bị chặn |
| T09 | Hai người gửi đồng thời | Không mất/trùng tin |
| T10 | Mở chat rồi tắt mạng | Xem tối đa 30 tin đã lưu |
| T11 | Gửi offline | Chặn và báo rõ |
| T12 | Kết nối lại | Tải và cache tin mới |
| T13 | A tạo phòng | Phòng xuất hiện |
| T14 | B/C tham gia | Không trùng thành viên |
| T15 | A gửi chat phòng | B/C nhận |
| T16 | Người ngoài đọc chat phòng | Firebase từ chối |
| T17 | A ghim thông báo | Thành viên thấy |
| T18 | B sửa ghim của A | Bị từ chối |
| T19 | A ngắt kết nối đột ngột | Presence đúng, xét nhiều thiết bị |
| T20 | Đổi theme | Toàn app đổi đồng bộ |
| T21 | A đăng xuất, B đăng nhập cùng máy | Không lộ cache A |
| T22 | Đóng/mở app | Khôi phục phiên/theme |
| T23 | Firebase lỗi | Hiện lỗi, không crash |
| T24 | Xoay màn hình/mở bàn phím | Không tràn hoặc che ô nhập |

Mỗi module lưu unit/widget test trong thư mục test riêng; Firebase Rules test theo module. PR chức năng cần nêu lệnh đã chạy và kết quả thật. Trước khi merge develop vào main, kiểm tra luồng TV1 → TV2, TV3 → TV2 và đổi tài khoản.
