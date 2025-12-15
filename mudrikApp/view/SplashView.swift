import SwiftUI
import AVKit

struct SplashView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var player: AVPlayer?
    @State private var navigate = false

    private var fileName: String {
        colorScheme == .dark ? "splashdark" : "splashlight"
    }

    private var bgUIColor: UIColor {
        colorScheme == .dark ? .black : .white
    }

    var body: some View {
        ZStack {
            // Background
            (colorScheme == .dark ? Color.black : Color.white)
                .ignoresSafeArea()

            if let player {
                CenteredVideoPlayer(player: player, background: bgUIColor)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear {
                        player.seek(to: .zero)
                        player.isMuted = true
                        player.play()

                        NotificationCenter.default.addObserver(
                            forName: .AVPlayerItemDidPlayToEndTime,
                            object: player.currentItem,
                            queue: .main
                        ) { _ in
                            navigate = true
                        }
                    }
            }
        }
        .onAppear { setupPlayer() }
        .onChange(of: colorScheme) { _ in setupPlayer() }
        .fullScreenCover(isPresented: $navigate) {
            ContentView()
        }
    }

    private func setupPlayer() {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "mov") else {
            print("❌ Missing video file: \(fileName).mov")
            return
        }
        player = AVPlayer(url: url)
    }
}



struct CenteredVideoPlayer: UIViewControllerRepresentable {
    let player: AVPlayer
    let background: UIColor

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let vc = AVPlayerViewController()
        vc.player = player
        vc.showsPlaybackControls = false
        vc.videoGravity = .resizeAspect   // ✅ keeps original size
        vc.view.backgroundColor = background
        return vc
    }

    func updateUIViewController(_ vc: AVPlayerViewController, context: Context) {
        vc.view.backgroundColor = background
    }
}

#Preview {
    SplashView()
}
