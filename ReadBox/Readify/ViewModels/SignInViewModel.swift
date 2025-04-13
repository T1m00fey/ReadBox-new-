//
//  SignInViewModel.swift
//  Readify
//
//  Created by Тимофей Юдин on 05.11.2024.
//

import SwiftUI

@MainActor
final class SignInViewModel: ObservableObject {
    @Published var isSignUpViewPresented = false
    @Published var isForgotPasswordPresented = false
    @Published var isErrorPopupPresented = false
    @Published var isLoading = false
    @Published var isSuccessPopupPresented = false
    
    @Published var isButtonEnable = false
    
    @Published var emailText = ""
    @Published var passwordText = ""
    @Published var errorText = ""
    
    @Published private(set) var user: DBUser? = nil
    
    func isSignInButtonEnabled() {
        withAnimation {
            if emailText.count > 0 && passwordText.count > 0 {
                isButtonEnable = true
            } else {
                isButtonEnable = false
            }
        }
    }
    
    func loadCurrentUser() async throws {
        let authDataResult = try AuthenticationManager.shared.getAuthenticatedUser()
        self.user = try await UserManager.shared.getUser(userId: authDataResult.uid)
    }
    
    func signIn() async throws {
        guard !emailText.isEmpty, !passwordText.isEmpty else {
            print("No email or password found")
            return
        }
        
        try await AuthenticationManager.shared.signInUser(withEmail: emailText, andPassword: passwordText)
    }
}


