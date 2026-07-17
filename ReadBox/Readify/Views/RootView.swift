//
//  RootView.swift
//  Readify
//
//  Created by Тимофей Юдин on 27.10.2024.
//

import SwiftUI
import FirebaseStorage
import PopupView
import UserNotifications

final class SessionManager: ObservableObject {
    @Published var sessionId: String = UUID().uuidString
}

final class ChangedPostsManager: ObservableObject {
    @Published var changedPostsIDs: [String] = []
}

enum TabType {
    case feed
    case favourites
    case subscribes
    case create
}

struct RootView: View {
    @State private var isReadViewPresented = false
    @State private var user: DBUser? = nil
    @State private var prePost: PrePost? = nil
    @State private var postToRead: PostToRead? = nil
    @State private var authorName: String? = ""
    @State private var isCheckmark: Bool? = false
    @State private var lastVersionOfAvatar: Int? = 0
    @State private var likedPosts: [String] = []
    @State private var isChannelViewPresented = false
    @State private var isWelcomeViewPresented = false
    @State private var authorId = ""
    @State private var isLoadingPopupPresented = false
    @State private var isDescriptionPopupPresented = false
    @State private var isNotificationPopupPresented = false
    @State private var isConfirmationPopupPresented = false
    @State private var isPremiumViewPresented = false

    @State private var selectedTab = TabType.feed
    @State private var bottomPaddingForHUD: CGFloat = 60

    @State private var isVersionPopupPresented = false
    @State private var relevantVersion: AppVersion? = nil
    @State private var isUpdatePopupDidPresented = false
    @State private var isUpdateBlur = false

    @StateObject var hudService = HUDService()
    @StateObject var sessionManager = SessionManager()
    @StateObject var changedPostsManager = ChangedPostsManager()
    @StateObject var sub = SubscriptionManager()

    @Environment(\.dismiss) var dismiss

    private var screenWidth = UIScreen.main.bounds.width

    var body: some View {
        ZStack(alignment: .bottom) {
            if (try? AuthenticationManager.shared.getAuthenticatedUser()) != nil {
                    TabView(selection: $selectedTab) {
                        FeedView(
                            isWelcomeViewPresented: $isWelcomeViewPresented,
                            selectedTab: $selectedTab,
                            isConfirmationViewPresented: $isConfirmationPopupPresented,
                            isPremiumViewPresented: $isPremiumViewPresented
                        )
                        .tag(TabType.feed)
                        .tabItem {
                            Label("", systemImage: "house.fill")
                        }

                        LikedPostsView(
                            isWelcomeViewPresented: $isWelcomeViewPresented,
                            isPremiumViewPresented: $isPremiumViewPresented
                        )
                        .tag(TabType.favourites)
                        .tabItem {
                            Label("", systemImage: "hand.thumbsup.fill")
                        }

                        SubscribesView(isPremiumViewPresented: $isPremiumViewPresented)
                            .tag(TabType.subscribes)
                            .tabItem {
                                Label("", systemImage: "person.crop.rectangle.stack")
                            }

                        CreatedPostsView(
                            isWelcomeViewPresented: $isWelcomeViewPresented,
                            isConfirmationPopupPresented: $isConfirmationPopupPresented
                        )
                        .tag(TabType.create)
                        .tabItem {
                            Label("", systemImage: "person.fill")
                        }
                    }
                    .disabled(isUpdateBlur)
                    .blur(radius: isUpdateBlur ? 5 : 0)
                    .tint(Color(uiColor: .label))
                    .onAppear {
                        isNotificationPopupPresented = !StorageManager.shared.isNotificationsPopupShowed()
                    }
            }
        }
            .environmentObject(sub)
            .environmentObject(hudService)
            .environmentObject(sessionManager)
            .environmentObject(changedPostsManager)
            .overlay(alignment: .bottom) {
                if hudService.isLoading {
                    hudService.makeLoadingPopup(screenWidth: screenWidth)
                }
            }
            .overlay(alignment: .bottom) {
                if hudService.isSuccessPopupPresented {
                    hudService.makeSuccessPopup(
                        screenWidth: screenWidth
                    )
                }
            }
            .overlay(alignment: .bottom) {
                if hudService.isErrorPopupPresented {
                    hudService.makeErrorPopup(
                        screenWidth: screenWidth,
                        bottomPadding: bottomPaddingForHUD
                    )
                }
            }
            .onChange(of: selectedTab) {
                if selectedTab == .create && !hudService.isLoading {
                    withAnimation {
                        bottomPaddingForHUD = 120
                    }
                } else {
                    withAnimation {
                        bottomPaddingForHUD = 60
                    }
                }
            }
            .onChange(of: isWelcomeViewPresented) {
                if !isWelcomeViewPresented {
                    Task {
                        let authUser = try? AuthenticationManager.shared.getAuthenticatedUser()
                        if let authUser {
                            AnalyticsManager.shared.setAuthenticatedUser(id: authUser.uid)
                        }
                        let user = try? await UserManager.shared.getUser(userId: authUser?.uid ?? "")

                        try? await UserManager.shared.set(
                            fcmToken: StorageManager.shared.getFcmToken(),
                            to: user?.userId ?? ""
                        )

                        if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                            try? await UserManager.shared.set(
                                appVersion: appVersion,
                                to: user?.userId ?? ""
                            )
                        }

                        try? await UserManager.shared.setOriginalLanguage(to: user?.userId ?? "")

                        if StorageManager.shared.getLanguage() == "en" && !(user?.subscribes?.contains (
                            "qDWmcGOLPGVAzJth2I8G2cwcp9x1"
                        ) ?? true) {

                            try? await UserManager.shared.un_subscribeUser(
                                on: "qDWmcGOLPGVAzJth2I8G2cwcp9x1",
                                isNeedToSubscribe: true
                            )

                        } else if StorageManager.shared.getLanguage() == "ru" && !(user?.subscribes?.contains(
                            "se8Any2drmcQg1sFoLXYXo4ttYt2"
                        ) ?? true) {

                            try? await UserManager.shared.un_subscribeUser(
                                on: "se8Any2drmcQg1sFoLXYXo4ttYt2",
                                isNeedToSubscribe: true
                            )

                        }
                    }
                }
            }
            .task { sub.start() }
            .onAppear {
                Task {
                    if let authUser = try? AuthenticationManager.shared.getAuthenticatedUser() {
                        AnalyticsManager.shared.setAuthenticatedUser(id: authUser.uid)
                        isWelcomeViewPresented = false
                        user = try? await UserManager.shared.getUser(userId: authUser.uid)

                        try? await UserManager.shared.set(
                            fcmToken: StorageManager.shared.getFcmToken(),
                            to: user?.userId ?? ""
                        )

                        try? await UserManager.shared.setOriginalLanguage(to: user?.userId ?? "")

                        if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                            try? await UserManager.shared.set(
                                appVersion: appVersion,
                                to: user?.userId ?? ""
                            )
                        }
                    } else {
                        AnalyticsManager.shared.clearAuthenticatedUser()
                        isWelcomeViewPresented = true
                    }
                }

                checkAppVersion()
                handlePendingNotificationArticleIfNeeded()
                handlePendingNotificationChannelIfNeeded()
            }
            .onOpenURL { url in
                handleOpenURL(url)
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("didReceiveRemoteNotification"))) { notification in
                guard let userInfo = notification.userInfo else { return }
                handleRemoteNotification(userInfo)
            }
            .onChange(of: isNotificationPopupPresented) {
                if !isNotificationPopupPresented {
                    StorageManager.shared.setNotificationsPopupShowed(true)
                }
            }
            .fullScreenCover(isPresented: $isReadViewPresented, content: {
                NavigationStack {
                    ReadView(
                        id: prePost?.id ?? "",
                        title: prePost?.title ?? NSLocalizedString("notFoundLabel", comment: ""),
                        text: postToRead?.text ?? NSLocalizedString("notFoundLabel", comment: ""),
                        dateCreated: postToRead?.dateCreated ?? Date(),
                        likesCount: prePost?.likesCount ?? 0,
                        authorId: prePost?.authorId ?? "",
                        authorName: authorName ?? "",
                        isCheckmark: isCheckmark ?? false,
                        isArchive: prePost?.isArchive ?? true,
                        mediaCount: prePost?.mediaCount ?? 1,
                        mediaVersion: prePost?.mediaVersion ?? 1,
                        mediaPosition: prePost?.mediaPosition ?? 0,
                        lastVersionOfAvatar: lastVersionOfAvatar ?? 0,
                        articleLanguage: prePost?.originalLanguage ?? "",
                        isPremiumPost: prePost?.isPremiumPost ?? false,
                        user: $user,
                        isChannelViewPresented: $isChannelViewPresented,
                        isPresented: $isReadViewPresented,
                        isLocalizedVersion: prePost?.isLocalizedVersion ?? false,
                        rootId: prePost?.rootId ?? ""
                    )
                    .tint(Color(uiColor: .label))
                    .environmentObject(sessionManager)
                    .environmentObject(changedPostsManager)
                    .environmentObject(sub)
                }
            })
            .fullScreenCover(isPresented: $isChannelViewPresented, content: {
                NavigationStack {
                    ChannelView(
                        user: $user,
                        authorId: authorId,
                        authorName: authorName ?? "",
                        isCheckmark: isCheckmark ?? false,
                        lastVersionOfAvatar: lastVersionOfAvatar ?? 0,
                        isPremiumViewPresented: $isPremiumViewPresented
                    )
                    .tint(Color(uiColor: .label))
                    .environmentObject(sessionManager)
                    .environmentObject(changedPostsManager)
                    .environmentObject(sub)
                }
            })
            .fullScreenCover(isPresented: $isPremiumViewPresented, content: {
                PremiumView()
                    .environmentObject(sub)
            })
            .fullScreenCover(isPresented: $isWelcomeViewPresented, content: {
                WelcomeView(isSignInViewPreseted: $isWelcomeViewPresented)
            })
            .sheet(isPresented: $isLoadingPopupPresented, content: {
                LoadingPopup()
                    .presentationDetents([.height(150)])
                    .presentationCornerRadius(30)
                    .presentationDragIndicator(.visible)
            })
            .sheet(isPresented: $isNotificationPopupPresented, content: {
                NotificationPermissionView(
                    isPopupPresented: $isNotificationPopupPresented,
                    route: .requestSystemPrompt
                )
                .presentationDetents([.height(250)])
                .presentationCornerRadius(30)
                .presentationDragIndicator(.visible)
            })
            .sheet(isPresented: $isVersionPopupPresented, content: {
                VersionPopupView(isCritical: relevantVersion?.isCritical ?? false)
                    .presentationDetents([.height((relevantVersion?.isCritical ?? false) ? 220 : 170)])
                    .presentationCornerRadius(30)
                    .presentationDragIndicator(.visible)
            })
        }
    }


private extension RootView {
    func handleOpenURL(_ url: URL) {
        let type = url.pathComponents.dropFirst().first ?? ""
        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
        let index = queryItems?.first(where: { $0.name == "index" })?.value
        let campaign = queryItems?.first(where: { $0.name == "utm_campaign" })?.value

        AnalyticsManager.shared.logInstallSourceIfNeeded(
            source: url.host ?? url.scheme ?? "external_link",
            campaign: campaign
        )

        guard let index, !index.isEmpty else { return }

        if type == "posts" {
            AnalyticsManager.shared.logWebToAppOpen(
                url: url,
                destination: "article",
                contentId: index
            )

            Task {
                await openArticleFromExternalRoute(id: index, shouldCountView: true)
            }
        } else if type == "authors" {
            AnalyticsManager.shared.logWebToAppOpen(
                url: url,
                destination: "author",
                contentId: index
            )

            Task {
                await openChannelFromExternalRoute(id: index)
            }
        }
    }

    func handleRemoteNotification(_ userInfo: [AnyHashable: Any]) {
        if let channelId = channelIdToOpen(from: userInfo) {
            StorageManager.shared.deletePendingNotificationChannelId()

            Task {
                await openChannelFromExternalRoute(id: channelId)
            }
            return
        }

        guard let type = userInfo["type"] as? String,
              type == "new_post",
              let articleId = userInfo["articleId"] as? String,
              !articleId.isEmpty else {
            return
        }

        StorageManager.shared.deletePendingNotificationArticleId()

        Task {
            await openArticleFromExternalRoute(id: articleId, shouldCountView: true)
        }
    }

    func channelIdToOpen(from userInfo: [AnyHashable: Any]) -> String? {
        guard let route = userInfo["route"] as? String,
              route == "channel",
              let channelId = userInfo["channelId"] as? String,
              !channelId.isEmpty else {
            return nil
        }

        return channelId
    }

    func handlePendingNotificationArticleIfNeeded() {
        guard let articleId = StorageManager.shared.getPendingNotificationArticleId(),
              !articleId.isEmpty else {
            return
        }

        StorageManager.shared.deletePendingNotificationArticleId()

        Task {
            await openArticleFromExternalRoute(id: articleId, shouldCountView: true)
        }
    }

    func handlePendingNotificationChannelIfNeeded() {
        guard let channelId = StorageManager.shared.getPendingNotificationChannelId(),
              !channelId.isEmpty else {
            return
        }

        StorageManager.shared.deletePendingNotificationChannelId()

        Task {
            await openChannelFromExternalRoute(id: channelId)
        }
    }

    func openChannelFromExternalRoute(id channelId: String) async {
        await MainActor.run {
            isLoadingPopupPresented = true
            isReadViewPresented = false
            isChannelViewPresented = false
            isPremiumViewPresented = false
        }

        do {
            guard let authUser = try? AuthenticationManager.shared.getAuthenticatedUser() else {
                await MainActor.run {
                    isLoadingPopupPresented = false
                }
                return
            }

            let loadedAuthorName = try? await UserManager.shared.getAuthorName(id: channelId)
            let loadedIsCheckmark = try? await UserManager.shared.getIsCheckmarkStatus(id: channelId)
            let loadedLastVersionOfAvatar = try? await UserManager.shared.getAvatarVersion(id: channelId)
            let loadedUser = try? await UserManager.shared.getUser(userId: authUser.uid)

            await MainActor.run {
                authorId = channelId
                authorName = loadedAuthorName
                isCheckmark = loadedIsCheckmark
                lastVersionOfAvatar = loadedLastVersionOfAvatar
                user = loadedUser
                isLoadingPopupPresented = false

                if authorName != nil {
                    isChannelViewPresented = true
                }
            }
        }
    }

    func openArticleFromExternalRoute(id articleId: String, shouldCountView: Bool) async {
        await MainActor.run {
            isLoadingPopupPresented = true
            isReadViewPresented = false
            isChannelViewPresented = false
            isPremiumViewPresented = false
        }

        do {
            let loadedPrePost = try await ArticlesManager.shared.getPrePost(id: articleId)
            let loadedAuthorName = try await UserManager.shared.getAuthorName(id: loadedPrePost.authorId ?? "")
            let loadedIsCheckmark = try await UserManager.shared.getIsCheckmarkStatus(id: loadedPrePost.authorId ?? "")
            let loadedLastVersionOfAvatar = try? await UserManager.shared.getAvatarVersion(id: loadedPrePost.authorId ?? "")
            let loadedAuthorId = loadedPrePost.authorId ?? ""

            guard let authUser = try? AuthenticationManager.shared.getAuthenticatedUser() else {
                await MainActor.run {
                    isLoadingPopupPresented = false
                }
                return
            }

            let loadedUser = try? await UserManager.shared.getUser(userId: authUser.uid)

            await MainActor.run {
                prePost = loadedPrePost
                authorName = loadedAuthorName
                isCheckmark = loadedIsCheckmark
                lastVersionOfAvatar = loadedLastVersionOfAvatar
                authorId = loadedAuthorId
                user = loadedUser
                likedPosts = loadedUser?.likedPosts ?? []
            }

            if let loadedUser,
               loadedPrePost.isPremiumPost ?? false,
               !sub.hasPremium,
               loadedUser.userId != loadedPrePost.authorId {
                await MainActor.run {
                    isLoadingPopupPresented = false
                    isPremiumViewPresented = true
                }
                return
            }

            let loadedPostToRead = try await ArticlesManager.shared.getPostToRead(id: articleId)

            if shouldCountView {
                try? await countLinkedArticleViewIfNeeded(loadedPrePost, viewer: loadedUser)
            }

            await MainActor.run {
                postToRead = loadedPostToRead
                isLoadingPopupPresented = false

                if authorName != nil && authorId != "" {
                    isReadViewPresented = true
                }
            }
        } catch {
            await MainActor.run {
                isLoadingPopupPresented = false
            }

            print("OPEN ARTICLE ERROR: \(error.localizedDescription)")
        }
    }

    func countLinkedArticleViewIfNeeded(_ post: PrePost?, viewer: DBUser?) async throws {
        guard let post else { return }
        guard post.authorId != viewer?.userId else { return }

        try await ArticlesManager.shared.updateViews(at: post.id)
    }

    func checkAppVersion() {
        Task {
            let version = try? await VersionManager.shared.getRelevantVersion()

            await MainActor.run {
                self.relevantVersion = version

                guard let version = version,
                      let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
                else {
                    self.isUpdateBlur = false
                    return
                }

                if version.appVersion != currentVersion && !self.isUpdatePopupDidPresented {
                    self.isUpdatePopupDidPresented = true
                    self.isNotificationPopupPresented = false
                    self.isLoadingPopupPresented = false

                    let isCritical = version.isCritical ?? false
                    withAnimation {
                        self.isUpdateBlur = isCritical
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        self.isVersionPopupPresented = true
                    }
                } else {
                    withAnimation {
                        self.isUpdateBlur = false
                    }
                }
            }
        }
    }

}

#Preview {
    RootView()
}
