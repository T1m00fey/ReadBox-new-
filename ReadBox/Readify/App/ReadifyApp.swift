//
//  ReadifyApp.swift
//  Readify
//
//  Created by Тимофей Юдин on 27.10.2024.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore
import FirebaseMessaging
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()

        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self

        application.registerForRemoteNotifications()

        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("Device Token: \(deviceToken.map { String(format: "%02.2hhx", $0) }.joined())")
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable : Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        print("📨 didReceiveRemoteNotification userInfo = \(userInfo)")
        completionHandler(.noData)
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        print("📨 [UNUserNotificationCenter] didReceive, userInfo = \(userInfo)")

        if let route = userInfo["route"] as? String,
           route == "channel",
           let channelId = userInfo["channelId"] as? String,
           !channelId.isEmpty {
            AnalyticsManager.shared.logPushOpen(
                destination: "channel",
                authorId: channelId,
                pushStyle: userInfo["push_style"] as? String
            )
        } else if let type = userInfo["type"] as? String,
                  type == "new_post",
                  let articleId = userInfo["articleId"] as? String,
                  !articleId.isEmpty {
            AnalyticsManager.shared.logPushOpen(
                destination: "article",
                articleId: articleId,
                pushStyle: userInfo["push_style"] as? String
            )
        }

        if let type = userInfo["type"] as? String,
           type == "new_post",
           let articleId = userInfo["articleId"] as? String,
           !articleId.isEmpty {
            StorageManager.shared.setPendingNotificationArticleId(articleId)
        } else if let route = userInfo["route"] as? String,
                  route == "channel",
                  let channelId = userInfo["channelId"] as? String,
                  !channelId.isEmpty {
            StorageManager.shared.setPendingNotificationChannelId(channelId)
        }

        NotificationCenter.default.post(name: Notification.Name("didReceiveRemoteNotification"),
                                        object: nil,
                                        userInfo: userInfo)
        completionHandler()
    }

    @objc func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase token: \(String(describing: fcmToken))")

        let originalLanguage = Locale.preferredLanguages.first?.components(separatedBy: "-").first == "ru"
            ? "ru"
            : "en"

        print("Original language: \(originalLanguage)")

        StorageManager.shared.set(fcmToken: fcmToken ?? "")

        Messaging.messaging().subscribe(toTopic: originalLanguage)
        Messaging.messaging().unsubscribe(
            fromTopic: originalLanguage == "en"
            ? "ru"
            : "en"
        )
    }

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        UIInterfaceOrientationMask.portrait
    }
}



// MARK: - Точка входа в SwiftUI-приложение
@main
struct ReadifyApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            NavigationView {
                RootView()
                    .onAppear {
                        DispatchQueue.main.async {
                            if StorageManager.shared.getLanguage() == nil {
                                StorageManager.shared.setLanguage(
                                    to: Locale.preferredLanguages.first?.components(separatedBy: "-").first == "ru"
                                        ? "ru"
                                        : "en"
                                )
                            }
                        }

                        // Пример: очистка кеша Firestore
//                        let db = Firestore.firestore()
//                        db.clearPersistence()
                    }
                    .task {
                        await AnalyticsManager.shared.refreshNotificationPermissionStatus(source: "app_launch")
                    }
                    .onChange(of: scenePhase) {
                        guard scenePhase == .active else { return }

                        Task {
                            await AnalyticsManager.shared.refreshNotificationPermissionStatus(source: "app_active")
                        }
                    }
//                    .onChange(of: scenePhase) {
//                        if scenePhase == .inactive || scenePhase == .background {
//                            let db = Firestore.firestore()
//                            db.clearPersistence()
//
//                            StorageManager.shared.deleteText()
//
//                            let userDefaults = UserDefaults.standard
//                            let storageDictionary = userDefaults.dictionaryRepresentation()
//
//                            for key in storageDictionary.keys {
//                                if key != "language"
//                                    && key != "views"
//                                    && key != "fontSize"
//                                    && key != "isNotificationsPopupPresented"
//                                    && key != "isNotificationsApproved"
//                                {
//                                    userDefaults.removeObject(forKey: key)
//                                }
//                            }
//                        }
//                    }
            }
        }

    }
}
