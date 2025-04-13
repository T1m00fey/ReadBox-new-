//
//  NewNameViewModel.swift
//  Readify
//
//  Created by Тимофей Юдин on 05.11.2024.
//

import SwiftUI

@MainActor
final class NewNameViewModel: ObservableObject {
    @Published var nameText = ""
    @Published var isButtonEnabled = false
    @Published var errorText = ""
    
    @Published var isErrorPopupPresented = false
    @Published var isSuccessPopupPresented = false
    
    func isButtonEnable() {
        withAnimation {
            if nameText.count > 0 {
                isButtonEnabled = true
            } else {
                isButtonEnabled = false
            }
        }
    }
    
    func changeName(userID: String, to name: String) async throws {
        try await UserManager.shared.changeName(userID: userID, to: name)
    }
}
