//
//  SignUpViewModel.swift
//  Readify
//
//  Created by Тимофей Юдин on 27.10.2024.
//

import SwiftUI

@MainActor
final class SignUpViewModel: ObservableObject {
    @Published var isButtonEnable = false
    @Published var isLoading = false
    
    @Published var isPopupPresented = false
    
    @Published var nameText = ""
    @Published var emailText = ""
    @Published var passwordText = ""
    @Published var errorText = ""
    
    @Published private(set) var user: DBUser? = nil
    
    let vibrationsService = VibrationsService.shared
    
    let privacyText = StorageManager.shared.getLanguage() == "en"
    ? "By using this application, you agree to the [terms of use](https://readbox-links.online/terms.html) and [privacy policy](https://readbox-links.online/privacy.html) regarding the processing of personal data by this application."
    : "Используя данное приложение, вы соглашаетесь с [условиями использования](https://readbox-links.online/terms.html) и [политикой конфиденциальности](https://readbox-links.online/privacy.html), касающейся обработки персональных данных этим приложением."
    
    func signUp() async throws {
        guard !emailText.isEmpty, !passwordText.isEmpty else {
            print("No email or password found.")
            return
        }
    
        let authDataResult = try await AuthenticationManager.shared.createUser(
            withEmail: emailText,
            andPassword: passwordText
        )
        
        let user = DBUser(
            userId: authDataResult.uid,
            name: nameText,
            email: authDataResult.email,
            dateCreated: Date(),
            likedPosts: [],
            isCheckmark: false,
            createdPosts: [],
            subscribersCount: 0,
            subscribes: [],
            authorDescription: ""            
        )
        
        try await UserManager.shared.createNewUser(user: user)
    }
    
    func isSignUpButtonEnabled() {
        withAnimation {
            if nameText.count > 0 && emailText.count > 0 && passwordText.count > 0 {
                isButtonEnable = true
            } else {
                isButtonEnable = false
            }
        }
    }
}
