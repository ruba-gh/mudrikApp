//
//  LoopingVideoView.swift
//  mudrikApp
//

import SwiftUI
import AVFoundation

// UIKit view that actually plays & loops the video
final class LoopingPlayerUIView: UIView {
    private let playerLayer = AVPlayerLayer()
    private let queuePlayer = AVQueuePlayer()
    private var playerLooper: AVPlayerLooper?

    init(videoName: String, videoType: String) {
        super.init(frame: .zero)

        guard let url = Bundle.main.url(forResource: videoName, withExtension: videoType) else {
            print("🔥 ERROR: Could not find video file \(videoName).\(videoType)")
            return
        }

        let item = AVPlayerItem(url: url)

        // Layer setup
        playerLayer.player = queuePlayer
        playerLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(playerLayer)

        // Looping
        playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: item)
        queuePlayer.isMuted = true
        queuePlayer.play()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// SwiftUI wrapper
struct LoopingVideoView: UIViewRepresentable {
    let resourceName: String
    let resourceExtension: String

    func makeUIView(context: Context) -> LoopingPlayerUIView {
        LoopingPlayerUIView(videoName: resourceName, videoType: resourceExtension)
    }

    func updateUIView(_ uiView: LoopingPlayerUIView, context: Context) {
        // nothing to update for now
    }
}
