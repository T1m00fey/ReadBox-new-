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

struct RootView: View {
    private enum TabType {
        case feed
        case favourites
        case create
        case profile
    }
    
    @State private var isReadViewPresented = false
    @State private var user: DBUser? = nil
    @State private var prePost: PrePost? = nil
    @State private var postToRead: PostToRead? = nil
    @State private var authorName: String? = ""
    @State private var isCheckmark: Bool? = false
    @State private var likedPosts: [String] = []
    @State private var isChannelViewPresented = false
    @State private var isWelcomeViewPresented = false
    @State private var authorId = ""
    @State private var isLoadingPopupPresented = false
    @State private var isDescriptionPopupPresented = false
    @State private var isNotificationPopupPresented = false
    
    @State private var selectedTab = TabType.feed
    @State private var bottomPaddingForHUD: CGFloat = 60
    
    @State private var isVersionPopupPresented = false
    @State private var relevantVersion: AppVersion? = nil
    @State private var isUpdatePopupDidPresented = false
    @State private var isUpdateBlur = false
    
    @StateObject var hudService = HUDService()
    @StateObject var sessionManager = SessionManager()
    @StateObject var changedPostsManager = ChangedPostsManager()
    
    @Environment(\.dismiss) var dismiss
    
    private var screenWidth = UIScreen.main.bounds.width
    
    var body: some View {
        ZStack {
            if let _ = try? AuthenticationManager.shared.getAuthenticatedUser() {
                TabView(selection: $selectedTab) {
                    FeedView(
                        isWelcomeViewPresented: $isWelcomeViewPresented
                    )
                    .tag(TabType.feed)
                    .tabItem {
                        Label("", systemImage: "house.fill")
                    }
                    
                    LikedPostsView(
                        isWelcomeViewPresented: $isWelcomeViewPresented
                    )
                    .tag(TabType.favourites)
                    .tabItem {
                        Label("", systemImage: "hand.thumbsup.fill")
                    }
                    
                    CreatedPostsView(isWelcomeViewPresented: $isWelcomeViewPresented)
                    .tag(TabType.create)
                    .tabItem {
                        Label("", systemImage: "pencil.and.scribble")
                    }
                    
                    ProfileView(
                        isWelcomeViewPresented: $isWelcomeViewPresented
                    )
                    .tag(TabType.profile)
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
        .onChange(of: isVersionPopupPresented) {
            if !isVersionPopupPresented {
                withAnimation {
                    isUpdateBlur = false
                }
            }
        }
        .onChange(of: isWelcomeViewPresented) {
            if !isWelcomeViewPresented {
                Task {
                    let authUser = try? AuthenticationManager.shared.getAuthenticatedUser()
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
        .onAppear {
            Task {
                if let authUser = try? AuthenticationManager.shared.getAuthenticatedUser() {
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
                    isWelcomeViewPresented = true
                }
            }
            
            checkAppVersion()
        }
        .onOpenURL { url in
            isLoadingPopupPresented = true
            
            isReadViewPresented = false
            isChannelViewPresented = false
            
            let type = url.absoluteString.components(separatedBy: "/")[3]
            var index = ""
            
            #if DEBUG
            print("url: \(url)")
            print("type: \(type)")
            #endif
            
            if type == "posts" {
                if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                    if let indexParam = components.queryItems?.first(where: { $0.name == "index" })?.value {
                        index = indexParam
                        
                        Task {
                            do {
                                prePost = try await ArticlesManager.shared.getPrePost(id: index)
                                postToRead = try await ArticlesManager.shared.getPostToRead(id: index)
                                authorName = try await UserManager.shared.getAuthorName(id: prePost?.authorId ?? "")
                                isCheckmark = try await UserManager.shared.getIsCheckmarkStatus(id: prePost?.authorId ?? "")
                                authorId = prePost?.authorId ?? ""
                                
                                isLoadingPopupPresented = false
                                
                                let authUser = try AuthenticationManager.shared.getAuthenticatedUser()
                                user = try? await UserManager.shared.getUser(userId: authUser.uid)
                                
                                if let user {
                                    likedPosts = user.likedPosts ?? []
                                    
                                    if prePost != nil && postToRead != nil && authorName != nil && authorId != "" {
                                        isReadViewPresented = true
                                    }
                                }
                            }
                        }
                    } else {
                        print("Index parameter not found.")
                    }
                }
            } else if type == "authors" {
                if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                    if let indexParam = components.queryItems?.first(where: { $0.name == "index" })?.value {
                        authorId = indexParam
                        
                        Task {
                            do {
                                authorName = try? await UserManager.shared.getAuthorName(id: authorId)
                                isCheckmark = try? await UserManager.shared.getIsCheckmarkStatus(id: authorId)
                                
                                let authUser = try AuthenticationManager.shared.getAuthenticatedUser()
                                user = try? await UserManager.shared.getUser(userId: authUser.uid)
                                
                                if user != nil && authorName != nil {
                                    isLoadingPopupPresented = false
                                    isChannelViewPresented = true
                                }
                            }
                        }
                        
                    } else {
                        print("Index parameter not found.")
                    }
                }
            }
            
        }
        .onChange(of: isNotificationPopupPresented) {
            if !isNotificationPopupPresented {
                StorageManager.shared.setNotificationsPopupShowed(true)
            }
        }
        .fullScreenCover(isPresented: $isReadViewPresented, content: {
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
                user: $user,
                isChannelViewPresented: $isChannelViewPresented
            )
            .tint(Color(uiColor: .label))
            .environmentObject(sessionManager)
            .environmentObject(changedPostsManager)
        })
        .fullScreenCover(isPresented: $isChannelViewPresented, content: {
            ChannelView(
                user: $user,
                authorId: authorId,
                authorName: authorName ?? "",
                isCheckmark: isCheckmark ?? false
            )
            .tint(Color(uiColor: .label))
            .environmentObject(sessionManager)
            .environmentObject(changedPostsManager)
        })
        .fullScreenCover(isPresented: $isWelcomeViewPresented, content: {
            WelcomeView(isSignInViewPreseted: $isWelcomeViewPresented)
        })
        .popup(isPresented: $isLoadingPopupPresented) {
            LoadingPopup()
        } customize: {
            $0
                .type(.toast)
                .appearFrom(.bottomSlide)
                .displayMode(.overlay)
        }
        .popup(isPresented: $isNotificationPopupPresented) {
            NotificationPermissionView(
                isPopupPresented: $isNotificationPopupPresented,
                route: .requestSystemPrompt
            )
            .shadow(radius: 2)
        } customize: {
            $0
                .type(.toast)
                .appearFrom(.bottomSlide)
                .dragToDismiss(true)
                .displayMode(.overlay)
        }
        .popup(isPresented: $isVersionPopupPresented) {
            VersionPopupView(isCritical: relevantVersion?.isCritical ?? false)
                .shadow(radius: 2)
        } customize: {
            $0
                .type(.toast)
                .appearFrom(.bottomSlide)
                .dragToDismiss(!(relevantVersion?.isCritical ?? true))
                .displayMode(.overlay)  
        }
    }
}

private extension RootView {
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
                    self.isVersionPopupPresented = true
                    self.isUpdatePopupDidPresented = true
                    
                    let isCritical = version.isCritical ?? false
                    withAnimation {
                        self.isUpdateBlur = isCritical
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
