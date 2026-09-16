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
        Task { await napVideoMacDinh() }
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

    private func napVideoMacDinh() async {
        guard let url = Bundle.main.url(forResource: "VideoMacDinh", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let danhSach = try? JSONDecoder().decode([VideoMacDinh].self, from: data) else { return }
        for item in danhSach {
            guard let id = Self.layYouTubeID(item.link),
                  !(duLieu.idsVideoMacDinhDaXoa ?? []).contains(id),
                  !duLieu.videos.contains(where: { $0.youtubeID == id }) else { continue }
            await themYouTubeNoiBo(link: item.link, danhMuc: item.danhMuc, hienThongBao: false)
        }
    }

    func themYouTube(link: String) async {
        await themYouTubeNoiBo(link: link, danhMuc: "Khám phá", hienThongBao: true)
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
        guard let c = URLComponents(string: text.trimmingCharacters(in: .whitespacesAndNewlines)) else { return nil }
        if c.host?.contains("youtu.be") == true { return c.path.split(separator: "/").first.map(String.init) }
        if c.path.contains("/shorts/") || c.path.contains("/embed/") { return c.path.split(separator: "/").last.map(String.init) }
        return c.queryItems?.first(where: { $0.name == "v" })?.value
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
