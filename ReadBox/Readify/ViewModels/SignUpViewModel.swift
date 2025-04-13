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
            authorName: "",
            isCheckmark: false,
            createdPosts: [],
            subscribersCount: 0,
            subscribes: []
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
