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
    case localize
    case delete
}

enum CreatedPostsSection: Int, CaseIterable {
    case all
    case articles
    case replies
    case archive
    case localizedPublished
    case localizedArchive

    var title: String {
        switch self {
        case .all:
            NSLocalizedString("publicationsLabel", comment: "")
        case .articles:
            NSLocalizedString("articlesLabel", comment: "")
        case .replies:
            NSLocalizedString("repliesLabel", comment: "")
        case .archive:
            NSLocalizedString("archiveLabel", comment: "")
        case .localizedPublished:
            NSLocalizedString("localizedPostsLabel", comment: "")
        case .localizedArchive:
            NSLocalizedString("localizedArchivePostsLabel", comment: "")
        }
    }
}

@MainActor
final class CreatedPostsViewModel: ObservableObject {
    @Published var isErrorPopupPresented = false
    @Published var errorText = ""
    @Published var articlesIndexes: [String] = []
    @Published var posts: [PrePost] = []
    @Published var archivePosts: [PrePost] = []
    @Published var replies: [Comment] = []
    @Published var replyAuthorsInfo: [String: PostAuthorInfo] = [:]
    @Published var isDescriptionPopupPresented = false
    @Published var isReadViewPresented = false
    @Published var shouldOpenCommentsOnRead = false
    @Published var isNewNameAlertPresented = false
    @Published var isSuccessPopupPresented = false
    @Published var isCreateViewPresented = false
    @Published var isArchivePresented = false
    @Published var isArticlesPresented = false
    @Published var isRepliesPresented = false
    @Published var isLocalizedPostsPresented = false
    @Published var postsNeedToLoad: [String] = []
    @Published var postOption: PostOptions = .nothing
    @Published var isNewPublicationButtonPresented = false
    @Published var isButtonEnabled = false
    @Published var isChannelViewPresented = false
    @Published var isSettingViewPresented = false
    @Published var isNeedToReload = false
    @Published var isLoading = true
    @Published var isLoadingShowing = true
    @Published var isLoadingPopupPresented = false
    @Published var lastPostSnapshot: DocumentSnapshot? = nil
    @Published var lastArchivedPostSnapshot: DocumentSnapshot? = nil
    @Published var isAllLoaded = false
    @Published var isAllArchivedLoaded = false
    @Published var mediaURLs: [URL] = []
    @Published var avatarImage: UIImage? = nil
    @Published var isZoomableImageViewPresented = false
    @Published var zoomableImage: UIImage? = nil
    @Published var isVideoCover = false
    @Published var videoURL: URL? = nil
    @Published var addingMode = 0
    @Published var isConfirmationPopupPresented = false
    @Published var isPostCreateViewPresented = false
    @Published var mediaKind: [MediaKind?] = []
    @Published var isPublicationsLabelVisible = true
    @Published var isDeletePostAlertPresented = false
    @Published var pendingDeletePostId = ""
    @Published var pendingDeleteReplyId = ""
    @Published var isRepliesLoading = false

    @Published var avatarVersion = 0
    @Published var postsCount = 0
    @Published var subscribersCount = 0
    @Published var name = NSLocalizedString("notFoundLabel", comment: "")
    @Published var description = ""
    @Published var isCheckmark = false
    @Published var isPremiumAuthor = false

    @Published var user: DBUser? = nil

    @Published var id = ""

    let vibrationsService = VibrationsService.shared
    let subscribersCountLabel = NSLocalizedString("subscribersCountLabel", comment: "")
    let postsCountLabel = NSLocalizedString("publicationsCountLabel", comment: "")

    var title = ""
    var image: UIImage? = nil
    var text = ""
    var likesCount = 0
    var dateCreated = Date()
    var isEditing = false
    var postId = ""
    var mediaCount = 0
    var mediaVersion = 0
    var mediaPosition = 0
    var readArticleLanguage = ""
    var readIsPremiumPost = false
    var readIsLocalizedVersion = false
    var readRootId = ""
    var readAuthorId = ""
    var readAuthorName = NSLocalizedString("notFoundLabel", comment: "")
    var readAuthorIsCheckmark = false
    var readAuthorAvatarVersion = 0
    var readReplyAuthorName: String? = nil
    var readReplyRootPostId: String? = nil
    var isReadingReplyComment = false
    var isLocalizing = false
    var localizationCount = 0
    var rootLang = ""
    var rootMediaPosition = 0
    var rootIsPremiumPost = false
    var createIsLocalizedVersion = false

    var alertText = ""

    func clearData() {
        postOption = .nothing
        id = ""
        text = ""
        isEditing = false
        postId = ""
        mediaURLs = []
        mediaKind = []
        mediaCount = 0
        mediaVersion = 0
        mediaPosition = 0
        readArticleLanguage = ""
        readIsPremiumPost = false
        readIsLocalizedVersion = false
        readRootId = ""
        readAuthorId = ""
        readAuthorName = NSLocalizedString("notFoundLabel", comment: "")
        readAuthorIsCheckmark = false
        readAuthorAvatarVersion = 0
        readReplyAuthorName = nil
        readReplyRootPostId = nil
        isReadingReplyComment = false
        isLocalizing = false
        localizationCount = 0
        rootLang = ""
        title = ""
        rootMediaPosition = 0
        rootIsPremiumPost = false
        createIsLocalizedVersion = false
        isDeletePostAlertPresented = false
        pendingDeletePostId = ""
        pendingDeleteReplyId = ""
    }

    func isButtonEnable() {
        withAnimation {
            if name.count > 0 && !isLoading {
                isButtonEnabled = true
            } else {
                isButtonEnabled = false
            }
        }
    }

    func getBottomPadding(by id: String) -> CGFloat {
        currentPosts.last?.id == id ? 70 : 10
    }

    func loadUser() async throws {
        let authDataResult = try AuthenticationManager.shared.getAuthenticatedUser()
        let user = try await UserManager.shared.getUser(userId: authDataResult.uid)
        if let id = user?.userId {
            isPremiumAuthor = try await UserManager.shared.getIsPremiumAuthorStatus(for: id)
        }

        postsCount = user?.postsCount ?? 0
        subscribersCount = user?.subscribersCount ?? 0
        name = user?.name ?? NSLocalizedString("notFoundLabel", comment: "")
        description = user?.authorDescription ?? ""
        isCheckmark = user?.isCheckmark ?? false
        avatarVersion = user?.avatarVersion ?? 0

        self.user = user
    }

    func getAuthorIsCheckmarkStatus(id: String) async throws -> Bool {
        try await UserManager.shared.getIsCheckmarkStatus(id: id) ?? false
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
            replies = []
            replyAuthorsInfo = [:]
            isArchivePresented = false
            isArticlesPresented = false
            isRepliesPresented = false
            isLocalizedPostsPresented = false
            postsCount = 0
            isLoadingShowing = true
            isNewPublicationButtonPresented = false
            isAllLoaded = false
            isAllArchivedLoaded = false
            isRepliesLoading = false
            lastPostSnapshot = nil
            lastArchivedPostSnapshot = nil
            isNeedToReload = false

            user = nil
        }

        Task {
            isLoading = true

            try? await loadUser()

            if let id = user?.userId {
                let ava = await MediaManager.shared.getAvatar(authorId: id, lastVersion: user?.avatarVersion ?? 0)

                withAnimation {
                    avatarImage = ava
                }
            }
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

    private func makePromotedPost(from post: PrePost) -> PrePost {
        PrePost(
            id: post.id,
            title: post.title,
            authorId: post.authorId,
            originalLanguage: post.originalLanguage,
            dateCreated: post.dateCreated,
            viewsCount: post.viewsCount,
            likesCount: post.likesCount,
            isArchive: post.isArchive,
            isShortPost: post.isShortPost,
            mediaCount: post.mediaCount,
            mediaVersion: post.mediaVersion,
            mediaPosition: post.mediaPosition,
            localizationCount: post.localizationCount,
            isLocalizedVersion: false,
            rootId: nil,
            isPremiumPost: post.isPremiumPost
        )
    }

    private func promoteLocalizedVersionsLocally(rootId: String) {
        posts = posts.map { post in
            guard post.rootId == rootId, post.isLocalizedVersion ?? false else { return post }
            return makePromotedPost(from: post)
        }

        archivePosts = archivePosts.map { post in
            guard post.rootId == rootId, post.isLocalizedVersion ?? false else { return post }
            return makePromotedPost(from: post)
        }
    }

    func deletePost(id: String) async throws {
        guard let post = isArchivePresented
                ? archivePosts.first(where: { $0.id == id })
                : posts.first(where: { $0.id == id }) else { return }

        var localizedVersions: [PrePost] = []

        if !(post.isLocalizedVersion ?? false) {
            localizedVersions = try await ArticlesManager.shared.getLocalizedVersions(rootId: id)
        }

        let hasLocalizedVersions = !localizedVersions.isEmpty

        if let isArchive = post.isArchive,
           isArchive == false,
           !(post.isLocalizedVersion ?? false),
           !hasLocalizedVersions {
            withAnimation {
                postsCount -= 1
            }

            try await UserManager.shared.updatePostsCount(
                userId: user?.userId ?? "",
                postsCount: postsCount
            )
        }

        let mediaURLs = try await ArticlesManager.shared.getMediaURLs(from: id)

        if let rootId = post.rootId, let isLocVer = post.isLocalizedVersion, isLocVer {
            let locCountOfRoot = try? await ArticlesManager.shared.getLocalizationCount(for: rootId)

            if let locCountOfRoot {
                try? await ArticlesManager.shared.setLocalizationCount(for: rootId, count: locCountOfRoot - 1)
            }
        } else if hasLocalizedVersions {
            try await ArticlesManager.shared.makeLocalizedVersionsRegular(rootId: id)
        }

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

            if hasLocalizedVersions {
                promoteLocalizedVersionsLocally(rootId: id)
            }

            updatePresentedSectionIfNeeded()
        }

        self.id = ""

        StorageManager.shared.deleteImage(id: id)

        let fileReference = Storage.storage().reference().child("images/\(id).jpg")
        let videoReference = Storage.storage().reference().child("images/\(id).mp4")

        try? await fileReference.delete()
        try? await videoReference.delete()
    }

    func shouldShowLocalizedDeleteAlert(for post: PrePost) -> Bool {
        !(post.isLocalizedVersion ?? false) && (post.localizationCount ?? 0) > 0
    }

    func postForDeletion(id: String) -> PrePost? {
        posts.first { $0.id == id } ?? archivePosts.first { $0.id == id }
    }

    func replyForDeletion(id: String) -> Comment? {
        replies.first { $0.id == id }
    }

    func deleteAlertMessageKey(for id: String) -> String {
        if !pendingDeleteReplyId.isEmpty {
            return "deletePublicationAlertMessage"
        }

        if let post = postForDeletion(id: id),
           shouldShowLocalizedDeleteAlert(for: post) {
            return "deleteLocalizedPostAlertMessage"
        }

        return "deletePublicationAlertMessage"
    }

    func updateIsArchiveStatus() {
       Task {
            do {
                let currentPost = isArchivePresented
                    ? archivePosts.first(where: { $0.id == id })
                    : posts.first(where: { $0.id == id })
                let familyId = currentPost?.rootId ?? currentPost?.id ?? id
                let hasOtherPublishedVersion = posts.contains {
                    ($0.rootId ?? $0.id) == familyId && $0.id != id
                }
                let wasPublishedBefore = !isArchivePresented || hasOtherPublishedVersion
                let willBePublishedAfter = isArchivePresented || hasOtherPublishedVersion
                let delta = (willBePublishedAfter ? 1 : 0) - (wasPublishedBefore ? 1 : 0)

                try await ArticlesManager.shared.updateIsArchiveStatus(id: id, isArchive: !isArchivePresented)

                if delta != 0 {
                    withAnimation {
                        postsCount += delta
                    }

                    try await UserManager.shared.updatePostsCount(userId: user?.userId ?? "", postsCount: postsCount)
                }

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

                updatePresentedSectionIfNeeded()
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

    func tapGestureHandler(on post: PrePost, openComments: Bool = false) {
        title = post.title ?? NSLocalizedString("notFoundLabel", comment: "")
        image = StorageManager.shared.getImage(id: post.id) ?? UIImage()
        likesCount = post.likesCount ?? 0
        id = post.id
        mediaCount = post.mediaCount ?? 1
        mediaVersion = post.mediaVersion ?? 1
        mediaPosition = post.mediaPosition ?? 0
        readArticleLanguage = post.originalLanguage ?? ""
        readIsPremiumPost = post.isPremiumPost ?? false
        readIsLocalizedVersion = post.isLocalizedVersion ?? false
        readRootId = post.rootId ?? ""
        readAuthorId = user?.userId ?? ""
        readAuthorName = user?.name ?? NSLocalizedString("notFoundLabel", comment: "")
        readAuthorIsCheckmark = user?.isCheckmark ?? false
                readAuthorAvatarVersion = user?.avatarVersion ?? 0
                readReplyAuthorName = nil
                readReplyRootPostId = nil
                isReadingReplyComment = false
                shouldOpenCommentsOnRead = openComments

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

    func openReplyRootPost(_ comment: Comment, openComments: Bool = false) {
        guard let rootPostId = comment.rootPostId, !rootPostId.isEmpty else { return }

        Task {
            do {
                isLoadingPopupPresented = true

                let resolvedRootPostId: String

                do {
                    _ = try await getPrePost(id: rootPostId)
                    resolvedRootPostId = rootPostId
                } catch {
                    let legacyComment = try await CommentariesManager.shared.getComment(id: rootPostId)
                    guard let legacyRootPostId = legacyComment.rootPostId, !legacyRootPostId.isEmpty else {
                        throw error
                    }

                    resolvedRootPostId = legacyRootPostId
                }

                let prePost = try await getPrePost(id: resolvedRootPostId)

                guard !(prePost.isArchive ?? false) else {
                    withAnimation {
                        isLoadingPopupPresented = false
                        errorText = NSLocalizedString("archiveArticleLabel", comment: "")
                        isErrorPopupPresented = true
                    }
                    return
                }

                let post = try await ArticlesManager.shared.getPostToRead(id: resolvedRootPostId)
                let authorInfo = try await UserManager.shared.getPostAuthorInfo(for: prePost.authorId ?? "")

                title = prePost.title ?? NSLocalizedString("notFoundLabel", comment: "")
                image = StorageManager.shared.getImage(id: prePost.id) ?? UIImage()
                likesCount = prePost.likesCount ?? 0
                id = prePost.id
                mediaCount = prePost.mediaCount ?? 1
                mediaVersion = prePost.mediaVersion ?? 1
                mediaPosition = prePost.mediaPosition ?? 0
                readArticleLanguage = prePost.originalLanguage ?? ""
                readIsPremiumPost = prePost.isPremiumPost ?? false
                readIsLocalizedVersion = prePost.isLocalizedVersion ?? false
                readRootId = prePost.rootId ?? ""
                readAuthorId = prePost.authorId ?? ""
                readAuthorName = authorInfo?.name ?? NSLocalizedString("notFoundLabel", comment: "")
                readAuthorIsCheckmark = authorInfo?.isCheckmark ?? false
                readAuthorAvatarVersion = authorInfo?.avatarVersion ?? 0
                dateCreated = post.dateCreated ?? Date()
                text = post.text ?? ""
                mediaURLs = (post.mediaURLs ?? []).compactMap { URL(string: $0) }
                isReadingReplyComment = false
                shouldOpenCommentsOnRead = openComments

                isLoadingPopupPresented = false
                isReadViewPresented = true
            } catch {
                withAnimation {
                    isLoadingPopupPresented = false
                    errorText = error.localizedDescription
                    isErrorPopupPresented = true
                }
            }
        }
    }

    func openReplyComment(_ comment: Comment, openComments: Bool = false) {
        title = comment.text ?? ""
        text = ""
        likesCount = comment.likesCount ?? 0
        dateCreated = comment.dateCreated ?? Date()
        id = comment.id
        mediaCount = 0
        mediaVersion = 1
        mediaPosition = 0
        readArticleLanguage = ""
        readIsPremiumPost = false
        readIsLocalizedVersion = false
        readRootId = ""
        readAuthorId = comment.authorId ?? (user?.userId ?? "")
        readAuthorName = user?.name ?? NSLocalizedString("notFoundLabel", comment: "")
        readAuthorIsCheckmark = user?.isCheckmark ?? false
        readAuthorAvatarVersion = user?.avatarVersion ?? 0
        readReplyAuthorName = replyAuthorsInfo[comment.rootAuthorId ?? ""]?.name
        readReplyRootPostId = comment.rootPostId
        isReadingReplyComment = true
        shouldOpenCommentsOnRead = openComments
        isReadViewPresented = true
    }

    var publishedPosts: [PrePost] {
        posts.filter { !($0.isLocalizedVersion ?? false) }
    }

    var articles: [PrePost] {
        publishedPosts.filter { !($0.isShortPost ?? false) }
    }

    var localizedPosts: [PrePost] {
        posts.filter { $0.isLocalizedVersion ?? false }
    }

    var regularArchivePosts: [PrePost] {
        archivePosts.filter { !($0.isLocalizedVersion ?? false) }
    }

    var localizedArchivePosts: [PrePost] {
        archivePosts.filter { $0.isLocalizedVersion ?? false }
    }

    var currentPosts: [PrePost] {
        if isArchivePresented && isLocalizedPostsPresented {
            localizedArchivePosts
        } else if isArchivePresented {
            regularArchivePosts
        } else if isLocalizedPostsPresented {
            localizedPosts
        } else if isRepliesPresented {
            []
        } else if isArticlesPresented {
            articles
        } else {
            publishedPosts
        }
    }

    var hasLocalizedPosts: Bool {
        !localizedPosts.isEmpty || !localizedArchivePosts.isEmpty
    }

    var hasRegularArchivePosts: Bool {
        !regularArchivePosts.isEmpty
    }

    var currentSection: CreatedPostsSection {
        if isArchivePresented && isLocalizedPostsPresented {
            .localizedArchive
        } else if isArchivePresented {
            .archive
        } else if isLocalizedPostsPresented {
            .localizedPublished
        } else if isRepliesPresented {
            .replies
        } else if isArticlesPresented {
            .articles
        } else {
            .all
        }
    }

    var currentSectionTitle: String {
        currentSection.title
    }

    func posts(for section: CreatedPostsSection) -> [PrePost] {
        switch section {
        case .all:
            publishedPosts
        case .articles:
            articles
        case .replies:
            []
        case .archive:
            regularArchivePosts
        case .localizedPublished:
            localizedPosts
        case .localizedArchive:
            localizedArchivePosts
        }
    }

    func showAllPosts() {
        isArchivePresented = false
        isArticlesPresented = false
        isRepliesPresented = false
        isLocalizedPostsPresented = false
    }

    func showArticles() {
        isArchivePresented = false
        isArticlesPresented = true
        isRepliesPresented = false
        isLocalizedPostsPresented = false
    }

    func loadArticlesUntilAvailableIfNeeded() async {
        while isArticlesPresented && articles.isEmpty && !isAllLoaded {
            do {
                try await getPosts()
            } catch {
                errorText = error.localizedDescription
                isErrorPopupPresented = true
                return
            }
        }
    }

    func showArchivePosts() {
        isArchivePresented = true
        isArticlesPresented = false
        isRepliesPresented = false
        isLocalizedPostsPresented = false
    }

    func showReplies() {
        isArchivePresented = false
        isArticlesPresented = false
        isRepliesPresented = true
        isLocalizedPostsPresented = false
    }

    func showLocalizedPosts() {
        isArchivePresented = false
        isArticlesPresented = false
        isRepliesPresented = false
        isLocalizedPostsPresented = true
    }

    func showLocalizedArchivePosts() {
        isArchivePresented = true
        isArticlesPresented = false
        isRepliesPresented = false
        isLocalizedPostsPresented = true
    }

    func loadRepliesIfNeeded() async {
        guard replies.isEmpty, !isRepliesLoading else { return }
        guard let authorId = user?.userId, !authorId.isEmpty else { return }

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
        } catch {
            isRepliesLoading = false
            errorText = error.localizedDescription
            isErrorPopupPresented = true
        }
    }

    func requestReplyDeletion(_ comment: Comment) {
        pendingDeleteReplyId = comment.id
        isDeletePostAlertPresented = true
    }

    func deleteReply(_ comment: Comment) {
        Task {
            do {
                try await deleteReply(id: comment.id)
            } catch {
                await MainActor.run {
                    withAnimation {
                        pendingDeleteReplyId = ""
                        errorText = error.localizedDescription
                        isErrorPopupPresented = true
                    }
                }
            }
        }
    }

    func deleteReply(id: String) async throws {
        guard let comment = replyForDeletion(id: id) else { return }

        try await CommentariesManager.shared.deleteComment(id: comment.id)

        if let rootPostId = comment.rootPostId, !rootPostId.isEmpty {
            try? await ArticlesManager.shared.updateCommentsCount(at: rootPostId, isPlus: false)
        }

        withAnimation {
            replies.removeAll { $0.id == comment.id }
            pendingDeleteReplyId = ""
        }
    }

    func updatePresentedSectionIfNeeded() {
        if currentSection == .localizedPublished && localizedPosts.isEmpty {
            showAllPosts()
        }

        if currentSection == .localizedArchive && localizedArchivePosts.isEmpty {
            showAllPosts()
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
