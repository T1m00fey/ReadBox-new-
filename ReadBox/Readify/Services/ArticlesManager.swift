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
            
            try? await fileReference.delete()
            
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
    
    func addNewPost(
        title: String,
        description: String,
        text: String,
        image: UIImage,
        isArchive: Bool,
        uploadingLanguage: String
    ) async throws {
        guard let maxIndex = try await getMaxIndex() else { return }
        let newMaxIndex = String((Int(maxIndex) ?? -2) + 1)
        
        let data: [String: Any] = [
            "id": newMaxIndex,
            "likes_count": 0,
            "views_count": 0,
            "title": title,
            "description": description,
            "text": text,
            "original_language": uploadingLanguage,
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
