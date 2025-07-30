//
//  VideoPlayerView.swift
//  ReadBox
//
//  Created by Macbook Pro on 24.07.2025.
//

import SwiftUI
import AVFoundation
import AVKit
import SwiftfulLoadingIndicators

struct CustomVideoPlayerView: UIViewRepresentable {
    let player: AVPlayer
    let cornerRadius: CGFloat
    var isLooping: Bool = true
    
    func makeUIView(context: Context) -> PlayerUIView {
        let view = PlayerUIView()
        view.setup(player: player, cornerRadius: cornerRadius, isLooping: isLooping)
        return view
    }

    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        // You could react to external changes here if needed
    }

    class PlayerUIView: UIView {
        private var playerLayer = AVPlayerLayer()
        private var playbackEndedObserver: Any?

        override init(frame: CGRect) {
            super.init(frame: frame)
            self.backgroundColor = .clear
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
        }
        
//        func setup(player: AVPlayer, cornerRadius: CGFloat, isLooping: Bool) {
//            self.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
//
//            playerLayer.player = player
//            playerLayer.videoGravity = .resizeAspectFill
//            playerLayer.masksToBounds = true
//            playerLayer.cornerRadius = cornerRadius
//
//            self.layer.addSublayer(playerLayer)
//
//            if isLooping {
//                NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime,
//                                                       object: player.currentItem,
//                                                       queue: .main) { _ in
//                    player.seek(to: .zero)
//                    player.play()
//                }
//            }
//
//            player.play()
//            
//            NotificationCenter.default.addObserver(forName: .stopAllVideoPlayback, object: nil, queue: .main) { _ in
//                player.pause()
//            }
//        }

        func setup(player: AVPlayer, cornerRadius: CGFloat, isLooping: Bool) {
            self.layer.sublayers?.forEach { $0.removeFromSuperlayer() }

            playerLayer.player = player
            playerLayer.videoGravity = .resizeAspectFill
            playerLayer.masksToBounds = true
            playerLayer.cornerRadius = cornerRadius

            self.layer.addSublayer(playerLayer)

            if isLooping {
                if let observer = playbackEndedObserver {
                    NotificationCenter.default.removeObserver(observer)
                }
                playbackEndedObserver = NotificationCenter.default.addObserver(
                    forName: .AVPlayerItemDidPlayToEndTime,
                    object: player.currentItem,
                    queue: .main
                ) { _ in
                    player.seek(to: .zero)
                    player.play()
                }
            }

            NotificationCenter.default.addObserver(forName: .stopAllVideoPlayback, object: nil, queue: .main) { _ in
                player.pause()
            }
        }

        
        override func layoutSubviews() {
            super.layoutSubviews()
            playerLayer.frame = bounds
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
            
            if let observer = playbackEndedObserver {
                NotificationCenter.default.removeObserver(observer)
            }
        }
    }
}

struct VideoFullscreenPresenter {
    private static var delegateRetainBag: [FullscreenDelegate] = []

    static func present(player: AVPlayer, onDismiss: @escaping (CMTime) -> Void) {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.modalPresentationStyle = .fullScreen

        let delegate = FullscreenDelegate(player: player, onDismiss: { _ in })
        controller.delegate = delegate
        delegateRetainBag.append(delegate)

        delegate.onDismiss = { time in
            onDismiss(time)
            delegateRetainBag.removeAll { $0 === delegate }
        }

        if let topVC = topMostViewController() {
            topVC.present(controller, animated: true) {
                player.play()
            }
        } else {
            print("⚠️ Failed to find top-most view controller.")
        }
    }

    static func topMostViewController(from base: UIViewController? = UIApplication.shared.connectedScenes
        .compactMap { ($0 as? UIWindowScene)?.keyWindow }
        .first?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topMostViewController(from: nav.visibleViewController)
        } else if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
            return topMostViewController(from: selected)
        } else if let presented = base?.presentedViewController {
            return topMostViewController(from: presented)
        }
        return base
    }

    class FullscreenDelegate: NSObject, AVPlayerViewControllerDelegate {
        var onDismiss: (CMTime) -> Void
        weak var player: AVPlayer?

        init(player: AVPlayer, onDismiss: @escaping (CMTime) -> Void) {
            self.player = player
            self.onDismiss = onDismiss
        }

        func playerViewControllerWillEndDismissalTransition(_ controller: AVPlayerViewController) {
            let time = player?.currentTime() ?? .zero
            print("📤 playerViewControllerWillEndDismissalTransition — captured time:", time.seconds)
            onDismiss(time)
        }
    }
}


struct AdaptiveVideoPlayerView: View {
    let url: URL
    let cornerRadius: CGFloat
    var externalPlayer: AVPlayer? = nil
    let onVideoSizeReady: () -> Void
    let width: CGFloat
    
    init(
        url: URL,
        cornerRadius: CGFloat,
        externalPlayer: AVPlayer? = nil,
        onVideoSizeReady: @escaping () -> Void,
        width: CGFloat
    ) {
        self.url = url
        self.cornerRadius = cornerRadius
        self.externalPlayer = externalPlayer
        self.onVideoSizeReady = onVideoSizeReady
        self.width = width
    }

    @State private var videoSize: CGSize?

    var body: some View {
        Group {
            if let size = videoSize {
                let height = width * size.height / size.width

                CustomVideoPlayerView(
                    player: externalPlayer ?? AVPlayer(url: url),
                    cornerRadius: cornerRadius
                )
                .frame(width: width, height: height)
            } else {
                LoadingIndicator(
                    animation: .circleRunner,
                    color: Color(.label),
                    size: .small,
                    speed: .fast
                )
                .frame(width: width, height: 200)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .onAppear(perform: loadVideoSize)
    }

    private func loadVideoSize() {
        Task {
            do {
                let asset = AVAsset(url: url)
                let tracks = try await asset.loadTracks(withMediaType: .video)
                guard let track = tracks.first else { return }

                let size = try await track.load(.naturalSize)
                let transform = try await track.load(.preferredTransform)
                let realSize = size.applying(transform)

                await MainActor.run {
                    self.videoSize = CGSize(width: abs(realSize.width), height: abs(realSize.height))
                    onVideoSizeReady()
                }
            } catch {
                print("⚠️ Failed to load video size:", error.localizedDescription)
            }
        }
    }
}

final class PlayerHolder: ObservableObject {
    let player = AVPlayer()

    @Published var isPlaying: Bool = false
    @Published var isMuted: Bool = true
    
    private var readyObserver: NSKeyValueObservation?
    private var statusObserver: NSKeyValueObservation?
    private var muteObserver: NSKeyValueObservation?

    init() {
        statusObserver = player.observe(\.timeControlStatus, options: [.initial, .new]) { [weak self] player, _ in
            DispatchQueue.main.async {
                self?.isPlaying = player.timeControlStatus == .playing
            }
        }
        
        muteObserver = player.observe(\.isMuted, options: [.initial, .new]) { [weak self] player, _ in
            DispatchQueue.main.async {
                self?.isMuted = player.isMuted
            }
        }

    }

    deinit {
        statusObserver?.invalidate()
        muteObserver?.invalidate()
        muteObserver?.invalidate()
    }
}

struct TappableVideoPreview: View {
    let url: URL
    let cornerRadius: CGFloat
    let width: CGFloat
    
    init(url: URL, cornerRadius: CGFloat, width: CGFloat = UIScreen.main.bounds.width - 32) {
        self.url = url
        self.cornerRadius = cornerRadius
        self.width = width
    }

    @StateObject private var playerHolder = PlayerHolder()
    @State private var hasInitialized = false
    @State private var playerViewId = UUID()
    @State private var resumeAfterFullscreenTime: CMTime? = nil
    @State private var shouldReplaceItem = true
    @State private var isVideoSizeReady = false

    var body: some View {
        ZStack(alignment: .top) {
            AdaptiveVideoPlayerView(
                url: url,
                cornerRadius: cornerRadius,
                externalPlayer: playerHolder.player,
                onVideoSizeReady: {
                    isVideoSizeReady = true
                },
                width: width
            )
            .id(playerViewId)
            .onChange(of: isVideoSizeReady) {
                guard isVideoSizeReady, shouldReplaceItem else {
                    shouldReplaceItem = true
                    return
                }
                
                let playerAsset: AVAsset

                if VideoCacheManager.shared.isCached(url) {
                    let cachedURL = VideoCacheManager.shared.cachedURL(for: url)
                    playerAsset = AVAsset(url: cachedURL)
                    print("📦 Используем кэшированное видео")
                } else {
                    playerAsset = AVURLAsset(url: url)
                    print("🌐 Стримим видео из сети")

                    Task.detached {
                        _ = try? await VideoCacheManager.shared.downloadIfNeeded(from: url)
                    }
                }

                let item = AVPlayerItem(asset: playerAsset)
                playerHolder.player.replaceCurrentItem(with: item)

                if let resumeTime = resumeAfterFullscreenTime {
                    playerHolder.player.seek(to: resumeTime, toleranceBefore: .zero, toleranceAfter: .zero)
                    resumeAfterFullscreenTime = nil
                } else {
                    try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
                    try? AVAudioSession.sharedInstance().setActive(true)
                    playerHolder.player.isMuted = true
                    playerHolder.player.play()
                }
            }

            Rectangle()
                .foregroundColor(.clear)
                .contentShape(Rectangle())
                .onTapGesture {
                    let currentTime = playerHolder.player.currentTime()
                    print("🟢 Tapped preview at time:", currentTime.seconds)

                    playerHolder.player.pause()

                    VideoFullscreenPresenter.present(player: playerHolder.player) { returnTime in
                        print("🔻 Fullscreen dismissed at:", returnTime.seconds)

                        DispatchQueue.main.async {
                            playerHolder.player.pause()
                            playerHolder.player.seek(to: returnTime, toleranceBefore: .zero, toleranceAfter: .zero)
                            resumeAfterFullscreenTime = returnTime
                            shouldReplaceItem = false
                            playerViewId = UUID()
                        }
                    }
                }

            HStack {
                Button(action: {
                    playerHolder.player.isMuted.toggle()
                }) {
                    Image(systemName: playerHolder.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .foregroundColor(.white)
                        .padding(8)
                        .background(.black.opacity(0.6))
                        .clipShape(Circle())
                }

                Spacer()

                Button(action: {
                    if playerHolder.isPlaying {
                        playerHolder.player.pause()
                    } else {
                        playerHolder.player.play()
                    }
                }) {
                    Image(systemName: playerHolder.isPlaying ? "pause.fill" : "play.fill")
                        .foregroundColor(.white)
                        .padding(8)
                        .background(.black.opacity(0.6))
                        .clipShape(Circle())
                }
            }
            .padding(8)
        }
    }
}
