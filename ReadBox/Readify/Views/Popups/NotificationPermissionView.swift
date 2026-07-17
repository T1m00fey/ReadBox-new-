//
//  NotificationPermissionView.swift
//  ReadBox
//
//  Created by Macbook Pro on 04.10.2025.
//

import SwiftUI

struct NotificationPermissionView: View {
    @Binding var isPopupPresented: Bool

    let route: NotificationPushRoute

    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Text(NSLocalizedString("notificationLabel", comment: ""))
                    .font(.system(size: 27))
                    .fontDesign(.rounded)

                Image(systemName: "bell.badge.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20)
                    .foregroundStyle(Color.gray)
            }
            .frame(width: UIScreen.main.bounds.width - 32, alignment: .leading)

            Text(NSLocalizedString("pleaseTurnOnYourNotificationsLabel", comment: ""))
                .multilineTextAlignment(.leading)
                .font(.system(size: 19))
                .fontDesign(.rounded)
                .fontWeight(.light)
                .frame(width: UIScreen.main.bounds.width - 32, alignment: .leading)
                .padding(.bottom, 10)

            VStack(spacing: 10) {
                Button {
                    if route == .requestSystemPrompt {
                        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                            Task {
                                await AnalyticsManager.shared.refreshNotificationPermissionStatus(source: "system_prompt")
                            }

                            if granted {
                                DispatchQueue.main.async {
                                    isPopupPresented = false
                                }
                            }
                        }
                    } else if route == .goToSettings {
                        print("DECIDEEE: go settings")
                        if let url = URL(string: UIApplication.openNotificationSettingsURLString),
                           UIApplication.shared.canOpenURL(url) {
                            print("DECIDEEE: go settings 1")
                            UIApplication.shared.open(url)
                        } else if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                            print("DECIDEEE: go settings 2")
                        }

                        print("DECIDEEE: go settings 3")
                    }
                } label: {
                    Text(NSLocalizedString("turnOnLabel", comment: ""))
                        .font(.system(size: 20))
                        .fontDesign(.rounded)
                        .fontWeight(.light)
                        .padding(.vertical, 10)
                        .foregroundStyle(Color(.systemBackground))
                        .frame(width: UIScreen.main.bounds.width - 32)
                        .background(Color(.label))
                        .clipShape(Capsule())
                }

                Button {
                    isPopupPresented = false
                } label: {
                    Text(NSLocalizedString("laterLabel", comment: ""))
                        .font(.system(size: 19))
                        .fontDesign(.rounded)
                        .foregroundStyle(Color.gray)
                }
            }
        }
    }
}

//#Preview {
//    NotificationPermissionView()
//}
