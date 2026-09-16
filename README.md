# Bé Xem Vui v6.2

Ứng dụng SwiftUI iOS 16 giúp phụ huynh tạo thư viện video an toàn cho trẻ.

- Chọn thư mục video local MP4/MOV/M4V.
- Tự tạo thumbnail từ khung hình tại giây thứ 2.
- Thêm từng liên kết YouTube đã được phụ huynh duyệt.
- Tự lấy tiêu đề, tên kênh và thumbnail YouTube.
- PIN phụ huynh, giới hạn phút mỗi ngày, khung giờ xem và lịch sử.

PIN mặc định: `1234`.

## Tạo IPA
Đưa mã nguồn lên GitHub, chạy workflow **Tạo IPA chưa ký**, tải artifact rồi ký bằng công cụ phù hợp.

## Bản v6.1
- Sửa lỗi YouTube 152-4 bằng iframe trực tiếp với nguồn YouTube hợp lệ và referrer policy.

## Bản v6.2
- Thử nghiệm trình phát bằng thư viện YouTube iOS Player Helper 1.0.4 qua Swift Package Manager.
