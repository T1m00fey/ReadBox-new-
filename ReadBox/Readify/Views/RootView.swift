//
//  RootView.swift
//  Readify
//
//  Created by Тимофей Юдин on 27.10.2024.
//

import SwiftUI
import FirebaseStorage

struct RootView: View {
    @State private var isSignInViewPresented = false
    @State private var isReadViewPresented = false
    @State private var user: DBUser? = nil
    @State private var post: Article? = nil
    @State private var authorName: String? = ""
    @State private var isCheckmark = false
    @State private var likedPosts: [String] = []
    @State private var isNeedToLoadUser = false
    @State private var isChannelViewPresented = false
    
    var body: some View {
        ZStack {
            TabView {
                FeedView()
                    .tabItem {
                        Label("", systemImage: "house.fill")
                    }
                
                LikedPostsView()
                    .tabItem {
                        Label("", systemImage: "hand.thumbsup.fill")
                    }
                
                CreatedPostsView()
                    .tabItem {
                        Label("", systemImage: "pencil.and.scribble")
                    }
                
                ProfileView(isSignInViewPresented: $isSignInViewPresented)
                    .tabItem {
                        Label("", systemImage: "person.fill")
                    }
            }
            .tint(Color(uiColor: .label))
        }
        .onOpenURL { url in
            isReadViewPresented = false
            
            Task {
                post = try? await ArticlesManager.shared.getArticle(id: url.absoluteString.components(separatedBy: "/").last ?? "")
                authorName = try? await UserManager.shared.getAuthorName(id: post?.authorId ?? "")
                isCheckmark = ((try? await UserManager.shared.getIsCheckmarkStatus(id: post?.authorId ?? "")) != nil)
                
                let authUser = try AuthenticationManager.shared.getAuthenticatedUser()
                user = try? await UserManager.shared.getUser(userId: authUser.uid)
                
                isSignInViewPresented = user == nil
            }
            
            likedPosts = user?.likedPosts ?? []
            
        }
        .onChange(of: authorName) { newValue in
            if authorName != "" {
                isReadViewPresented = true
            }
        }
        .onChange(of: isReadViewPresented) { newValue in
            if !newValue {
                authorName = ""
            }
        }
        .fullScreenCover(isPresented: $isReadViewPresented, content: {
            ReadView(
                id: post?.id ?? "",
                userId: user?.userId ?? "",
                title: post?.title ?? NSLocalizedString("notFoundLabel", comment: ""),
                text: post?.text ?? NSLocalizedString("notFoundLabel", comment: ""),
                dateCreated: post?.dateCreated ?? Date(),
                likesCount: post?.likesCount ?? 0,
                authorName: authorName ?? "",
                isCheckmark: isCheckmark,
                likedPosts: $likedPosts,
                isChannelViewPresented: $isChannelViewPresented
            )
            .tint(Color(uiColor: .label))
        })
        .onAppear {
            Task {
                let authUser = try AuthenticationManager.shared.getAuthenticatedUser()
                self.user = try? await UserManager.shared.getUser(userId: authUser.uid)
                self.isSignInViewPresented = user == nil
            }
        }
        .fullScreenCover(isPresented: $isSignInViewPresented) {
            SignInView(isPresented: $isSignInViewPresented)
        }
    }
}

#Preview {
    RootView()
}
