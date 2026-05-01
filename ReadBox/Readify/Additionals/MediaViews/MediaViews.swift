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
    
    @Binding var zoomableImage: UIImage?
    @Binding var isZoomableViewPresented: Bool
    @Binding var currentIndex: Int
    
    @State private var images: [MediaKind?] = []
    @State private var redrawTick = 0
    @State private var isLoadingMedia: Bool = false
    
    @State private var videoPreviews: [Int: UIImage] = [:]
    
    
    @EnvironmentObject var sessionManager: SessionManager
    @EnvironmentObject var changedPostsManager: ChangedPostsManager

    private let maxImageSizeBytes: Int64 = 100 * 1024 * 1024      // до 4 МБ на фото
    private let maxPreviewSizeBytes: Int64 = 1 * 1024  * 1024      // до 512 КБ на превью видео

    private func carouselHeight(for width: CGFloat) -> CGFloat {
        min(width * 1.12, 450)
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
                let remoteURL = try await mp4Ref.downloadURLAsync()
                let cacheVideoId = "video_\(id)_\(i)"

                if let local = await VideoCacheManager.shared.cachedLocalURL(id: cacheVideoId),
                   !ignoreCache {
                    await MainActor.run {
                        if images.count != mediaCount { images = Array(repeating: nil, count: mediaCount) }
                        images[i] = MediaKind(videoURL: local)
                    }
                } else {
                    await MainActor.run {
                        if images.count != mediaCount { images = Array(repeating: nil, count: mediaCount) }
                        images[i] = MediaKind(videoURL: remoteURL)
                    }

                    Task.detached(priority: .utility) {
                        await VideoCacheManager.shared.warmCache(remoteURL: remoteURL, id: cacheVideoId)
                    }
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

            if let local = await VideoCacheManager.shared.cachedLocalURL(id: cacheId) {
                await MainActor.run {
                    if images.isEmpty {
                        images = [MediaKind(videoURL: local)]
                    } else {
                        images[0] = MediaKind(videoURL: local)
                    }
                }
                return
            }

            await MainActor.run {
                if images.isEmpty {
                    images = [MediaKind(videoURL: remoteURL)]
                } else {
                    images[0] = MediaKind(videoURL: remoteURL)
                }
            }

            Task.detached(priority: .utility) {
                await VideoCacheManager.shared.warmCache(remoteURL: remoteURL, id: cacheId)
            }
        } catch {
            // ничего нет — оставляем пусто
        }

    }
    
    var body: some View {
        let feedW = UIScreen.main.bounds.width - 25
        let ph = carouselHeight(for: feedW)
        let placeholderHeight = ph * 0.7
        
        let hasMedia = images.contains { $0 != nil }
        
        let containerHeight: CGFloat? = {
            if mediaCount == 0 {
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
                    return ph
                } else if isLoadingMedia {
                    return placeholderHeight
                } else {
                    return 0
                }
            }
        }()
        
        return ZStack {
            if hasMedia && mediaCount != 0 {
                Group {
                    if mediaCount == 1 {
                        if let image = images.first??.image {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 23))
                                .frame(maxWidth: feedW, maxHeight: 350, alignment: .leading)
                                .onTapGesture {
                                    withAnimation {
                                        zoomableImage = image
                                        isZoomableViewPresented = true
                                    }
                                }
                                
                        } else if let url = images.first??.videoURL {
                            TappableVideoPreview(
                                url: url,
                                cornerRadius: 23,
                                width: feedW,
                                placeholder: videoPreviews[0],
                                fillMode: true,
                                maxHeight: 400
                            )
                            .id(url.absoluteString)
                        }
                    } else {
                        TabView(selection: $currentIndex) {
                            ForEach(0..<mediaCount, id: \.self) { i in
                                carouselItem(at: i, feedW: feedW, carouselHeight: ph)
                                    .tag(i)
                            }
                        }
                        .id(redrawTick)
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .contentMargins(.horizontal, 0, for: .scrollContent)
                        .frame(width: feedW, height: ph)
                        .clipShape(RoundedRectangle(cornerRadius: 23))
                    }
                }
                .transition(.opacity)
                
            } else if isLoadingMedia {
                RoundedRectangle(cornerRadius: 23)
                    .fill(Color(.systemGray5))
                    .frame(width: feedW, height: placeholderHeight)
                    .redacted(reason: .placeholder)
                    .shimmering()
                    .transition(.opacity)
            }
        }
        .frame(width: feedW, height: containerHeight)
        .animation(.easeOut(duration: 0.18), value: hasMedia)
        .animation(.easeOut(duration: 0.12), value: isLoadingMedia)
        .task {
            guard mediaCount != 0 else { return }
            
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
    func carouselItem(at index: Int, feedW: CGFloat, carouselHeight: CGFloat) -> some View {
        ZStack(alignment: .top) {
            if images.count > index {
                if let image = images[index]?.image {
                    ZStack(alignment: .top) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: feedW, height: carouselHeight)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 23))
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation {
                                    zoomableImage = image
                                    isZoomableViewPresented = true
                                }
                            }

                        makeIndicatorView()
                    }
                } else if let videoURL = images[index]?.videoURL {
                    ZStack(alignment: .top) {
                        TappableVideoPreview(
                            url: videoURL,
                            cornerRadius: 23,
                            width: feedW,
                            height: carouselHeight,
                            placeholder: videoPreviews[index],
                            fillMode: true
                        )
                        .id(videoURL.absoluteString)
                        .frame(width: feedW, height: carouselHeight)

                        makeIndicatorView(isVideo: true)
                    }
                } else {
                    makePlaceholderView(
                        feedW: feedW,
                        height: carouselHeight,
                        preview: videoPreviews[index]
                    )
                }
            } else {
                makePlaceholderView(
                    feedW: feedW,
                    height: carouselHeight,
                    preview: videoPreviews[index]
                )
            }
        }
        .frame(width: feedW, height: carouselHeight)
    }

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

private extension MediaViews {
    @ViewBuilder
    func makeIndicatorView(isVideo: Bool = false) -> some View {
        if #available(iOS 26, *) {
            Text("\(currentIndex + 1)/\(mediaCount)")
                .font(.system(size: 14))
                .padding(.all, 8)
                .glassEffect(.regular, in: Capsule())
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.top, 12)
                .padding(.horizontal, 10)
                .padding(.trailing, isVideo ? 40 : 0)
        } else{
            Text("\(currentIndex + 1)/\(mediaCount)")
            .font(.system(size: 17))
            .fontDesign(.rounded)
            .foregroundStyle(Color.gray)
            .frame(width: UIScreen.main.bounds.width - 32,
                   alignment: .trailing)
            .padding(.top, -10)
        }
    }
}
