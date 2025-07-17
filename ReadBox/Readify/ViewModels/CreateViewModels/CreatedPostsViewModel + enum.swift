//
//  CreatedPostsViewModel + enum.swift
//  ReadBox
//
//  Created by Тимофей Юдин on 24.05.2025.
//

import SwiftUI
import FirebaseStorage

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
    @Published var isLoading = true
    @Published var postOption: PostOptions = .nothing
    @Published var likedPosts: [String] = []
    @Published var isNewPublicationButtonPresented = true
    @Published var authorNameText = ""
    @Published var isButtonEnabled = false
    @Published var isChannelViewPresented = false
    @Published var descriptionText = ""
    @Published var isSettingViewPresented = false
    @Published var isNeedToReload = false
    @Published var postsCount = 0
    @Published var isLoadingShowing = true
    @Published var isLoadingPopupPresented = false
    
    @Published var user: DBUser? = nil
    
    @Published var id = ""
    
    var description = ""
    var title = ""
    var image: UIImage? = nil
    var text = ""
    var likesCount = 0
    var dateCreated = Date()
    var isEditing = false
    
    var alertText = ""
    
    func isButtonEnable() {
        withAnimation {
            if authorNameText.count > 0 {
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
    }
    
    func getIndexes() async throws {
        let indexes = try await UserManager.shared.getAuthorsCreatedPosts(id: user?.userId ?? "") ?? []
        articlesIndexes = indexes.reversed()
    }
    
    func reload() {
        withAnimation {
            posts = []
            archivePosts = []
            articlesIndexes = []
            postsCount = 0
            isLoadingShowing = true
            
            user = nil
        }
        
        Task {
            isLoading = true
            
            try? await loadUser()
        }
    }
    
    func deletePost(id: String) {
        Task {
            do {
                try await ArticlesManager.shared.deletePost(id: id)
                try await UserManager.shared.deleteCreatedPost(id: id)
                
                if !(posts.first { $0.id == id }?.isArchive ?? true)  {
                    withAnimation {
                        postsCount -= 1
                    }
                    
                    try await UserManager.shared.updatePostsCount(
                        userId: user?.userId ?? "",
                        postsCount: postsCount
                    )
                }
            } catch {
                withAnimation {
                    errorText = error.localizedDescription
                    isErrorPopupPresented = true
                }
            }
        }
        
        Task {
            StorageManager.shared.deleteImage(id: id)
            
            let fileReference = Storage.storage().reference().child("images/\(id).jpg")
            
            try? await fileReference.delete()
        }
        
        withAnimation {
            if isArchivePresented {
                archivePosts.removeAll { $0.id == id }
            } else {
                posts.removeAll { $0.id == id }
            }
        }
        
        self.id = ""
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
        
        var indexes: [String] = []
        
        var count = 0
        
        for index in postsNeedToLoad {
            if count < 20 {
                indexes.append(index)
                count += 1
            }
        }
        
        for index in indexes {
            do {
                let article = try await getPrePost(id: index)
                
                withAnimation {
                    if article.isArchive ?? true {
                        archivePosts.append(article)
                    } else {
                        posts.append(article)
                    }
                
                    isLoadingShowing = false
                    postsNeedToLoad.removeAll { $0 == index }
                }
            } catch {
                postsNeedToLoad.removeAll { $0 == index }
                
                withAnimation {
                    errorText = NSLocalizedString("someArticlesNotFoundLabel", comment: "")
                    isErrorPopupPresented = true
                }
            }
        }
                
        withAnimation {
            isLoading = false
            isLoadingShowing = false
        }
            
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
            if likedPosts == [] {
                likedPosts = user?.likedPosts ?? []
            }
            
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
