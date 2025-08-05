//
//  CreatedPostsViewModel + enum.swift
//  ReadBox
//
//  Created by Тимофей Юдин on 24.05.2025.
//

import SwiftUI
import FirebaseStorage
import Firebase

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
    
    @Published var user: DBUser? = nil
    
    @Published var id = ""
    
    let vibrationsService = VibrationsService.shared
    
    var description = ""
    var title = ""
    var image: UIImage? = nil
    var text = ""
    var likesCount = 0
    var dateCreated = Date()
    var isEditing = false
    
    var alertText = ""
    
    func getAvatar() {
        DispatchQueue.main.async {
            let storage = Storage.storage()
            let storageRef = storage.reference()
            let islandRef = storageRef.child("avatars/\(self.user?.userId ?? "").jpg")
            
            islandRef.getData(maxSize: 1 * 5012 * 5012) { data, error in
                if let error = error {
                    print(error.localizedDescription)
                } else {
                    withAnimation {
                        self.avatarImage = UIImage(data: data!)
                    }
                }
            }
        }
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
        
        if postsCount == 0 {
            postsCount = user?.postsCount ?? 0
        }
        
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
        description = post.description ?? ""
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
            
            user = nil
        }
        
        Task {
            isLoading = true
            
            try? await loadUser()
            
            getAvatar()
        }
    }
    
    func deletePost(id: String) {
        Task {
            do {
                if let _ = posts.first(where: { $0.id == id})?.isArchive  {
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
            
                let storage = Storage.storage()
                
                let imageRef = storage.reference().child("images/\(id).jpg")
                let videoRef = storage.reference().child("images/\(id).mp4")
                try? await imageRef.delete()
                try? await videoRef.delete()
                
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
            } catch {
                withAnimation {
                    errorText = error.localizedDescription
                    isErrorPopupPresented = true
                    self.id = ""
                }
            }
        }
        
        Task {
            StorageManager.shared.deleteImage(id: id)
            
            let fileReference = Storage.storage().reference().child("images/\(id).jpg")
            let videoReference = Storage.storage().reference().child("images/\(id).mp4")
            
            try? await fileReference.delete()
            try? await videoReference.delete()
        }
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
        
        if post.isArchive ?? true {
            image = UIImage()
        }
        
        if user != nil {
            Task {
                do {
                    isLoadingPopupPresented = true
                    try await getPostToRead(id: post.id)
                    
                    if description == "" {
                        isLoadingPopupPresented = false
                        isReadViewPresented = true
                    } else {
                        isLoadingPopupPresented = false
                        isDescriptionPopupPresented = true
                    }
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
