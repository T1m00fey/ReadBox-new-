//
//  MediaManager.swift
//  ReadBox
//
//  Created by Тимофей Юдин on 16.01.2026.
//

import FirebaseStorage
import UIKit

final class MediaManager {
    static let shared = MediaManager()
    private init() {}

    func getAvatar(authorId: String, lastVersion: Int) async -> UIImage? {
        let cacheKey = "avatar_\(authorId)_\(lastVersion)"
        let cacheKeyForDelete = "avatar_\(authorId)_\(lastVersion - 1)"

        if let cached = StorageManager.shared.getImage(id: cacheKey) {
            return cached
        }

        let ref = Storage.storage().reference().child("avatars/\(authorId).jpg")

        do {
            let data = try await ref.data(maxSize: 5 * 1024 * 1024 * 1024)
            guard let image = UIImage(data: data) else { return nil }

            await MainActor.run {
                StorageManager.shared.saveImage(id: cacheKey, image: image)
                StorageManager.shared.deleteImage(id: cacheKeyForDelete)
            }

            return image
        } catch {
            return nil
        }
    }
}
