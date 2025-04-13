//
//  NewPasswordViewModel.swift
//  Readify
//
//  Created by Тимофей Юдин on 05.11.2024.
//

import SwiftUI

@MainActor
final class NewPasswordViewModel: ObservableObject {
    @Published var isButtonEnable = false

    @Published var newPassword = ""
    @Published var oldPassword = ""
    @Published var errorText = ""
    
    @Published var isErrorPopupPresented = false
    
    func resetPassword() async throws {
        let authUser = try AuthenticationManager.shared.getAuthenticatedUser()
        
        guard let email = authUser.email else {
            throw URLError(.fileDoesNotExist)
        }
        
        try await AuthenticationManager.shared.resetPassword(withEmail: email)
    }
    
    func updatePassword(to newPassword: String) async throws {
        try await AuthenticationManager.shared.updatePassword(to: newPassword)
    }
    
    func signIn(email: String) async throws {
        try await AuthenticationManager.shared.signInUser(withEmail: email, andPassword: oldPassword)
    }
    
    func isChangeButtonEnabled() {
        withAnimation {
            if newPassword.count > 0 && oldPassword.count > 0 {
                isButtonEnable = true
            }
        }
    }
}
