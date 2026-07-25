//
//  NotificationsManager.swift
//  ReadBox
//
//  Created by Тимофей Юдин on 06.05.2026.
//

import Foundation
import FirebaseFirestore

final class NotificationsManager {
    static let shared = NotificationsManager()
    private init() {}

    private let notificationsCollection = Firestore.firestore().collection("notifications")

    func getNotifications(for userId: String) async throws -> [PersonalNotificationItem] {
        let snapshot = try await notificationsCollection
            .whereField("user_id", isEqualTo: userId)
            .getDocuments()

        return snapshot.documents
            .map(makeNotificationItem)
            .sorted { ($0.dateCreated ?? .distantPast) > ($1.dateCreated ?? .distantPast) }
    }

    private func makeNotificationItem(from document: QueryDocumentSnapshot) -> PersonalNotificationItem {
        let data = document.data()

        return PersonalNotificationItem(
            id: document.documentID,
            userId: data["user_id"] as? String,
            typeRawValue: data["type"] as? String,
            actorId: data["actor_id"] as? String,
            postId: data["post_id"] as? String,
            dateCreated: (data["date_created"] as? Timestamp)?.dateValue(),
            expiresAt: (data["expires_at"] as? Timestamp)?.dateValue(),
            isRead: data["is_read"] as? Bool ?? false
        )
    }

    func markAsRead(ids: [String]) async throws {
        guard !ids.isEmpty else { return }

        let batch = Firestore.firestore().batch()

        for id in ids {
            batch.updateData(
                ["is_read": true],
                forDocument: notificationsCollection.document(id)
            )
        }

        try await batch.commit()
    }
}
