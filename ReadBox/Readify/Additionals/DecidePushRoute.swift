//
//  DecidePushRoute.swift
//  ReadBox
//
//  Created by Macbook Pro on 07.11.2025.
//

import SwiftUI

func decidePushRoute() async -> NotificationPushRoute {
    await withCheckedContinuation { cont in
        UNUserNotificationCenter.current().getNotificationSettings { s in
            let route: NotificationPushRoute
            
            switch s.authorizationStatus {
            case .notDetermined:
                route = .requestSystemPrompt
                print("DECIDE 1: \(route)")
            case .denied:
                route = .goToSettings
                print("DECIDE 2: \(route)")
            case .authorized, .provisional, .ephemeral:
                route = .ok
            @unknown default:
                route = .goToSettings
            }
            
            print("DECIDE: \(route)")
            
            cont.resume(returning: route)
        }
    }
}
