//
//  FeedViewModel.swift
//  ReadBox
//
//  Created by Тимофей Юдин on 24.05.2025.
//

import SwiftUI
import FirebaseFirestore

@MainActor
final class FeedViewModel: ObservableObject {
    @Published var topArticlesIndexes: [String] = []
    @Published var topArticles: [PrePost] = []
    @Published var articles: [PrePost] = []
    @Published var errorText = ""
    @Published var isErrorPopupPresented = false
    @Published var isDescriptionPopupPresented = false
    @Published var isReadViewPresented = false
    @Published var fromIndex = -1
    @Published var maxIndex = ""
    @Published var likedPosts: [String] = []
    @Published var primaryLanguage = ""
    @Published var loadCount = 0
    @Published var authorsNames: [String: String] = [:]
    @Published var authorsCheckmarks: [String: Bool] = [:]
    @Published var isChannelViewPresented = false
    @Published var postToView: PrePost? = nil
    @Published var isLoading = true
    @Published var height: CGFloat = 0.0
    @Published var views: [String] = []
    @Published var isLoadingPopupPresented = false
    @Published var isLoadingShowing = true
    @Published var postToRead: PostToRead? = nil
    @Published var relevantVersion: AppVersion? = nil
    @Published var isVersionPopupViewPresented = false
    @Published var isBlur = false
    @Published var lastDocument: DocumentSnapshot? = nil
    
    @Published var user: DBUser? = nil
    
    var description = ""
    var title = ""
    var image = UIImage()
    var dateCreated = Date()
    var text = ""
    var likesCount = 0
    var id = ""
    var userId = ""
    var authorId = ""
    var isArchive = false
    
    private var db = Firestore.firestore()
    
    func getViews() {
        views = StorageManager.shared.getViews()
    }
    
    func saveViews() {
        StorageManager.shared.save(views: views)
    }
    
    func loadUser() async throws {
        let authDataResult = try AuthenticationManager.shared.getAuthenticatedUser()
        let user = try await UserManager.shared.getUser(userId: authDataResult.uid)
        
        self.user = user
    }
    
    func getRelevantVersion() {
        Task {
            do {
                relevantVersion = try? await VersionManager.shared.getRelevantVersion()
                
                if let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String, let relevantVersion {
                    
                    if relevantVersion.appVersion != currentVersion {
                        isVersionPopupViewPresented = true
                        
                        if let isCritical = relevantVersion.isCritical {
                            withAnimation {
                                isBlur = isCritical ? true : false
                            }
                        }
                    } else {
                        withAnimation {
                            isBlur = false
                        }
                    }
                    
                }
                
            }
        }
    }
    
    func refresh() {
        primaryLanguage = StorageManager.shared.getLanguage()
        
        Task {
            isLoading = true
        }
        
        withAnimation {
            isLoadingShowing = true
            
            topArticlesIndexes = []
            topArticles = []
            articles = []
            authorsNames = [:]
            authorsCheckmarks = [:]
            user = nil
        }
        
        Task {
            do {
                try await getTopIndexes()
                
                return
            } catch {
                withAnimation {
                    errorText = error.localizedDescription
                }
            }
            
            isErrorPopupPresented = true
        }
        
        Task {
            try? await loadUser()
        }
    }
    
    func getAuthorName(id: String) async throws -> String {
        try await UserManager.shared.getAuthorName(id: id) ?? ""
    }
    
    func getAuthorIsCheckmarkStatus(id: String) async throws -> Bool {
        try await UserManager.shared.getIsCheckmarkStatus(id: id) ?? false
    }
    
    func getMaxIndex() async throws {
        maxIndex = try await ArticlesManager.shared.getMaxIndex() ?? "10"
    }
    
    func getArticle(id: String) async throws -> PrePost {
        try await ArticlesManager.shared.getPrePost(id: id)
    }
    
    func getOriginalLanguageOfArticle(id: String) async throws -> String {
        try await ArticlesManager.shared.getOriginalLanguageOfArticle(id: id)
    }
    
    func getTopArticles() async throws {
        topArticles = []
        
        for index in topArticlesIndexes {
            if index != "" {
                do {
                    let isArchive = try await ArticlesManager.shared.getIsArchive(of: index)
                
                    if isArchive {
                        withAnimation {
                            topArticles.append(
                                PrePost(
                                    id: index,
                                    title: NSLocalizedString("archiveArticleLabel", comment: ""),
                                    authorId: "",
                                    viewsCount: 0,
                                    likesCount: 0
                                )
                            )
                        }
                    } else {
                        let article = try await getArticle(id: index)
                        
                        withAnimation {
                            topArticles.append(article)
                        }
                        
                    }
                } catch {
                    withAnimation {
                        
                        topArticles.append(
                            PrePost(
                                id: index,
                                title: NSLocalizedString("articleErrorLabel", comment: ""),
                                authorId: "",
                                viewsCount: 0,
                                likesCount: 0
                            )
                        )
                        
                    }
                }
            } else {
                withAnimation {
                    topArticles.append(
                        PrePost(
                            id: index,
                            title: NSLocalizedString("articleErrorLabel", comment: ""),
                            authorId: "",
                            viewsCount: 0,
                            likesCount: 0
                        )
                    )
                }
            }
        }
        
    }
    
    func getTopIndexes() async throws {
        topArticlesIndexes = try await ArticlesManager.shared.getTopArticlesIndexes() ?? ["0"]
    }
    
    func getPostToRead(id: String) async throws {
        let post = try await ArticlesManager.shared.getPostToRead(id: id)
        
        dateCreated = post.dateCreated ?? Date()
        text = post.text ?? NSLocalizedString("notFoundLabel", comment: "")
        description = post.description ?? NSLocalizedString("notFoundLabel", comment: "")
    }
    
    func getArticles() async throws {
        Task {
            var query = db.collection("articles")
                .whereField("id", notIn: topArticlesIndexes)
                .whereField("is_archive", isEqualTo: false)
                .whereField("original_language", isEqualTo: StorageManager.shared.getLanguage())
                .order(by: "date_created", descending: true)
                .limit(to: 20)
            
            if let last = lastDocument {
                query = query.start(afterDocument: last)
            }
            
            do {
                let snapshot = try await query.getDocuments()
                let newPosts = snapshot.documents.compactMap { PrePost(document: $0) }
                self.articles.append(contentsOf: newPosts)
                self.lastDocument = snapshot.documents.count == 20 ? snapshot.documents.last : nil
            } catch {
                withAnimation {
                    errorText = error.localizedDescription
                    isErrorPopupPresented = true
                }
            }
            
            withAnimation {
                isLoading = false
                isLoadingShowing = false
            }
        }
    }
    
    func onPostAppearing(post: PrePost) {
        if !authorsNames.keys.contains(post.authorId ?? "") {
            Task {
                do {
                    let authorName = try await getAuthorName(id: post.authorId ?? "")
                    let isCheckmark = try await getAuthorIsCheckmarkStatus(id: post.authorId ?? "")
                    
                    withAnimation {
                        authorsNames[post.authorId ?? ""] = authorName
                        authorsCheckmarks[post.authorId ?? ""] = isCheckmark
                    }
                } catch {
                    //                                                    withAnimation {
                    //                                                        viewModel.errorText = error.localizedDescription
                    //                                                        viewModel.isErrorPopupPresented = true
                    //                                                    }
                }
            }
        }
        
        if articles.last == post && lastDocument != nil {
            Task {
                do {
                    try await getArticles()
                } catch {
                    print("ERROR TO FETCH MORE POSTS: \(error.localizedDescription)")
                }
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
        
        if post.isArchive ?? true {
            image = UIImage()
        }
        
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
                    try await getPostToRead(id: post.id)
                    
                    isLoadingPopupPresented = false
                    
                    if description == "" {
                        isReadViewPresented = true
                    } else {
                        isDescriptionPopupPresented = true
                    }
                    
                    if user?.userId ?? "" != post.authorId {
                        if !views.contains(id) {
                            Task {
                                do {
                                    try await ArticlesManager.shared.updateViews(at: id)
                                    
                                    views.append(id)
                                    saveViews()
                                }
                            }
                        }
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
