//
//  ProfileViewModel.swift
//  Readify
//
//  Created by Тимофей Юдин on 05.11.2024.
//

import SwiftUI
import SwiftUIMailView

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var user: DBUser? = nil
    
    @Published var isDeleteAccDialogPresented = false
    @Published var isSignOutDialogPresented = false
    @Published var isSuccessPopupPresented = false
    @Published var isLanguagePopupPresented = false
    @Published var isErrorPopupPresented = false
    @Published var isMemorySettingsPopupPresented = false
    @Published var sizeOfData: Double = 0
    @Published var isFontSettingPopupPresented = false
    @Published var isMoreSettingPopupPresented = false
    @Published var isMailViewPresented = false
    @Published var isLoading = true
    @Published var isNeedToReload = false
    @Published var mailData = ComposeMailData(
        subject: "To the developer",
         recipients: ["support@ireadbox.ru"],
         message: """
                    App: ReadBox
                    iOS: \(UIDevice.current.systemVersion)
                    _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
                
                    Your question...
                """,
         attachments: []
    )
    
    @Published var successText = ""
    @Published var errorText = ""
    
    func loadCurrentUser() async throws {
        let authDataResult = try AuthenticationManager.shared.getAuthenticatedUser()
        let user = try await UserManager.shared.getUser(userId: authDataResult.uid)
        
        withAnimation {
            self.user = user
            isLoading = false
        }
    }
    
    func signOut() async throws {
        try? await UserManager.shared.deleteFcmToken(from: user?.userId ?? "")
        try AuthenticationManager.shared.signOut()
    }
    
    func reload() {
        if !isLoading {
            withAnimation {
                isLoading = true
            }
        }
        
        Task {
            try? await loadCurrentUser()
        }
        
        withAnimation {
            isLoading = false
        }
    }
    
    func getDays(regDate: Date?) -> Int {
        let timeInterval = Int(Date().timeIntervalSince(regDate ?? Date()))

        return timeInterval / 60 / 60 / 24
    }
    
    func getStringOf(days: Int) -> String {
        if StorageManager.shared.getLanguage() == "ru" {
            if days == 11 || days == 12 || days == 13 || days == 14 {
                return "дней"
            } else if days % 10 == 1 {
                return "день"
            } else if days % 10 == 2 || days % 10 == 4 || days % 10 == 3 {
                return "дня"
            } else {
                return "дней"
            }
        } else {
            if days == 1 {
                return "day"
            } else {
                return "days"
            }
        }
    }
    
    func getUserDefaultsSize() {
        var totalSize = 0
        
        // Получаем все ключи в UserDefaults
        let dictionary = UserDefaults.standard.dictionaryRepresentation()
        
        // Для каждого значения в UserDefaults
        for (_, value) in dictionary {
            if let data = try? NSKeyedArchiver.archivedData(withRootObject: value, requiringSecureCoding: false) {
                totalSize += data.count // Суммируем размеры данных
            }
        }
        
        // Переводим размер в мегабайты (MB)
        let sizeInMB = Double(totalSize) / (1024 * 1024)
        sizeOfData = sizeInMB
    }
    
    func getStringOf(articlesRead: Int) -> String {
        if StorageManager.shared.getLanguage() == "ru" {
            if articlesRead % 10 == 1 {
                return "статья"
            } else if articlesRead % 10 == 2 || articlesRead % 10 == 4 || articlesRead % 10 == 3 {
                return "статьи"
            } else {
                return "статей"
            }
        } else {
            if articlesRead == 1 {
                return "publication"
            } else {
                return "publications"
            }
        }
    }
    
    func delete() async throws {
        guard let user = user else {
            throw URLError(.fileDoesNotExist)
        }
        
        try await UserManager.shared.deleteUser(user: user)
        try await AuthenticationManager.shared.delete()
    }
    
    
}
