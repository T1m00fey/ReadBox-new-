//
//  AnalyticsManager.swift
//  ReadBox
//
//  Created by Тимофей Юдин on 17.06.2026.
//

import Foundation
import FirebaseAnalytics
import UserNotifications

final class AnalyticsManager {

    static let shared = AnalyticsManager()
    private init() {}

    private let firstActionEvent = "first_action"
    private let openArticleEvent = "open_article"
    private let articleLikeEvent = "article_like"
    private let openChannelEvent = "open_channel"
    private let subscribeAuthorEvent = "subscribe_author"
    private let unsubscribeAuthorEvent = "unsubscribe_author"
    private let pushOpenEvent = "push_open"
    private let commentCreatedEvent = "comment_created"
    private let postCreationStartedEvent = "post_creation_started"
    private let postPublishedEvent = "post_published"
    private let publicationSharedEvent = "publication_shared"
    private let onboardingStartedEvent = "onboarding_started"
    private let interestsSelectedEvent = "interests_selected"
    private let onboardingCompletedEvent = "onboarding_completed"
    private let feedImpressionEvent = "feed_impression"
    private let readingTimeEvent = "reading_time"
    private let recommendedAuthorShownEvent = "recommended_author_shown"
    private let installSourceEvent = "install_source"
    private let webToAppOpenEvent = "web_to_app_open"
    private let authorApplicationEvent = "author_application"
    private let draftCreatedEvent = "draft_created"
    private let publishFailedEvent = "publish_failed"
    private let notificationPermissionStatusUserProperty = "notif_permission_status"
    private let notificationPermissionStatusEvent = "notification_permission_status"

    private var didLogOnboardingStart = false
    private var loggedFeedImpressions: Set<String> = []
    private var loggedRecommendedAuthors: Set<String> = []
    private let installSourceTrackedKey = "readbox_install_source_tracked"

    func setAuthenticatedUser(id: String) {
        guard !id.isEmpty else { return }
        Analytics.setUserID(id)
    }

    func clearAuthenticatedUser() {
        Analytics.setUserID(nil)
    }

    func logOpenArticle(id: String, contentType: String, source: String) {
        guard !id.isEmpty else { return }

        Analytics.logEvent(
            openArticleEvent,
            parameters: [
                "article_id": id,
                "content_type": contentType,
                "source": source
            ]
        )

        logFirstActionIfNeeded("open_article")
    }

    func logOpenChannel(authorId: String, source: String) {
        guard !authorId.isEmpty else { return }

        Analytics.logEvent(
            openChannelEvent,
            parameters: [
                "author_id": authorId,
                "source": source
            ]
        )

        logFirstActionIfNeeded("open_channel")
    }

    func logArticleLike(id: String, contentType: String, source: String) {
        guard !id.isEmpty else { return }

        Analytics.logEvent(
            articleLikeEvent,
            parameters: [
                "article_id": id,
                "content_type": contentType,
                "source": source
            ]
        )

        logFirstActionIfNeeded("article_like")
    }

    func logSubscribeAuthor(authorId: String) {
        guard !authorId.isEmpty else { return }

        Analytics.logEvent(
            subscribeAuthorEvent,
            parameters: [
                "author_id": authorId
            ]
        )

        logFirstActionIfNeeded("subscribe_author")
    }

    func logUnsubscribeAuthor(authorId: String) {
        guard !authorId.isEmpty else { return }

        Analytics.logEvent(
            unsubscribeAuthorEvent,
            parameters: [
                "author_id": authorId
            ]
        )
    }

    func logPushOpen(destination: String, articleId: String? = nil, authorId: String? = nil, pushStyle: String? = nil) {
        var parameters: [String: Any] = [
            "destination": destination
        ]

        if let articleId, !articleId.isEmpty {
            parameters["article_id"] = articleId
        }

        if let authorId, !authorId.isEmpty {
            parameters["author_id"] = authorId
        }

        if let pushStyle, !pushStyle.isEmpty {
            parameters["push_style"] = pushStyle
        }

        Analytics.logEvent(pushOpenEvent, parameters: parameters)
        logFirstActionIfNeeded("push_open")
    }

    func logCommentCreated(postId: String, isReply: Bool) {
        guard !postId.isEmpty else { return }

        Analytics.logEvent(
            commentCreatedEvent,
            parameters: [
                "post_id": postId,
                "is_reply": isReply ? 1 : 0
            ]
        )

        logFirstActionIfNeeded("comment_created")
    }

    func logPostCreationStarted() {
        Analytics.logEvent(postCreationStartedEvent, parameters: nil)
        logFirstActionIfNeeded("post_creation_started")
    }

    func logPostPublished(id: String, destination: String, language: String, hasMedia: Bool) {
        guard !id.isEmpty else { return }

        Analytics.logEvent(
            postPublishedEvent,
            parameters: [
                "post_id": id,
                "destination": destination,
                "language": language,
                "has_media": hasMedia ? 1 : 0
            ]
        )

        logFirstActionIfNeeded("post_published")
    }

    func logPublicationShared(id: String, contentType: String, source: String) {
        guard !id.isEmpty else { return }

        Analytics.logEvent(
            publicationSharedEvent,
            parameters: [
                "publication_id": id,
                "content_type": contentType,
                "source": source
            ]
        )

        logFirstActionIfNeeded("publication_shared")
    }

    func logOnboardingStarted(source: String) {
        guard !didLogOnboardingStart else { return }
        didLogOnboardingStart = true

        Analytics.logEvent(
            onboardingStartedEvent,
            parameters: ["source": source]
        )
    }

    func logInterestsSelected(_ interests: [String], source: String = "onboarding") {
        let normalizedInterests = interests
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }

        guard !normalizedInterests.isEmpty else { return }

        Analytics.logEvent(
            interestsSelectedEvent,
            parameters: [
                "interests": normalizedInterests.joined(separator: "|"),
                "interests_count": normalizedInterests.count,
                "source": source
            ]
        )
    }

    func logOnboardingCompleted(method: String, interestsCount: Int = 0) {
        Analytics.logEvent(
            onboardingCompletedEvent,
            parameters: [
                "method": method,
                "interests_count": max(0, interestsCount)
            ]
        )
    }

    func logFeedImpression(
        publicationId: String,
        authorId: String,
        contentType: String,
        source: String,
        position: Int? = nil
    ) {
        guard !publicationId.isEmpty else { return }

        let impressionKey = "\(source):\(publicationId)"
        guard loggedFeedImpressions.insert(impressionKey).inserted else { return }

        var parameters: [String: Any] = [
            "publication_id": publicationId,
            "author_id": authorId,
            "content_type": contentType,
            "source": source
        ]

        if let position {
            parameters["position"] = max(0, position)
        }

        Analytics.logEvent(feedImpressionEvent, parameters: parameters)
    }

    func logArticleReadMilestone(
        id: String,
        percent: Int,
        contentType: String,
        source: String
    ) {
        guard !id.isEmpty, [25, 50, 75, 100].contains(percent) else { return }

        Analytics.logEvent(
            "article_read_\(percent)",
            parameters: [
                "article_id": id,
                "content_type": contentType,
                "source": source
            ]
        )
    }

    func logReadingTime(
        id: String,
        seconds: Int,
        contentType: String,
        source: String
    ) {
        guard !id.isEmpty, seconds > 0 else { return }

        Analytics.logEvent(
            readingTimeEvent,
            parameters: [
                "article_id": id,
                "seconds": min(seconds, 86_400),
                "content_type": contentType,
                "source": source
            ]
        )
    }

    func logRecommendedAuthorShown(authorId: String, source: String, position: Int? = nil) {
        guard !authorId.isEmpty else { return }

        let recommendationKey = "\(source):\(authorId)"
        guard loggedRecommendedAuthors.insert(recommendationKey).inserted else { return }

        var parameters: [String: Any] = [
            "author_id": authorId,
            "source": source
        ]

        if let position {
            parameters["position"] = max(0, position)
        }

        Analytics.logEvent(recommendedAuthorShownEvent, parameters: parameters)
    }

    func logInstallSourceIfNeeded(source: String, campaign: String? = nil) {
        guard !UserDefaults.standard.bool(forKey: installSourceTrackedKey) else { return }

        var parameters: [String: Any] = ["source": source]
        if let campaign, !campaign.isEmpty {
            parameters["campaign"] = campaign
        }

        Analytics.logEvent(installSourceEvent, parameters: parameters)
        UserDefaults.standard.set(true, forKey: installSourceTrackedKey)
    }

    func logWebToAppOpen(url: URL, destination: String, contentId: String? = nil) {
        var parameters: [String: Any] = [
            "host": url.host ?? "unknown",
            "destination": destination
        ]

        if let contentId, !contentId.isEmpty {
            parameters["content_id"] = contentId
        }

        if let campaign = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name == "utm_campaign" })?
            .value,
           !campaign.isEmpty {
            parameters["campaign"] = campaign
        }

        Analytics.logEvent(webToAppOpenEvent, parameters: parameters)
    }

    func logAuthorApplication(source: String) {
        Analytics.logEvent(authorApplicationEvent, parameters: ["source": source])
        logFirstActionIfNeeded("author_application")
    }

    func logDraftCreated(id: String, contentType: String, language: String, hasMedia: Bool) {
        guard !id.isEmpty else { return }

        Analytics.logEvent(
            draftCreatedEvent,
            parameters: [
                "publication_id": id,
                "content_type": contentType,
                "language": language,
                "has_media": hasMedia ? 1 : 0
            ]
        )

        logFirstActionIfNeeded("draft_created")
    }

    func logPublishFailed(
        contentType: String,
        operation: String,
        isDraft: Bool,
        error: Error
    ) {
        let nsError = error as NSError

        Analytics.logEvent(
            publishFailedEvent,
            parameters: [
                "content_type": contentType,
                "operation": operation,
                "is_draft": isDraft ? 1 : 0,
                "error_domain": nsError.domain,
                "error_code": nsError.code
            ]
        )
    }

    func refreshNotificationPermissionStatus(source: String) async {
        let status = await getNotificationPermissionStatus()
        let statusRawValue = status.rawValue

        Analytics.setUserProperty(statusRawValue, forName: notificationPermissionStatusUserProperty)

        if StorageManager.shared.getLastTrackedNotificationPermissionStatus() != statusRawValue {
            Analytics.logEvent(
                notificationPermissionStatusEvent,
                parameters: [
                    "status": statusRawValue,
                    "source": source
                ]
            )

            StorageManager.shared.setLastTrackedNotificationPermissionStatus(statusRawValue)
        }
    }

    private func logFirstActionIfNeeded(_ action: String) {
        guard !StorageManager.shared.hasTrackedFirstAction(action) else { return }

        Analytics.logEvent(
            firstActionEvent,
            parameters: [
                "action": action
            ]
        )

        StorageManager.shared.trackFirstAction(action)
    }

    private func getNotificationPermissionStatus() async -> NotificationPermissionStatus {
        await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                continuation.resume(returning: NotificationPermissionStatus(status: settings.authorizationStatus))
            }
        }
    }
}

private enum NotificationPermissionStatus: String {
    case notDetermined = "not_determined"
    case denied = "denied"
    case authorized = "authorized"
    case provisional = "provisional"
    case ephemeral = "ephemeral"
    case unknown = "unknown"

    init(status: UNAuthorizationStatus) {
        switch status {
        case .notDetermined:
            self = .notDetermined
        case .denied:
            self = .denied
        case .authorized:
            self = .authorized
        case .provisional:
            self = .provisional
        case .ephemeral:
            self = .ephemeral
        @unknown default:
            self = .unknown
        }
    }
}
