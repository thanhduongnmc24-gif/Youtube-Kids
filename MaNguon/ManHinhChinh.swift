import SwiftUI

struct ManHinhChinh: View {
    @EnvironmentObject var kho: KhoDuLieu
    @State private var danhMuc = "Tất cả"
    @State private var timKiem = ""
    @State private var videoDangPhat: VideoTreEm?
    @State private var moKhoa = false
    @State private var hienPin = false
    @State private var baoHetGio = false
    @State private var thuTuXaoTron: [String] = []
    private let cot = [GridItem(.adaptive(minimum: 250), spacing: 22)]

    var videos: [VideoTreEm] {
        let loc = kho.duLieu.videos.filter { $0.dangBat && (danhMuc == "Tất cả" || $0.danhMuc == danhMuc) && (timKiem.isEmpty || $0.tieuDe.localizedCaseInsensitiveContains(timKiem)) }
        let viTri = Dictionary(uniqueKeysWithValues: thuTuXaoTron.enumerated().map { ($1, $0) })
        return loc.sorted { (viTri[$0.id] ?? Int.max) < (viTri[$1.id] ?? Int.max) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [Color(red: 0.92, green: 0.98, blue: 1), .white], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 18) {
                        thanhDau
                        thanhDanhMuc
                        if videos.isEmpty { VStack(spacing: 14) { Image(systemName: "play.rectangle").font(.system(size: 54)).foregroundStyle(.secondary); Text("Chưa có video").font(.title2.bold()); Text("Phụ huynh hãy chọn thư mục hoặc thêm video YouTube trong Cài đặt.").foregroundStyle(.secondary) }.padding(.top, 80) }
                        LazyVGrid(columns: cot, spacing: 24) { ForEach(videos) { v in TheVideo(video: v).onTapGesture { mo(v) } } }
                    }.padding(20)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .fullScreenCover(item: $videoDangPhat) { ManHinhPhatVideo(video: $0).environmentObject(kho) }
            .sheet(isPresented: $hienPin) { KhoaPhuHuynh { moKhoa = true; hienPin = false } }
            .sheet(isPresented: $moKhoa) { NavigationStack { ManHinhCaiDat() } }
            .alert("Đã đến giờ nghỉ", isPresented: $baoHetGio) { Button("Đã hiểu") {} } message: { Text("Bé đã hết thời gian xem hôm nay hoặc đang ngoài khung giờ được phép.") }
            .task { await kho.quetVideoLocal(); xaoTron() }
            .onChange(of: kho.duLieu.videos.map(\.id)) { _ in xaoTronNeuCan() }
        }
    }

    private var thanhDau: some View {
        HStack(spacing: 14) {
            ZStack { Circle().fill(.red); Image(systemName: "play.fill").foregroundStyle(.white).font(.title2) }.frame(width: 52, height: 52)
            VStack(alignment: .leading, spacing: 0) { Text("BÉ XEM VUI").font(.title2.bold()).foregroundStyle(.red); Text("Xin chào, \(kho.duLieu.cauHinh.tenBe)!").foregroundStyle(.secondary) }
            Spacer()
            HStack { Image(systemName: "magnifyingglass"); TextField("Tìm video", text: $timKiem).frame(maxWidth: 180) }.padding(12).background(.white).clipShape(Capsule()).shadow(color: .black.opacity(0.08), radius: 8)
            Button { hienPin = true } label: { Image(systemName: "lock.fill").font(.title2).padding(14).background(.yellow).clipShape(Circle()).foregroundStyle(.black) }
        }
    }
    private var thanhDanhMuc: some View { ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 12) { ForEach(kho.duLieu.cauHinh.danhMuc, id: \.self) { d in Button(d) { danhMuc = d }.font(.headline).padding(.horizontal, 22).padding(.vertical, 12).background(danhMuc == d ? Color.red : Color.white).foregroundStyle(danhMuc == d ? .white : .primary).clipShape(Capsule()).shadow(color: .black.opacity(0.08), radius: 5) } } } }
    private func xaoTron() { thuTuXaoTron = kho.duLieu.videos.map(\.id).shuffled() }
    private func xaoTronNeuCan() {
        let ids = Set(kho.duLieu.videos.map(\.id))
        let cu = thuTuXaoTron.filter { ids.contains($0) }
        let moi = kho.duLieu.videos.map(\.id).filter { !cu.contains($0) }.shuffled()
        thuTuXaoTron = cu + moi
    }
    private func mo(_ v: VideoTreEm) { if kho.duocPhepXem() { videoDangPhat = v } else { baoHetGio = true } }
}

struct TheVideo: View {
    @EnvironmentObject var kho: KhoDuLieu
    let video: VideoTreEm
    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            ZStack(alignment: .bottomTrailing) {
                AnhThumbnail(video: video).aspectRatio(16/9, contentMode: .fill).frame(maxWidth: .infinity).clipped().clipShape(RoundedRectangle(cornerRadius: 20))
                if video.thoiLuong > 0 { Text(dinhDang(video.thoiLuong)).font(.caption.bold()).padding(.horizontal, 7).padding(.vertical, 4).background(.black.opacity(0.75)).foregroundStyle(.white).clipShape(Capsule()).padding(9) }
            }
            Text(video.tieuDe).font(.headline).lineLimit(2)
            HStack { Image(systemName: video.loai == .youtube ? "play.rectangle.fill" : "internaldrive.fill"); Text(video.kenh).lineLimit(1) }.font(.subheadline).foregroundStyle(.secondary)
        }.contentShape(Rectangle())
    }
    private func dinhDang(_ s: Double) -> String { String(format: "%d:%02d", Int(s)/60, Int(s)%60) }
}

struct AnhThumbnail: View {
    @EnvironmentObject var kho: KhoDuLieu
    let video: VideoTreEm
    @State private var image: UIImage?
    var body: some View {
        Group { if let image { Image(uiImage: image).resizable() } else { nen } }
            .task(id: video.id) { image = await kho.anhThumbnail(video) }
    }
    private var nen: some View { ZStack { LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing); ProgressView().tint(.white) } }
}

struct KhoaPhuHuynh: View {
    @EnvironmentObject var kho: KhoDuLieu
    @Environment(\.dismiss) var dismiss
    @State private var pin = ""
    @State private var sai = false
    @FocusState private var dangNhapPIN: Bool
    let thanhCong: () -> Void

    var body: some View {
        VStack(spacing: 22) {
            Image(systemName: "person.2.badge.key.fill")
                .font(.system(size: 55))
                .foregroundStyle(.orange)
            Text("Nhập mã PIN phụ huynh")
                .font(.title2.bold())

            HStack(spacing: 14) {
                ForEach(0..<4, id: \.self) { index in
                    Circle()
                        .fill(index < pin.count ? Color.indigo : Color.gray.opacity(0.25))
                        .frame(width: 18, height: 18)
                }
            }

            TextField("", text: $pin)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($dangNhapPIN)
                .frame(width: 1, height: 1)
                .opacity(0.01)
                .onChange(of: pin) { giaTri in
                    let chiSo = String(giaTri.filter(\.isNumber).prefix(4))
                    if chiSo != giaTri { pin = chiSo; return }
                    sai = false
                    guard chiSo.count == 4 else { return }
                    if chiSo == kho.duLieu.cauHinh.pin {
                        dangNhapPIN = false
                        thanhCong()
                    } else {
                        sai = true
                        pin = ""
                        dangNhapPIN = true
                    }
                }

            if sai { Text("Mã PIN chưa đúng").foregroundStyle(.red) }
            Button("Đóng") { dismiss() }
        }
        .padding(35)
        .presentationDetents([.medium])
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                dangNhapPIN = true
            }
        }
        .onTapGesture { dangNhapPIN = true }
    }
}
