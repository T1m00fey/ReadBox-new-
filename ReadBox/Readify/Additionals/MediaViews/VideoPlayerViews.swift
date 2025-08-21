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
                    object: nil,
                    queue: .main
                ) { [weak self] notification in
                    guard let _ = self else { return }
                    guard let item = notification.object as? AVPlayerItem,
                          item == player.currentItem else { return }

                    player.seek(to: .zero)
                    player.play()
                }
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
    private static var delegateMap = NSMapTable<AVPlayerViewController, FullscreenDelegate>(
        keyOptions: .weakMemory,
        valueOptions: .strongMemory
    )

    static func present(player: AVPlayer, onDismiss: @escaping (CMTime) -> Void) {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.modalPresentationStyle = .fullScreen

        let delegate = FullscreenDelegate(player: player) { time in
            onDismiss(time)
            delegateMap.removeObject(forKey: controller)
        }

        controller.delegate = delegate
        delegateMap.setObject(delegate, forKey: controller)

        if let topVC = topMostViewController() {
            topVC.present(controller, animated: true) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    player.play()
                }
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
            print("📤 Dismissed at time:", time.seconds)
            onDismiss(time)
        }
    }
}

struct AdaptiveVideoPlayerView: View {
    let url: URL
    let cornerRadius: CGFloat
    var externalPlayer: AVPlayer? = nil
    let width: CGFloat
    let isReady: Bool
    let height: CGFloat
    
    init(
        url: URL,
        cornerRadius: CGFloat,
        externalPlayer: AVPlayer? = nil,
        width: CGFloat,
        isReady: Bool,
        height: CGFloat
    ) {
        self.url = url
        self.cornerRadius = cornerRadius
        self.externalPlayer = externalPlayer
        self.width = width
        self.isReady = isReady
        self.height = height
    }

    var body: some View {
        Group {
            if let player = externalPlayer, isReady {
                CustomVideoPlayerView(
                    player: player,
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
                .frame(width: width, height: height > 300 ? 200 : height)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }
}

final class PlayerHolder: ObservableObject {
    let player = AVPlayer()

    @Published var isPlaying: Bool = false
    @Published var isMuted: Bool = true
    @Published var isReadyToPlay: Bool = false

    private var currentItemObserver: NSKeyValueObservation?
    private var statusObserverForItem: NSKeyValueObservation?
    private var statusObserver: NSKeyValueObservation?
    private var muteObserver: NSKeyValueObservation?

    init() {
        statusObserver = player.observe(\.timeControlStatus, options: [.initial, .new]) { [weak self] player, _ in
            DispatchQueue.main.async {
                self?.isPlaying = (player.timeControlStatus == .playing || player.timeControlStatus == .waitingToPlayAtSpecifiedRate)
            }
        }

        muteObserver = player.observe(\.isMuted, options: [.initial, .new]) { [weak self] player, _ in
            DispatchQueue.main.async { self?.isMuted = player.isMuted }
        }

        currentItemObserver = player.observe(\.currentItem, options: [.initial, .new]) { [weak self] player, _ in
            guard let self = self else { return }

            self.statusObserverForItem?.invalidate()
            self.statusObserverForItem = nil

            guard let item = player.currentItem else {
                DispatchQueue.main.async { self.isReadyToPlay = false }
                return
            }

            self.statusObserverForItem = item.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
                guard let self = self else { return }
                let ready = (item.status == .readyToPlay)
                DispatchQueue.main.async {
                    self.isReadyToPlay = ready
                    if ready {
                        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
                        try? AVAudioSession.sharedInstance().setActive(true)
                        self.player.play()
                    }
                }
            }
        }
    }

    deinit {
        statusObserver?.invalidate()
        muteObserver?.invalidate()
        currentItemObserver?.invalidate()
        statusObserverForItem?.invalidate()
    }
}

struct TappableVideoPreview: View {
    let url: URL
    let cornerRadius: CGFloat
    let width: CGFloat
    let height: CGFloat?
    
    init(
        url: URL,
        cornerRadius: CGFloat,
        width: CGFloat = UIScreen.main.bounds.width - 32,
        height: CGFloat? = nil
    ) {
        self.url = url
        self.cornerRadius = cornerRadius
        self.width = width
        self.height = height
    }
    
    @StateObject private var playerHolder = PlayerHolder()
    
    @State private var playerViewId = UUID()
    @State private var resumeAfterFullscreenTime: CMTime? = nil
    @State private var hasInitialized = false
    @State private var videoSize: CGSize? = nil
    
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        let calculatedHeight: CGFloat? = {
            if let size = videoSize {
                return width * size.height / size.width
            } else {
                return nil
            }
        }()
        
        ZStack(alignment: .top) {
            AdaptiveVideoPlayerView(
                url: url,
                cornerRadius: cornerRadius,
                externalPlayer: playerHolder.player,
                width: width,
                isReady: playerHolder.isReadyToPlay,
                height: height ?? calculatedHeight ?? 250
            )
            .id(playerViewId)
            .onAppear {
                guard !hasInitialized else { return }
                hasInitialized = true

                let asset = AVURLAsset(url: url, options: [
                    AVURLAssetPreferPreciseDurationAndTimingKey: false
                ])
                let item = AVPlayerItem(asset: asset)

                playerHolder.player.replaceCurrentItem(with: item)
                playerHolder.player.automaticallyWaitsToMinimizeStalling = true
                playerHolder.player.isMuted = true

                if let t = resumeAfterFullscreenTime {
                    playerHolder.player.seek(to: t, toleranceBefore: .zero, toleranceAfter: .zero)
                    resumeAfterFullscreenTime = nil
                } else {
                    try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
                    try? AVAudioSession.sharedInstance().setActive(true)
                }

                loadVideoSize()
            }
            .onDisappear {
                playerHolder.player.pause()
            }
            .onScreenVisibility(threshold: 0.25) { isVisible in
                if !isVisible {
                    playerHolder.player.pause()
                } else {
                    playerHolder.player.play()
                }
            }
            .onChange(of: scenePhase) {
                if scenePhase != .active {
                    playerHolder.player.pause()
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
    
    private func loadVideoSize() {
        Task {
            let asset = AVAsset(url: url)
            let tracks = try? await asset.loadTracks(withMediaType: .video)
            if let track = tracks?.first {
                let naturalSize = try? await track.load(.naturalSize)
                let transform = try? await track.load(.preferredTransform)
                let size = naturalSize ?? .zero
                let t = transform ?? .identity
                let realSize = size.applying(t)
                await MainActor.run {
                    self.videoSize = CGSize(width: abs(realSize.width), height: abs(realSize.height))
                }
            }
        }
    }
}
