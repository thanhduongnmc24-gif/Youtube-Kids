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
        let config = WKWebViewConfiguration(); config.allowsInlineMediaPlayback = true; config.mediaTypesRequiringUserActionForPlayback = []
        let web = WKWebView(frame: .zero, configuration: config); web.scrollView.isScrollEnabled = false; web.isOpaque = false; web.navigationDelegate = context.coordinator
        let html = """
        <!doctype html><html><head><meta name='viewport' content='width=device-width,initial-scale=1,maximum-scale=1'><style>html,body,#p{margin:0;width:100%;height:100%;background:#000;overflow:hidden}</style></head><body><div id='p'></div><script src='https://www.youtube.com/iframe_api'></script><script>function onYouTubeIframeAPIReady(){new YT.Player('p',{videoId:'\(id)',playerVars:{autoplay:1,playsinline:1,rel:0,modestbranding:1,iv_load_policy:3}})}</script></body></html>
        """
        web.loadHTMLString(html, baseURL: URL(string: "https://www.youtube.com")); return web
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator() }
    final class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) { decisionHandler(navigationAction.navigationType == .linkActivated ? .cancel : .allow) }
    }
}
