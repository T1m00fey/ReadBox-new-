//
//  PostCreateViewModel.swift
//  ReadBox
//
//  Created by Тимофей Юдин on 18.08.2025.
//

import SwiftUI
import PhotosUI
import FirebaseStorage

final class PostCreateViewModel: ObservableObject {
    @Published var text = ""
    @Published var isArchive = false
    @Published var imageItem: PhotosPickerItem? = nil
    @Published var image: UIImage? = nil
    @Published var videoURL: URL? = nil
    @Published var isVideoCover = false
    @Published var selectedLanguage: String = StorageManager.shared.getLanguage()
    @Published var addingMode = 0
    @Published var didChangeCover = false
    @Published var isLoading = false
    
    @Published var errorText = ""
    @Published var isErrorPopupPresented = false
    
    @Published var isConfirmationPopupPresented = false
    
    func setCover(image: UIImage?, isVideo: Bool) {
        self.image = image
        self.isVideoCover = isVideo
    }
    
    private func deleteCover(for id: String, isVideo: Bool) async {
        let path = isVideo ? "images/\(id).mp4" : "images/\(id).jpg"
        let ref = Storage.storage().reference(withPath: path)
        
        do { try await ref.delete() } catch {  }
    }
    
    private func uploadCover(for id: String) async throws {
        if isVideoCover, let url = videoURL {
            let data = try Data(contentsOf: url)
            let ref = Storage.storage().reference(withPath: "images/\(id).mp4")
            _ = try await ref.putDataAsync(data)
            await deleteCover(for: id, isVideo: false)
        } else if let image, image != UIImage() {
            let ref = Storage.storage().reference(withPath: "images/\(id).jpg")
            _ = try await ref.putDataAsync(image.jpegData(compressionQuality: 0.9)!)
            await deleteCover(for: id, isVideo: true)
        } else {
            await deleteCover(for: id, isVideo: true)
            await deleteCover(for: id, isVideo: false)
        }
    }
    
    func uploadPost(
        title: String,
        isArchive: Bool,
        uploadingLanguage: String
    ) async throws -> String {
        let id = try await ArticlesManager.shared.addNewPost(
            title: title,
            text: "",
            isArchive: isArchive,
            uploadingLanguage: uploadingLanguage
        )
        
        try await uploadCover(for: id)
        if !isVideoCover {
            if let image {
                StorageManager.shared.saveImage(id: id, image: image)
            }
        }
        return id
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
            isArchive: isArchive,
            uploadingLanguage: uploadingLanguage
        )
        
        if didChangeCover {
            try await uploadCover(for: postId)
            if !isVideoCover {
                if let image {
                    StorageManager.shared.saveImage(id: postId, image: image)
                }
            }
        }
    }
}
