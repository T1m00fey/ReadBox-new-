//
//  MediaViews.swift
//  ReadBox
//
//  Created by Тимофей Юдин on 09.11.2025.
//

import SwiftUI
import FirebaseStorage
import SwiftfulLoadingIndicators
import AVFoundation
import Shimmer

struct MediaViews: View {
    let id: String
    let authorId: String
    let mediaCount: Int
    let mediaVersion: Int
    let isArchive: Bool
    
    @Binding var zoomableImage: UIImage?
    @Binding var isZoomableViewPresented: Bool
    @Binding var currentIndex: Int
    
    @State private var images: [MediaKind?] = []
    @State private var aspects: [Int: CGFloat] = [:]
    @State private var redrawTick = 0
    @State private var isLoadingMedia: Bool = false
    
    @State private var videoPreviews: [Int: UIImage] = [:]
    
    
    @EnvironmentObject var sessionManager: SessionManager
    @EnvironmentObject var changedPostsManager: ChangedPostsManager
    
    private let minAspect: CGFloat = 4.0/5.0
    private let maxAspect: CGFloat = 1.91/1.0
    
    private let maxImageSizeBytes: Int64 = 100 * 1024 * 1024      // до 4 МБ на фото
    private let maxPreviewSizeBytes: Int64 = 1 * 1024  * 1024      // до 512 КБ на превью видео

    private func clampAspect(_ a: CGFloat) -> CGFloat {
        min(max(a, minAspect), maxAspect)
    }

    private func itemHeight(for i: Int, width: CGFloat) -> CGFloat {
        let a = clampAspect(aspects[i] ?? 1.0)
        return width / a
    }

//    private func carouselHeight(for width: CGFloat) -> CGFloat {
//        let a = clampAspect(aspects.values.max() ?? 1.0)
//        return width / a
//    }
    
    private func carouselHeight(for width: CGFloat) -> CGFloat {
        let a: CGFloat = 4.0 / 5.0
        return width / a
    }
    
    private func fetchImages(
        ignoreCache: Bool = false,
        ignoreCacheFull: Bool = false
    ) async {
        let storage = Storage.storage()
        let root = storage.reference().child("images")

        await MainActor.run {
            if images.count != mediaCount {
                images = Array(repeating: nil, count: mediaCount)
            }
        }

        await withTaskGroup(of: Void.self) { group in
            for index in 0..<mediaCount {
                group.addTask {
                    await loadMediaItem(
                        at: index,
                        root: root,
                        ignoreCache: ignoreCache,
                        ignoreCacheFull: ignoreCacheFull
                    )
                }
            }
        }
    }

    
    private func loadMediaItem(
        at i: Int,
        root: StorageReference,
        ignoreCache: Bool,
        ignoreCacheFull: Bool
    ) async {
        let cacheId = "\(id)_\(i)"
        let previewCacheId = "\(id)_\(i)_preview"

        var gotMainMedia = false

        // 1. Пробуем взять из локального кеша (StorageManager)
        if !ignoreCacheFull,
           let cached = StorageManager.shared.getImage(id: cacheId) {

            await MainActor.run {
                if images.count != mediaCount {
                    images = Array(repeating: nil, count: mediaCount)
                }
                if images[i] == nil {
                    images[i] = MediaKind(image: cached)
                    aspects[i] = max(
                        0.1,
                        cached.size.width / max(cached.size.height, 0.1)
                    )
                }
            }

            gotMainMedia = true

            // Если не хотим обновлять из сети — на этом всё
            if !ignoreCache {
                return
            }
        }

        // 2. Пробуем скачать JPG (фото)
        do {
            let jpgRef = root.child("\(id)_\(i).jpg")
            let data = try await jpgRef.dataAsync(maxSize: maxImageSizeBytes)

            if let ui = UIImage(data: data) {
                await MainActor.run {
                    if images.count != mediaCount {
                        images = Array(repeating: nil, count: mediaCount)
                    }
                    images[i] = MediaKind(image: ui)
                    StorageManager.shared.saveImage(id: cacheId, image: ui)
                    aspects[i] = max(
                        0.1,
                        ui.size.width / max(ui.size.height, 0.1)
                    )
                }
                gotMainMedia = true
            }
        } catch {
            // jpg нет — возможно, это видео
        }

        // 3. Если фото не нашли — пробуем видео (превью + mp4)
        if !gotMainMedia {
            // 3.1. Превью видео
            if videoPreviews[i] == nil {
                if let cachedPreview = StorageManager.shared.getImage(id: previewCacheId) {
                    await MainActor.run {
                        videoPreviews[i] = cachedPreview
                    }
                } else {
                    do {
                        let previewRef = root.child("\(id)_\(i)_preview.jpg")
                        let previewData = try await previewRef.dataAsync(maxSize: maxPreviewSizeBytes)
                        if let previewImage = UIImage(data: previewData) {
                            await MainActor.run {
                                videoPreviews[i] = previewImage
                                StorageManager.shared.saveImage(
                                    id: previewCacheId,
                                    image: previewImage
                                )
                            }
                        }
                    } catch {
                        // нет превью — покажем просто серый плейсхолдер со спиннером
                    }
                }
            }

            // 3.2. Само видео
            do {
                let mp4Ref = root.child("\(id)_\(i).mp4")
                let url = try await mp4Ref.downloadURLAsync()
                let cacheVideoId = "video_\(id)_\(i)"

                let localURL = try await VideoCacheManager.shared.cachedURL(
                    for: url,
                    id: cacheVideoId,
                    ignoreCache: ignoreCache
                )

                await MainActor.run {
                    if images.count != mediaCount {
                        images = Array(repeating: nil, count: mediaCount)
                    }
                    images[i] = MediaKind(videoURL: localURL)
                }

                // 3.3. В фоне считаем аспект видео
                Task.detached(priority: .utility) {
                    let asset = AVURLAsset(url: url)
                    do {
                        let tracks = try await asset.loadTracks(withMediaType: .video)
                        if let track = tracks.first {
                            async let ns = track.load(.naturalSize)
                            async let tr = track.load(.preferredTransform)
                            let size = try await ns.applying(tr)
                            let w = abs(size.width), h = abs(size.height)
                            guard w > 0, h > 0 else { return }
                            await MainActor.run { aspects[i] = w / h }
                        }
                    } catch { }
                }

            } catch {
                // не нашли и видео — оставляем плейсхолдер, потом сработает fallback
            }
        }
    }
    
    private func fetchImageFallback() async {
        if let articleImage = StorageManager.shared.getImage(id: id) {
            await MainActor.run {
                if images.isEmpty {
                    images = [MediaKind(image: articleImage)]
                } else {
                    images[0] = MediaKind(image: articleImage)
                }
            }
            return
        }

        let storage = Storage.storage()
        let storageRef = storage.reference()

        do {
            let data = try await storageRef
                .child("images/\(id).jpg")
                .dataAsync(maxSize: 2 * 5012 * 5012)

            if let image = UIImage(data: data) {
                await MainActor.run {
                    if images.isEmpty {
                        images = [MediaKind(image: image)]
                    } else {
                        images[0] = MediaKind(image: image)
                    }
                    StorageManager.shared.saveImage(id: id, image: image)
                }
                return
            }
        } catch { }

        do {
            let remoteURL = try await storageRef
                .child("images/\(id).mp4")
                .downloadURLAsync()

            let cacheId = "video_\(self.id)_0"
            let localURL = (try? await VideoCacheManager.shared.cachedURL(
                for: remoteURL,
                id: cacheId
            )) ?? remoteURL

            await MainActor.run {
                if images.isEmpty {
                    images = [MediaKind(videoURL: localURL)]
                } else {
                    images[0] = MediaKind(videoURL: localURL)
                }
            }
        } catch {
            // ничего нет — оставляем пусто
        }
    }
    
    var body: some View {
        let feedW = UIScreen.main.bounds.width - 25
        let ph = carouselHeight(for: feedW)
        let placeholderHeight = ph * 0.7
        let counterHeight: CGFloat = 24
        
        let hasMedia = images.contains { $0 != nil }
        
        let containerHeight: CGFloat? = {
            if mediaCount == 0 || isArchive {
                return 0
            }
            
            if mediaCount == 1 {
                if hasMedia {
                    return nil
                } else if isLoadingMedia {
                    return placeholderHeight
                } else {
                    return 0
                }
            } else {
                if hasMedia {
                    return ph + counterHeight
                } else if isLoadingMedia {
                    return placeholderHeight
                } else {
                    return 0
                }
            }
        }()
        
        return ZStack {
            if hasMedia && mediaCount != 0 && !isArchive {
                Group {
                    if mediaCount == 1 {
                        if let image = images.first??.image {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: feedW)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .onTapGesture {
                                    withAnimation {
                                        zoomableImage = image
                                        isZoomableViewPresented = true
                                    }
                                }
                                
                        } else if let url = images.first??.videoURL {
                            let h = itemHeight(for: 0, width: feedW)
                            
                            TappableVideoPreview(
                                url: url,
                                cornerRadius: 20,
                                width: feedW,
                                height: h,
                                placeholder: videoPreviews[0]
                            )
                            .id(url.absoluteString)
                            .frame(width: feedW, height: h)
                        }
                    } else {
                        VStack {
                            Text("\(currentIndex + 1)/\(mediaCount)")
                                .font(.system(size: 18))
                                .fontDesign(.rounded)
                                .foregroundStyle(Color.gray)
                                .frame(width: UIScreen.main.bounds.width - 32,
                                       alignment: .trailing)
                                .padding(.top, -10)
                            
                            TabView(selection: $currentIndex) {
                                ForEach(0..<mediaCount, id: \.self) { i in
                                    ZStack {
                                        if images.count > i {
                                            if let image = images[i]?.image {
                                                Image(uiImage: image)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: feedW, height: ph)
                                                    .clipped()
                                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                                                    .contentShape(Rectangle())
                                                    .onTapGesture {
                                                        withAnimation {
                                                            zoomableImage = image
                                                            isZoomableViewPresented = true
                                                        }
                                                    }
                                                
                                            } else if let videoURL = images[i]?.videoURL {
                                                TappableVideoPreview(
                                                    url: videoURL,
                                                    cornerRadius: 20,
                                                    width: feedW,
                                                    height: ph,
                                                    placeholder: videoPreviews[i]
                                                )
                                                .id(videoURL.absoluteString)
                                                .frame(width: feedW, height: ph)
                                                
                                            } else {
                                                makePlaceholderView(
                                                    feedW: feedW,
                                                    height: ph,
                                                    preview: videoPreviews[i]
                                                )
                                            }
                                        } else {
                                            makePlaceholderView(
                                                feedW: feedW,
                                                height: ph,
                                                preview: videoPreviews[i]
                                            )
                                        }
                                    }
                                    .frame(width: feedW, height: ph)
                                    .tag(i)
                                }
                            }
                            .id(redrawTick)
                            .tabViewStyle(.page(indexDisplayMode: .never))
                            .contentMargins(.horizontal, 0, for: .scrollContent)
                            .frame(width: feedW, height: ph)
                        }
                    }
                }
                .transition(.opacity)
                
            } else if isLoadingMedia {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemGray5))
                    .frame(width: feedW, height: placeholderHeight)
                    .redacted(reason: .placeholder)
                    .shimmering()
                    .transition(.opacity)
            }
        }
        .frame(width: feedW, height: containerHeight)
        .padding(.bottom, 5)
        .animation(.easeOut(duration: 0.18), value: hasMedia)
        .animation(.easeOut(duration: 0.12), value: isLoadingMedia)
        .task {
            guard mediaCount != 0, !isArchive else { return }
            
            if mediaVersion == 1 {
                let alreadyHasMedia = await MainActor.run {
                    images.contains { $0 != nil }
                }
                if alreadyHasMedia { return }

                await MainActor.run {
                    withAnimation {
                        isLoadingMedia = true
                    }
                }

                await fetchImageFallback()

                await MainActor.run {
                    withAnimation {
                        isLoadingMedia = false
                    }
                }

                return
            }

            await MainActor.run {
                withAnimation {
                    isLoadingMedia = true
                }
            }

            let lastSessionId = StorageManager.shared.getSessionId()
            let currentSessionId = sessionManager.sessionId
            let isSameSession = (lastSessionId == currentSessionId)
            let isChanged = changedPostsManager.changedPostsIDs.contains(id)
            let ignoreCache = isChanged || !isSameSession

            if !ignoreCache {
                let alreadyHasMedia = await MainActor.run {
                    images.contains { $0 != nil }
                }
                if alreadyHasMedia {
                    await MainActor.run {
                        withAnimation {
                            isLoadingMedia = false
                        }
                    }
                    return
                }
            }

            if ignoreCache {
                await fetchImages(ignoreCache: true, ignoreCacheFull: false)
                await MainActor.run {
                    StorageManager.shared.setSessionId(currentSessionId)
                    changedPostsManager.changedPostsIDs.removeAll { $0 == id }
                }
            } else {
                await fetchImages(ignoreCache: false, ignoreCacheFull: false)
            }

            await MainActor.run {
                withAnimation {
                    isLoadingMedia = false
                }
            }
        }
    }
}

private extension MediaViews {
    @ViewBuilder
    func makePlaceholderView(feedW: CGFloat, height: CGFloat, preview: UIImage?) -> some View {
        if let preview {
            ZStack {
                Image(uiImage: preview)
                    .resizable()
                    .scaledToFill()
                    .frame(width: feedW, height: height)
                    .clipped()
                    .blur(radius: 8)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                
                LoadingIndicator(
                    animation: .circleRunner,
                    color: Color(.label),
                    size: .small,
                    speed: .fast
                )
            }
            .frame(width: feedW, height: height)
        } else {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemGray5))
                .redacted(reason: .placeholder)
                .shimmering()
                .frame(width: feedW, height: height)
        }
    }
}
