//
//  NotificationService.swift
//  NotificationService
//
//  Created by Macbook Pro on 29.07.2025.
//

import UserNotifications
import UIKit

class NotificationService: UNNotificationServiceExtension {
    
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    
    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        guard let bestAttemptContent else {
            return contentHandler(request.content)
        }

        guard
            let imageUrlString = bestAttemptContent.userInfo["imageUrl"] as? String,
            let imageUrl = URL(string: imageUrlString)
        else {
            return contentHandler(bestAttemptContent)
        }

        downloadImage(from: imageUrl) { attachment in
            if let attachment {
                bestAttemptContent.attachments = [attachment]
            }
            contentHandler(bestAttemptContent)
        }
    }

    override func serviceExtensionTimeWillExpire() {
        if let contentHandler, let bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

    private func downloadImage(from url: URL, completion: @escaping (UNNotificationAttachment?) -> Void) {
        let task = URLSession.shared.downloadTask(with: url) { tempFileUrl, _, _ in
            guard let tempFileUrl else { return completion(nil) }

            let fileManager = FileManager.default
            let localUrl = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(url.lastPathComponent)

            try? fileManager.moveItem(at: tempFileUrl, to: localUrl)
            let attachment = try? UNNotificationAttachment(identifier: "image", url: localUrl, options: nil)
            completion(attachment)
        }
        task.resume()
    }
}
