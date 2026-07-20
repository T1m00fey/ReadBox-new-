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
    let originalLanguage: String?
    let dateCreated: Date?
    let viewsCount: Int?
    let likesCount: Int?
    let commentsCount: Int?
    var isArchive: Bool?
    var isShortPost: Bool?
    let mediaCount: Int?
    let mediaVersion: Int?
    let mediaPosition: Int?
    let localizationCount: Int?
    let isLocalizedVersion: Bool?
    let rootId: String?
    let isPremiumPost: Bool?

    var repliesCount: Int {
        commentsCount ?? 0
    }

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
        self.originalLanguage = data?["original_language"] as? String
        self.dateCreated = (data?["date_created"] as? Timestamp)?.dateValue() ?? data?["date_created"] as? Date
        self.viewsCount = viewsCount
        self.likesCount = likesCount
        self.commentsCount = data?["comments_count"] as? Int
        self.isArchive = isArchive
        self.isShortPost = data?["is_short_post"] as? Bool
        self.mediaCount = data?["media_count"] as? Int
        self.mediaVersion = data?["media_version"] as? Int
        self.mediaPosition = data?["media_position"] as? Int
        self.localizationCount = data?["localization_count"] as? Int
        self.isLocalizedVersion = data?["is_localized_version"] as? Bool
        self.rootId = data?["root_id"] as? String
        self.isPremiumPost = data?["is_premium_post"] as? Bool
    }

    init(
        id: String,
        title: String?,
        authorId: String?,
        originalLanguage: String? = nil,
        dateCreated: Date? = nil,
        viewsCount: Int?,
        likesCount: Int?,
        commentsCount: Int? = nil,
        isArchive: Bool? = nil,
        isShortPost: Bool?,
        mediaCount: Int?,
        mediaVersion: Int?,
        mediaPosition: Int?,
        localizationCount: Int?,
        isLocalizedVersion: Bool?,
        rootId: String? = nil,
        isPremiumPost: Bool? = false
    ) {
        self.id = id
        self.title = title
        self.authorId = authorId
        self.originalLanguage = originalLanguage
        self.dateCreated = dateCreated
        self.viewsCount = viewsCount
        self.likesCount = likesCount
        self.commentsCount = commentsCount
        self.isArchive = isArchive
        self.isShortPost = isShortPost
        self.mediaCount = mediaCount
        self.mediaVersion = mediaVersion
        self.mediaPosition = mediaPosition
        self.localizationCount = localizationCount
        self.isLocalizedVersion = isLocalizedVersion
        self.rootId = rootId
        self.isPremiumPost = isPremiumPost
    }

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case title = "title"
        case likesCount = "likes_count"
        case authorId = "author_id"
        case originalLanguage = "original_language"
        case dateCreated = "date_created"
        case viewsCount = "views_count"
        case commentsCount = "comments_count"
        case isArchive = "is_archive"
        case isShortPost = "is_short_post"
        case mediaCount = "media_count"
        case mediaVersion = "media_version"
        case mediaPosition = "media_position"
        case localizationCount = "localization_count"
        case isLocalizedVersion = "is_localized_version"
        case rootId = "root_id"
        case isPremiumPost = "is_premium_post"
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

struct LocalizationCount: Codable {
    let localizationCount: Int

    enum CodingKeys: String, CodingKey {
        case localizationCount = "localization_count"
    }
}

struct IsPremiumAuthor: Codable {
    let isPremiumAuthor: Bool?

    enum CodingKeys: String, CodingKey {
        case isPremiumAuthor = "is_premium_author"
    }
}

struct Comment: Identifiable, Codable {
    let id: String
    let text: String?
    let dateCreated: Date?
    let authorId: String?
    let rootAuthorId: String?
    let rootPostId: String?
    let viewsCount: Int?
    let likesCount: Int?
    let repliesCount: Int?

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case text = "text"
        case dateCreated = "date_created"
        case authorId = "author_id"
        case rootAuthorId = "root_author_id"
        case rootPostId = "root_post_id"
        case viewsCount = "views_count"
        case likesCount = "likes_count"
        case repliesCount = "replies_count"
    }
}

struct CommentsCount: Codable {
    let commentsCount: Int?

    enum CodingKeys: String, CodingKey {
        case commentsCount = "comments_count"
    }
}

//struct WorldNewsItem: Identifiable, Codable {
//    let id: String
//    let provider: String?
//    let language: String?
//    let title: String?
//    let descriptionText: String?
//    let content: String?
//    let url: String?
//    let imageURL: String?
//    let sourceName: String?
//    let domainURL: String?
//    let publishedAt: Date?
//    let sortIndex: Int?
//
//    enum CodingKeys: String, CodingKey {
//        case id = "id"
//        case provider = "provider"
//        case language = "language"
//        case title = "title"
//        case descriptionText = "description"
//        case content = "content"
//        case url = "url"
//        case imageURL = "image_url"
//        case sourceName = "source_name"
//        case domainURL = "domain_url"
//        case publishedAt = "published_at"
//        case sortIndex = "sort_index"
//    }
//}

enum NotificationPushRoute: Codable {
    case requestSystemPrompt
    case goToSettings
    case ok
}

enum InAppNotificationType: String, Codable {
    case postLiked = "post_liked"
    case userSubscribed = "user_subscribed"
    case commentAdded = "comment_added"
    case commentReply = "comment_reply"
}

struct PersonalNotificationItem: Identifiable, Codable {
    let id: String
    let userId: String?
    let typeRawValue: String?
    let actorId: String?
    let postId: String?
    let dateCreated: Date?
    let expiresAt: Date?

    var type: InAppNotificationType? {
        guard let typeRawValue else { return nil }
        return InAppNotificationType(rawValue: typeRawValue)
    }

    init(
        id: String,
        userId: String?,
        typeRawValue: String?,
        actorId: String?,
        postId: String?,
        dateCreated: Date?,
        expiresAt: Date?
    ) {
        self.id = id
        self.userId = userId
        self.typeRawValue = typeRawValue
        self.actorId = actorId
        self.postId = postId
        self.dateCreated = dateCreated
        self.expiresAt = expiresAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case typeRawValue = "type"
        case actorId = "actor_id"
        case postId = "post_id"
        case dateCreated = "date_created"
        case expiresAt = "expires_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(String.self, forKey: .id) ?? ""
        userId = try container.decodeIfPresent(String.self, forKey: .userId)
        typeRawValue = try container.decodeIfPresent(String.self, forKey: .typeRawValue)
        actorId = try container.decodeIfPresent(String.self, forKey: .actorId)
        postId = try container.decodeIfPresent(String.self, forKey: .postId)
        dateCreated = try container.decodeIfPresent(Date.self, forKey: .dateCreated)
        expiresAt = try container.decodeIfPresent(Date.self, forKey: .expiresAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(userId, forKey: .userId)
        try container.encodeIfPresent(typeRawValue, forKey: .typeRawValue)
        try container.encodeIfPresent(actorId, forKey: .actorId)
        try container.encodeIfPresent(postId, forKey: .postId)
        try container.encodeIfPresent(dateCreated, forKey: .dateCreated)
        try container.encodeIfPresent(expiresAt, forKey: .expiresAt)
    }
}
