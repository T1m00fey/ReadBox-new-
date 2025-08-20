//
//  PostCreateViewModel.swift
//  ReadBox
//
//  Created by Тимофей Юдин on 18.08.2025.
//

import SwiftUI
import PhotosUI

final class PostCreateViewModel: ObservableObject {
    @Published var text = ""
    @Published var isArchive = false
    @Published var imageItem: PhotosPickerItem? = nil
    @Published var selectedLanguage: String = StorageManager.shared.getLanguage()
    @Published var addingMode = 0
    
    @Published var isConfirmationPopupPresented = false
    
    func uploadPost(
        title: String,
        isArchive: Bool,
        uploadingLanguage: String
    ) async throws -> String {
        try await ArticlesManager.shared.addNewPost(
            title: title,
            text: "",
            isArchive: isArchive,
            uploadingLanguage: uploadingLanguage
        )
    }
    
    func updatePost(
        postId: String,
        title: String,
        isArchive: Bool,
        uploadingLanguage: String
    ) async throws {
        try await ArticlesManager.shared.updatePost(
            id: postId,
            title: title,
            text: "",
            isArchive: isArchive
        )
    }
}
