//
//  DecidePushRoute.swift
//  ReadBox
//
//  Created by Macbook Pro on 07.11.2025.
//

import UserNotifications

func decidePushRoute() async -> NotificationPushRoute {
    let settings = await UNUserNotificationCenter.current().notificationSettings()

    switch settings.authorizationStatus {
    case .notDetermined:
        return .requestSystemPrompt
    case .denied:
        return .goToSettings
    case .authorized, .provisional, .ephemeral:
        return .ok
    @unknown default:
        return .goToSettings
    }
}
