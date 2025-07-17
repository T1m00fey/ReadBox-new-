//
//  ChannelViewModel.swift
//  ReadBox
//
//  Created by Тимофей Юдин on 24.05.2025.
//

import SwiftUI

@MainActor
final class ChannelViewModel: ObservableObject {
    @Published var postsNeedToLoad: [String] = []
    @Published var isLoading = true
    @Published var posts: [PrePost] = []
    @Published var errorText = ""
    @Published var isErrorPopupPresented = false
    @Published var postOption = PostOptions.nothing
    @Published var id = ""
    @Published var isDescriptionPopupPresented = false
    @Published var isReadViewPresented = false
    @Published var subscribersCount = 0
    @Published var authorDescription = ""
    @Published var isSubscribed: Bool? = nil
    @Published var postsCount = 0
    @Published var views: [String] = []
    @Published var isLoadingPopupPresented = false
    @Published var isLoadingShowing = true
    
    var description = ""
    
    func getViews() {
        views = StorageManager.shared.getViews()
    }
    
    func saveViews() {
        StorageManager.shared.save(views: views)
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
    
    func loadPostsIndexes(id: String) async throws {
        let indexes = try await UserManager.shared.getAuthorsCreatedPosts(id: id) ?? []
        postsNeedToLoad = indexes.reversed()
        
        if postsNeedToLoad != [] {
            try await loadPosts()
        } else {
            withAnimation {
                isLoading = false
            }
        }
    }
    
    func getSubscribersCount(authorId: String) async throws {
        subscribersCount = try await UserManager.shared.getSubscribersCount(authorId: authorId)
    }
    
    func getPostsCount(authorId: String) async throws {
        postsCount = try await UserManager.shared.getPostsCount(authorId: authorId)
    }
    
    func getAuthorDescription(id: String) async throws {
        authorDescription = try await UserManager.shared.getAuthorDescription(id: id)
    }
    
    func loadPosts() async throws {
        var count = 0
        
        for index in postsNeedToLoad {
            if count < 20 && postsNeedToLoad != [] {
                do {
                    let isArchive = try await ArticlesManager.shared.getIsArchive(of: index)
                    
                    if !isArchive {
                        let post = try await ArticlesManager.shared.getPrePost(id: index)
                        
                        withAnimation {
                            posts.append(post)
                            isLoadingShowing = false
                        }
                        
                        count += 1
                    }
                    
                    postsNeedToLoad.removeAll { $0 == index }
                    print("Channel post index: \(index)")
                } catch {
                    withAnimation {
                        errorText = NSLocalizedString("someArticlesNotFoundLabel", comment: "")
                        isErrorPopupPresented = true
                    }
                }
            }
        }
        
        withAnimation {
            isLoading = false
        }

    }
}
