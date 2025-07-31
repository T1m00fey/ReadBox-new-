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
    
    let vibrationsService = VibrationsService.shared
    
    let privacyText = StorageManager.shared.getLanguage() == "en"
    ? "By using this application, you agree to the [terms of use](https://readbox-links.online/terms.html) and [privacy policy](https://readbox-links.online/privacy.html) regarding the processing of personal data by this application."
    : "Используя данное приложение, вы соглашаетесь с [условиями использования](https://readbox-links.online/terms.html) и [политикой конфиденциальности](https://readbox-links.online/privacy.html), касающейся обработки персональных данных этим приложением."
    
    
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


