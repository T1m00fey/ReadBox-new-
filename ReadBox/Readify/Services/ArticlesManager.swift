//
//  ArticlesManager.swift
//  Readify
//
//  Created by Тимофей Юдин on 05.11.2024.
//

import SwiftUI
import FirebaseFirestore
import FirebaseStorage 

final class ArticlesManager {
    static let shared = ArticlesManager()
    private init() {}
    
    private let articlesCollection = Firestore.firestore().collection("articles")
    
    private func articleDocument(id: String) -> DocumentReference {
        articlesCollection.document(id)
    }
    
    func getPrePost(id: String) async throws -> PrePost {
        try await articleDocument(id: id).getDocument(as: PrePost.self)
    }
    
    func getPostToRead(id: String) async throws -> PostToRead {
        try await articleDocument(id: id).getDocument(as: PostToRead.self)
    }
    
    func getOriginalLanguageOfArticle(id: String) async throws -> String {
        try await articleDocument(id: id).getDocument(as: OriginalLanguage.self).originalLanguage ?? "en"
    }
    
    func getIsArchive(of id: String) async throws -> Bool {
        try await articleDocument(id: id).getDocument(as: isArchive.self).isArchive ?? true
    }
    
    func getLikesCount(byPostId id: String) async throws -> Int {
        try await articleDocument(id: id).getDocument(as: LikesCount.self).likesCount ?? 0
    }
    
    func getTopArticlesIndexes() async throws -> [String]? {
        let topArticlesIndexes = try await Firestore.firestore().collection("topArticlesIndexes").document("0").getDocument(as: TopArticlesIndexes.self)
        
        return topArticlesIndexes.topArticlesIndexes
    }
    
    func updateLikes(at articleId: String, likesCount: Int) async throws {
        let data: [String: Any] = [
            "likes_count": likesCount
        ]
        
        try await articleDocument(id: articleId).updateData(data)
    }
    
    func getViews(at id: String) async throws -> Int {
        try await articleDocument(id: id).getDocument(as: ViewsCount.self).viewsCount
    }
    
    func updateViews(at id: String) async throws {
        let viewsCount = try await articleDocument(id: id).getDocument(as: ViewsCount.self).viewsCount
        
        let data: [String: Any] = [
            "views_count": viewsCount + 1
        ]
        
        try await articleDocument(id: id).updateData(data)
    }
    
    func getAuthorId(byPostId id: String) async throws -> String {
        try await articleDocument(id: id).getDocument(as: AuthorId.self).authorId ?? ""
    }
    
    func getLocalizationCount(for id: String) async throws -> Int {
        try await articleDocument(id: id).getDocument(as: LocalizationCount.self).localizationCount
    }
    
    func setLocalizationCount(for id: String, count: Int) async throws {
        let data: [String: Any] = [
            "localization_count": count
        ]
        
        try await articleDocument(id: id).updateData(data)
    }
    
    func getLocalizedVersions(rootId: String) async throws -> [PrePost] {
        let snapshot = try await articlesCollection
            .whereField("root_id", isEqualTo: rootId)
            .getDocuments()
        
        return snapshot.documents.compactMap { PrePost(document: $0) }
    }
    
    func makeLocalizedVersionsRegular(rootId: String) async throws {
        let snapshot = try await articlesCollection
            .whereField("root_id", isEqualTo: rootId)
            .getDocuments()
        
        guard !snapshot.documents.isEmpty else { return }
        
        let batch = Firestore.firestore().batch()
        
        snapshot.documents.forEach { document in
            batch.updateData(
                [
                    "is_localized_version": FieldValue.delete(),
                    "root_id": FieldValue.delete()
                ],
                forDocument: document.reference
            )
        }
        
        try await batch.commit()
    }
    
    func updatePost(
        id: String,
        title: String,
        text: String,
        isArchive: Bool,
        uploadingLanguage: String,
        mediaCount: Int,
        mediaPosition: Int,
        isPremiumPost: Bool,
        shouldRefreshDateCreated: Bool = false
    ) async throws {
        var data: [String: Any] = [
            "title": title,
            "text": text,
            "is_archive": isArchive,
            "original_language": uploadingLanguage,
            "media_count": mediaCount,
            "media_position": mediaPosition,
            "is_premium_post": isPremiumPost
        ]

        if shouldRefreshDateCreated {
            data["date_created"] = Date()
        }

        
        try await articlesCollection.document(id).updateData(data)
    }
    
    func updateIsArchiveStatus(id: String, isArchive: Bool) async throws {
        var data: [String: Any] = [:]
        
        if isArchive {
            data = [
                "is_archive": isArchive
            ]
        } else {
            data = [
                "is_archive": isArchive,
                "date_created": Date()
            ]
        }
        
        try await articleDocument(id: id).updateData(data)
    }
    
    func deletePost(id: String) async throws {
        try await articleDocument(id: id).delete()
    }
    
    func addNewPost(
        title: String,
        text: String,
        isArchive: Bool,
        uploadingLanguage: String,
        mediaCount: Int,
        isShortPost: Bool,
        mediaPosition: Int,
        isLocalizing: Bool = false,
        rootId: String = "",
        isPremiumPost: Bool
    ) async throws -> String {
        let ref = articlesCollection.document()
        let newId = ref.documentID
        
        var data: [String: Any] = [
            "id": newId,
            "likes_count": 0,
            "views_count": 0,
            "title": title,
            "text": text,
            "original_language": uploadingLanguage,
            "author_id": try AuthenticationManager.shared.getAuthenticatedUser().uid,
            "is_archive": isArchive,
            "date_created": Date(),
            "is_short_post": isShortPost,
            "media_count": mediaCount,
            "media_version": 2,
            "media_position": mediaPosition,
            "is_premium_post": isPremiumPost
        ]
        
        if isLocalizing {
            data["is_localized_version"] = isLocalizing
            data["root_id"] = rootId
        }
        
        try await ref.setData(data)
        
//        try await UserManager.shared.updateCreatedPosts(newPost: newId)
        
        return newId
    }
    
    func getMaxIndex() async throws -> String? {
        let maxIndex = try await Firestore.firestore().collection("maxIndex").document("0").getDocument(as: MaxIndex.self)
        
        return maxIndex.maxIndex
    }
    
    func updateMaxIndex(to newIndex: String) async throws {
        let data: [String: Any] = [
            "max_index": newIndex
        ]
        
        try await Firestore.firestore().collection("maxIndex").document("0").updateData(data)
    }
    
    func uploadImage(id: String, image: UIImage, folder: String) async throws -> String {
        let id = UUID().uuidString + id
    
        let storage = Storage.storage()
        let ref = storage.reference(withPath: "\(folder)/\(id).jpg")
        
        guard let imageData = image.jpegData(compressionQuality: 1) else { return "" }
        _ = try await ref.putDataAsync(imageData)
        
        return try await ref.downloadURL().absoluteString
    }
    
    func getCreatedPosts(userId: String, startAfter: DocumentSnapshot? = nil, isArchive: Bool = false) async throws -> ([PrePost?], DocumentSnapshot?) {
        var query = Firestore.firestore()
            .collection("articles")
            .whereField("author_id", isEqualTo: userId)
            .whereField("is_archive", isEqualTo: isArchive)
            .order(by: "date_created", descending: true)
            .limit(to: 20)
        
        if let last = startAfter {
            query = query.start(afterDocument: last)
        }
        
        let snapshot = try await query.getDocuments()
        let posts: [PrePost?] = snapshot.documents.map { try? $0.data(as: PrePost.self) }
        
        return (posts, snapshot.documents.last)
    }
    
    func getMediaURLs(from id: String) async throws -> [URL] {
        let mediaURLs = try await articleDocument(id: id).getDocument(as: MediaURLs.self).mediaURLs
        var URLs: [URL] = []
        
        mediaURLs?.forEach { url in
            if let url = URL(string: url) {
                URLs.append(url)
            }
        }
        
        return URLs
    }
    
    func uploadMedia(URLs: [String], to id: String) async throws {
        let data: [String: Any] = [
            "media_URLs": URLs
        ]
        
        try await articleDocument(id: id).updateData(data)
    }
    
    func removeMedia(url: String, from id: String) async throws {
        let data: [String: Any] = [
            "media_URLs": FieldValue.arrayRemove([url])
        ]
        try await articleDocument(id: id).updateData(data)
    }

    func deleteImage(url: URL) async throws {
        let ref = Storage.storage().reference(forURL: url.absoluteString)
        try await ref.delete()
    }

    func getCommsCount(at id: String) async throws -> Int {
        try await articleDocument(id: id).getDocument(as: CommentsCount.self).commentsCount
    }

    func updateCommentsCount(at postId: String, isPlus: Bool) async throws {
        let commentsCount = try await articleDocument(id: postId).getDocument(as: CommentsCount.self).commentsCount

        let data: [String: Any] = [
            "comments_count": isPlus ? commentsCount + 1 : commentsCount - 1
        ]

        try await articleDocument(id: postId).updateData(data)
    }
}
