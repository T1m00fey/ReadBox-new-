//
//  UserManager.swift
//  Readify
//
//  Created by Тимофей Юдин on 27.10.2024.
//

import Foundation
import FirebaseFirestore

struct AuthorName: Codable {
    let authorName: String?
    
    enum CodingKeys: String, CodingKey {
        case authorName = "author_name"
    }
}

struct SubscribersCount : Codable {
    let subscribersCount: Int?
    
    enum CodingKeys: String, CodingKey {
        case subscribersCount = "subscribers_count"
    }
}

struct PostsCount: Codable {
    let postsCount: Int?
    
    enum CodingKeys: String, CodingKey {
        case postsCount = "posts_count"
    }
}

struct IsCheckmark: Codable {
    let isCheckmark: Bool?
    
    enum CodingKeys: String, CodingKey {
        case isCheckmark = "is_checkmark"
    }
}

struct CreatedPosts: Codable {
    let createdPosts: [String]?
    
    enum CodingKeys: String, CodingKey {
        case createdPosts = "created_posts"
    }
}

struct Notifications: Codable {
    let notifications: [String]?
}

struct DBUser: Codable, Equatable {
    let userId: String
    let name: String?
    let email: String?
    let dateCreated: Date?
    let likedPosts: [String]?
    var authorName: String?
    let isCheckmark: Bool?
    let createdPosts: [String]?
    let subscribersCount: Int?
    let subscribes: [String]?
    let authorDescription: String?
    let postsCount: Int?
    
    init(auth: AuthDataResultModel) {
        self.userId = auth.uid
        self.name = ""
        self.email = auth.email
        self.dateCreated = Date()
        self.likedPosts = []
        self.authorName = ""
        self.isCheckmark = false
        self.createdPosts = []
        self.subscribes = []
        self.subscribersCount = 0
        self.authorDescription = ""
        self.postsCount = 0
    }
    
    init(
        userId: String,
        name: String? = nil,
        email: String? = nil,
        dateCreated: Date? = nil,
        likedPosts: [String]? = nil,
        authorName: String? = nil,
        isCheckmark: Bool? = nil,
        createdPosts: [String]? = nil,
        subscribersCount: Int? = nil,
        subscribes: [String]? = nil,
        authorDescription: String? = nil,
        postsCount: Int? = nil
    ) {
        self.userId = userId
        self.name = name
        self.email = email
        self.dateCreated = dateCreated
        self.likedPosts = likedPosts
        self.authorName = authorName
        self.isCheckmark = isCheckmark
        self.createdPosts = createdPosts
        self.subscribersCount = subscribersCount
        self.subscribes = subscribes
        self.authorDescription = authorDescription
        self.postsCount = postsCount
    }
    
    enum CodingKeys: String, CodingKey {
        case userId = "id"
        case name = "name"
        case email = "email"
        case dateCreated = "date_created"
        case likedPosts = "liked_posts"
        case authorName = "author_name"
        case isCheckmark = "is_checkmark"
        case createdPosts = "created_posts"
        case subscribes = "subscribes"
        case subscribersCount = "subscribers_count"
        case authorDescription = "author_description"
        case postsCount = "posts_count"
    }
    
//    init(from decoder: any Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        self.userId = try container.decode(String.self, forKey: .userId)
//        self.name = try container.decode(String.self, forKey: .name)
//        self.email = try container.decodeIfPresent(String.self, forKey: .email)
//        self.dateCreated = try container.decodeIfPresent(Date.self, forKey: .dateCreated)
//        self.likedPosts = try container.decodeIfPresent([String].self, forKey: .likedPosts)
//        self.articlesRead = try container.decodeIfPresent(Int.self, forKey: .articlesRead)
//        self.authorName = tr
//    }
//    
//    func encode(to encoder: any Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(self.userId, forKey: .userId)
//        try container.encode(self.name, forKey: .name)
//        try container.encodeIfPresent(self.email, forKey: .email)
//        try container.encodeIfPresent(self.dateCreated, forKey: .dateCreated)
//        try container.encodeIfPresent(self.likedPosts, forKey: .likedPosts)
//        try container.encodeIfPresent(self.articlesRead, forKey: .articlesRead)
//    }
}

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
    
    private func userDocument(userId: String) -> DocumentReference {
        return userCollection.document(userId)
    }
    
    func createNewUser(user: DBUser) async throws {
        try userDocument(userId: user.userId).setData(from: user, merge: false)
    }
    
    func deleteUser(user: DBUser) async throws {
        try await userDocument(userId: user.userId).delete()
    }
    
    func getUser(userId: String) async throws -> DBUser {
        try await userDocument(userId: userId).getDocument(as: DBUser.self)
    }
    
    func getAuthorName(id: String) async throws -> String? {
        if id != "" {
            return try await userDocument(userId: id).getDocument(as: AuthorName.self).authorName
        } else {
            return nil
        }
    }
    
    func getIsCheckmarkStatus(id: String) async throws -> Bool? {
        if id != "" {
            return try await userDocument(userId: id).getDocument(as: IsCheckmark.self).isCheckmark
        } else {
            return nil
        }
    }
    
    func getAuthorsCreatedPosts(id: String) async throws -> [String]? {
        try await userDocument(userId: id).getDocument(as: CreatedPosts.self).createdPosts
    }
    
    func deleteCreatedPost(id: String) async throws {
        let userId = try? AuthenticationManager.shared.getAuthenticatedUser().uid
        
        let data: [String: Any] = [
            "created_posts": FieldValue.arrayRemove([id])
        ]
        
        try await userDocument(userId: userId ?? "").updateData(data)
    }
    
    func plusReadArticle(userId: String, articlesRead: Int) async throws {
        let data: [String: Any] = [
            "articles_read": articlesRead + 1
        ]
        
        try await userDocument(userId: userId).updateData(data)
    }
    
    func getSubscribersCount(authorId: String) async throws -> Int {
        try await userDocument(userId: authorId).getDocument(as: SubscribersCount.self).subscribersCount ?? 0
    }
    
    func getPostsCount(authorId: String) async throws -> Int {
        try await userDocument(userId: authorId).getDocument(as: PostsCount.self).postsCount ?? 0
    }
    
    func updatePostsCount(userId: String, postsCount: Int) async throws {
        let data: [String: Any] = [
            "posts_count": postsCount
        ]
        
        try await userDocument(userId: userId).updateData(data)
    }
    
    func addLikedPost(id: String, likedPost: String) async throws {
        let data: [String: Any] = [
            "liked_posts": FieldValue.arrayUnion([likedPost])
        ]
        
        try await userDocument(userId: id).updateData(data)
    }
    
    func removeLikedPost(id: String, likedPost: String) async throws {
        let data: [String: Any] = [
            "liked_posts": FieldValue.arrayRemove([likedPost])
        ]
        
        try await userDocument(userId: id).updateData(data)
    }
    
    func changeName(userID: String, to name: String) async throws {
        let data: [String: Any] = [
            "name": name
        ]
        
        try await userDocument(userId: userID).updateData(data)
    }
    
    func changeAuthorName(userId: String, to name: String, description: String) async throws {
        let data: [String: Any] = [
            "author_name": name,
            "author_description": description
        ]
        
        try await userDocument(userId: userId).updateData(data)
    }
    
    func removeCheckmarkStatus(userId: String) async throws {
        let data: [String: Any] = [
            "is_checkmark": false
        ]
        
        try await userDocument(userId: userId).updateData(data)
    }
    
    func updateCreatedPosts(newPost: String) async throws {
        let userId = try? AuthenticationManager.shared.getAuthenticatedUser().uid
        
        let data: [String: Any] = [
            "created_posts": FieldValue.arrayUnion([newPost])
        ]
        
        try await userDocument(userId: userId ?? "").updateData(data)
    }
    
}
