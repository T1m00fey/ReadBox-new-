//
//  NotificationPermissionView.swift
//  ReadBox
//
//  Created by Macbook Pro on 04.10.2025.
//

import SwiftUI

struct NotificationPermissionView: View {
    @Binding var isPopupPresented: Bool
    @Binding var route: NotificationPushRoute
    
    var body: some View {
        VStack(spacing: 15) {
            Capsule()
                .frame(width: 25, height: 5)
                .foregroundStyle(Color.gray)
                .padding(.top, 5)
            
//            Image(systemName: "bell.badge")
//                .resizable()
//                .scaledToFit()
//                .frame(width: 70)
//                .foregroundStyle(Color.gray)
            
            HStack {
                Text("Уведомления")
                    .font(.system(size: 27))
                    .fontDesign(.rounded)
                
                Image(systemName: "bell.badge.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20)
                    .foregroundStyle(Color.gray)
            }
            .frame(width: UIScreen.main.bounds.width - 32, alignment: .leading)
            
            Text("Включите уведомления чтобы не пропускать последние публкации ваших любимых авторов!")
                .multilineTextAlignment(.leading)
                .font(.system(size: 19))
                .fontDesign(.rounded)
                .fontWeight(.light)
                .frame(width: UIScreen.main.bounds.width - 32)
                .padding(.bottom, 10)
            
            VStack(spacing: 10) {
                Button {
                    if route == .requestSystemPrompt {
                        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                            StorageManager.shared.setNotificationsPopupShowed(true)
                            isPopupPresented = false
                        }
                    } else if route == .goToSettings {
                        if let url = URL(string: UIApplication.openNotificationSettingsURLString),
                           UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url)
                        } else if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                } label: {
                    Text("Включить")
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
                    Text("Позже")
                        .font(.system(size: 19))
                        .fontDesign(.rounded)
                        .foregroundStyle(Color.gray)
                }
            }
            .padding(.bottom, 50)
        }
        .onDisappear {
            StorageManager.shared.setNotificationsPopupShowed(true)
        }
        .frame(width: UIScreen.main.bounds.width)
        .frame(minHeight: 100)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 30))
    }
}

//#Preview {
//    NotificationPermissionView()
//}
