//
//  ChannelViewModel.swift
//  ReadBox
//
//  Created by Тимофей Юдин on 24.05.2025.
//

import SwiftUI
import Firebase
import FirebaseStorage
import SwiftfulLoadingIndicators

@MainActor
final class ChannelViewModel: ObservableObject {
    @Published var postsNeedToLoad: [String] = []
    @Published var isLoading = true
    @Published var posts: [PrePost] = []
    @Published var errorText = ""
    @Published var isErrorPopupPresented = false
    @Published var postOption = PostOptions.nothing
    @Published var id = ""
    @Published var isReadViewPresented = false
    @Published var subscribersCount = 0
    @Published var authorDescription = ""
    @Published var isSubscribed: Bool? = nil
    @Published var postsCount = 0
    @Published var views: [String] = []
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
    @Published var isDataLoaded = false
    @Published var isSubscribeLoading = false
    @Published var pushRoute: NotificationPushRoute? = nil
    @Published var isNotificationPopupPresented = false
    
    func getAvatar() {
        DispatchQueue.main.async {
            let storage = Storage.storage()
            let storageRef = storage.reference()
            
            if let image = StorageManager.shared.getImage(id: self.authorId) {
                withAnimation {
                    self.avatarImage = image
                }
            } else {
                let islandRef = storageRef.child("avatars/\(self.authorId).jpg")
                
                islandRef.getData(maxSize: 1 * 5012 * 5012) { data, error in
                    if let data, let image = UIImage(data: data) {
                        withAnimation {
                            self.avatarImage = image
                        }
                        StorageManager.shared.saveImage(id: self.authorId, image: image)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    func buildSubscribeButtonView(_ isSubscribed: Bool) -> some View {
        if isSubscribeLoading {
            LoadingIndicator(
                animation: .circleRunner,
                color: isSubscribed
                ? Color(.label)
                : Color(.systemBackground),
                size: .small,
                speed: .fast
            )
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity)
        } else {
            Text(
                isSubscribed
                ? NSLocalizedString("youSubscribedLabel", comment: "")
                : NSLocalizedString("subscribeLabel", comment: "")
            )
            .foregroundStyle(
                isSubscribed
                ? Color(.label)
                : Color(.systemBackground)
            )
            .font(.system(size: 20))
            .fontDesign(.rounded)
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity)
        }
    }
    
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
    
    func getSubscribersCount(authorId: String) async throws {
        subscribersCount = try await UserManager.shared.getSubscribersCount(authorId: authorId)
    }
    
    func getPostsCount(authorId: String) async throws {
        postsCount = try await UserManager.shared.getPostsCount(authorId: authorId)
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
        
        posts.forEach { post in
            if let post {
                withAnimation {
                    self.posts.append(post)
                    isLoadingShowing = false
                }
            }
        }
        
        self.lastDocument = lastDocument
        
        withAnimation {
            isLoading = false
        }
    }
}
