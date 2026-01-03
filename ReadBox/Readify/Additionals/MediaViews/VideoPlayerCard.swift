//
//  VideoPlayerCard.swift
//  ReadBox
//
//  Created by Macbook Pro on 07.11.2025.
//

//import SwiftUI
//import AVFoundation
//import AVKit
//import VideoPlayer
//import SwiftfulLoadingIndicators
//
//public struct VideoPlayerCard: View {
//    // MARK: - Public props
//    public let url: URL
//    public let cornerRadius: CGFloat
//    public let maxWidth: CGFloat
//    public let maxHeight: CGFloat
//    public let fallbackAspect: CGFloat
//    public let autoReplay: Bool
//    public let startMuted: Bool
//    public let isActive: Bool
//
//    // MARK: - Playback state
//    @State private var play: Bool = false
//    @State private var mute: Bool = false
//    @State private var time: CMTime = .zero
//    @State private var durationSec: Double? = nil
//
//    // MARK: - UI state
//    @State private var isLoading: Bool = true
//    @State private var isAspectReady: Bool = false
//    @State private var aspect: CGFloat? = nil
//    @State private var bufferProgress: Double = 0
//    @State private var stalled: Bool = false
//    @State private var visibleRatio: CGFloat = 0
//
//    // MARK: - Fullscreen state (system player)
//    @State private var showFullscreen: Bool = false
//    @State private var fullscreenTime: CMTime = .zero // актуальная позиция фуллскрина
//
//    // MARK: - Stall handling
//    private let stallThreshold: TimeInterval = 0.8
//    @State private var lastBufferChangeAt: Date = Date()
//    private let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
//
//    // MARK: - Visibility control
//    private let visibleThreshold: CGFloat = 0.5
//    private let activationGrace: TimeInterval = 0.35   // игнорим видимость сразу после активации
//    @State private var lastActivatedAt: Date = .distantPast
//
//    // MARK: - Aspect cache
//    private static let aspectCache = NSCache<NSString, NSNumber>()
//
//    // MARK: - Init
//    public init(
//        url: URL,
//        cornerRadius: CGFloat,
//        width: CGFloat,
//        height: CGFloat,
//        fallbackAspect: CGFloat = 1.0,
//        autoReplay: Bool = true,
//        startMuted: Bool = true,
//        isActive: Bool
//    ) {
//        self.url = url
//        self.cornerRadius = cornerRadius
//        self.maxWidth = width
//        self.maxHeight = height
//        self.fallbackAspect = fallbackAspect
//        self.autoReplay = autoReplay
//        self.startMuted = startMuted
//        self.isActive = isActive
//    }
//
//    // MARK: - Controls overlay
//    @ViewBuilder
//    private var controlsOverlay: some View {
//        if isAspectReady {
//            VStack {
//                HStack {
//                    Button {
//                        mute.toggle()
//                    } label: {
//                        Image(systemName: mute ? "speaker.slash.fill" : "speaker.wave.2.fill")
//                            .foregroundStyle(.white)
//                            .padding(8)
//                            .background(.black.opacity(0.6))
//                            .clipShape(Circle())
//                            .shadow(radius: 2)
//                    }
//
//                    Spacer(minLength: 0)
//
//                    Button {
//                        play.toggle()
//                        withAnimation { isLoading = play }
//                    } label: {
//                        Image(systemName: play ? "pause.fill" : "play.fill")
//                            .foregroundStyle(.white)
//                            .padding(8)
//                            .background(.black.opacity(0.6))
//                            .clipShape(Circle())
//                            .shadow(radius: 2)
//                    }
//                }
//                .padding(.horizontal, 8)
//                .padding(.top, 8)
//
//                Spacer()
//            }
//            .zIndex(10)
//            .allowsHitTesting(true)
//        }
//    }
//
//    // MARK: - Body
//    public var body: some View {
//        let ratio = aspect ?? fallbackAspect
//
//        let base = ZStack(alignment: .top) {
//            // 1) Видео
//            if isAspectReady {
//                VideoPlayer(url: url, play: $play, time: $time)
//                    .autoReplay(autoReplay)
//                    .mute(mute)
//                    .onStateChanged { state in
//                        switch state {
//                        case .loading:
//                            isLoading = true
//                        case .playing(let totalDuration):
//                            isLoading = false
//                            stalled = false
//                            if totalDuration > 1 { durationSec = totalDuration }
//                        case .paused(let playProgress, _):
//                            isLoading = false
//                            // playProgress может быть прогрессом (0...1) или секундами
//                            let seconds: Double
//                            if playProgress <= 1.05, let d = durationSec {
//                                seconds = max(0, min(d, d * playProgress))
//                            } else {
//                                seconds = max(0, playProgress)
//                            }
//                            time = CMTime(seconds: seconds, preferredTimescale: 600)
//                        case .error:
//                            isLoading = false
//                            stalled = false
//                        }
//                    }
//                    .onBufferChanged { progress in
//                        if progress > bufferProgress + 0.001 {
//                            lastBufferChangeAt = Date()
//                            stalled = false
//                        }
//                        bufferProgress = progress
//                    }
//                    .aspectRatio(ratio, contentMode: .fill)
//                    .clipped()
//                    .zIndex(0)
//            }
//
//            // 2) Лоадер под кнопками
//            if !isAspectReady || isLoading {
//                ZStack {
//                    Color.black.opacity(0.2).allowsHitTesting(false)
//                    LoadingIndicator(
//                        animation: .circleRunner,
//                        color: Color(.label),
//                        size: .small,
//                        speed: .fast
//                    )
//                }
//                .allowsHitTesting(false)
//                .zIndex(1)
//            }
//        }
//        // Тап по любому свободному месту — открываем системный фуллскрин
//        .contentShape(Rectangle())
//        .onTapGesture {
//            guard isAspectReady else { return }
//            fullscreenTime = time        // синхронизируем стартовую позицию
//            play = false                 // останавливаем инлайн, чтобы не было дубля звука
//            showFullscreen = true
//        }
//
//        return base
//            .frame(width: maxWidth, height: maxHeight)
//            .background(Color.black)
//            .compositingGroup()
//            .mask(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
//            .overlay(controlsOverlay, alignment: .top)
//
//            // MARK: - Fullscreen system player
//            .fullScreenCover(isPresented: $showFullscreen, onDismiss: {
//                // Возвращаемся с актуальной позицией
//                time = fullscreenTime
//                if isActive { play = true }
//            }) {
//                SystemFullscreenPlayer(
//                    url: url,
//                    startTime: fullscreenTime,
//                    isMuted: mute,
//                    lastKnownTime: $fullscreenTime
//                )
//                .ignoresSafeArea()
//            }
//
//            // MARK: - Lifecycle & visibility
//            .onAppear {
//                mute = startMuted
//                isLoading = true
//                probeAspect()
//            }
//            .onChange(of: isActive) { _, new in
//                // Активировали страницу карусели → сразу стартуем
//                lastActivatedAt = Date()
//                play = new
//                withAnimation { isLoading = new }
//            }
//            .onChange(of: visibleRatio) { _, new in
//                // Игнорируем первые activationGrace секунд после активации страницы
//                if Date().timeIntervalSince(lastActivatedAt) < activationGrace { return }
//                guard isActive else { return } // управляем только активной страницей
//                let shouldPlay = new >= visibleThreshold
//                if play != shouldPlay {
//                    play = shouldPlay
//                    withAnimation { isLoading = shouldPlay }
//                }
//            }
//            .onDisappear { play = false }
//            .onReceive(timer) { _ in
//                if play, isLoading, Date().timeIntervalSince(lastBufferChangeAt) > stallThreshold {
//                    // «пинок» буфера
//                    stalled = true
//                    play = false
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { play = true }
//                }
//            }
//            .visibilityDetector { ratio in
//                visibleRatio = ratio
//            }
//    }
//
//    // MARK: - Aspect probing & cache
//    private func probeAspect() {
//        let key = url.lastPathComponent as NSString
//        if let cached = Self.aspectCache.object(forKey: key) {
//            DispatchQueue.main.async {
//                aspect = CGFloat(truncating: cached)
//                isAspectReady = true
//                play = isActive
//                withAnimation { isLoading = false }
//            }
//            return
//        }
//
//        let asset = AVURLAsset(url: url)
//        asset.loadValuesAsynchronously(forKeys: ["tracks"]) {
//            var error: NSError?
//            if asset.statusOfValue(forKey: "tracks", error: &error) == .loaded,
//               let track = asset.tracks(withMediaType: .video).first {
//                let size = track.naturalSize.applying(track.preferredTransform)
//                let w = abs(size.width), h = abs(size.height)
//                guard w > 0, h > 0 else { return }
//                let ratio = w / h
//                Self.aspectCache.setObject(NSNumber(value: Float(ratio)), forKey: key)
//                DispatchQueue.main.async {
//                    aspect = ratio
//                    isAspectReady = true
//                    play = isActive
//                    withAnimation { isLoading = false }
//                }
//            } else {
//                DispatchQueue.main.async {
//                    aspect = fallbackAspect
//                    isAspectReady = true
//                    play = isActive
//                    withAnimation { isLoading = false }
//                }
//            }
//        }
//    }
//}
//
//// MARK: - UIKit fullscreen AVPlayerViewController wrapper
//private struct SystemFullscreenPlayer: UIViewControllerRepresentable {
//    let url: URL
//    let startTime: CMTime
//    let isMuted: Bool
//    @Binding var lastKnownTime: CMTime
//
//    final class Coordinator {
//        // Тот игрок, на который был добавлен observer в рамках ТЕКУЩЕГО VC
//        weak var observedPlayer: AVPlayer?
//        var timeObserver: Any?
//    }
//
//    func makeCoordinator() -> Coordinator { Coordinator() }
//
//    func makeUIViewController(context: Context) -> AVPlayerViewController {
//        let vc = AVPlayerViewController()
//
//        let player = AVPlayer(url: url)
//        player.seek(to: startTime, toleranceBefore: .zero, toleranceAfter: .zero)
//        player.isMuted = isMuted
//
//        vc.player = player
//        vc.entersFullScreenWhenPlaybackBegins = false
//        vc.exitsFullScreenWhenPlaybackEnds = true
//        vc.showsPlaybackControls = true
//
//        // Вешаем observer и запоминаем КОНКРЕТНЫЙ player, к которому он привязан
//        context.coordinator.observedPlayer = player
//        context.coordinator.timeObserver = player.addPeriodicTimeObserver(
//            forInterval: CMTime(seconds: 0.2, preferredTimescale: 600),
//            queue: .main
//        ) { t in
//            lastKnownTime = t
//        }
//
//        player.play()
//        return vc
//    }
//
//    func updateUIViewController(_ vc: AVPlayerViewController, context: Context) {
//        // здесь изменений не требуется
//    }
//
//    static func dismantleUIViewController(_ vc: AVPlayerViewController, coordinator: Coordinator) {
//        // Снимаем observer именно с того player, на который его навешивали
//        if let obs = coordinator.timeObserver, let p = coordinator.observedPlayer {
//            p.removeTimeObserver(obs)
//        }
//        coordinator.timeObserver = nil
//        coordinator.observedPlayer = nil
//    }
//}
//
//// MARK: - Visibility detector
//private struct VisibilityDetector: ViewModifier {
//    let onChange: (CGFloat) -> Void
//
//    func body(content: Content) -> some View {
//        content.background(
//            GeometryReader { geo in
//                Color.clear
//                    .onAppear { report(geo) }
//                    .onChange(of: geo.frame(in: .global)) { _ in report(geo) }
//            }
//        )
//    }
//
//    private func report(_ geo: GeometryProxy) {
//        let frame = geo.frame(in: .global)
//        let screen = UIScreen.main.bounds
//        let intersection = frame.intersection(screen)
//        let visible = max(0, min(frame.height, intersection.height))
//        let ratio = frame.height > 0 ? visible / frame.height : 0
//        onChange(ratio.isFinite ? ratio : 0)
//    }
//}
//
//private extension View {
//    func visibilityDetector(onChange: @escaping (CGFloat) -> Void) -> some View {
//        modifier(VisibilityDetector(onChange: onChange))
//    }
//}
