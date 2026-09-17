import SwiftUI
import AVKit
import WebKit

struct ManHinhPhatVideo: View {
    @EnvironmentObject var kho: KhoDuLieu
    @Environment(\.dismiss) var dismiss
    let video: VideoTreEm
    @State private var batDau = Date()
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()
            if video.loai == .local, let url = kho.urlVideoLocal(video) { TrinhPhatLocal(url: url) }
            else if let id = video.youtubeID {
                TrinhPhatYouTube(
                    id: id,
                    goiY: kho.duLieu.videos.compactMap(\.youtubeID).filter { $0 != id }.shuffled(),
                    urlTrangPhat: kho.duLieu.cauHinh.urlTrangPhat ?? ""
                )
            }
            Button { dismiss() } label: { Image(systemName: "xmark").font(.title2.bold()).padding(14).background(.black.opacity(0.65)).foregroundStyle(.white).clipShape(Circle()) }.padding()
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .simultaneousGesture(
            DragGesture(minimumDistance: 30)
                .onEnded { value in
                    let laVuotXuong = value.translation.height > 120 && abs(value.translation.height) > abs(value.translation.width)
                    if laVuotXuong { dismiss() }
                }
        )
        .onDisappear { kho.ghiLuotXem(video: video, giay: max(1, Date().timeIntervalSince(batDau))) }
    }
}

struct TrinhPhatLocal: View {
    @State private var player: AVPlayer
    init(url: URL) { _player = State(initialValue: AVPlayer(url: url)) }
    var body: some View { VideoPlayer(player: player).ignoresSafeArea().onAppear { player.play() }.onDisappear { player.pause() } }
}

struct TrinhPhatYouTube: UIViewRepresentable {
    let id: String
    let goiY: [String]
    let urlTrangPhat: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.allowsAirPlayForMediaPlayback = true
        config.allowsPictureInPictureMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.backgroundColor = .black
        webView.isOpaque = true
        taiVideo(id: id, trong: webView)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard context.coordinator.videoID != id || context.coordinator.urlTrangPhat != urlTrangPhat else { return }
        context.coordinator.videoID = id
        context.coordinator.urlTrangPhat = urlTrangPhat
        taiVideo(id: id, trong: webView)
    }

    private func taiVideo(id: String, trong webView: WKWebView) {
        let goc = urlTrangPhat.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !goc.isEmpty, var components = URLComponents(string: goc) else {
            webView.loadHTMLString("<html><body style='background:#000;color:#fff;font:20px -apple-system;text-align:center;padding-top:25%'>Phụ huynh chưa nhập URL trang phát HTTPS trong Cài đặt.</body></html>", baseURL: nil)
            return
        }
        var items = components.queryItems ?? []
        items.removeAll { $0.name == "v" }
        items.append(URLQueryItem(name: "v", value: id))
        items.append(URLQueryItem(name: "goiY", value: goiY.prefix(10).joined(separator: ",")))
        components.queryItems = items
        guard let url = components.url, url.scheme == "https" else {
            webView.loadHTMLString("<html><body style='background:#000;color:#fff;font:20px -apple-system;text-align:center;padding-top:25%'>URL trang phát phải bắt đầu bằng HTTPS.</body></html>", baseURL: nil)
            return
        }
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        webView.load(request)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(videoID: id, urlTrangPhat: urlTrangPhat)
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var videoID: String
        var urlTrangPhat: String

        init(videoID: String, urlTrangPhat: String) {
            self.videoID = videoID
            self.urlTrangPhat = urlTrangPhat
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.cancel)
                return
            }
            let host = url.host?.lowercased() ?? ""
            let duocPhep = navigationAction.navigationType != .linkActivated || host.contains("youtube.com") || host.contains("youtube-nocookie.com")
            decisionHandler(duocPhep ? .allow : .cancel)
        }
    }
}
