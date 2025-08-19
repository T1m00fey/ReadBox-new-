//
//  RootView.swift
//  Readify
//
//  Created by Тимофей Юдин on 27.10.2024.
//

import SwiftUI
import FirebaseStorage
import PopupView

struct RootView: View {
    @State private var isReadViewPresented = false
    @State private var user: DBUser? = nil
    @State private var prePost: PrePost? = nil
    @State private var postToRead: PostToRead? = nil
    @State private var authorName: String? = ""
    @State private var isCheckmark: Bool? = false
    @State private var likedPosts: [String] = []
    @State private var isChannelViewPresented = false
    @State private var isWelcomeViewPresented = false
    @State private var postToView: PrePost? = nil
    @State private var authorId = ""
    @State private var isLoadingPopupPresented = false
    @State private var isDescriptionPopupPresented = false
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            if let _ = try? AuthenticationManager.shared.getAuthenticatedUser() {
                TabView {
                    FeedView(isWelcomeViewPresented: $isWelcomeViewPresented)
                        .tabItem {
                            Label("", systemImage: "house.fill")
                        }
                    
                    LikedPostsView(isWelcomeViewPresented: $isWelcomeViewPresented)
                        .tabItem {
                            Label("", systemImage: "hand.thumbsup.fill")
                        }
                    
                    CreatedPostsView(isWelcomeViewPresented: $isWelcomeViewPresented)
                        .tabItem {
                            Label("", systemImage: "pencil.and.scribble")
                        }
                    
                    ProfileView(isWelcomeViewPresented: $isWelcomeViewPresented)
                        .tabItem {
                            Label("", systemImage: "person.fill")
                        }
                }
                .tint(Color(uiColor: .label))
                .onAppear {
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                        print("Permission granted: \(granted)")
                    }                                        
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
                    
                    if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {                        
                        try? await UserManager.shared.set(
                            appVersion: appVersion,
                            to: user?.userId ?? ""
                        )
                    }
                    
                    if StorageManager.shared.getLanguage() == "en" && !(user?.subscribes?.contains (
                        "qDWmcGOLPGVAzJth2I8G2cwcp9x1"
                    ) ?? true) {
                        
                        try? await UserManager.shared.un_subscribeUser(
                            on: "qDWmcGOLPGVAzJth2I8G2cwcp9x1",
                            isNeedToSubscribe: true
                        )
                        
                        user?.subscribes?.append("qDWmcGOLPGVAzJth2I8G2cwcp9x1")
                        
                    } else if StorageManager.shared.getLanguage() == "ru" && !(user?.subscribes?.contains(
                        "se8Any2drmcQg1sFoLXYXo4ttYt2"
                    ) ?? true) {
                        
                        try? await UserManager.shared.un_subscribeUser(
                            on: "se8Any2drmcQg1sFoLXYXo4ttYt2",
                            isNeedToSubscribe: true
                        )
                        
                        user?.subscribes?.append("se8Any2drmcQg1sFoLXYXo4ttYt2")
                        
                    }
                } else {
                    isWelcomeViewPresented = true
                }
            }
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
                                prePost = try? await ArticlesManager.shared.getPrePost(id: index)
                                postToRead = try? await ArticlesManager.shared.getPostToRead(id: index)
                                authorName = try? await UserManager.shared.getAuthorName(id: prePost?.authorId ?? "")
                                isCheckmark = try? await UserManager.shared.getIsCheckmarkStatus(id: prePost?.authorId ?? "")
                                
                                isLoadingPopupPresented = false
                                
                                let authUser = try AuthenticationManager.shared.getAuthenticatedUser()
                                user = try? await UserManager.shared.getUser(userId: authUser.uid)
                                
                                if user != nil {
                                    likedPosts = user?.likedPosts ?? []
                                    
                                    isReadViewPresented = true
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
                                
                                if user != nil {
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
        .onChange(of: postToView) {
            isLoadingPopupPresented = true
            
            Task {
                prePost = try? await ArticlesManager.shared.getPrePost(id: postToView?.id ?? "")
                postToRead = try? await ArticlesManager.shared.getPostToRead(id: postToView?.id ?? "")
                authorName = try? await UserManager.shared.getAuthorName(id: prePost?.authorId ?? "")
                isCheckmark = try? await UserManager.shared.getIsCheckmarkStatus(id: prePost?.authorId ?? "")
                
                isLoadingPopupPresented = false
                isReadViewPresented = true
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
                user: $user,
                isChannelViewPresented: $isChannelViewPresented
            )
            .tint(Color(uiColor: .label))
        })
        .fullScreenCover(isPresented: $isChannelViewPresented, content: {
            ChannelView(
                user: $user,
                authorId: prePost?.authorId ?? "",
                authorName: authorName ?? "",
                isCheckmark: isCheckmark ?? false,
                postToView: $postToView,
                postToRead: $postToRead
            )
            .tint(Color(uiColor: .label))
        })
        .fullScreenCover(isPresented: $isWelcomeViewPresented, content: {
            WelcomeView(isSignInViewPreseted: $isWelcomeViewPresented)
        })
        .popup(isPresented: $isLoadingPopupPresented) {
            LoadingPopup()
                .shadow(radius: 3)
        } customize: {
            $0
                .type(.toast)
                .appearFrom(.bottomSlide)
        }
        
    }
}

#Preview {
    RootView()
}
