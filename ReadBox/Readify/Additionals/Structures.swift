//
//  Structures.swift
//  ReadBox
//
//  Created by Тимофей Юдин on 02.06.2025.
//

import SwiftUI
import Firebase

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

struct AuthorDescription: Codable {
    let authorDescription: String?
    
    enum CodingKeys: String, CodingKey {
        case authorDescription = "author_description"
    }
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
    var subscribes: [String]?
    var authorDescription: String?
    let postsCount: Int?
    let fcmToken: String?
    let appVersion: String?
    
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
        self.fcmToken = ""
        self.appVersion = ""
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
        postsCount: Int? = nil,
        fcmToken: String? = nil,
        appVersion: String? = nil
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
        self.fcmToken = fcmToken
        self.appVersion = appVersion
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
        case fcmToken = "fcm_token"
        case appVersion = "app_version"
    }
}


struct ArticleImage: Codable {
    let id: String
    let image: Data?
}

struct PrePost: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let title: String?
    let authorId: String?
    let viewsCount: Int?
    let likesCount: Int?
    var isArchive: Bool?
    
    init?(document: DocumentSnapshot) {
        let data = document.data()
        
        guard
            let id = data?["id"] as? String,
            let title = data?["title"] as? String,
            let authorId = data?["author_id"] as? String,
            let viewsCount = data?["views_count"] as? Int,
            let likesCount = data?["likes_count"] as? Int,
            let isArchive = data?["is_archive"] as? Bool
        else {
            return nil
        }
        
        self.id = id
        self.title = title
        self.authorId = authorId
        self.viewsCount = viewsCount
        self.likesCount = likesCount
        self.isArchive = isArchive
    }
    
    init(
        id: String,
        title: String?,
        authorId: String?,
        viewsCount: Int?,
        likesCount: Int?,
        isArchive: Bool? = nil
    ) {
        self.id = id
        self.title = title
        self.authorId = authorId
        self.viewsCount = viewsCount
        self.likesCount = likesCount
        self.isArchive = isArchive
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case title = "title"
        case likesCount = "likes_count"
        case authorId = "author_id"
        case viewsCount = "views_count"
        case isArchive = "is_archive"
    }
}

struct PostToRead: Codable {
    let dateCreated: Date?
    let text: String?
    let description: String?
    
    enum CodingKeys: String, CodingKey {
        case dateCreated = "date_created"
        case text = "text"
        case description = "description"
    }
}

struct ViewsCount: Codable {
    let viewsCount: Int
    
    enum CodingKeys: String, CodingKey {
        case viewsCount = "views_count"
    }
}

struct TopArticlesIndexes: Codable {
    let topArticlesIndexes: [String]?
    
    enum CodingKeys: String, CodingKey {
        case topArticlesIndexes = "top_articles_indexes"
    }
}

struct OriginalLanguage: Codable {
    let originalLanguage: String?
    
    enum CodingKeys: String, CodingKey {
        case originalLanguage = "original_language"
    }
}

struct MaxIndex: Codable {
    let maxIndex: String
    
    enum CodingKeys: String, CodingKey {
        case maxIndex = "max_index"
    }
}

struct isArchive: Codable {
    let isArchive: Bool?
    
    enum CodingKeys: String, CodingKey {
        case isArchive = "is_archive"
    }
}

struct AuthorId: Codable {
    let authorId: String?
    
    enum CodingKeys: String, CodingKey {
        case authorId = "author_id"
    }
}

struct LikesCount: Codable {
    let likesCount: Int?
    
    enum CodingKeys: String, CodingKey {
        case likesCount = "likes_count"
    }
}

struct AppVersion: Codable {
    let appVersion: String?
    let isCritical: Bool?
    
    enum CodingKeys: String, CodingKey {
        case appVersion = "app_version"
        case isCritical = "is_critical"
    }
}

