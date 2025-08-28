//
//  UserManager.swift
//  Readify
//
//  Created by Тимофей Юдин on 27.10.2024.
//

import Foundation
import FirebaseFirestore

final class UserManager {
    
    static let shared = UserManager()
    private init() {}
    
    private let userCollection = Firestore.firestore().collection("users")
    
    private let encoder: Firestore.Encoder = {
        let encoder = Firestore.Encoder()
        return encoder
    }()
    
    private let decoder: Firestore.Decoder = {
        let decoder = Firestore.Decoder()
        return decoder
    }()
    
    private func userDocument(userId: String) -> DocumentReference? {
        if userId != "" {
            return userCollection.document(userId)
        }
        
        return nil
    }
    
    func createNewUser(user: DBUser) async throws {
        try userDocument(userId: user.userId)?.setData(from: user, merge: false)
    }
    
    func deleteUser(user: DBUser) async throws {
        try await userDocument(userId: user.userId)?.delete()
    }
    
    func getUser(userId: String) async throws -> DBUser? {
        try await userDocument(userId: userId)?.getDocument(as: DBUser.self)
    }

    func set(fcmToken: String, to userId: String) async throws {
        let data: [String: Any] = [
            "fcm_token": fcmToken
        ]
        
        try await userDocument(userId: userId)?.updateData(data)
    }
    
    func set(appVersion: String, to userId: String) async throws {
        let data: [String: Any] = [
            "app_version": appVersion
        ]
        
        try await userDocument(userId: userId)?.updateData(data)
    }
    
    func deleteFcmToken(from userId: String) async throws {
        try await userDocument(userId: userId)?.updateData(
            [
                "fcm_token": FieldValue.delete()
            ]
        )
    }
    
    func setOriginalLanguage(to userId: String) async throws {
        let local = Locale.preferredLanguages.first?.components(separatedBy: "-").first == "ru"
        ? "ru"
        : "en"
        
        let data: [String: Any] = [
            "original_language": local
        ]
        
        try await userDocument(userId: userId)?.updateData(data)
    }
    
    func getAuthorName(id: String) async throws -> String? {
        if id != "" {
            return try await userDocument(userId: id)?.getDocument(as: AuthorName.self).name
        } else {
            return nil
        }
    }
    
    func getAuthorDescription(id: String) async throws -> String {
        try await userDocument(userId: id)?.getDocument(as: AuthorDescription.self).authorDescription ?? NSLocalizedString("notFoundLabel", comment: "")
    }
    
    func getIsCheckmarkStatus(id: String) async throws -> Bool? {
        if id != "" {
            return try await userDocument(userId: id)?.getDocument(as: IsCheckmark.self).isCheckmark ?? false
        } else {
            return nil
        }
    }
    
//    func getAuthorsCreatedPosts(id: String) async throws -> [String]? {
//        try await userDocument(userId: id)?.getDocument(as: CreatedPosts.self).createdPosts
//    }
    
    func deleteCreatedPost(id: String) async throws {
        let userId = try? AuthenticationManager.shared.getAuthenticatedUser().uid
        
        let data: [String: Any] = [
            "created_posts": FieldValue.arrayRemove([id])
        ]
        
        try await userDocument(userId: userId ?? "")?.updateData(data)
    }
    
    func plusReadArticle(userId: String, articlesRead: Int) async throws {
        let data: [String: Any] = [
            "articles_read": articlesRead + 1
        ]
        
        try await userDocument(userId: userId)?.updateData(data)
    }
    
    func getSubscribersCount(authorId: String) async throws -> Int {
        try await userDocument(userId: authorId)?.getDocument(as: SubscribersCount.self).subscribersCount ?? 0
    }
    
    func getPostsCount(authorId: String) async throws -> Int {
        try await userDocument(userId: authorId)?.getDocument(as: PostsCount.self).postsCount ?? 0
    }
    
    func updatePostsCount(userId: String, postsCount: Int) async throws {
        let data: [String: Any] = [
            "posts_count": postsCount
        ]
        
        try await userDocument(userId: userId)?.updateData(data)
    }
    
    func addLikedPost(id: String, likedPost: String) async throws {
        let data: [String: Any] = [
            "liked_posts": FieldValue.arrayUnion([likedPost])
        ]
        
        try await userDocument(userId: id)?.updateData(data)
    }
    
    func removeLikedPost(id: String, likedPost: String) async throws {
        let data: [String: Any] = [
            "liked_posts": FieldValue.arrayRemove([likedPost])
        ]
        
        try await userDocument(userId: id)?.updateData(data)
    }
    
    func changeName(userID: String, to name: String) async throws {
        let data: [String: Any] = [
            "name": name
        ]
        
        try await userDocument(userId: userID)?.updateData(data)
    }
    
    func changeAuthorName(userId: String, to name: String, description: String) async throws {
        let data: [String: Any] = [
            "name": name,
            "author_description": description
        ]
        
        try await userDocument(userId: userId)?.updateData(data)
    }
    
    func removeCheckmarkStatus(userId: String) async throws {
        let data: [String: Any] = [
            "is_checkmark": false
        ]
        
        try await userDocument(userId: userId)?.updateData(data)
    }
    
//    func updateCreatedPosts(newPost: String) async throws {
//        let userId = try? AuthenticationManager.shared.getAuthenticatedUser().uid
//        
//        let data: [String: Any] = [
//            "created_posts": FieldValue.arrayUnion([newPost])
//        ]
//        
//        try await userDocument(userId: userId ?? "")?.updateData(data)
//    }
    
    func un_subscribeUser(on id: String, isNeedToSubscribe: Bool) async throws {
        let userId = try? AuthenticationManager.shared.getAuthenticatedUser().uid
        
        let subsCount = try await getUser(userId: id)?.subscribersCount ?? 0
    
        if isNeedToSubscribe {
            try await userDocument(userId: userId ?? "")?.updateData(["subscribes": FieldValue.arrayUnion([id])])
            try await userDocument(userId: id)?.updateData(["subscribers_count": subsCount + 1])
        } else {
            try await userDocument(userId: userId ?? "")?.updateData(["subscribes": FieldValue.arrayRemove([id])])
            try await userDocument(userId: id)?.updateData(["subscribers_count": subsCount - 1])
        }
    }
}
