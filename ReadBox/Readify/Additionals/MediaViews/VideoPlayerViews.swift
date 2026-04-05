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
import UIKit

// MARK: - UIKit player layer wrapper

struct CustomVideoPlayerView: UIViewRepresentable {
    let player: AVPlayer
    let cornerRadius: CGFloat
    var isLooping: Bool = true
    var videoGravity: AVLayerVideoGravity = .resizeAspectFill
    
    func makeUIView(context: Context) -> PlayerUIView {
        let view = PlayerUIView()
        view.setup(
            player: player,
            cornerRadius: cornerRadius,
            isLooping: isLooping,
            videoGravity: videoGravity
        )
        return view
    }

    func updateUIView(_ uiView: PlayerUIView, context: Context) {}

    class PlayerUIView: UIView {
        private var playerLayer = AVPlayerLayer()
        private var playbackEndedObserver: Any?
        private var storedCornerRadius: CGFloat = 0

        func setup(player: AVPlayer, cornerRadius: CGFloat, isLooping: Bool, videoGravity: AVLayerVideoGravity) {
            layer.sublayers?.forEach { $0.removeFromSuperlayer() }

            backgroundColor = .clear
            layer.cornerRadius = cornerRadius
            layer.cornerCurve = .continuous
            layer.masksToBounds = true
            clipsToBounds = true
            storedCornerRadius = cornerRadius

            playerLayer = AVPlayerLayer()
            playerLayer.player = player
            playerLayer.videoGravity = videoGravity     // ✅ важно
            playerLayer.needsDisplayOnBoundsChange = true
            layer.addSublayer(playerLayer)

            if isLooping {
                if let observer = playbackEndedObserver {
                    NotificationCenter.default.removeObserver(observer)
                }
                playbackEndedObserver = NotificationCenter.default.addObserver(
                    forName: .AVPlayerItemDidPlayToEndTime,
                    object: nil,
                    queue: .main
                ) { [weak player] note in
                    guard let item = note.object as? AVPlayerItem,
                          let player, item == player.currentItem else { return }
                    player.seek(to: .zero)
                    player.play()
                }
            }
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            playerLayer.frame = bounds

            // ✅ Скругляем и клипаем по bounds (работает стабильно и с .resizeAspectFill)
            playerLayer.cornerRadius = storedCornerRadius
            playerLayer.masksToBounds = true

            // ❌ НЕ ставим mask по videoRect — именно он ломает скругления на fill
            playerLayer.mask = nil
        }

        deinit {
            if let observer = playbackEndedObserver {
                NotificationCenter.default.removeObserver(observer)
            }
        }
    }
}

// MARK: - Fullscreen presenter

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

    final class FullscreenDelegate: NSObject, AVPlayerViewControllerDelegate {
        var onDismiss: (CMTime) -> Void
        weak var player: AVPlayer?

        init(player: AVPlayer, onDismiss: @escaping (CMTime) -> Void) {
            self.player = player
            self.onDismiss = onDismiss
        }

        func playerViewControllerWillEndDismissalTransition(_ controller: AVPlayerViewController) {
            let time = player?.currentTime() ?? .zero
            onDismiss(time)
        }
    }
}

// MARK: - Player holder

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
            guard let self else { return }

            self.statusObserverForItem?.invalidate()
            self.statusObserverForItem = nil

            guard let item = player.currentItem else {
                DispatchQueue.main.async { self.isReadyToPlay = false }
                return
            }

            self.statusObserverForItem = item.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
                guard let self else { return }
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

// MARK: - Adaptive view (stable aspect ratio)

struct AdaptiveVideoPlayerView: View {
    let url: URL
    let cornerRadius: CGFloat
    var externalPlayer: AVPlayer? = nil
    let width: CGFloat
    let isReady: Bool

    /// Если задано — мы рисуем в фиксированном прямоугольнике width×height (для карусели)
    let height: CGFloat?
    /// true = заполняем прямоугольник (как фото в карусели), false = fit (натурально)
    let fillMode: Bool

    let showSpinner: Bool

    var body: some View {
        let h = height

        Group {
            if let player = externalPlayer, isReady {
                CustomVideoPlayerView(
                    player: player,
                    cornerRadius: cornerRadius,
                    videoGravity: fillMode ? .resizeAspectFill : .resizeAspect
                )
                .frame(width: width, height: h)            // ✅ фикс. прямоугольник в карусели
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            } else if showSpinner {
                LoadingIndicator(
                    animation: .circleRunner,
                    color: Color(.label),
                    size: .small,
                    speed: .fast
                )
                .frame(width: width, height: h)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            } else {
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(width: width, height: h)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            }
        }
    }
}

// MARK: - Main view

struct TappableVideoPreview: View {
    let url: URL
    let cornerRadius: CGFloat
    let width: CGFloat
    let placeholder: UIImage?
    let height: CGFloat?
    let fillMode: Bool
    let maxHeight: CGFloat?

    init(
        url: URL,
        cornerRadius: CGFloat,
        width: CGFloat = UIScreen.main.bounds.width - 32,
        height: CGFloat? = nil,
        placeholder: UIImage? = nil,
        fillMode: Bool = false,
        maxHeight: CGFloat? = nil
    ) {
        self.url = url
        self.cornerRadius = cornerRadius
        self.width = width
        self.height = height
        self.placeholder = placeholder
        self.fillMode = fillMode
        self.maxHeight = maxHeight
    }

    @StateObject private var playerHolder = PlayerHolder()

    @State private var playerViewId = UUID()
    @State private var resumeAfterFullscreenTime: CMTime? = nil
    @State private var videoSize: CGSize? = nil
    @State private var isManuallyPaused = false

    @State private var showPlaceholderOverlay = true
    @State private var overlayOpacity: Double = 1
    @State private var overlayBlur: CGFloat = 8

    @State private var initializedURL: URL?

    // ✅ высота фиксируется один раз и больше не меняется → нет "скачков"
    @State private var lockedHeight: CGFloat? = nil

    @Environment(\.scenePhase) private var scenePhase

    private var ratio: CGFloat {
        if let s = videoSize, s.height > 0 { return s.width / s.height }
        if let ph = placeholder, ph.size.height > 0 { return ph.size.width / ph.size.height }
        return 1.0
    }

    private func clampHeight(_ h: CGFloat) -> CGFloat {
        if let maxHeight { return min(h, maxHeight) }
        return h
    }

    private var cardHeight: CGFloat {
        if let h = height { return h }                 // карусель — задано снаружи
        if let h = lockedHeight { return h }           // одиночное — фиксированное
        return clampHeight(width / max(ratio, 0.01))    // fallback (пока ещё ничего нет)
    }

    private func lockHeightIfNeeded(usingRatio r: CGFloat) {
        guard height == nil else { return } // если height задан — это карусель, там фикс снаружи
        guard lockedHeight == nil else { return }
        let computed = clampHeight(width / max(r, 0.01))
        lockedHeight = computed
    }

    private func configurePlayerIfNeeded() {
        if initializedURL == url { return }
        initializedURL = url

        // ✅ фиксируем высоту сразу по placeholder (самое раннее и стабильное)
        if let ph = placeholder, ph.size.height > 0 {
            lockHeightIfNeeded(usingRatio: ph.size.width / ph.size.height)
            if videoSize == nil { videoSize = ph.size }
        } else {
            // если нет placeholder — хотя бы по текущему ratio (1.0) зафиксируем не будем,
            // подождём трек (иначе можно зафиксировать неверно)
        }

        showPlaceholderOverlay = true
        overlayOpacity = 1
        overlayBlur = 8

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

    var body: some View {
        let h = cardHeight

        ZStack(alignment: .top) {
            AdaptiveVideoPlayerView(
                url: url,
                cornerRadius: cornerRadius,
                externalPlayer: playerHolder.player,
                width: width,
                isReady: playerHolder.isReadyToPlay,
                height: h,
                fillMode: fillMode,
                showSpinner: (placeholder == nil)
            )
            .id(playerViewId)
            .onAppear { configurePlayerIfNeeded() }
            .onChange(of: url) {
                videoSize = nil
                lockedHeight = nil
                configurePlayerIfNeeded()
            }
            .onDisappear { playerHolder.player.pause() }
            .onScreenVisibility(threshold: 0.25) { isVisible in
                if !isVisible {
                    playerHolder.player.pause()
                } else if !isManuallyPaused {
                    playerHolder.player.play()
                }
            }
            .onChange(of: scenePhase) {
                if scenePhase != .active {
                    playerHolder.player.pause()
                }
            }
            .onChange(of: playerHolder.isReadyToPlay) {
                guard playerHolder.isReadyToPlay, showPlaceholderOverlay else { return }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        overlayBlur = 0
                        overlayOpacity = 0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showPlaceholderOverlay = false
                    }
                }
            }

            if let ph = placeholder, showPlaceholderOverlay {
                ZStack {
                    Image(uiImage: ph)
                        .resizable()
                        .scaledToFill()
                        .frame(width: width, height: h)
                        .clipped()
                        .blur(radius: overlayBlur)
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))

                    if !playerHolder.isReadyToPlay {
                        LoadingIndicator(
                            animation: .circleRunner,
                            color: Color(.white),
                            size: .small,
                            speed: .fast
                        )
                    }
                }
                .frame(width: width, height: h)
                .opacity(overlayOpacity)
            }

            Rectangle()
                .foregroundColor(.clear)
                .contentShape(Rectangle())
                .onTapGesture {
                    playerHolder.player.pause()

                    VideoFullscreenPresenter.present(player: playerHolder.player) { returnTime in
                        DispatchQueue.main.async {
                            playerHolder.player.pause()
                            playerHolder.player.seek(to: returnTime, toleranceBefore: .zero, toleranceAfter: .zero)
                            resumeAfterFullscreenTime = returnTime
                            playerViewId = UUID()
                        }
                    }
                }

            HStack {
                Button(action: { playerHolder.player.isMuted.toggle() }) {
                    Image(systemName: playerHolder.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .foregroundColor(.white)
                        .padding(8)
                        .background(.black.opacity(0.6))
                        .clipShape(Circle())
                }

                Spacer()

                Button(action: {
                    if playerHolder.isPlaying {
                        isManuallyPaused = true
                        playerHolder.player.pause()
                    } else {
                        isManuallyPaused = false
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
            .padding(.top, 10)
            .padding(.horizontal, 12)
        }
        .frame(width: width, height: h)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    private func loadVideoSize() {
        let asset = AVURLAsset(
            url: url,
            options: [AVURLAssetPreferPreciseDurationAndTimingKey: false]
        )

        Task.detached(priority: .utility) {
            do {
                let tracks = try await asset.loadTracks(withMediaType: .video)
                guard let track = tracks.first else { return }

                async let naturalSize = track.load(.naturalSize)
                async let preferredTransform = track.load(.preferredTransform)

                let size = try await naturalSize.applying(preferredTransform)
                let w = abs(size.width)
                let h = abs(size.height)
                guard w > 0, h > 0 else { return }

                await MainActor.run {
                    videoSize = CGSize(width: w, height: h)

                    // ✅ если placeholder не было — зафиксируем высоту по настоящему размеру один раз
                    if lockedHeight == nil, height == nil {
                        lockHeightIfNeeded(usingRatio: w / h)
                    }
                }
            } catch {
                print("⚠️ loadVideoSize error:", error)
            }
        }
    }
}

