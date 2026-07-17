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

    func getComment(id: String) async throws -> Comment {
        try await commentDocument(id: id).getDocument(as: Comment.self)
    }

    func getCommentaries(rootPostId: String) async throws -> [Comment] {
        let snapshot = try await commentariesCollection
            .whereField("root_post_id", isEqualTo: rootPostId)
            .getDocuments()

        return snapshot.documents
            .compactMap { try? $0.data(as: Comment.self) }
            .sorted { ($0.dateCreated ?? .distantPast) < ($1.dateCreated ?? .distantPast) }
    }

    func getCommentariesPage(
        rootPostId: String,
        limit: Int,
        startAfter: DocumentSnapshot? = nil
    ) async throws -> ([Comment], DocumentSnapshot?) {
        var query = commentariesCollection
            .whereField("root_post_id", isEqualTo: rootPostId)
            .order(by: "date_created")
            .limit(to: limit)

        if let startAfter {
            query = query.start(afterDocument: startAfter)
        }

        let snapshot = try await query.getDocuments()
        let commentaries = snapshot.documents.compactMap { try? $0.data(as: Comment.self) }
        let lastDocument = snapshot.documents.count == limit ? snapshot.documents.last : nil

        return (commentaries, lastDocument)
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
            "replies_count": 0,
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
            likesCount: 0,
            repliesCount: 0
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

    func updateRepliesCount(at id: String, isPlus: Bool) async throws {
        if isPlus {
            let data: [String: Any] = [
                "replies_count": FieldValue.increment(Int64(1))
            ]

            try await commentDocument(id: id).updateData(data)
            return
        }

        let repliesCount = try await commentDocument(id: id).getDocument(as: Comment.self).repliesCount ?? 0
        let nextCount = max(0, repliesCount - 1)

        let data: [String: Any] = [
            "replies_count": nextCount
        ]

        try await commentDocument(id: id).updateData(data)
    }

    func deleteComment(id: String) async throws {
        try await commentDocument(id: id).delete()
    }

}
