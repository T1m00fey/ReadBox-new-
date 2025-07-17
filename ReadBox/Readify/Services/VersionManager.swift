//
//  VersionManager.swift
//  ReadBox
//
//  Created by Macbook Pro on 18.06.2025.
//

import Foundation
import FirebaseFirestore

final class VersionManager {
    static let shared = VersionManager()
    private init() {}
    
    func getRelevantVersion() async throws -> AppVersion? {
        let version = try await Firestore.firestore().collection("app_version").document("0").getDocument(as: AppVersion.self)
        
        return version
    }
}
