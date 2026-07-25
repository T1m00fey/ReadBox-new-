//
//  NotificationsViewModel.swift
//  ReadBox
//
//  Created by Тимофей Юдин on 06.05.2026.
//

import SwiftUI

private struct NotificationsCache: Codable {
    let notifications: [PersonalNotificationItem]
    let actorInfo: [String: PostAuthorInfo]
    let articleTitles: [String: String]
    let postKinds: [String: Bool]
}

@MainActor
final class NotificationsViewModel: ObservableObject {
    @Published var notifications: [PersonalNotificationItem] = []
    @Published var actorInfo: [String: PostAuthorInfo] = [:]
    @Published var articleTitles: [String: String] = [:]
    @Published var postKinds: [String: Bool] = [:]
    @Published var isLoading = true
    @Published var isRefreshing = false
    @Published var errorText = ""
    @Published var isErrorPopupPresented = false
    @Published var user: DBUser? = nil

    @Published var isReadViewPresented = false
    @Published var isChannelViewPresented = false

    private var loadedUserId = ""

    var authorId = ""
    var prePost: PrePost?
    var postToRead: PostToRead?

    var unreadCount: Int {
        notifications.filter { !$0.isRead }.count
    }

    func loadNotifications() async {
        guard let userId = try? AuthenticationManager.shared.getAuthenticatedUser().uid else { return }

        if loadedUserId != userId {
            loadedUserId = userId
            notifications = []
            actorInfo = [:]
            articleTitles = [:]
            postKinds = [:]
            isLoading = true

            loadCache()
        }

        await refresh()
    }

    func refresh() async {
        if notifications.isEmpty {
            isLoading = true
        } else {
            isRefreshing = true
        }

        errorText = ""
        isErrorPopupPresented = false

        do {
            let userId = try AuthenticationManager.shared.getAuthenticatedUser().uid
            let notifications = try await NotificationsManager.shared.getNotifications(for: userId)

            withAnimation {
                self.notifications = notifications
                self.isLoading = false
            }

            saveCache()
            await loadActorInfo(for: notifications)
            await loadArticleTitles(for: notifications)
            user = try await UserManager.shared.getUser(userId: userId)

            withAnimation {
                self.isRefreshing = false
            }

            saveCache()
        } catch {
            withAnimation {
                errorText = error.localizedDescription
                isErrorPopupPresented = true
                isLoading = false
                isRefreshing = false
            }
        }
    }

    private func loadActorInfo(for notifications: [PersonalNotificationItem]) async {
        let actorIds = Set(
            notifications
                .compactMap(\.actorId)
                .filter { !$0.isEmpty }
        )

        for actorId in actorIds {
            if let info = try? await UserManager.shared.getPostAuthorInfo(for: actorId) {
                withAnimation {
                    actorInfo[actorId] = info
                }
            }
        }
    }

    private func loadArticleTitles(for notifications: [PersonalNotificationItem]) async {
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

    private func loadCache() {
        guard let data = UserDefaults.standard.data(forKey: "notifications.cache.\(loadedUserId)"),
              let cache = try? JSONDecoder().decode(NotificationsCache.self, from: data) else {
            return
        }

        notifications = cache.notifications
        actorInfo = cache.actorInfo
        articleTitles = cache.articleTitles
        postKinds = cache.postKinds
        isLoading = false
    }

    private func saveCache() {
        guard !loadedUserId.isEmpty else { return }

        let cache = NotificationsCache(
            notifications: notifications,
            actorInfo: actorInfo,
            articleTitles: articleTitles,
            postKinds: postKinds
        )

        guard let data = try? JSONEncoder().encode(cache) else { return }
        UserDefaults.standard.set(data, forKey: "notifications.cache.\(loadedUserId)")
    }

    func markNotificationsAsRead() async {
        let ids = notifications
            .filter { !$0.isRead }
            .map(\.id)

        guard !ids.isEmpty else { return }

        for index in notifications.indices where ids.contains(notifications[index].id) {
            notifications[index].isRead = true
        }

        saveCache()

        do {
            try await NotificationsManager.shared.markAsRead(ids: ids)
        } catch {
            for index in notifications.indices where ids.contains(notifications[index].id) {
                notifications[index].isRead = false
            }

            saveCache()

            withAnimation {
                errorText = error.localizedDescription
                isErrorPopupPresented = true
            }
        }
    }

    func open(_ notification: PersonalNotificationItem) async {
        if let postId = notification.postId, !postId.isEmpty {
            await openArticle(id: postId)
            return
        }

        let actorId = notification.actorId ?? ""
        guard !actorId.isEmpty else { return }

        if let userId = try? AuthenticationManager.shared.getAuthenticatedUser().uid {
            user = try? await UserManager.shared.getUser(userId: userId)
        }

        authorId = actorId
        isChannelViewPresented = true
    }

    func openAuthorChannel(for notification: PersonalNotificationItem) async {
        let actorId = notification.actorId ?? ""
        guard !actorId.isEmpty else { return }

        if let userId = try? AuthenticationManager.shared.getAuthenticatedUser().uid {
            user = try? await UserManager.shared.getUser(userId: userId)
        }

        authorId = actorId
        isChannelViewPresented = true
    }

    private func openArticle(id articleId: String) async {
        do {
            let prePost = try await ArticlesManager.shared.getPrePost(id: articleId)
            let post = try await ArticlesManager.shared.getPostToRead(id: articleId)

            authorId = prePost.authorId ?? ""
            self.prePost = prePost
            self.postToRead = post

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
