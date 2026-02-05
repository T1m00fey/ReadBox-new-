//
//  Structures.swift
//  ReadBox
//
//  Created by Тимофей Юдин on 02.06.2025.
//

import SwiftUI
import Firebase

struct MediaKind {
    let videoURL: URL?
    let image: UIImage?
    let videoPreview: UIImage?
    
    init(
        videoURL: URL? = nil,
        image: UIImage? = nil,
        videoPreview: UIImage? = nil
    ) {
        self.videoURL = videoURL
        self.image = image
        self.videoPreview = videoPreview
    }
}

struct AuthorName: Codable {
    let name: String?
    
    enum CodingKeys: String, CodingKey {
        case name
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

struct AuthorDescription: Codable {
    let authorDescription: String?
    
    enum CodingKeys: String, CodingKey {
        case authorDescription = "author_description"
    }
}

struct DBUser: Codable, Equatable {
    let userId: String
    var name: String?
    let email: String?
    let dateCreated: Date?
    var likedPosts: [String]?
    let isCheckmark: Bool?
    let subscribersCount: Int?
    var subscribes: [String]?
    var authorDescription: String?
    let postsCount: Int?
    let fcmToken: String?
    let appVersion: String?
    let originalLanguage: String?
    let avatarVersion: Int?
    
    init(auth: AuthDataResultModel) {
        self.userId = auth.uid
        self.name = ""
        self.email = auth.email
        self.dateCreated = Date()
        self.likedPosts = []
        self.isCheckmark = false
        self.subscribes = []
        self.subscribersCount = 0
        self.authorDescription = ""
        self.postsCount = 0
        self.fcmToken = ""
        self.appVersion = ""
        self.originalLanguage = ""
        self.avatarVersion = 0
    }
    
    init(
        userId: String,
        name: String? = nil,
        email: String? = nil,
        dateCreated: Date? = nil,
        likedPosts: [String]? = nil,
        isCheckmark: Bool? = nil,
        createdPosts: [String]? = nil,
        subscribersCount: Int? = nil,
        subscribes: [String]? = nil,
        authorDescription: String? = nil,
        postsCount: Int? = nil,
        fcmToken: String? = nil,
        appVersion: String? = nil,
        originalLanguage: String? = nil,
        avatarVersion: Int? = 0
    ) {
        self.userId = userId
        self.name = name
        self.email = email
        self.dateCreated = dateCreated
        self.likedPosts = likedPosts
        self.isCheckmark = isCheckmark
        self.subscribersCount = subscribersCount
        self.subscribes = subscribes
        self.authorDescription = authorDescription
        self.postsCount = postsCount
        self.fcmToken = fcmToken
        self.appVersion = appVersion
        self.originalLanguage = originalLanguage
        self.avatarVersion = avatarVersion
    }
    
    enum CodingKeys: String, CodingKey {
        case userId = "id"
        case name = "name"
        case email = "email"
        case dateCreated = "date_created"
        case likedPosts = "liked_posts"
        case isCheckmark = "is_checkmark"
        case subscribes = "subscribes"
        case subscribersCount = "subscribers_count"
        case authorDescription = "author_description"
        case postsCount = "posts_count"
        case fcmToken = "fcm_token"
        case appVersion = "app_version"
        case originalLanguage = "original_language"
        case avatarVersion = "avatar_version"
    }
}

struct ChannelInfo: Codable {
    let id: String
    let name: String?
    let isCheckmark: Bool?
    let avatarVersion: Int?
    
    init?(document: DocumentSnapshot) {
        let data = document.data()
        
        guard
            let id = data?["id"] as? String,
            let name = data?["name"] as? String,
            let isCheckmark = data?["is_checkmark"] as? Bool
        else {
            return nil
        }
        
        self.id = id
        self.name = name
        self.isCheckmark = isCheckmark
        self.avatarVersion = data?["avatarVersion"] as? Int
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case name = "name"
        case isCheckmark = "is_checkmark"
        case avatarVersion = "avatar_version"
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
    var isShortPost: Bool?
    let mediaCount: Int?
    let mediaVersion: Int?
    let mediaPosition: Int?
    
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
        self.isShortPost = data?["is_short_post"] as? Bool
        self.mediaCount = data?["media_count"] as? Int
        self.mediaVersion = data?["media_version"] as? Int
        self.mediaPosition = data?["media_position"] as? Int
    }
    
    init(
        id: String,
        title: String?,
        authorId: String?,
        viewsCount: Int?,
        likesCount: Int?,
        isArchive: Bool? = nil,
        isShortPost: Bool?,
        mediaCount: Int?,
        mediaVersion: Int?,
        mediaPosition: Int?
    ) {
        self.id = id
        self.title = title
        self.authorId = authorId
        self.viewsCount = viewsCount
        self.likesCount = likesCount
        self.isArchive = isArchive
        self.isShortPost = isShortPost
        self.mediaCount = mediaCount
        self.mediaVersion = mediaVersion
        self.mediaPosition = mediaPosition
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case title = "title"
        case likesCount = "likes_count"
        case authorId = "author_id"
        case viewsCount = "views_count"
        case isArchive = "is_archive"
        case isShortPost = "is_short_post"
        case mediaCount = "media_count"
        case mediaVersion = "media_version"
        case mediaPosition = "media_position"
    }
}

struct PostToRead: Codable {
    let dateCreated: Date?
    let text: String?
    let mediaURLs: [String]?
    
    enum CodingKeys: String, CodingKey {
        case dateCreated = "date_created"
        case text = "text"
        case mediaURLs = "media_URLs"
    }
}

struct PostAuthorInfo: Codable {
    let name: String?
    let isCheckmark: Bool?
    let avatarVersion: Int?
    
    enum CodingKeys: String, CodingKey {
        case name = "name"
        case isCheckmark = "is_checkmark"
        case avatarVersion = "avatar_version"
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

struct MediaURLs: Codable {
    let mediaURLs: [String]?
    
    enum CodingKeys: String, CodingKey {
        case mediaURLs = "media_URLs"
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

struct AvatarVersion: Codable {
    let avatarVersion: Int
    
    enum CodingKeys: String, CodingKey {
        case avatarVersion = "avatar_version"
    }
}

enum NotificationPushRoute: Codable {
    case requestSystemPrompt
    case goToSettings
    case ok
}

