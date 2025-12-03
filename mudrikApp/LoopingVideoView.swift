import SwiftUI
import AVKit

struct LoopingVideoView: View {
    let player: AVPlayer?

    init(resourceName: String, resourceExtension: String) {
        if let url = Bundle.main.url(forResource: resourceName, withExtension: resourceExtension) {
            self.player = AVPlayer(url: url)
        } else {
            self.player = nil
        }
    }

    var body: some View {
        VideoPlayerView(player: player)
            .onAppear {
                guard let player else { return }
                // Loop
                NotificationCenter.default.addObserver(
                    forName: .AVPlayerItemDidPlayToEndTime,
                    object: player.currentItem,
                    queue: .main
                ) { _ in
                    player.seek(to: .zero)
                    player.play()
                }
                player.play()
                player.isMuted = true
            }
            .onDisappear {
                player?.pause()
            }
    }
}

// UIViewRepresentable to host AVPlayerLayer
private struct VideoPlayerView: UIViewRepresentable {
    let player: AVPlayer?

    func makeUIView(context: Context) -> PlayerView {
        let v = PlayerView()
        v.player = player
        v.videoGravity = .resizeAspectFill
        return v
    }

    func updateUIView(_ uiView: PlayerView, context: Context) {
        uiView.player = player
    }
}

// A UIView whose backing layer is AVPlayerLayer
private final class PlayerView: UIView {
    override static var layerClass: AnyClass { AVPlayerLayer.self }

    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

    var player: AVPlayer? {
        get { playerLayer.player }
        set { playerLayer.player = newValue }
    }

    var videoGravity: AVLayerVideoGravity {
        get { playerLayer.videoGravity }
        set { playerLayer.videoGravity = newValue }
    }
}
