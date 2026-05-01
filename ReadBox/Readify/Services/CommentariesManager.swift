//
//  CommentariesManager.swift
//  ReadBox
//
//  Created by Тимофей Юдин on 22.04.2026.
//

import Foundation
import FirebaseFirestore

final class CommentariesManager {
    static let shared = CommentariesManager()
    private init() {}

    private let commentariesCollection = Firestore.firestore().collection("commentaries")

    private func commentDocument(id: String) -> DocumentReference {
        commentariesCollection.document(id)
    }

    func getLikesCount(for id: String) async throws -> Int {
        try await commentDocument(id: id).getDocument(as: LikesCount.self).likesCount ?? 0
    }

    func getViewsCount(for id: String) async throws -> Int {
        try await commentDocument(id: id).getDocument(as: ViewsCount.self).viewsCount
    }

    func getCommentaries(rootPostId: String) async throws -> [Comment] {
        let snapshot = try await commentariesCollection
            .whereField("root_post_id", isEqualTo: rootPostId)
            .getDocuments()

        return snapshot.documents
            .compactMap { try? $0.data(as: Comment.self) }
            .sorted { ($0.dateCreated ?? .distantPast) < ($1.dateCreated ?? .distantPast) }
    }

    func getCommentaries(authorId: String) async throws -> [Comment] {
        let snapshot = try await commentariesCollection
            .whereField("author_id", isEqualTo: authorId)
            .getDocuments()

        return snapshot.documents
            .compactMap { try? $0.data(as: Comment.self) }
            .sorted { ($0.dateCreated ?? .distantPast) > ($1.dateCreated ?? .distantPast) }
    }

    func createComment(
        rootPostId: String,
        rootAuthorId: String,
        authorId: String,
        text: String
    ) async throws -> Comment {
        let ref = commentariesCollection.document()
        let id = ref.documentID
        let dateCreated = Date()

        let data: [String: Any] = [
            "id": id,
            "author_id": authorId,
            "date_created": dateCreated,
            "likes_count": 0,
            "root_author_id": rootAuthorId,
            "root_post_id": rootPostId,
            "text": text,
            "views_count": 0
        ]

        try await ref.setData(data)

        return Comment(
            id: id,
            text: text,
            dateCreated: dateCreated,
            authorId: authorId,
            rootAuthorId: rootAuthorId,
            rootPostId: rootPostId,
            viewsCount: 0,
            likesCount: 0
        )
    }

    func updateLike(at id: String, isPlus: Bool) async throws {
        let likesCount = try await getLikesCount(for: id)

        let data: [String: Any] = [
            "likes_count": isPlus ? likesCount + 1 : likesCount - 1
        ]

        try await commentDocument(id: id).updateData(data)
    }

    func updateViews(at id: String) async throws {
        let viewsCount = try await getViewsCount(for: id)

        let data: [String: Any] = [
            "views_count": viewsCount + 1
        ]

        try await commentDocument(id: id).updateData(data)
    }

}
