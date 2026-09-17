import Foundation
import AVFoundation
import SwiftUI

@MainActor
final class KhoDuLieu: ObservableObject {
    @Published var duLieu = DuLieuUngDung() { didSet { if !dangNap { luu() } } }
    @Published var dangQuet = false
    @Published var thongBao: String?
    @Published var thuMucDangChon: URL?
    @Published private(set) var soVideoTrongLuot = 0
    @Published private(set) var nghiDen: Date?
    private var dangNap = false
    private let tenTep = "BeXemVui.json"
    private let phienBanVideoMacDinh = 2
    private var urlTep: URL { FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(tenTep) }
    private var thuMucThumbnail: URL {
        let u = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Thumbnails", isDirectory: true)
        try? FileManager.default.createDirectory(at: u, withIntermediateDirectories: true)
        return u
    }

    init() {
        nap()
        moLaiThuMuc()
        if !duLieu.cauHinh.danhMuc.contains("Truyện cổ tích") { duLieu.cauHinh.danhMuc.append("Truyện cổ tích") }
        Task { await dongBoVideoMacDinh(hienThongBao: false) }
    }

    func nap() {
        guard let data = try? Data(contentsOf: urlTep), let d = try? JSONDecoder.chuan.decode(DuLieuUngDung.self, from: data) else { luu(); return }
        dangNap = true; duLieu = d; dangNap = false
    }
    func luu() { try? JSONEncoder.chuan.encode(duLieu).write(to: urlTep, options: .atomic) }

    func chonThuMuc(_ url: URL) {
        do {
            let bookmark = try url.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil)
            duLieu.bookmarkThuMuc = bookmark
            thuMucDangChon = url
            Task { await quetVideoLocal() }
        } catch { thongBao = "Không thể ghi nhớ thư mục: \(error.localizedDescription)" }
    }

    private func moLaiThuMuc() {
        guard let data = duLieu.bookmarkThuMuc else { return }
        var stale = false
        if let url = try? URL(resolvingBookmarkData: data, options: [.withoutUI], relativeTo: nil, bookmarkDataIsStale: &stale) { thuMucDangChon = url }
    }

    func quetVideoLocal() async {
        guard let folder = thuMucDangChon else { return }
        dangQuet = true; defer { dangQuet = false }
        let accessed = folder.startAccessingSecurityScopedResource(); defer { if accessed { folder.stopAccessingSecurityScopedResource() } }
        let keys: [URLResourceKey] = [.isRegularFileKey, .contentModificationDateKey]
        let files = (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: keys, options: [.skipsHiddenFiles])) ?? []
        let exts = Set(["mp4", "mov", "m4v"])
        let hopLe = files.filter { exts.contains($0.pathExtension.lowercased()) }
        let youtube = duLieu.videos.filter { $0.loai == .youtube }
        var local: [VideoTreEm] = []
        for file in hopLe {
            let maTen = Data(file.lastPathComponent.utf8).base64EncodedString().replacingOccurrences(of: "/", with: "_")
            let id = "local-" + maTen
            let asset = AVURLAsset(url: file)
            let duration = (try? await asset.load(.duration).seconds) ?? 0
            let cu = duLieu.videos.first { $0.id == id }
            local.append(VideoTreEm(id: id, loai: .local, tieuDe: cu?.tieuDe ?? file.deletingPathExtension().lastPathComponent, kenh: "Video trên máy", tenTep: file.lastPathComponent, youtubeID: nil, thumbnailURL: nil, thoiLuong: duration.isFinite ? duration : 0, danhMuc: cu?.danhMuc ?? "Khám phá", dangBat: cu?.dangBat ?? true, ngayThem: cu?.ngayThem ?? Date()))
            await taoThumbnailNeuCan(videoID: id, fileURL: file)
        }
        duLieu.videos = youtube + local.sorted { $0.tieuDe.localizedStandardCompare($1.tieuDe) == .orderedAscending }
    }

    func urlVideoLocal(_ video: VideoTreEm) -> URL? {
        guard let folder = thuMucDangChon, let ten = video.tenTep else { return nil }
        return folder.appendingPathComponent(ten)
    }
    func urlThumbnail(_ video: VideoTreEm) -> URL? {
        if video.loai == .local { return thuMucThumbnail.appendingPathComponent("Local-" + video.id + ".jpg") }
        guard let id = video.youtubeID else { return nil }
        return thuMucThumbnail.appendingPathComponent("YouTube-" + id + ".jpg")
    }

    func anhThumbnail(_ video: VideoTreEm) async -> UIImage? {
        guard let localURL = urlThumbnail(video) else { return nil }
        if let image = UIImage(contentsOfFile: localURL.path) { return image }
        guard video.loai == .youtube, let remote = URL(string: video.thumbnailURL ?? "") else { return nil }
        do {
            let (data, response) = try await URLSession.shared.data(from: remote)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode), let image = UIImage(data: data) else { return nil }
            try data.write(to: localURL, options: .atomic)
            return image
        } catch { return nil }
    }

    private func taoThumbnailNeuCan(videoID: String, fileURL: URL) async {
        let output = thuMucThumbnail.appendingPathComponent("Local-" + videoID + ".jpg")
        guard !FileManager.default.fileExists(atPath: output.path) else { return }
        let generator = AVAssetImageGenerator(asset: AVURLAsset(url: fileURL)); generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 640, height: 360)
        do {
            let image = try await generator.image(at: CMTime(seconds: 2, preferredTimescale: 600)).image
            if let data = UIImage(cgImage: image).jpegData(compressionQuality: 0.82) { try data.write(to: output, options: .atomic) }
        } catch {
            do {
                let image = try await generator.image(at: .zero).image
                if let data = UIImage(cgImage: image).jpegData(compressionQuality: 0.82) { try data.write(to: output, options: .atomic) }
            } catch { }
        }
    }

    func dongBoVideoMacDinh(hienThongBao: Bool = true) async {
        let danhSach = docVideoMacDinh()
        guard !danhSach.isEmpty else {
            if hienThongBao { thongBao = "VideoMacDinh.txt đang trống hoặc sai định dạng." }
            return
        }

        var soThem = 0
        let boQuaDaXoa = duLieu.phienBanVideoMacDinhDaNap == phienBanVideoMacDinh
        for item in danhSach {
            let danhMuc = item.danhMuc.trimmingCharacters(in: .whitespacesAndNewlines)
            if !danhMuc.isEmpty && danhMuc != "Tất cả" && !duLieu.cauHinh.danhMuc.contains(danhMuc) {
                duLieu.cauHinh.danhMuc.append(danhMuc)
            }
            guard let id = Self.layYouTubeID(item.link),
                  !(boQuaDaXoa && (duLieu.idsVideoMacDinhDaXoa ?? []).contains(id)),
                  !duLieu.videos.contains(where: { $0.youtubeID == id }) else { continue }
            await themYouTubeNoiBo(link: item.link, danhMuc: danhMuc.isEmpty ? "Khám phá" : danhMuc, hienThongBao: false)
            if duLieu.videos.contains(where: { $0.youtubeID == id }) { soThem += 1 }
        }
        duLieu.phienBanVideoMacDinhDaNap = phienBanVideoMacDinh
        if hienThongBao { thongBao = "Đã đồng bộ \(soThem) video mặc định mới." }
    }

    private func docVideoMacDinh() -> [VideoMacDinh] {
        if let url = Bundle.main.url(forResource: "VideoMacDinh", withExtension: "txt"),
           let noiDung = try? String(contentsOf: url, encoding: .utf8) {
            let dong = noiDung.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty && !$0.hasPrefix("#") }
            var ketQua: [VideoMacDinh] = []
            var i = 0
            while i + 1 < dong.count {
                ketQua.append(VideoMacDinh(link: dong[i], danhMuc: dong[i + 1]))
                i += 2
            }
            if !ketQua.isEmpty { return ketQua }
        }
        return [
            VideoMacDinh(link: "https://youtu.be/-zfd3yX_rN8", danhMuc: "Truyện cổ tích"),
            VideoMacDinh(link: "https://youtu.be/74sXo5z4NY4", danhMuc: "Truyện cổ tích")
        ]
    }

    func khoiPhucVideoMacDinh() async {
        duLieu.idsVideoMacDinhDaXoa = []
        duLieu.phienBanVideoMacDinhDaNap = nil
        await dongBoVideoMacDinh(hienThongBao: true)
    }

    func themYouTube(link: String, danhMuc: String) async {
        let muc = duLieu.cauHinh.danhMuc.contains(danhMuc) && danhMuc != "Tất cả" ? danhMuc : "Khám phá"
        await themYouTubeNoiBo(link: link, danhMuc: muc, hienThongBao: true)
    }

    private func themYouTubeNoiBo(link: String, danhMuc: String, hienThongBao: Bool) async {
        guard let id = Self.layYouTubeID(link) else { if hienThongBao { thongBao = "Link YouTube không hợp lệ." }; return }
        guard !duLieu.videos.contains(where: { $0.youtubeID == id }) else { if hienThongBao { thongBao = "Video này đã có trong thư viện." }; return }
        var title = "Video YouTube", author = "YouTube"
        if let encoded = "https://www.youtube.com/watch?v=\(id)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: "https://www.youtube.com/oembed?url=\(encoded)&format=json"),
           let (data, _) = try? await URLSession.shared.data(from: url),
           let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            title = object["title"] as? String ?? title; author = object["author_name"] as? String ?? author
        }
        let v = VideoTreEm(id: "yt-\(id)", loai: .youtube, tieuDe: title, kenh: author, tenTep: nil, youtubeID: id, thumbnailURL: "https://i.ytimg.com/vi/\(id)/hqdefault.jpg", thoiLuong: 0, danhMuc: danhMuc, dangBat: true, ngayThem: Date())
        duLieu.videos.insert(v, at: 0)
        _ = await anhThumbnail(v)
        if hienThongBao { thongBao = "Đã thêm video được duyệt." }
    }

    static func layYouTubeID(_ text: String) -> String? {
        var giaTri = text.trimmingCharacters(in: .whitespacesAndNewlines)
        giaTri = giaTri.removingPercentEncoding ?? giaTri

        if let range = giaTri.range(of: "https://") {
            giaTri = String(giaTri[range.lowerBound...])
        }
        if let range = giaTri.range(of: "http://"), !giaTri.hasPrefix("https://") {
            giaTri = String(giaTri[range.lowerBound...])
        }
        let kyTuKetThuc: Set<Character> = [" ", "<", "\"", "'"]
        if let dauKetThuc = giaTri.firstIndex(where: { kyTuKetThuc.contains($0) }) {
            giaTri = String(giaTri[..<dauKetThuc])
        }

        let hopLe: (String?) -> String? = { ungVien in
            guard let id = ungVien?.trimmingCharacters(in: .whitespacesAndNewlines),
                  id.range(of: "^[A-Za-z0-9_-]{11}$", options: .regularExpression) != nil else { return nil }
            return id
        }

        if let id = hopLe(giaTri) { return id }
        guard var components = URLComponents(string: giaTri) else { return nil }
        let host = (components.host ?? "").lowercased()
        let cacPhan = components.path.split(separator: "/").map(String.init)

        if host == "youtu.be" || host.hasSuffix(".youtu.be") {
            return hopLe(cacPhan.first)
        }

        let laYouTube = host == "youtube.com" || host.hasSuffix(".youtube.com") || host == "youtube-nocookie.com" || host.hasSuffix(".youtube-nocookie.com")
        guard laYouTube else { return nil }

        if let id = hopLe(components.queryItems?.first(where: { $0.name.lowercased() == "v" })?.value) {
            return id
        }

        let tienTo = Set(["shorts", "embed", "live", "v"])
        if cacPhan.count >= 2, tienTo.contains(cacPhan[0].lowercased()) {
            return hopLe(cacPhan[1])
        }

        components.query = nil
        return nil
    }

    func xoa(_ offsets: IndexSet) {
        var daXoa = duLieu.idsVideoMacDinhDaXoa ?? []
        for index in offsets where duLieu.videos.indices.contains(index) {
            let video = duLieu.videos[index]
            if let id = video.youtubeID, !daXoa.contains(id) { daXoa.append(id) }
            if let thumbnail = urlThumbnail(video) { try? FileManager.default.removeItem(at: thumbnail) }
        }
        duLieu.idsVideoMacDinhDaXoa = daXoa
        duLieu.videos.remove(atOffsets: offsets)
    }
    func ghiLuotXem(video: VideoTreEm, giay: Double) {
        duLieu.lichSu.insert(LuotXem(videoID: video.id, tieuDe: video.tieuDe, soGiay: giay), at: 0)
        duLieu.lichSu = Array(duLieu.lichSu.prefix(500))
        soVideoTrongLuot += 1
        if soVideoTrongLuot >= duLieu.cauHinh.gioiHanVideoMoiLuot {
            nghiDen = Date().addingTimeInterval(Double(duLieu.cauHinh.soPhutNghi * 60))
        }
    }
    func soGiayDaXemHomNay() -> Double { duLieu.lichSu.filter { Calendar.current.isDateInToday($0.batDau) }.reduce(0) { $0 + $1.soGiay } }
    func duocPhepXem() -> Bool {
        if let den = nghiDen {
            if Date() < den { return false }
            nghiDen = nil; soVideoTrongLuot = 0
        }
        let h = Calendar.current.component(.hour, from: Date())
        return h >= duLieu.cauHinh.gioBatDau && h < duLieu.cauHinh.gioKetThuc && soGiayDaXemHomNay() < Double(duLieu.cauHinh.gioiHanPhutMoiNgay * 60)
    }
}

extension JSONEncoder { static var chuan: JSONEncoder { let e = JSONEncoder(); e.outputFormatting = [.prettyPrinted, .sortedKeys]; e.dateEncodingStrategy = .iso8601; return e } }
extension JSONDecoder { static var chuan: JSONDecoder { let d = JSONDecoder(); d.dateDecodingStrategy = .iso8601; return d } }
