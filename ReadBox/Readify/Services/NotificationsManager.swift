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

    func getNotifications(for userId: String) async throws -> [InAppNotificationItem] {
        let snapshot = try await notificationsCollection
            .whereField("user_id", isEqualTo: userId)
            .getDocuments()

        return snapshot.documents
            .compactMap(makeNotificationItem)
            .sorted { ($0.dateCreated ?? .distantPast) > ($1.dateCreated ?? .distantPast) }
    }

    private func makeNotificationItem(from document: QueryDocumentSnapshot) -> InAppNotificationItem? {
        let data = document.data()

        let dateCreated = (data["date_created"] as? Timestamp)?.dateValue()
        let expiresAt = (data["expires_at"] as? Timestamp)?.dateValue()

        return InAppNotificationItem(
            id: document.documentID,
            userId: data["user_id"] as? String,
            typeRawValue: data["type"] as? String,
            actorId: data["actor_id"] as? String,
            postId: data["post_id"] as? String,
            dateCreated: dateCreated,
            expiresAt: expiresAt
        )
    }
}
