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
    @Published var primaryLanguage = ""
    @Published var authorsInfo: [String: PostAuthorInfo] = [:]
    @Published var isChannelViewPresented = false
    @Published var isLoading = true
    @Published var isLoadingPopupPresented = false
    @Published var isLoadingShowing = true
    @Published var lastDocument: DocumentSnapshot? = nil
    @Published var isZoomableImageViewPresented = false
    @Published var zoomableImage: UIImage? = nil
    @Published var shouldOpenCommentsOnRead = false

    @Published var isLargeHeaderVisible = true
    @Published var authorId = ""

    @Published var user: DBUser? = nil

    var title = ""
    var dateCreated = Date()
    var text = ""
    var likesCount = 0
    var id = ""
    var isArchive = false
    var mediaCount = 0
    var mediaVersion = 0
    var mediaPosition = 0
    var articleLanguage = ""
    var isPremiumPost = false
    var isLocalizedVersion = false
    var rootId = ""

    private var db = Firestore.firestore()

    func loadUser() async throws {
        let authDataResult = try AuthenticationManager.shared.getAuthenticatedUser()
        let user = try await UserManager.shared.getUser(userId: authDataResult.uid)

        self.user = user
    }

    func refresh() {
        primaryLanguage = StorageManager.shared.getLanguage() ?? "en"

        Task {
            isLoading = true
        }

        withAnimation {
            isLoadingShowing = true

            topArticlesIndexes = []
            topArticles = []
            articles = []
            authorsInfo = [:]
            lastDocument = nil
            user = nil
        }

        Task {
            try? await loadUser()
        }
    }

    func getArticle(id: String) async throws -> PrePost {
        try await ArticlesManager.shared.getPrePost(id: id)
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
                                    likesCount: 0,
                                    isShortPost: false,
                                    mediaCount: 0,
                                    mediaVersion: 2,
                                    mediaPosition: 0,
                                    localizationCount: 0,
                                    isLocalizedVersion: false
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
                                likesCount: 0,
                                isShortPost: false,
                                mediaCount: 0,
                                mediaVersion: 2,
                                mediaPosition: 0,
                                localizationCount: 0,
                                isLocalizedVersion: false
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
                            likesCount: 0,
                            isShortPost: false,
                            mediaCount: 0,
                            mediaVersion: 2,
                            mediaPosition: 0,
                            localizationCount: 0,
                            isLocalizedVersion: false
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
    }

    func getArticles() async throws {
        var query = db.collection("articles")
            .whereField("id", notIn: topArticlesIndexes)
            .whereField("is_archive", isEqualTo: false)
            .whereField("original_language", isEqualTo: primaryLanguage)
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
                self.isLoadingShowing = false
            }
        } catch {
            withAnimation {
                self.errorText = error.localizedDescription
                self.isErrorPopupPresented = true
                self.isLoading = false
                self.isLoadingShowing = false
            }
            throw error
        }
    }

    func onPostAppearing(post: PrePost) {
        if !authorsInfo.keys.contains(post.authorId ?? "") {
            Task {
                if let info = try? await UserManager.shared.getPostAuthorInfo(for: post.authorId ?? "") {

                    withAnimation {
                        authorsInfo[post.authorId ?? ""] = info
                    }
                }
            }
        }

        if articles.last == post && lastDocument != nil {
            Task {
                try? await getArticles()
            }
        }

        if user?.userId ?? "" != post.authorId {
            Task {
                do {
                    try await ArticlesManager.shared.updateViews(at: post.id)
                }
            }
        }
    }

    func tapGestureHandler(on post: PrePost, openComments: Bool = false) {
        title = post.title ?? NSLocalizedString("notFoundLabel", comment: "")
        likesCount = post.likesCount ?? 0
        id = post.id
        authorId = post.authorId ?? ""
        isArchive = post.isArchive ?? true
        mediaCount = post.mediaCount ?? 1
        mediaVersion = post.mediaVersion ?? 1
        mediaPosition = post.mediaPosition ?? 0
        articleLanguage = post.originalLanguage ?? ""
        isPremiumPost = post.isPremiumPost ?? false
        isLocalizedVersion = post.isLocalizedVersion ?? false
        rootId = post.rootId ?? ""

        guard user != nil else {
            withAnimation {
                errorText = NSLocalizedString("loadDataErrorText", comment: "")
                isErrorPopupPresented = true
            }
            return
        }

        shouldOpenCommentsOnRead = openComments

        isLoadingPopupPresented = true

        Task {
            do {
                try await getPostToRead(id: post.id)

                await MainActor.run {
                    self.isLoadingPopupPresented = false
                    withAnimation {
                        self.isReadViewPresented = true
                    }
                }

            } catch {
                await MainActor.run {
                    self.isLoadingPopupPresented = false
                    withAnimation {
                        self.errorText = error.localizedDescription
                        self.isErrorPopupPresented = true
                    }
                }
            }
        }
    }
}
