//
//  CreatedPostsViewModel + enum.swift
//  ReadBox
//
//  Created by Тимофей Юдин on 24.05.2025.
//

import SwiftUI
import FirebaseStorage
import Firebase
import AVFoundation

enum PostOptions {
    case nothing
    case editing
    case toArchive
    case publish
    case delete
}

@MainActor
final class CreatedPostsViewModel: ObservableObject {
    @Published var isErrorPopupPresented = false
    @Published var errorText = ""
    @Published var articlesIndexes: [String] = []
    @Published var posts: [PrePost] = []
    @Published var archivePosts: [PrePost] = []
    @Published var isDescriptionPopupPresented = false
    @Published var isReadViewPresented = false
    @Published var isNewNameAlertPresented = false
    @Published var isSuccessPopupPresented = false
    @Published var isCreateViewPresented = false
    @Published var isArchivePresented = false
    @Published var postsNeedToLoad: [String] = []
    @Published var postOption: PostOptions = .nothing
    @Published var isNewPublicationButtonPresented = false
    @Published var authorNameText = ""
    @Published var isButtonEnabled = false
    @Published var isChannelViewPresented = false
    @Published var descriptionText = ""
    @Published var isSettingViewPresented = false
    @Published var isNeedToReload = false
    @Published var postsCount = 0
    @Published var isLoading = false
    @Published var isLoadingShowing = true
    @Published var isLoadingPopupPresented = false
    @Published var lastPostSnapshot: DocumentSnapshot? = nil
    @Published var lastArchivedPostSnapshot: DocumentSnapshot? = nil
    @Published var isAllLoaded = false
    @Published var isAllArchivedLoaded = false
    @Published var mediaURLs: [URL] = []
    @Published var avatarImage: UIImage? = nil
    @Published var isZoomableImageViewPresented = false
    @Published var isVideoCover = false
    @Published var videoURL: URL? = nil
    @Published var addingMode = 0
    @Published var isConfirmationPopupPresented = false
    @Published var isPostCreateViewPresented = false
    @Published var mediaKind: [MediaKind?] = []
    @Published var isPublicationsLabelVisisble = true
    
    @Published var user: DBUser? = nil
    
    @Published var id = ""
    
    let vibrationsService = VibrationsService.shared

    var title = ""
    var image: UIImage? = nil
    var text = ""
    var likesCount = 0
    var dateCreated = Date()
    var isEditing = false
    var postId = ""
    var mediaCount = 0
    var mediaVersion = 0
    
    var alertText = ""
    
    func getAvatar() {
        DispatchQueue.main.async {
            let storage = Storage.storage()
            let storageRef = storage.reference()
            
            if let userId = self.user?.userId {
                if let image = StorageManager.shared.getImage(id: userId) {
                    withAnimation {
                        self.avatarImage = image
                    }
                } else {
                    let islandRef = storageRef.child("avatars/\(userId).jpg")
                    
                    islandRef.getData(maxSize: 1 * 5012 * 5012) { data, error in
                        if let data, let image = UIImage(data: data) {
                            withAnimation {
                                self.avatarImage = image
                            }
                            StorageManager.shared.saveImage(id: userId, image: image)
                        }
                    }
                }
            }
        }
    }
    
    func clearData() {
        postOption = .nothing
        id = ""
        text = ""
        mediaURLs = []
        mediaKind = []
    }
    
    func isButtonEnable() {
        withAnimation {
            if authorNameText.count > 0 && !isLoading {
                isButtonEnabled = true
            } else {
                isButtonEnabled = false
            }
        }
    }
    
    func getBottomPadding(by id: String) -> CGFloat {
        if isArchivePresented {
            return archivePosts.last?.id == id ? 70 : 0
        } else {
            return posts.last?.id == id ? 70 : 0
        }
    }
    
    func loadUser() async throws {
        let authDataResult = try AuthenticationManager.shared.getAuthenticatedUser()
        let user = try await UserManager.shared.getUser(userId: authDataResult.uid)
        
        postsCount = user?.postsCount ?? 0
        
        self.user = user
    }
    
    func getAuthorIsCheckmarkStatus(id: String) async throws -> Bool {
        try await UserManager.shared.getIsCheckmarkStatus(id: id) ?? false
    }
    
    func changeAuthorName(to name: String, description: String) async throws {
        try await UserManager.shared.changeAuthorName(userId: user?.userId ?? "", to: name, description: description)
    }
    
    func removeCheckmarkStatus() async throws {
        try await UserManager.shared.removeCheckmarkStatus(userId: user?.userId ?? "")
    }
    
    func getPrePost(id: String) async throws -> PrePost {
        try await ArticlesManager.shared.getPrePost(id: id)
    }
    
    func getPostToRead(id: String) async throws {
        let post = try await ArticlesManager.shared.getPostToRead(id: id)
        
        dateCreated = post.dateCreated ?? Date()
        text = post.text ?? ""
        
        if let mediaURLs = post.mediaURLs {
            self.mediaURLs = mediaURLs.map { URL(string: $0)! }
        }
    }
    
    func reload() {
        withAnimation {
            posts = []
            archivePosts = []
            postsCount = 0
            isLoadingShowing = true
            isNewPublicationButtonPresented = false
            isAllLoaded = false
            isAllArchivedLoaded = false
            lastPostSnapshot = nil
            lastArchivedPostSnapshot = nil
            isNeedToReload = false
            
            user = nil
        }
        
        Task {
            isLoading = true
            
            try? await loadUser()
            
            getAvatar()
        }
    }
    
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
    
    func deletePost(id: String) async throws {
        guard let post = isArchivePresented
                ? archivePosts.first(where: { $0.id == id })
                : posts.first(where: { $0.id == id }) else { return }
        
        if let isArchive = post.isArchive, isArchive == false {
            withAnimation {
                postsCount -= 1
            }
            
            try await UserManager.shared.updatePostsCount(
                userId: user?.userId ?? "",
                postsCount: postsCount
            )
        }
        
        let mediaURLs = try await ArticlesManager.shared.getMediaURLs(from: id)
        
        try await ArticlesManager.shared.deletePost(id: id)
        try await UserManager.shared.deleteCreatedPost(id: id)
        
        await deleteAllCovers(postId: id, mediaCount: post.mediaCount ?? 10)
        
        let storage = Storage.storage()
        
        for url in mediaURLs {
            if let path = URLComponents(string: url.absoluteString)?
                .path
                .removingPercentEncoding?
                .replacingOccurrences(of: "/v0/b/\(storage.reference().bucket)/o/", with: "")
                .components(separatedBy: "?")
                .first?
                .replacingOccurrences(of: "%2F", with: "/") {
                
                let ref = storage.reference(withPath: path)
                try? await ref.delete()
                print("🗑 Удалено: \(path)")
            }
        }
        
        withAnimation {
            if isArchivePresented {
                archivePosts.removeAll { $0.id == id }
            } else {
                posts.removeAll { $0.id == id }
            }
        }
        
        self.id = ""
        
        StorageManager.shared.deleteImage(id: id)
        
        let fileReference = Storage.storage().reference().child("images/\(id).jpg")
        let videoReference = Storage.storage().reference().child("images/\(id).mp4")
        
        try? await fileReference.delete()
        try? await videoReference.delete()
    }
    
    func updateIsArchiveStatus() {
       Task {
            do {
                try await ArticlesManager.shared.updateIsArchiveStatus(id: id, isArchive: !isArchivePresented)
                
                withAnimation {
                    postsCount += isArchivePresented ? 1 : -1
                }
                
                try await UserManager.shared.updatePostsCount(userId: user?.userId ?? "", postsCount: postsCount)
                
            } catch {
                withAnimation {
                    errorText = error.localizedDescription
                    isErrorPopupPresented = true
                }
                
                return
            }
            
            withAnimation {
                if isArchivePresented {
                    posts.insert(archivePosts.filter { $0.id == id }[0], at: 0)
                    posts[0].isArchive?.toggle()
                    archivePosts.removeAll { $0.id == id }
                } else {
                    archivePosts.insert(posts.filter { $0.id == id }[0], at: 0)
                    archivePosts[0].isArchive?.toggle()
                    posts.removeAll { $0.id == id }
                }
            }
           
           id = ""
        }
    }
    
    func getPosts() async throws {
        guard !isAllLoaded else { return }
        
        let (posts, lastDocument) = try await ArticlesManager.shared.getCreatedPosts(
            userId: user?.userId ?? "",
            startAfter: lastPostSnapshot
        )
        
        if posts.isEmpty {
            isAllLoaded = true
            return
        }
        
        
        posts.forEach { post in
            if let post {
                withAnimation {
                    self.posts.append(post)
                }
            }
        }
        
        lastPostSnapshot = lastDocument
    }
    
    func getArchivedPost() async throws {
        guard !isAllArchivedLoaded else { return }
        
        let (posts, lastDocument) = try await ArticlesManager.shared.getCreatedPosts(
            userId: user?.userId ?? "",
            startAfter: lastArchivedPostSnapshot,
            isArchive: true
        )
        
        if posts.isEmpty {
            isAllArchivedLoaded = true
            return
        }
        
        posts.forEach { post in
            if let post {
                self.archivePosts.append(post)
            }
        }
        
        lastArchivedPostSnapshot = lastDocument
    }
    
    func tapGestureHandler(on post: PrePost) {
        title = post.title ?? NSLocalizedString("notFoundLabel", comment: "")
        image = StorageManager.shared.getImage(id: post.id) ?? UIImage()
        likesCount = post.likesCount ?? 0
        id = post.id
        mediaCount = post.mediaCount ?? 1
        mediaVersion = post.mediaVersion ?? 1
        
        if post.isArchive ?? true {
            image = UIImage()
        }
        
        if user != nil {
            Task {
                do {
                    isLoadingPopupPresented = true
                    try await getPostToRead(id: post.id)
                    
                    isLoadingPopupPresented = false
                    isReadViewPresented = true
                } catch {
                    withAnimation {
                        errorText = error.localizedDescription
                        isErrorPopupPresented = true
                    }
                }
                
                isLoadingPopupPresented = false
            }
        } else {
            withAnimation {
                errorText = NSLocalizedString("loadDataErrorText", comment: "")
                isErrorPopupPresented = true
            }
        }
    }
    
}

extension CreatedPostsViewModel {

    @MainActor
    func getMedia(mediaCount: Int, postId: String, ignoreCache: Bool = false) async {
        let storage = Storage.storage()
        let root = storage.reference().child("images")

        mediaKind = Array(repeating: nil, count: mediaCount)

        for i in 0..<mediaCount {
            let imageCacheId   = "\(postId)_\(i)"
            let previewCacheId = "\(postId)_\(i)_preview"
            
            if ignoreCache {
                StorageManager.shared.deleteImage(id: imageCacheId)
                StorageManager.shared.deleteImage(id: previewCacheId)
            } else {
                if let cached = StorageManager.shared.getImage(id: imageCacheId) {
                    mediaKind[i] = MediaKind(image: cached)
                    continue
                }
            }

            let jpgRef = root.child("\(postId)_\(i).jpg")
            do {
                let data = try await jpgRef.dataAsync(maxSize: 1 * 5012 * 5012)
                if let ui = UIImage(data: data) {
                    withAnimation { mediaKind[i] = MediaKind(image: ui) }
                    StorageManager.shared.saveImage(id: imageCacheId, image: ui)
                    continue
                }
            } catch {
                // object-not-found — норм, идём к mp4
            }
            
            let mp4Ref = root.child("\(postId)_\(i).mp4")
            do {
                let url = try await mp4Ref.downloadURLAsync()
                
                var preview: UIImage? = StorageManager.shared.getImage(id: previewCacheId)
                
                if preview == nil {
                    do {
                        let data = try await root
                            .child("\(postId)_\(i)_preview.jpg")
                            .dataAsync(maxSize: 512 * 1024)
                        if let ui = UIImage(data: data) {
                            preview = ui
                            StorageManager.shared.saveImage(id: previewCacheId, image: ui)
                        }
                    } catch {
                        if let thumb = try? await makeVideoThumbnail(url: url) {
                            preview = thumb
                            StorageManager.shared.saveImage(id: previewCacheId, image: thumb)
                        }
                    }
                }
                
                withAnimation {
                    mediaKind[i] = MediaKind(videoURL: url, videoPreview: preview)
                }
                
            } catch {
                // нет ни jpg, ни mp4 — оставляем nil, потом fallback
            }
        }

        if mediaKind.compactMap({ $0 }).isEmpty {
            await fetchFallbackCover(postId: postId)
        }
    }

    // MARK: - Helpers

    private func makeVideoThumbnail(url: URL) async throws -> UIImage? {
        let asset = AVURLAsset(url: url)
        let _ = try await asset.load(.duration)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        let time = CMTime(seconds: 0.05, preferredTimescale: 600)
        let cg = try? generator.copyCGImage(at: time, actualTime: nil)
        return cg.map { UIImage(cgImage: $0) }
    }

    @MainActor
    private func fetchFallbackCover(postId: String) async {
        let storage = Storage.storage()
        let storageRef = storage.reference()

        if let cached = StorageManager.shared.getImage(id: postId) {
            withAnimation { mediaKind = [MediaKind(image: cached)] }
            return
        }

        do {
            let data = try await storageRef.child("images/\(postId).jpg").dataAsync(maxSize: 1 * 5012 * 5012)
            if let ui = UIImage(data: data) {
                withAnimation {
                    mediaKind = [MediaKind(image: ui)]
                    StorageManager.shared.saveImage(id: postId, image: ui)
                }
                return
            }
        } catch { /* ignore */ }

        do {
            let url = try await storageRef.child("images/\(postId).mp4").downloadURLAsync()
            let thumb = try await makeVideoThumbnail(url: url)
            withAnimation { mediaKind = [MediaKind(videoURL: url, videoPreview: thumb)] }
        } catch { /* nothing */ }
    }
    
    private func isNotFound(_ error: Error) -> Bool {
        let ns = error as NSError
        return ns.domain == StorageErrorDomain
            && StorageErrorCode(rawValue: ns.code) == .objectNotFound
    }
}
