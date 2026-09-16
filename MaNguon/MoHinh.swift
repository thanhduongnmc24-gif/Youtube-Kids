import Foundation

enum LoaiNguonVideo: String, Codable { case local, youtube }

struct VideoTreEm: Identifiable, Codable, Hashable {
    var id: String
    var loai: LoaiNguonVideo
    var tieuDe: String
    var kenh: String
    var tenTep: String?
    var youtubeID: String?
    var thumbnailURL: String?
    var thoiLuong: Double
    var danhMuc: String
    var dangBat: Bool
    var ngayThem: Date
}

struct LuotXem: Identifiable, Codable {
    var id = UUID()
    var videoID: String
    var tieuDe: String
    var batDau = Date()
    var soGiay: Double
}

struct CauHinhUngDung: Codable {
    var tenBe = "Bé"
    var pin = "1234"
    var gioiHanPhutMoiNgay = 60
    var gioiHanVideoMoiLuot = 10
    var gioBatDau = 7
    var gioKetThuc = 21
    var soPhutNghi = 15
    var danhMuc = ["Tất cả", "Học tập", "Âm nhạc", "Khám phá"]
}

struct DuLieuUngDung: Codable {
    var videos: [VideoTreEm] = []
    var lichSu: [LuotXem] = []
    var cauHinh = CauHinhUngDung()
    var bookmarkThuMuc: Data?
}
