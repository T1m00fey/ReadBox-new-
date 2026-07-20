//
//  ChannelViewModel.swift
//  ReadBox
//
//  Created by Тимофей Юдин on 24.05.2025.
//

import SwiftUI
import Firebase

enum ChannelPostsSection: Int, CaseIterable {
    case all
    case articles
    case replies
    case localized

    var title: String {
        switch self {
        case .all:
            NSLocalizedString("publicationsLabel", comment: "")
        case .articles:
            NSLocalizedString("articlesLabel", comment: "")
        case .replies:
            NSLocalizedString("repliesLabel", comment: "")
        case .localized:
            NSLocalizedString("localizedPostsLabel", comment: "")
        }
    }
}

@MainActor
final class ChannelViewModel: ObservableObject {
    @Published var postsNeedToLoad: [String] = []
    @Published var isLoading = true
    @Published var posts: [PrePost] = []
    @Published var allPosts: [PrePost] = []
    @Published var replies: [Comment] = []
    @Published var replyAuthorsInfo: [String: PostAuthorInfo] = [:]
    @Published var errorText = ""
    @Published var isErrorPopupPresented = false
    @Published var postOption = PostOptions.nothing
    @Published var id = ""
    @Published var isReadViewPresented = false
    @Published var subscribersCount = 0
    @Published var authorDescription = ""
    @Published var isAuthorInfoLoading = true
    @Published var isSubscribed: Bool? = nil
    @Published var postsCount = 0
    @Published var authorDateCreated: Date? = nil
    @Published var isLoadingPopupPresented = false
    @Published var isLoadingShowing = true
    @Published var isAllLoading = false
    @Published var lastDocument: DocumentSnapshot? = nil
    @Published var avatarImage: UIImage? = nil
    @Published var authorId = ""
    @Published var isZoomableImageViewPresented = false
    @Published var zoomableImage: UIImage? = nil
    @Published var postToView: PrePost? = nil
    @Published var postToRead: PostToRead? = nil
    @Published var commentToRead: Comment? = nil
    @Published var readAuthorId = ""
    @Published var readAuthorName = ""
    @Published var readAuthorIsCheckmark = false
    @Published var readAuthorAvatarVersion = 0
    @Published var readArticleLanguage = ""
    @Published var readIsPremiumPost = false
    @Published var readIsLocalizedVersion = false
    @Published var readRootId = ""
    @Published var readReplyAuthorName: String? = nil
    @Published var readReplyRootPostId: String? = nil
    @Published var shouldOpenCommentsOnRead = false
    @Published var isDataLoaded = false
    @Published var isSubscribeLoading = false
    @Published var pushRoute: NotificationPushRoute? = nil
    @Published var isNotificationPopupPresented = false
    @Published var isPublicationsLabelVisible = true
    @Published var primaryLanguage = "en"
    @Published var currentSection: ChannelPostsSection = .all
    @Published var isRepliesLoading = false

    func updatePrimaryLanguage(user: DBUser?) {
        let fallbackLanguage = Locale.preferredLanguages.first?.components(separatedBy: "-").first == "ru"
        ? "ru"
        : "en"

        let userLanguage = user?.originalLanguage?.trimmingCharacters(in: .whitespacesAndNewlines)

        primaryLanguage = (userLanguage?.isEmpty == false ? userLanguage : nil) ?? fallbackLanguage
    }

    func isSubscribed(_ user: DBUser?, on author: String) -> Bool? {
        if user?.userId == author {
            return nil
        } else {
            return user?.subscribes?.contains(author) ?? nil
        }
    }

    func un_subscribeUser(on id: String, isNeedToSubscribe: Bool) async throws {
        try await UserManager.shared.un_subscribeUser(on: id, isNeedToSubscribe: isNeedToSubscribe)
    }

    func getSubscribersCount(authorId: String) async throws {
        subscribersCount = try await UserManager.shared.getSubscribersCount(authorId: authorId)
    }

    func getPostsCount(authorId: String) async throws {
        postsCount = try await UserManager.shared.getPostsCount(authorId: authorId)
    }

    func loadAuthorInfo(authorId: String) async throws {
        isAuthorInfoLoading = true

        let author = try await UserManager.shared.getUser(userId: authorId)

        authorDescription = author?.authorDescription ?? ""
        subscribersCount = author?.subscribersCount ?? 0
        postsCount = author?.postsCount ?? 0
        authorDateCreated = author?.dateCreated
        isAuthorInfoLoading = false
    }

    func getAuthorDescription(id: String) async throws {
        authorDescription = try await UserManager.shared.getAuthorDescription(id: id)
    }

    func loadPosts(by authorId: String) async throws {
        guard !isAllLoading else { return }

        let (posts, lastDocument) = try await ArticlesManager.shared.getCreatedPosts(
            userId: authorId,
            startAfter: lastDocument
        )

        if posts.isEmpty {
            isAllLoading = true
            withAnimation {
                isLoading = false
                isLoadingShowing = false
            }

            return
        }

        let newPosts = posts.compactMap { $0 }

        withAnimation {
            allPosts.append(contentsOf: newPosts)
            self.posts = localizedPosts(from: allPosts)
            isLoadingShowing = false
        }

        self.lastDocument = lastDocument

        withAnimation {
            isLoading = false
        }
    }

    var currentPosts: [PrePost] {
        switch currentSection {
        case .all:
            posts
        case .articles:
            posts.filter { !($0.isShortPost ?? false) }
        case .replies:
            []
        case .localized:
            allPosts.filter { $0.isLocalizedVersion ?? false }
        }
    }

    var currentSectionTitle: String {
        currentSection.title
    }

    func showSection(_ section: ChannelPostsSection) {
        currentSection = section
    }

    func loadCurrentSectionUntilAvailableIfNeeded(authorId: String) async {
        if currentSection == .replies {
            await loadRepliesIfNeeded(authorId: authorId)
            return
        }

        while currentPosts.isEmpty && !isAllLoading {
            do {
                try await loadPosts(by: authorId)
            } catch {
                errorText = error.localizedDescription
                isErrorPopupPresented = true
                return
            }
        }
    }

    private func localizedPosts(from posts: [PrePost]) -> [PrePost] {
        var bestPostsByRoot: [String: (post: PrePost, index: Int)] = [:]

        for (index, post) in posts.enumerated() {
            let rootKey = post.rootId ?? post.id

            if let current = bestPostsByRoot[rootKey] {
                if localizationPriority(for: post) < localizationPriority(for: current.post) {
                    bestPostsByRoot[rootKey] = (post, index)
                }
            } else {
                bestPostsByRoot[rootKey] = (post, index)
            }
        }

        return bestPostsByRoot
            .values
            .sorted { $0.index < $1.index }
            .map(\.post)
    }

    private func localizationPriority(for post: PrePost) -> Int {
        if post.originalLanguage == primaryLanguage {
            return 0
        }

        if !(post.isLocalizedVersion ?? false) {
            return 1
        }

        return 2
    }

    func loadRepliesIfNeeded(authorId: String) async {
        guard replies.isEmpty, !isRepliesLoading else { return }
        guard !authorId.isEmpty else { return }

        isRepliesLoading = true

        do {
            replies = try await CommentariesManager.shared.getCommentaries(authorId: authorId)

            let replyAuthorIds = Set(
                replies
                    .compactMap { $0.rootAuthorId }
                    .filter { !$0.isEmpty }
            )

            for replyAuthorId in replyAuthorIds where replyAuthorsInfo[replyAuthorId] == nil {
                if let info = try await UserManager.shared.getPostAuthorInfo(for: replyAuthorId) {
                    replyAuthorsInfo[replyAuthorId] = info
                }
            }

            isRepliesLoading = false
            withAnimation {
                isLoading = false
                isLoadingShowing = false
            }
        } catch {
            isRepliesLoading = false
            errorText = error.localizedDescription
            isErrorPopupPresented = true
        }
    }
}
