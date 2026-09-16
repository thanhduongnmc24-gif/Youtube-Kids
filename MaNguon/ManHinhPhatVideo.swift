import SwiftUI
import AVKit
import YouTubeiOSPlayerHelper

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

    func makeUIView(context: Context) -> YTPlayerView {
        let playerView = YTPlayerView(frame: .zero)
        playerView.backgroundColor = .black
        playerView.delegate = context.coordinator
        playerView.load(
            withVideoId: id,
            playerVars: [
                "playsinline": 1,
                "autoplay": 1,
                "controls": 1,
                "rel": 0,
                "iv_load_policy": 3,
                "modestbranding": 1,
                "origin": "https://www.youtube.com"
            ]
        )
        return playerView
    }

    func updateUIView(_ uiView: YTPlayerView, context: Context) {
        guard context.coordinator.videoID != id else { return }
        context.coordinator.videoID = id
        uiView.load(
            withVideoId: id,
            playerVars: [
                "playsinline": 1,
                "autoplay": 1,
                "controls": 1,
                "rel": 0,
                "iv_load_policy": 3,
                "modestbranding": 1,
                "origin": "https://www.youtube.com"
            ]
        )
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(videoID: id)
    }

    final class Coordinator: NSObject, YTPlayerViewDelegate {
        var videoID: String

        init(videoID: String) {
            self.videoID = videoID
        }

        func playerViewDidBecomeReady(_ playerView: YTPlayerView) {
            playerView.playVideo()
        }
    }
}
