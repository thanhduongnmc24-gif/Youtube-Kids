# Bé Xem Vui v6.6

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

## Bản v6.3
- Phát YouTube qua trang HTTPS trung gian trong `docs/player.html`.
- Tự triển khai trang phát bằng GitHub Pages.
- Nhập URL `player.html` trong Cài đặt phụ huynh.

## Bật trang phát HTTPS
1. Đẩy mã nguồn lên GitHub.
2. Vào Settings > Pages > Source, chọn GitHub Actions.
3. Chạy workflow `Trien khai trang phat HTTPS`.
4. Lấy URL Pages và thêm `/player.html`, sau đó dán vào ứng dụng.


## Bản v6.4
- Hỗ trợ `TaiNguyen/VideoMacDinh.json` để nhúng sẵn video YouTube theo danh mục.
- Thêm hai video mẫu vào danh mục Truyện cổ tích.
- Xáo trộn thứ tự video mỗi lần mở ứng dụng và giữ ổn định trong phiên sử dụng.
- Lưu thumbnail local và YouTube tại Documents/Thumbnails để không tải lại ở lần mở sau.
- Ghi nhớ video mặc định đã bị phụ huynh xóa, không tự thêm lại.

## Tự thêm video mặc định
Sửa file `TaiNguyen/VideoMacDinh.json`, mỗi phần tử gồm `link` và `danhMuc`.


## Bản v6.5
- Sửa nạp video mặc định: có danh sách dự phòng trong Swift, không còn thất bại im lặng khi thiếu JSON.
- Thêm nút Đồng bộ và Khôi phục video mặc định.
- Bỏ hoàn toàn bước workflow có thể ghi đè icon.
- Workflow kiểm tra icon 1024x1024, JSON, Assets.car và VideoMacDinh.json trong app bundle.
- Đặt MARKETING_VERSION 6.5 và CURRENT_PROJECT_VERSION 65.


## Bản v6.6
- Chấp nhận icon PNG vuông với mọi kích thước.
- GitHub Actions tự chuyển icon vuông về 1024x1024 trước khi build.
- Chỉ báo lỗi khi icon không vuông hoặc không đọc được.
