//
//  PostView.swift
//  Readify
//
//  Created by Тимофей Юдин on 11.01.2025.
//

import SwiftUI
import FirebaseStorage
import AVFoundation

struct PostView: View {
    let id: String
    let title: String
    let likesCount: Int
    let viewsCount: Int
    let isArchive: Bool
    let mediaCount: Int
    
    @Binding var postOption: PostOptions
    @Binding var selectedId: String
    
    @State private var image: UIImage? = nil
    @State private var isVideo = false
    
    @EnvironmentObject var hudService: HUDService
    
    private func makeVideoThumbnail(url: URL) async -> UIImage? {
        let asset = AVURLAsset(url: url)
        _ = try? await asset.load(.duration)
        let gen = AVAssetImageGenerator(asset: asset)
        gen.appliesPreferredTrackTransform = true
        gen.maximumSize = CGSize(width: 220, height: 220)
        gen.requestedTimeToleranceBefore = .zero
        gen.requestedTimeToleranceAfter  = .zero
        let time = CMTime(seconds: 0.05, preferredTimescale: 600)
        let cg = try? gen.copyCGImage(at: time, actualTime: nil)
        return cg.map { UIImage(cgImage: $0) }
    }
    
    private func loadPreview(ignoreCache: Bool = false) async {
        await MainActor.run {
            image = nil
            isVideo = false
        }
        
        let root = Storage.storage().reference().child("images")
        let mainCacheId = "\(id)_0"          // фото
        let previewCacheId = "\(id)_0_preview" // превью для видео
        
        // 0) Если нужно игнорировать кэш — сбросим его
        if ignoreCache {
            StorageManager.shared.deleteImage(id: mainCacheId)
            StorageManager.shared.deleteImage(id: previewCacheId)
        } else {
            // 1) Пробуем основное фото из кэша
            if let cached = StorageManager.shared.getImage(id: mainCacheId) {
                await MainActor.run {
                    withAnimation {
                        image = cached
                        isVideo = false
                    }
                }
                return
            }
            
            // 2) Пробуем превью видео из кэша
            if let cachedPreview = StorageManager.shared.getImage(id: previewCacheId) {
                await MainActor.run {
                    withAnimation {
                        image = cachedPreview
                        isVideo = true
                    }
                }
                return
            }
        }
        
        // 3) Пытаемся получить первое медиа с сервера:
        //    сначала jpg_0, потом _preview, потом mp4
        // 3.1 jpg_0
        do {
            let data = try await root.child("\(id)_0.jpg").dataAsync(maxSize: 600 * 1024)
            if let ui = UIImage(data: data) {
                await MainActor.run {
                    withAnimation {
                        image = ui
                        isVideo = false
                    }
                    StorageManager.shared.saveImage(id: mainCacheId, image: ui)
                }
                return
            }
        } catch {
            // нет jpg_0 — идём дальше
        }
        
        // 3.2 _preview для видео
        do {
            let data = try await root.child("\(id)_0_preview.jpg").dataAsync(maxSize: 600 * 1024)
            if let ui = UIImage(data: data) {
                await MainActor.run {
                    withAnimation {
                        image = ui
                        isVideo = true
                    }
                    StorageManager.shared.saveImage(id: previewCacheId, image: ui)
                }
                return
            }
        } catch {
            // нет превью — попробуем mp4
        }
        
        // 3.3 mp4_0 + локальный thumbnail (fallback, на всякий)
        do {
            let url = try await root.child("\(id)_0.mp4").downloadURLAsync()
            if let thumb = await makeVideoThumbnail(url: url) {
                await MainActor.run {
                    withAnimation {
                        image = thumb
                        isVideo = true
                    }
                    StorageManager.shared.saveImage(id: previewCacheId, image: thumb)
                }
                return
            }
        } catch {
            // нет и mp4_0 — падаем в легаси-схему
        }
        
        // 4) Легаси: id, images/id.jpg, images/id.mp4
        if !ignoreCache, let cached = StorageManager.shared.getImage(id: id) {
            await MainActor.run {
                withAnimation {
                    image = cached
                    isVideo = false
                }
            }
            return
        }
        
        if let data = try? await root.child("\(id).jpg").dataAsync(maxSize: 600 * 1024),
           let ui = UIImage(data: data) {
            await MainActor.run {
                withAnimation {
                    image = ui
                    isVideo = false
                }
                StorageManager.shared.saveImage(id: id, image: ui)
            }
            return
        }
        
        if let url = try? await root.child("\(id).mp4").downloadURLAsync(),
           let thumb = await makeVideoThumbnail(url: url) {
            await MainActor.run {
                withAnimation {
                    image = thumb
                    isVideo = true
                }
            }
        }
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .frame(width: UIScreen.main.bounds.width - 10)
                .foregroundStyle(Color(uiColor: .secondarySystemBackground))
                .shadow(radius: 1)
            
            HStack {
                if let image = image {
                    ZStack {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .padding(.vertical, 10)
                        
                        if isVideo {
                            Image(systemName: "play.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30)
                                .foregroundStyle(Color(.secondarySystemBackground))
                        }
                    }
                    .overlay(
                        Text("\(mediaCount)")
                            .fontDesign(.rounded)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.gray)
                            .padding(.all, 10)
                            .background(Color(.systemBackground))
                            .clipShape(Circle())
                            .offset(x: 10)
                            .opacity(mediaCount > 1 ? 1 : 0),
                        alignment: .topTrailing
                    )
                }
                
                VStack {
                    HStack {
                        Text(title)
                            .font(.title3)
                            .fontDesign(.rounded)
                            .lineLimit(3)
                        
                        Spacer()
                    }
                    
                    Spacer()
                    
                    HStack {
                        Image(systemName: "eye")
                            .scaleEffect(0.8)
                        
                        Text("\(viewsCount)")
                            .padding(.leading, -5)
                            .padding(.trailing, 5)
                        
                        Image(systemName: "hand.thumbsup")
                            .scaleEffect(0.8)
                        
                        Text("\(likesCount)")
                            .padding(.leading, -5)
                        
                        Spacer()
                    }
                    .frame(alignment: .leading)
                }
                .padding(.vertical, 20)
                .padding(.leading, 10)
                
                Menu {
                    Button {
                        postOption = .editing
                        selectedId = id
                    } label: {
                        Label(NSLocalizedString("editingLabel", comment: ""), systemImage: "pencil")
                    }
                    
                    Button {
                        selectedId = id
                        
                        if isArchive {
                            postOption = .publish
                        } else {
                            postOption = .toArchive
                        }
                        
                    } label: {
                        if isArchive {
                            Label(NSLocalizedString("publishLabel", comment: ""), systemImage: "paperplane")
                        } else {
                            Label(NSLocalizedString("saveToArchiveLabel", comment: ""), systemImage: "archivebox")
                        }
                    }
                
                    Button {
                        postOption = .delete
                        selectedId = id
                        
                        print("HERE: \(id)")
                        
                        StorageManager.shared.deleteImage(id: id)
                    } label: {
                        Label(NSLocalizedString("deleteLabel", comment: ""), systemImage: "xmark.circle")
                    }
                    
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.title2)
                        .foregroundStyle(Color.gray)
                        .frame(width: 30, height: 30)
                        .padding(.trailing, 10)
                }
                .opacity(hudService.isLoading ? 0 : 1)
                .animation(.default, value: hudService.isLoading)
            }
            .frame(width: UIScreen.main.bounds.width - 30)
        }
        .onAppear {
            Task(priority: .userInitiated) { await loadPreview() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .postMediaDidUpdate)) { note in
            guard let pid = note.userInfo?["postId"] as? String, pid == id else { return }
            Task(priority: .userInitiated) { await loadPreview(ignoreCache: true) }
        }
    }
}

//#Preview {
//    PostView(id: "", title: "", likesCount: 0, viewsCount: 0, isArchive: false, isAuthorView: true, postOption: .constant(PostOptions.nothing), selectedId: .constant("7"))
//}
