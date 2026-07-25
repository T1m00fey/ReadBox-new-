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
                    Task {
                        switch route {
                        case .requestSystemPrompt:
                            let isAllowed = (try? await UNUserNotificationCenter.current().requestAuthorization(
                                options: [.alert, .sound, .badge]
                            )) ?? false

                            if isAllowed {
                                isPopupPresented = false
                            }

                            await AnalyticsManager.shared.refreshNotificationPermissionStatus(
                                source: "system_prompt"
                            )
                        case .goToSettings:
                            if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                                await UIApplication.shared.open(url)
                            } else if let url = URL(string: UIApplication.openSettingsURLString) {
                                await UIApplication.shared.open(url)
                            }
                        case .ok:
                            isPopupPresented = false
                        }
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
