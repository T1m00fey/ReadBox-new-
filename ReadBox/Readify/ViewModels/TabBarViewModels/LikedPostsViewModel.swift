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
    @Published var authorsInfo: [String: PostAuthorInfo] = [:]
    @Published var indexesNeedToLoad: [String] = []
    @Published var isLoading = true
    @Published var isChannelViewPresented = false
    @Published var isNeedToReload = false
    @Published var isLoadingPopupPresented = false
    @Published var isLoadingShowed = true
    @Published var isZoomableViewPresented = false
    @Published var zoomableImage: UIImage? = nil
    @Published var authorId = ""
    @Published var isLargeHeaderVisible = true
    
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
    var mediaPosition = 0
    
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
            authorsInfo = [:]
        }
        
        Task {
            try? await loadUser()
        }
    }

    private func chunked<T>(_ array: [T], size: Int) -> [[T]] {
        guard size > 0 else { return [] }
        return stride(from: 0, to: array.count, by: size).map {
            Array(array[$0..<min($0 + size, array.count)])
        }
    }

    func getArticles() async throws {
        guard !indexesNeedToLoad.isEmpty else {
            withAnimation {
                self.articles = []
                self.isLoading = false
                self.isLoadingShowed = false
            }
            return
        }

        let chunks = chunked(indexesNeedToLoad, size: 30)

        do {
            var all: [PrePost] = []

            for ids in chunks {
                let snapshot = try await db.collection("articles")
                    .whereField("id", in: ids)
                    .whereField("is_archive", isEqualTo: false)
                    .getDocuments()

                let posts = snapshot.documents.compactMap { PrePost(document: $0) }
                all.append(contentsOf: posts)
            }

            let order: [String: Int] = Dictionary(
                uniqueKeysWithValues: indexesNeedToLoad.enumerated().map { ($0.element, $0.offset) }
            )

            all.sort { (a: PrePost, b: PrePost) -> Bool in
                let ia = order[a.id] ?? Int.max
                let ib = order[b.id] ?? Int.max
                return ia < ib
            }

            withAnimation {
                self.articles = all
                self.isLoading = false
                self.isLoadingShowed = false
                self.lastDocument = nil
            }
        } catch {
            withAnimation {
                self.errorText = error.localizedDescription
                self.isErrorPopupPresented = true
                self.isLoading = false
                self.isLoadingShowed = false
            }
        }
    }

    func onPostAppearing(_ post: PrePost) {
        if !authorsInfo.keys.contains(post.authorId ?? "") && post.authorId != nil {
            Task {
                do {
                    let info = try await UserManager.shared.getPostAuthorInfo(for: post.authorId ?? "")
                    
                    withAnimation {
                        authorsInfo[post.authorId ?? ""] = info
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
        mediaPosition = post.mediaPosition ?? 0
        
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
