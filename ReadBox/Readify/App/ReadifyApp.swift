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
    
    // Вызывается при запуске приложения
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
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        NotificationCenter.default.post(name: Notification.Name("didReceiveRemoteNotification"), object: nil, userInfo: userInfo)
        completionHandler()
    }
    
    @objc func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase token: \(String(describing: fcmToken))")
        
        let originalLanguage = StorageManager.shared.getLanguage()
        
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
struct YourApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                RootView()                
                    .onAppear {
                        DispatchQueue.main.async {
                            StorageManager.shared.setLanguage(
                                to: Locale.preferredLanguages.first?.components(separatedBy: "-").first == "ru"
                                    ? "ru"
                                    : "en"
                            )
                        }
                        
                        // Пример: очистка кеша Firestore
                        let db = Firestore.firestore()
                        db.clearPersistence()
                    }
                    .onChange(of: scenePhase) {
                        if scenePhase == .inactive || scenePhase == .background {
                            let db = Firestore.firestore()
                            db.clearPersistence()
                            
                            StorageManager.shared.deleteText()
                            
                            let userDefaults = UserDefaults.standard
                            let storageDictionary = userDefaults.dictionaryRepresentation()
                            
                            for key in storageDictionary.keys {
                                if key != "language" && key != "views" && key != "fontSize" && key != "notificationPermission" {
                                    userDefaults.removeObject(forKey: key)
                                }
                            }
                        }
                    }
            }
        }
        
    }
}
