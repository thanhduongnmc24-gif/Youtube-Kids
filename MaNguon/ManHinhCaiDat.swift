import SwiftUI
import UniformTypeIdentifiers

struct ManHinhCaiDat: View {
    @EnvironmentObject var kho: KhoDuLieu
    @Environment(\.dismiss) var dismiss
    @State private var chonThuMuc = false
    @State private var link = ""
    @State private var dangThem = false
    @AppStorage("DanhMucThemGanNhat") private var danhMucDangChon = "Khám phá"
    var body: some View {
        Form {
            Section("Thư mục video local") {
                LabeledContent("Thư mục", value: kho.thuMucDangChon?.lastPathComponent ?? "Chưa chọn")
                Button { chonThuMuc = true } label: { Label("Chọn thư mục chứa video", systemImage: "folder.badge.plus") }
                Button { Task { await kho.quetVideoLocal() } } label: { Label("Quét lại thư mục", systemImage: "arrow.clockwise") }.disabled(kho.thuMucDangChon == nil || kho.dangQuet)
                if kho.dangQuet { ProgressView("Đang tạo thumbnail tại giây thứ 2...") }
                Text("Hỗ trợ MP4, MOV và M4V. Ứng dụng tự lấy khung hình tại giây thứ 2; video ngắn sẽ dùng khung hình đầu.").font(.caption).foregroundStyle(.secondary)
            }
            Section("Video mặc định") {
                Button { Task { await kho.dongBoVideoMacDinh() } } label: {
                    Label("Đồng bộ video mặc định", systemImage: "arrow.triangle.2.circlepath")
                }
                Button { Task { await kho.khoiPhucVideoMacDinh() } } label: {
                    Label("Khôi phục video mặc định", systemImage: "arrow.uturn.backward.circle")
                }
                Text("Danh sách nguồn: TaiNguyen/VideoMacDinh.json. Nếu tài nguyên bị thiếu, ứng dụng vẫn dùng hai video dự phòng tích hợp sẵn.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section("Thêm video YouTube được duyệt") {
                TextField("Dán link video YouTube", text: $link)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)

                Picker("Danh mục", selection: $danhMucDangChon) {
                    ForEach(kho.duLieu.cauHinh.danhMuc.filter { $0 != "Tất cả" }, id: \.self) { danhMuc in
                        Text(danhMuc).tag(danhMuc)
                    }
                }

                Button {
                    let linkCanThem = link
                    let danhMucCanThem = danhMucDangChon
                    dangThem = true
                    Task {
                        await kho.themYouTube(link: linkCanThem, danhMuc: danhMucCanThem)
                        if kho.thongBao == "Đã thêm video được duyệt." { link = "" }
                        dangThem = false
                    }
                } label: {
                    Label("Thêm vào \(danhMucDangChon)", systemImage: "plus.circle.fill")
                }
                .disabled(link.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || dangThem)

                if dangThem { ProgressView("Đang lấy tiêu đề và hình thu nhỏ...") }
            }
            Section("Kiểm soát thời gian") {
                Stepper("\(kho.duLieu.cauHinh.gioiHanPhutMoiNgay) phút mỗi ngày", value: $kho.duLieu.cauHinh.gioiHanPhutMoiNgay, in: 5...480, step: 5)
                Stepper("Tối đa \(kho.duLieu.cauHinh.gioiHanVideoMoiLuot) video mỗi lượt", value: $kho.duLieu.cauHinh.gioiHanVideoMoiLuot, in: 1...50)
                Stepper("Bắt đầu từ \(kho.duLieu.cauHinh.gioBatDau):00", value: $kho.duLieu.cauHinh.gioBatDau, in: 0...23)
                Stepper("Kết thúc lúc \(kho.duLieu.cauHinh.gioKetThuc):00", value: $kho.duLieu.cauHinh.gioKetThuc, in: 1...24)
                Stepper("Nghỉ \(kho.duLieu.cauHinh.soPhutNghi) phút", value: $kho.duLieu.cauHinh.soPhutNghi, in: 5...60, step: 5)
                LabeledContent("Đã xem hôm nay", value: "\(Int(kho.soGiayDaXemHomNay()/60)) phút")
            }
            Section("Trang phát YouTube HTTPS") {
                TextField("https://ten-github.github.io/ten-repo/player.html", text: Binding(get: { kho.duLieu.cauHinh.urlTrangPhat ?? "" }, set: { kho.duLieu.cauHinh.urlTrangPhat = $0 }))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                Text("Sau khi bật GitHub Pages, dán địa chỉ player.html vào đây. Ứng dụng sẽ tự thêm mã video vào tham số v.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section("Hồ sơ và bảo vệ") {
                TextField("Tên bé", text: $kho.duLieu.cauHinh.tenBe)
                SecureField("Mã PIN phụ huynh", text: $kho.duLieu.cauHinh.pin).keyboardType(.numberPad)
                Text("PIN mặc định: 1234. Hãy đổi ngay sau khi cài.").font(.caption).foregroundStyle(.secondary)
            }
            Section("Thư viện đã duyệt") {
                ForEach($kho.duLieu.videos) { $v in
                    HStack(spacing: 12) {
                        AnhThumbnail(video: v).frame(width: 100, height: 58).aspectRatio(16/9, contentMode: .fill).clipped().clipShape(RoundedRectangle(cornerRadius: 9))
                        VStack(alignment: .leading) { TextField("Tiêu đề", text: $v.tieuDe); Picker("Danh mục", selection: $v.danhMuc) { ForEach(kho.duLieu.cauHinh.danhMuc.dropFirst(), id: \.self) { Text($0).tag($0) } }.labelsHidden() }
                        Toggle("", isOn: $v.dangBat).labelsHidden()
                    }
                }.onDelete(perform: kho.xoa)
            }
            Section("Lịch sử xem") {
                if kho.duLieu.lichSu.isEmpty { Text("Chưa có lượt xem") }
                ForEach(kho.duLieu.lichSu.prefix(30)) { item in VStack(alignment: .leading) { Text(item.tieuDe).font(.subheadline.bold()); Text("\(item.batDau.formatted(date: .abbreviated, time: .shortened)) • \(Int(item.soGiay/60)) phút").font(.caption).foregroundStyle(.secondary) } }
                Button("Xóa lịch sử", role: .destructive) { kho.duLieu.lichSu = [] }
            }
        }
        .navigationTitle("Cài đặt phụ huynh")
        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Xong") { dismiss() } } }
        .fileImporter(isPresented: $chonThuMuc, allowedContentTypes: [.folder], allowsMultipleSelection: false) { result in if case .success(let urls) = result, let url = urls.first { kho.chonThuMuc(url) } else if case .failure(let e) = result { kho.thongBao = e.localizedDescription } }
        .alert("Thông báo", isPresented: Binding(get: { kho.thongBao != nil }, set: { if !$0 { kho.thongBao = nil } })) { Button("OK") { kho.thongBao = nil } } message: { Text(kho.thongBao ?? "") }
    }
}
