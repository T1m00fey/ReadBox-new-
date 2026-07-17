//
//  AuthenticationManager.swift
//  Readify
//
//  Created by Тимофей Юдин on 27.10.2024.
//

import Foundation
import FirebaseAuth

struct AuthDataResultModel {
    let uid: String
    let email: String?

    init(user: User) {
        self.uid = user.uid
        self.email = user.email
    }
}

final class AuthenticationManager {

    static let shared = AuthenticationManager()
    private init() {}

    @discardableResult
    func createUser(withEmail email:  String, andPassword password: String) async throws -> AuthDataResultModel {
        let authDataResult = try await Auth.auth().createUser(withEmail: email, password: password)
        let user = AuthDataResultModel(user: authDataResult.user)
        AnalyticsManager.shared.setAuthenticatedUser(id: user.uid)
        return user
    }

    @discardableResult
    func signInUser(withEmail email:  String, andPassword password: String) async throws -> AuthDataResultModel {
        let authDataResult = try await Auth.auth().signIn(withEmail: email, password: password)
        let user = AuthDataResultModel(user: authDataResult.user)
        AnalyticsManager.shared.setAuthenticatedUser(id: user.uid)
        return user
    }

    func getAuthenticatedUser() throws -> AuthDataResultModel {
        guard let user = Auth.auth().currentUser else {
            throw URLError(.badServerResponse)
        }

        return AuthDataResultModel(user: user)
    }

    func signOut() throws {
        try Auth.auth().signOut()
        AnalyticsManager.shared.clearAuthenticatedUser()
    }

    func resetPassword(withEmail email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }

    func delete() async throws {
        guard let user = Auth.auth().currentUser else {
            throw URLError(.badURL)
        }

        try await user.delete()
        AnalyticsManager.shared.clearAuthenticatedUser()
    }

    func updatePassword(to password: String) async throws {
        guard let user = Auth.auth().currentUser else {
            throw URLError(.badServerResponse)
        }

        try await user.updatePassword(to: password)
    }
}
