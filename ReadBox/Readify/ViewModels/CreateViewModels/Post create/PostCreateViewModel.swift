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
    @Published var selectedLanguage: String = StorageManager.shared.getLanguage()
    @Published var addingMode = 0
    @Published var isLoading = false
    @Published var media: [MediaKind] = []
    @Published var oldMediaCount = 0
    @Published var isCoverLoading = false
    @Published var imagePickerTask: Task<Void, Never>? = nil
    
    @Published var errorText = ""
    @Published var isErrorPopupPresented = false
    
    @Published var isConfirmationPopupPresented = false
    
    private func deleteAllCovers(postId: String, mediaCount: Int) async {
        for i in 0..<mediaCount {
            let imageRef = Storage.storage().reference(withPath: "images/\(postId)_\(i).jpg")
            let videoRef = Storage.storage().reference(withPath: "images/\(postId)_\(i).mp4")
            
            try? await imageRef.delete()
            try? await videoRef.delete()
            
            StorageManager.shared.deleteImage(id: "\(postId)_\(i)")
        }
    }
    
    private func uploadCover(media: MediaKind, postId: String, index: Int) async throws {        
        if let image = media.image {
            let ref = Storage.storage().reference(withPath: "images/\(postId)_\(index).jpg")
            _ = try await ref.putDataAsync(image.jpegData(compressionQuality: 0.9)!)
            
            StorageManager.shared.saveImage(id: "\(postId)_\(index)", image: image)
        } else if let videoURL = media.videoURL {
            let data = try Data(contentsOf: videoURL)
            let ref = Storage.storage().reference(withPath: "images/\(postId)_\(index).mp4")
            _ = try await ref.putDataAsync(data)
        }
    }
    
    func uploadPost(
        title: String,
        isArchive: Bool,
        uploadingLanguage: String,
        mediaCount: Int
    ) async throws -> String {
        let id = try await ArticlesManager.shared.addNewPost(
            title: title,
            text: "",
            isArchive: isArchive,
            uploadingLanguage: uploadingLanguage,
            mediaCount: mediaCount,
            isShortPost: true
        )
        
        for i in 0..<media.count {
            try await uploadCover(
                media: media[i],
                postId: id,
                index: i
            )
        }
        
        return id
    }
        
    func updatePost(
        postId: String,
        title: String,
        isArchive: Bool,
        uploadingLanguage: String,
        mediaCount: Int
    ) async throws {
        await deleteAllCovers(postId: postId, mediaCount: oldMediaCount)
        
        try await ArticlesManager.shared.updatePost(
            id: postId,
            title: title,
            text: "",
            isArchive: isArchive,
            uploadingLanguage: uploadingLanguage,
            mediaCount: mediaCount
        )
        
        for i in 0..<media.count {
            try await uploadCover(
                media: media[i],
                postId: postId,
                index: i
            )
        }
    }
}
