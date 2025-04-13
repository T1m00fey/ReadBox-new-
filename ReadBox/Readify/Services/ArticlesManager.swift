//
//  ArticlesManager.swift
//  Readify
//
//  Created by Тимофей Юдин on 05.11.2024.
//

import SwiftUI
import FirebaseFirestore
import FirebaseStorage

struct ArticleImage: Codable {
    let id: String
    let image: Data?
}

//struct EnArticle: Identifiable, Codable, Equatable, Hashable {
//    let id: String
//    let dateCreated: Date?
//    let enTitle: String?
//    let enText: String?
//    let enDescription: String?
//    let likesCount: Int?
//    let isPremium: Bool?
//    let authorId: String?
//    let viewsCount: Int?
//    
//    enum CodingKeys: String, CodingKey {
//        case id = "id"
//        case dateCreated = "date_created"
//        case enTitle = "en_title"
//        case enText = "en_text"
//        case enDescription = "en_description"
//        case likesCount = "likes_count"
//        case isPremium = "is_premium"
//        case authorId = "author_id"
//        case viewsCount = "views_count"
//    }
//}
//
//struct RuArticle: Identifiable, Codable, Equatable, Hashable {
//    let id: String
//    let dateCreated: Date?
//    let ruTitle: String?
//    let ruText: String?
//    let ruDescription: String?
//    let likesCount: Int?
//    let isPremium: Bool?
//    let authorId: String?
//    let viewsCount: Int?
//    
//    enum CodingKeys: String, CodingKey {
//        case id = "id"
//        case dateCreated = "date_created"
//        case ruTitle = "ru_title"
//        case ruText = "ru_text"
//        case ruDescription = "ru_description"
//        case likesCount = "likes_count"
//        case isPremium = "is_premium"
//        case authorId = "author_id"
//        case viewsCount = "views_count"
//    }
//}

struct Article: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let dateCreated: Date?
    let title: String?
    let text: String?
    let description: String?
    let likesCount: Int?
    var isArchive: Bool?
    let authorId: String?
    let viewsCount: Int?
    let originalLanguage: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case dateCreated = "date_created"
        case title = "title"
        case text = "text"
        case description = "description"
        case likesCount = "likes_count"
        case isArchive = "is_archive"
        case authorId = "author_id"
        case viewsCount = "views_count"
        case originalLanguage = "original_language"
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

struct MaxIndex: Codable {
    let maxIndex: String
    
    enum CodingKeys: String, CodingKey {
        case maxIndex = "max_index"
    }
}

struct OriginalLanguage: Codable {
    let originalLanguage: String?
    
    enum CodingKeys: String, CodingKey {
        case originalLanguage = "original_language"
    }
}

final class ArticlesManager {
    static let shared = ArticlesManager()
    private init() {}
    
    private let articlesCollection = Firestore.firestore().collection("articles")
    
    private func articleDocument(id: String) -> DocumentReference {
        articlesCollection.document(id)
    }
    
    func getArticle(id: String) async throws -> Article {
        try await articleDocument(id: id).getDocument(as: Article.self)
    }
    
    func getOriginalLanguageOfArticle(id: String) async throws -> String {
        try await articleDocument(id: id).getDocument(as: OriginalLanguage.self).originalLanguage ?? "en"
    }
    
//    func getRuArticle(id: String) async throws -> RuArticle {
//        try await articleDocument(id: id).getDocument(as: RuArticle.self)
//    }
//    
//    func getEnArticle(id: String) async throws -> EnArticle {
//        try await articleDocument(id: id).getDocument(as: EnArticle.self)
//    }
    
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
    
    func updateViews(at id: String) async throws {
        let viewsCount = try await articleDocument(id: id).getDocument(as: ViewsCount.self).viewsCount
        
        let data: [String: Any] = [
            "views_count": viewsCount + 1
        ]
        
        try await articleDocument(id: id).updateData(data)
    }
    
    func updatePost(id: String, title: String, image: UIImage, description: String, text: String, isArchive: Bool) async throws {
        let data: [String: Any] = [
            "title": title,
            "description": description,
            "text": text,
            "is_archive": isArchive
        ]
        
        try await articlesCollection.document(id).updateData(data)
        
        if image == UIImage() {
            let fileReference = Storage.storage().reference().child("images/\(id).jpg")
            
            try await fileReference.delete()
            
            StorageManager.shared.deleteImage(id: id)
            
        } else {
            let storage = Storage.storage()
            let ref = storage.reference(withPath: "images/\(id).jpg")
            guard let imageData = image.jpegData(compressionQuality: 1) else { return }
            
            ref.putData(imageData)
            
            StorageManager.shared.saveImage(id: id, image: image)
        }
        
    }
    
    func updateIsArchiveStatus(id: String, isArchive: Bool) async throws {
        let data: [String: Any] = [
            "is_archive": isArchive
        ]
        
        try await articleDocument(id: id).updateData(data)
    }
    
    func deletePost(id: String) async throws {
        try await articleDocument(id: id).delete()
    }
    
    func addNewPost(title: String, description: String, text: String, image: UIImage, isArchive: Bool) async throws {
        guard let maxIndex = try await getMaxIndex() else { return }
        let newMaxIndex = String((Int(maxIndex) ?? -2) + 1)
        
        let data: [String: Any] = [
            "id": newMaxIndex,
            "likes_count": 0,
            "views_count": 0,
            "title": title,
            "description": description,
            "text": text.replacingOccurrences(of: "\n", with: "<br>"),
            "original_language": StorageManager.shared.getLanguage(),
            "author_id": try AuthenticationManager.shared.getAuthenticatedUser().uid,
            "is_archive": isArchive,
            "date_created": Date()
        ]
        
        try await articlesCollection.document("\(newMaxIndex)").setData(data)
        
        if image != UIImage() {
            let storage = Storage.storage()
            let ref = storage.reference(withPath: "images/\(newMaxIndex).jpg")
            guard let imageData = image.jpegData(compressionQuality: 1) else { return }
            
            ref.putData(imageData)
        }
        
        try await UserManager.shared.updateCreatedPosts(newPost: newMaxIndex)
        
        try await updateMaxIndex(to: newMaxIndex)
    }
    
//    func getAllEnArticles() async throws -> [EnArticle?] {
//        let snapshot = try await articlesCollection.getDocuments()
//        
//        var articles: [EnArticle] = []
//        
//        for document in snapshot.documents {
//            let article = try document.data(as: EnArticle.self)
//            articles.append(article)
//        }
//        
//        return articles
//    }
//    
//    func getAllRuArticles() async throws -> [RuArticle?] {
//        let snapshot = try await articlesCollection.getDocuments()
//        
//        var articles: [RuArticle] = []
//        
//        for document in snapshot.documents {
//            let article = try document.data(as: RuArticle.self)
//            articles.append(article)
//        }
//        
//        return articles
//    }
    
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
}
