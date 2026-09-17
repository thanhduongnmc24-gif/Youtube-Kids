# Bé Xem Vui v7.0

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


## Bản v6.7
- Khai báo riêng `HinhAnh.xcassets` và `VideoMacDinh.json` trong resource build phase của XcodeGen.
- Workflow tìm JSON trong toàn bộ app bundle thay vì chỉ kiểm tra một vị trí cứng.
- Tăng build number lên 67.


## Bản v6.8
- Sửa đúng cú pháp XcodeGen: đưa JSON và asset catalog vào `sources` với `buildPhase: resources`.
- Workflow kiểm tra trực tiếp file project.pbxproj trước khi archive.
- Tăng phiên bản lên 6.8, build 68.


## Bản v6.9
- Thêm Picker chọn danh mục khi phụ huynh thêm video YouTube thủ công.
- Ghi nhớ danh mục được chọn gần nhất bằng AppStorage.
- Nút thêm hiển thị rõ danh mục đích.
- Không xóa nội dung link nếu thao tác thêm thất bại.


## Bản v7.0
- Sửa trình phát trên iPad từ popup dạng sheet sang fullScreenCover toàn màn hình.
- Ẩn thanh trạng thái và system overlays khi đang phát video.
- Giữ nút đóng riêng của ứng dụng để thoát trình phát.


## Bản v7.0
- Màn hình phát dùng fullScreenCover nên chiếm toàn bộ màn hình iPad.
- Bộ đọc liên kết hỗ trợ URL đầy đủ và rút gọn: watch, shorts, embed, live, youtu.be, m.youtube.com và music.youtube.com.
- Tự loại tham số chia sẻ như `si`, `list`, `index`, `t` và kiểm tra Video ID đủ 11 ký tự.

## Bản v7.1
- Đổi danh sách mẫu sang `VideoMacDinh.txt`, mỗi video chỉ gồm link ở dòng trên và danh mục ở dòng dưới.
- Tự tạo danh mục mới nếu tên trong file chưa tồn tại.
- Bổ sung các link mẫu vào Truyện cổ tích, Nấu ăn, Khám phá và Nhạc.
- Khi chạm màn hình phát YouTube, video tạm dừng và hiện tối đa 10 thumbnail gợi ý.
- Chạm thumbnail để phát ngay video được chọn hoặc chọn Xem tiếp.
- Không chỉnh sửa hay thay thế file icon ứng dụng.


## Bản v7.2
- Sửa lỗi cú pháp chuỗi tại hàm nhận dạng YouTube ID.
- Dùng `Set<Character>` để nhận biết khoảng trắng, thẻ HTML và dấu nháy an toàn.
- Các lỗi dây chuyền về JSONEncoder, duocPhepXem và ghiLuotXem được loại bỏ sau khi parser đọc đầy đủ class.


## Bản v7.3
- Hỗ trợ `youtubekids.com` và `www.youtubekids.com`.
- Bỏ qua các tham số phụ như `hl` và lấy đúng tham số `v`.
- Đồng bộ hiển thị số mục đã đọc, số video thêm mới, số đã có và số link lỗi.
- Liệt kê tối đa 5 link lỗi thay vì bỏ qua âm thầm.
- Tăng phiên bản dữ liệu mặc định để tự đồng bộ lại các link YouTube Kids.


## Bản v7.4
- Video gợi ý khi tạm dừng chỉ hiện thành một hàng ngang ở đáy màn hình.
- Thêm chức năng nhập danh sách video từ file TXT trong Cài đặt phụ huynh.
- Tự bóc Video ID từ link thường, Shorts, YouTube Kids, youtu.be, đoạn HTML và chuỗi chứa link.
- Ví dụ link YouTube Kids tự lấy `ktlaDZUK4Ek`.
- Không thay đổi icon ứng dụng.


## Bản v7.5
- Gộp hai fileImporter thành một trình chọn duy nhất để tránh xung đột trên iPad.
- Chấp nhận đúng file `.txt`, kiểm tra UTF-8 và loại bỏ BOM.
- Hiện trạng thái đang nhập và thông báo kết quả kể cả khi toàn bộ video đã tồn tại.
- Không thay đổi icon ứng dụng.


## Bản v7.6
- Bỏ fileImporter dùng chung bị treo trên iPad.
- Dùng UIDocumentPickerViewController riêng cho file TXT với chế độ asCopy.
- Callback chọn, hủy và nhập file được xử lý rõ ràng.
- Trình chọn thư mục video vẫn hoạt động độc lập.
- Không thay đổi icon ứng dụng.


## Bản v7.7
- Chạm lại màn hình gợi ý để tiếp tục video và tự ẩn hàng thumbnail, bỏ nút Xem tiếp.
- Vuốt xuống hơn 120 điểm để đóng trình phát.
- Mở khóa phụ huynh tự bật bàn phím số, nhập đủ 4 số sẽ kiểm tra ngay.
- Bỏ nút Mở cài đặt.
- Thêm chức năng đổi mã PIN với mã cũ, mã mới và xác nhận.
- Không thay đổi icon ứng dụng.


## Bản v7.8
- Sửa lỗi build do thiếu ba State dùng cho đổi mã PIN.
- Bổ sung đầy đủ giao diện nhập PIN hiện tại, PIN mới và xác nhận PIN mới.
- Giữ nguyên vuốt xuống để đóng video, mở khóa tự động 4 số và hàng gợi ý chạm để xem tiếp.
- Không thay đổi icon ứng dụng.


## Bản v7.9
- Sửa hàng video gợi ý không ẩn khi tiếp tục phát.
- Thêm lớp bắt chạm phủ toàn màn hình khi video đang tạm dừng.
- Chạm vùng video hoặc hàng gợi ý sẽ ẩn gợi ý và phát tiếp.
- Chọn thumbnail sẽ ẩn gợi ý trước khi phát video mới.
- Không thay đổi icon ứng dụng.
