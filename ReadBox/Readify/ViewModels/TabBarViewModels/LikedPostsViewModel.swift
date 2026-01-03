//
//  LikedPostsViewModel.swift
//  ReadBox
//
//  Created by Тимофей Юдин on 24.05.2025.
//

import SwiftUI
import FirebaseFirestore

@MainActor
final class LikedPostsViewModel: ObservableObject {
    @Published var isReadViewPresented = false
    @Published var articles: [PrePost] = []
    @Published var errorText = ""
    @Published var isErrorPopupPresented = false
    @Published var isDescriptionPopupPresented = false
    @Published var user: DBUser? = nil
    @Published var likedPosts: [String] = []
    @Published var fromIndex = ""
    @Published var authorsNames: [String: String] = [:]
    @Published var authorsCheckmarks: [String: Bool] = [:]
    @Published var indexesNeedToLoad: [String] = []
    @Published var isLoading = true
    @Published var isChannelViewPresented = false
    @Published var isNeedToReload = false
    @Published var isLoadingPopupPresented = false
    @Published var isLoadingShowed = true
    @Published var isZoomableViewPresented = false
    @Published var zoomableImage: UIImage? = nil
    @Published var authorId = ""
    
    @Published var lastDocument: DocumentSnapshot? = nil
    
    var title = ""
    var image = UIImage()
    var dateCreated = Date()
    var text = ""
    var likesCount = 0
    var id = ""
    var userId = ""
    var isArchive = false
    var mediaCount = 0
    var mediaVersion = 0
    
    private var db = Firestore.firestore()
    
    func getPostToRead(id: String) {
        Task {
            do {
                let post = try await ArticlesManager.shared.getPostToRead(id: id)
                
                dateCreated = post.dateCreated ?? Date()
                text = post.text ?? NSLocalizedString("notFoundLabel", comment: "")
            } catch {
                dateCreated = Date()
                text = ""
            }
            
            isLoadingPopupPresented = false
            isReadViewPresented = true
        }
    }
    
    func getPrePost(id: String) async throws -> PrePost {
        try await ArticlesManager.shared.getPrePost(id: id)
    }
    
    func getAuthorName(id: String) async throws -> String {
        try await UserManager.shared.getUser(userId: id)?.name ?? ""
    }
    
    func getAuthorIsCheckmarkStatus(id: String) async throws -> Bool {
        try await UserManager.shared.getUser(userId: id)?.isCheckmark ?? false
    }
    
    func loadUser() async throws {
        let authDataResult = try AuthenticationManager.shared.getAuthenticatedUser()
        let user = try await UserManager.shared.getUser(userId: authDataResult.uid)
        
        self.user = user
    }
    
    func reload() {
        withAnimation {
            isLoading = true
            isLoadingShowed = true
        }
        
        
        withAnimation {
            likedPosts = []
            articles = []
            user = nil
            authorsNames = [:]
            authorsCheckmarks = [:]
        }
        
        Task {
            try? await loadUser()
        }
    }
    
    func getArticles() async throws {
        var query = db.collection("articles")
            .whereField("id", in: indexesNeedToLoad)
            .whereField("is_archive", isEqualTo: false)
            .order(by: "date_created", descending: true)
            .limit(to: 20)
        
        if let last = lastDocument {
            query = query.start(afterDocument: last)
        }
        
        do {
            let snapshot = try await query.getDocuments()
            let newPosts = snapshot.documents.compactMap { PrePost(document: $0) }
            
            withAnimation {
                self.articles.append(contentsOf: newPosts)
                self.lastDocument = snapshot.documents.count == 20 ? snapshot.documents.last : nil
                self.isLoading = false
                self.isLoadingShowed = false
            }
        } catch {
            withAnimation {
                errorText = error.localizedDescription
                self.isErrorPopupPresented = true
                self.isLoading = false
                self.isLoadingShowed = false
            }
        }
    }
    
    func onPostAppearing(_ post: PrePost) {
        if !authorsNames.keys.contains(post.authorId ?? "") && post.authorId != nil {
            Task {
                do {
                    let authorName = try await getAuthorName(id: post.authorId ?? "")
                    let isCheckmark = try await getAuthorIsCheckmarkStatus(id: post.authorId ?? "")
                    
                    withAnimation {
                        authorsNames[post.authorId ?? ""] = authorName
                        authorsCheckmarks[post.authorId ?? ""] = isCheckmark
                    }
                } catch {
//                                            withAnimation {
//                                                viewModel.errorText = error.localizedDescription
//                                                viewModel.isErrorPopupPresented = true
//                                            }
                }
            }
        }
        
        if post == articles.last && lastDocument != nil {
            Task {
                try? await getArticles()
            }
        }
    }
    
    func tapGestureHandler(on post: PrePost) {
        title = post.title ?? NSLocalizedString("notFoundLabel", comment: "")
        image = StorageManager.shared.getImage(id: post.id) ?? UIImage()
        likesCount = post.likesCount ?? 0
        id = post.id
        authorId = post.authorId ?? ""
        isArchive = post.isArchive ?? true
        mediaCount = post.mediaCount ?? 1
        mediaVersion = post.mediaVersion ?? 1
        
        if user != nil {
            if likedPosts == [] {
                likedPosts = user?.likedPosts ?? []
            }
            
            if userId == "" {
                userId = user?.userId ?? ""
            }
            
            Task {
                do {
                    isLoadingPopupPresented = true
                    getPostToRead(id: post.id)
                    
                    if post.isArchive ?? true {
                        image = UIImage()
                        text = ""
                    }
                    
                    isLoadingPopupPresented = false
                    isReadViewPresented = true
                }
            }
        } else {
            withAnimation {
                errorText = NSLocalizedString("loadDataErrorText", comment: "")
                isErrorPopupPresented = true
            }
        }
        
        isLoadingPopupPresented = false
    }
}
