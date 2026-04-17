//
//  PostCreateViewModel.swift
//  ReadBox
//
//  Created by Тимофей Юдин on 18.08.2025.
//

import SwiftUI
import PhotosUI
import FirebaseStorage

final class PostCreateViewModel: ObservableObject {
    private static var defaultLanguageSelection: Int {
        Locale.preferredLanguages.first?.components(separatedBy: "-").first == "ru" ? 1 : 0
    }
    
    @Published var text = ""
    @Published var isArchive = false
    @Published var imageItem: PhotosPickerItem? = nil
    @Published var selectedLanguage = PostCreateViewModel.defaultLanguageSelection
    @Published var selectedMediaPosition = 0
    @Published var addingMode = 0
    @Published var isPremiumPost = 0
    @Published var isLoading = false
    @Published var oldMediaCount = 0
    @Published var isCoverLoading = false
    @Published var imagePickerTask: Task<Void, Never>? = nil
    @Published var avatarImage: UIImage? = nil
    
    @Published var errorText = ""
    @Published var isErrorPopupPresented = false
    
    @Published var isConfirmationPopupPresented = false
    @Published var isPostSettingsPopupPresented = false
    
    func getHeightOfPopupSettingPopup(isLanguageSettingHidden: Bool, isPremiumAuthor: Bool) -> CGFloat {
        var h = CGFloat(200)
        
        if !isLanguageSettingHidden { h += 100 }
        if isPremiumAuthor { h += 100 }
        
        return h
    }
    
    // MARK: - Helpers for full delete (если где-то пригодится)
    
    private func deleteAllCovers(postId: String, mediaCount: Int) async {
        for i in 0..<mediaCount {
            let imageRef   = Storage.storage().reference(withPath: "images/\(postId)_\(i).jpg")
            let videoRef   = Storage.storage().reference(withPath: "images/\(postId)_\(i).mp4")
            let previewRef = Storage.storage().reference(withPath: "images/\(postId)_\(i)_preview.jpg")
            
            try? await imageRef.delete()
            try? await videoRef.delete()
            try? await previewRef.delete()
            
            StorageManager.shared.deleteImage(id: "\(postId)_\(i)")
            StorageManager.shared.deleteImage(id: "\(postId)_\(i)_preview")
        }
    }
    
    // MARK: - Загрузка обложек
    
    private func uploadCover(media: MediaKind, postId: String, index: Int) async throws {
        if let image = media.image {
            let ref = Storage.storage().reference(withPath: "images/\(postId)_\(index).jpg")
            let meta = StorageMetadata()
            meta.contentType = "image/jpeg"
            
            let resized = image.resizedForFeed(maxDimension: 1600)
            guard let data = resized.jpegData(compressionQuality: 0.7) else { return }
            
            _ = try await ref.putDataAsync(data, metadata: meta)
            
            StorageManager.shared.saveImage(id: "\(postId)_\(index)", image: resized)
        } else if let videoURL = media.videoURL {
            if let preview = media.videoPreview {
                let previewRef = Storage.storage().reference(
                    withPath: "images/\(postId)_\(index)_preview.jpg"
                )
                let previewMeta = StorageMetadata()
                previewMeta.contentType = "image/jpeg"
                
                if let previewData = preview.jpegData(compressionQuality: 0.4) {
                    _ = try? await previewRef.putDataAsync(previewData, metadata: previewMeta)
                    StorageManager.shared.saveImage(
                        id: "\(postId)_\(index)_preview",
                        image: preview
                    )
                }
            }
            
            let ref = Storage.storage().reference(withPath: "images/\(postId)_\(index).mp4")
            let meta = StorageMetadata()
            meta.contentType = "video/mp4"
            
            if videoURL.isFileURL {
                var needsStop = false
                if videoURL.startAccessingSecurityScopedResource() {
                    needsStop = true
                }
                defer { if needsStop { videoURL.stopAccessingSecurityScopedResource() } }
                _ = try await ref.putFileAsync(from: videoURL, metadata: meta)
            } else {
                let (data, _) = try await URLSession.shared.data(from: videoURL)
                _ = try await ref.putDataAsync(data, metadata: meta)
            }
        }
    }
    
    // MARK: - Новый пост
    
    func uploadPost(
        title: String,
        isArchive: Bool,
        uploadingLanguage: String,
        items: [MediaKind],
        mediaPosition: Int,
        isLocalizing: Bool,
        localizationCount: Int,
        rootId: String,
        isPremiumPost: Bool
    ) async throws -> String {
        let id = try await ArticlesManager.shared.addNewPost(
            title: title,
            text: "",
            isArchive: isArchive,
            uploadingLanguage: uploadingLanguage,
            mediaCount: items.count,
            isShortPost: true,
            mediaPosition: mediaPosition,
            isLocalizing: isLocalizing,
            rootId: rootId,
            isPremiumPost: isPremiumPost
        )
        
        if isLocalizing {
            try await ArticlesManager.shared.setLocalizationCount(for: rootId, count: localizationCount + 1)
        }
        
        for i in 0..<items.count {
            try await uploadCover(media: items[i], postId: id, index: i)
        }
        return id
    }
    
    // MARK: - Обновление поста
    
    func updatePost(
        postId: String,
        title: String,
        isArchive: Bool,
        uploadingLanguage: String,
        items: [MediaKind],
        mediaPosition: Int,
        isPremiumPost: Bool
    ) async throws {
        
        StorageManager.shared.deleteCacheForPost(
            id: postId,
            maxIndex: max(oldMediaCount, items.count)
        )
        await VideoCacheManager.shared.clearPost(id: postId, maxIndex: max(oldMediaCount, items.count))
        
        let maxParallel = 2
        
        func preDeleteIfTypeChanged(index: Int, media: MediaKind) async {
            let jpgRef     = Storage.storage().reference(withPath: "images/\(postId)_\(index).jpg")
            let mp4Ref     = Storage.storage().reference(withPath: "images/\(postId)_\(index).mp4")
            let previewRef = Storage.storage().reference(withPath: "images/\(postId)_\(index)_preview.jpg")
            
            if media.videoURL != nil {
                try? await jpgRef.delete()
                StorageManager.shared.deleteImage(id: "\(postId)_\(index)")
            }
            
            if media.image != nil {
                try? await mp4Ref.delete()
                try? await previewRef.delete()
                StorageManager.shared.deleteImage(id: "\(postId)_\(index)_preview")
            }
        }
        
        try await withThrowingTaskGroup(of: Void.self) { group in
            var nextIndex = 0
                        
            while nextIndex < min(items.count, maxParallel) {
                let i = nextIndex
                group.addTask { [weak self] in
                    guard let self else { return }
                    let media = items[i]
                    await preDeleteIfTypeChanged(index: i, media: media)
                    try await self.uploadCover(media: media, postId: postId, index: i)
                }
                nextIndex += 1
            }
                        
            while let _ = try await group.next() {
                if nextIndex < items.count {
                    let i = nextIndex
                    group.addTask { [weak self] in
                        guard let self else { return }
                        let media = items[i]
                        await preDeleteIfTypeChanged(index: i, media: media)
                        try await self.uploadCover(media: media, postId: postId, index: i)
                    }
                    nextIndex += 1
                }
            }
        }
                
        if oldMediaCount > items.count {
            try await withThrowingTaskGroup(of: Void.self) { group in
                for i in items.count..<oldMediaCount {
                    group.addTask {
                        let imageRef   = Storage.storage().reference(withPath: "images/\(postId)_\(i).jpg")
                        let videoRef   = Storage.storage().reference(withPath: "images/\(postId)_\(i).mp4")
                        let previewRef = Storage.storage().reference(withPath: "images/\(postId)_\(i)_preview.jpg")
                        
                        try? await imageRef.delete()
                        try? await videoRef.delete()
                        try? await previewRef.delete()
                        
                        StorageManager.shared.deleteImage(id: "\(postId)_\(i)")
                        StorageManager.shared.deleteImage(id: "\(postId)_\(i)_preview")
                    }
                }
                while (try await group.next()) != nil {}
            }
        }
        
        try await ArticlesManager.shared.updatePost(
            id: postId,
            title: title,
            text: "",
            isArchive: isArchive,
            uploadingLanguage: uploadingLanguage,
            mediaCount: items.count,
            mediaPosition: mediaPosition,
            isPremiumPost: isPremiumPost
        )
        
        await MainActor.run {
            self.oldMediaCount = items.count
            NotificationCenter.default.post(
                name: .postMediaDidUpdate,
                object: nil,
                userInfo: ["postId": postId, "mediaCount": items.count]
            )
        }
    }
}
