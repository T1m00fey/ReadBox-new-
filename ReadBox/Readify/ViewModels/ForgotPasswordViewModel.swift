//
//  ForgotPasswordViewModel.swift
//  Readify
//
//  Created by Тимофей Юдин on 05.11.2024.
//

import SwiftUI

@MainActor
final class ForgotPasswordViewModel: ObservableObject {
    @Published var emailText = ""
    @Published var isButtonEnabled = false
    @Published var errorText = ""
    @Published var isErrorPopupPresented = false
    
    func isButtonEnable() {
        withAnimation {
            if emailText.count > 0 {
                isButtonEnabled = true
            } else {
                isButtonEnabled = false
            }
        }
    }
    
    func resetPassword() async throws {
        try await AuthenticationManager.shared.resetPassword(withEmail: emailText)
    }
}
