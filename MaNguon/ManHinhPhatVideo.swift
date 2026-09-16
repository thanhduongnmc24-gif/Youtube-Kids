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
            else if let id = video.youtubeID { TrinhPhatYouTube(id: id) }
            Button { dismiss() } label: { Image(systemName: "xmark").font(.title2.bold()).padding(14).background(.black.opacity(0.65)).foregroundStyle(.white).clipShape(Circle()) }.padding()
        }.onDisappear { kho.ghiLuotXem(video: video, giay: max(1, Date().timeIntervalSince(batDau))) }
    }
}

struct TrinhPhatLocal: View {
    @State private var player: AVPlayer
    init(url: URL) { _player = State(initialValue: AVPlayer(url: url)) }
    var body: some View { VideoPlayer(player: player).ignoresSafeArea().onAppear { player.play() }.onDisappear { player.pause() } }
}

struct TrinhPhatYouTube: UIViewRepresentable {
    let id: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.allowsAirPlayForMediaPlayback = true
        config.allowsPictureInPictureMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        config.defaultWebpagePreferences = preferences

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.backgroundColor = .black
        webView.isOpaque = true

        let html = """
        <!doctype html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
            <style>
                html, body {
                    margin: 0;
                    padding: 0;
                    width: 100%;
                    height: 100%;
                    overflow: hidden;
                    background: #000;
                }
                iframe {
                    position: absolute;
                    inset: 0;
                    width: 100%;
                    height: 100%;
                    border: 0;
                }
            </style>
        </head>
        <body>
            <iframe
                src="https://www.youtube.com/embed/\(id)?playsinline=1&rel=0&autoplay=1&controls=1&iv_load_policy=3"
                title="YouTube video player"
                frameborder="0"
                referrerpolicy="strict-origin-when-cross-origin"
                allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
                allowfullscreen>
            </iframe>
        </body>
        </html>
        """

        var request = URLRequest(url: URL(string: "https://www.youtube.com")!)
        request.setValue("https://www.youtube.com/", forHTTPHeaderField: "Referer")
        webView.loadHTMLString(html, baseURL: request.url)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            if navigationAction.navigationType == .linkActivated {
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }
    }
}
