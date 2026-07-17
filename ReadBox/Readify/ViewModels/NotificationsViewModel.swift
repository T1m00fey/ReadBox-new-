//
//  NotificationsViewModel.swift
//  ReadBox
//
//  Created by Тимофей Юдин on 06.05.2026.
//

import SwiftUI

@MainActor
final class NotificationsViewModel: ObservableObject {
    @Published var notifications: [InAppNotificationItem] = []
    @Published var actorInfo: [String: PostAuthorInfo] = [:]
    @Published var articleTitles: [String: String] = [:]
    @Published var postKinds: [String: Bool] = [:]
    @Published var isLoading = true
    @Published var isRefreshingInBackground = false
    @Published var errorText = ""
    @Published var isErrorPopupPresented = false
    @Published var user: DBUser? = nil

    @Published var isReadViewPresented = false
    @Published var isChannelViewPresented = false

    var hasLoadedOnce = false

    var title = ""
    var text = ""
    var dateCreated = Date()
    var likesCount = 0
    var id = ""
    var authorId = ""
    var isArchive = false
    var mediaCount = 0
    var mediaVersion = 0
    var mediaPosition = 0
    var articleLanguage = ""
    var isPremiumPost = false
    var isLocalizedVersion = false
    var rootId = ""

    private let userDefaults = UserDefaults.standard
    private let notificationsCacheKeyPrefix = "notifications.cache.items."
    private let actorInfoCacheKeyPrefix = "notifications.cache.actorInfo."
    private let articleTitlesCacheKeyPrefix = "notifications.cache.articleTitles."
    private let postKindsCacheKeyPrefix = "notifications.cache.postKinds."

    func loadIfNeeded() async {
        guard !hasLoadedOnce else { return }

        hasLoadedOnce = true
        do {
            let authDataResult = try AuthenticationManager.shared.getAuthenticatedUser()
            loadCachedContent(for: authDataResult.uid)
            await refresh(showSkeletons: notifications.isEmpty)
        } catch {
            await refresh(showSkeletons: notifications.isEmpty)
        }
    }

    func refresh() async {
        await refresh(showSkeletons: notifications.isEmpty)
    }

    func refresh(showSkeletons: Bool) async {
        if showSkeletons {
            withAnimation {
                isLoading = true
                isRefreshingInBackground = false
                errorText = ""
                isErrorPopupPresented = false
            }
        } else {
            withAnimation {
                isLoading = false
                isRefreshingInBackground = true
                errorText = ""
                isErrorPopupPresented = false
            }
        }

        do {
            let authDataResult = try AuthenticationManager.shared.getAuthenticatedUser()
            let user = try await UserManager.shared.getUser(userId: authDataResult.uid)
            let notifications = try await NotificationsManager.shared.getNotifications(for: authDataResult.uid)

            await loadActorInfo(for: notifications)
            await loadArticleTitles(for: notifications)

            saveCachedContent(
                notifications: notifications,
                actorInfo: actorInfo,
                articleTitles: articleTitles,
                postKinds: postKinds,
                userId: authDataResult.uid
            )

            withAnimation {
                self.user = user
                self.notifications = notifications
                self.isLoading = false
                self.isRefreshingInBackground = false
            }
        } catch {
            withAnimation {
                errorText = error.localizedDescription
                isErrorPopupPresented = true
                isLoading = false
                isRefreshingInBackground = false
            }
        }
    }

    private func loadActorInfo(for notifications: [InAppNotificationItem]) async {
        let actorIds = Set(
            notifications
                .compactMap(\.actorId)
                .filter { !$0.isEmpty }
        )

        for actorId in actorIds where actorInfo[actorId] == nil {
            if let info = try? await UserManager.shared.getPostAuthorInfo(for: actorId) {
                actorInfo[actorId] = info
            }
        }
    }

    private func loadArticleTitles(for notifications: [InAppNotificationItem]) async {
        let postIds = Set(
            notifications
                .compactMap(\.postId)
                .filter { !$0.isEmpty }
        )

        for postId in postIds where articleTitles[postId] == nil || postKinds[postId] == nil {
            if let prePost = try? await ArticlesManager.shared.getPrePost(id: postId) {
                articleTitles[postId] = prePost.title ?? ""
                postKinds[postId] = prePost.isShortPost ?? false
            }
        }
    }

    private func loadCachedContent(for userId: String) {
        if let cachedActorInfo: [String: PostAuthorInfo] = loadCachedValue(forKey: actorInfoCacheKeyPrefix + userId) {
            actorInfo = cachedActorInfo
        }

        if let cachedArticleTitles: [String: String] = loadCachedValue(forKey: articleTitlesCacheKeyPrefix + userId) {
            articleTitles = cachedArticleTitles
        }

        if let cachedPostKinds: [String: Bool] = loadCachedValue(forKey: postKindsCacheKeyPrefix + userId) {
            postKinds = cachedPostKinds
        }

        if let cachedNotifications: [InAppNotificationItem] = loadCachedValue(forKey: notificationsCacheKeyPrefix + userId),
           hasActorInfo(for: cachedNotifications) {
            notifications = cachedNotifications
            isLoading = false
        }
    }

    private func hasActorInfo(for notifications: [InAppNotificationItem]) -> Bool {
        notifications.allSatisfy { notification in
            guard let actorId = notification.actorId, !actorId.isEmpty else { return true }
            return actorInfo[actorId] != nil
        }
    }

    private func saveCachedContent(
        notifications: [InAppNotificationItem],
        actorInfo: [String: PostAuthorInfo],
        articleTitles: [String: String],
        postKinds: [String: Bool],
        userId: String
    ) {
        saveCachedValue(notifications, forKey: notificationsCacheKeyPrefix + userId)
        saveCachedValue(actorInfo, forKey: actorInfoCacheKeyPrefix + userId)
        saveCachedValue(articleTitles, forKey: articleTitlesCacheKeyPrefix + userId)
        saveCachedValue(postKinds, forKey: postKindsCacheKeyPrefix + userId)
    }

    private func saveCachedValue<T: Codable>(_ value: T, forKey key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        userDefaults.set(data, forKey: key)
    }

    private func loadCachedValue<T: Codable>(forKey key: String) -> T? {
        guard let data = userDefaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    func open(_ notification: InAppNotificationItem) async {
        if let postId = notification.postId, !postId.isEmpty {
            await openArticle(id: postId)
            return
        }

        let actorId = notification.actorId ?? ""
        guard !actorId.isEmpty else { return }

        authorId = actorId
        isChannelViewPresented = true
    }

    func openAuthorChannel(for notification: InAppNotificationItem) {
        let actorId = notification.actorId ?? ""
        guard !actorId.isEmpty else { return }

        authorId = actorId
        isChannelViewPresented = true
    }

    private func openArticle(id articleId: String) async {
        do {
            let prePost = try await ArticlesManager.shared.getPrePost(id: articleId)
            let post = try await ArticlesManager.shared.getPostToRead(id: articleId)

            title = prePost.title ?? NSLocalizedString("notFoundLabel", comment: "")
            text = post.text ?? NSLocalizedString("notFoundLabel", comment: "")
            dateCreated = post.dateCreated ?? Date()
            likesCount = prePost.likesCount ?? 0
            id = prePost.id
            authorId = prePost.authorId ?? ""
            isArchive = prePost.isArchive ?? false
            mediaCount = prePost.mediaCount ?? 0
            mediaVersion = prePost.mediaVersion ?? 0
            mediaPosition = prePost.mediaPosition ?? 0
            articleLanguage = prePost.originalLanguage ?? ""
            isPremiumPost = prePost.isPremiumPost ?? false
            isLocalizedVersion = prePost.isLocalizedVersion ?? false
            rootId = prePost.rootId ?? ""

            if authorId != "", actorInfo[authorId] == nil {
                actorInfo[authorId] = try? await UserManager.shared.getPostAuthorInfo(for: authorId)
            }

            isReadViewPresented = true
        } catch {
            withAnimation {
                errorText = error.localizedDescription
                isErrorPopupPresented = true
            }
        }
    }
}
