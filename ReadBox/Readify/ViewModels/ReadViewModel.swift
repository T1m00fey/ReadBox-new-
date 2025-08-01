//
//  ReadViewModel.swift
//  ReadBox
//
//  Created by Тимофей Юдин on 24.05.2025.
//

import SwiftUI
import FirebaseStorage

final class ReadViewModel: ObservableObject {
    @Published var isPostLiked = false
    @Published var errorText = ""
    @Published var isErrorPopupPresented = false
    @Published var likesCount = 0
    @Published var fontSize = 0
    @Published var isFontSettingPopupPresented = false
    @Published var image = UIImage()
    @Published var avatarImage: UIImage? = nil
    @Published var videoURL: URL? = nil
    @Published var scrollOffset: CGFloat = 0
    
    @Published var selectedImageURL: URL? = nil
    @Published var isImageFullscreenPresented = false
    
    let vibrationsService = VibrationsService.shared
    
    func getAvatar(_ authorId: String) {
        DispatchQueue.main.async {
            let storage = Storage.storage()
            let storageRef = storage.reference()
            let islandRef = storageRef.child("avatars/\(authorId).jpg")
            
            islandRef.getData(maxSize: 1 * 5012 * 5012) { data, error in
                if let error = error {
                    print(error.localizedDescription)
                } else {
                    withAnimation {
                        self.avatarImage = UIImage(data: data!)
                    }
                }
            }
        }
    }
    
    func addLikedPost(userId: String, articleId: String) async throws {
        try await UserManager.shared.addLikedPost(id: userId, likedPost: articleId)
    }
    
    func removeLikedPost(userId: String, articleId: String) async throws {
        try await UserManager.shared.removeLikedPost(id: userId, likedPost: articleId)
    }
    
    func updateLikes(at article: String, likesCount: Int) async throws {
        try await ArticlesManager.shared.updateLikes(at: article, likesCount: likesCount)
    }
    
    func fetchImage(byId id: String) {
        let image = StorageManager.shared.getImage(id: id)
        
        if let image {
            withAnimation {
                self.image = image
            }
        } else {
            let imageRef = Storage.storage().reference().child("images/\(id).jpg")
            
            imageRef.getData(maxSize: 1 * 5012 * 5012) { data, error in
                if let data {
                    withAnimation {
                        self.image = UIImage(data: data) ?? UIImage()
                        StorageManager.shared.saveImage(id: id, image: self.image)
                    }
                } else {
                    let videoRef = Storage.storage().reference().child("images/\(id).mp4")
                    videoRef.downloadURL { url, error in
                        if let url {
                            DispatchQueue.main.async {
                                withAnimation {
                                    self.videoURL = url
                                }
                            }
                        } else {
                            print("Ни фото, ни видео не найдено")
                        }
                    }
                }
            }
        }
    }
    
    func un_subcribeUser(on authorId: String, isNeedToSubscribe: Bool) async throws {
        try await UserManager.shared.un_subscribeUser(
            on: authorId,
            isNeedToSubscribe: isNeedToSubscribe
        )
    }
    
//    func getMarkdownText(_ text: String) -> NSAttributedString {
//        let preMarkdown = text.replacingOccurrences(of: "/n", with: "\n")
//
//        let markdownString = SwiftyMarkdown(string: preMarkdown)
//        markdownString.bold.fontSize = CGFloat(fontSize)
//        markdownString.body.fontSize = CGFloat(fontSize)
//        markdownString.blockquotes.fontSize = CGFloat(fontSize)
//        markdownString.italic.fontSize = CGFloat(fontSize)
//        markdownString.code.fontSize = CGFloat(fontSize)
//        markdownString.strikethrough.fontSize = CGFloat(fontSize)
//        markdownString.link.fontSize = CGFloat(fontSize)
//        markdownString.h1.fontSize = CGFloat(fontSize)
//        markdownString.h2.fontSize = CGFloat(fontSize)
//        markdownString.h3.fontSize = CGFloat(fontSize)
//        markdownString.h4.fontSize = CGFloat(fontSize)
//        markdownString.h5.fontSize = CGFloat(fontSize)
//        markdownString.h6.fontSize = CGFloat(fontSize)
//
//
//        return markdownString.attributedString()
//    }
    
    func getDateCreated(regDate: Date) -> String {
        let timeInterval = Int(Date().timeIntervalSince(regDate)) / 60 / 60 / 24
        var date = ""
        
        if StorageManager.shared.getLanguage() == "ru" {
            if timeInterval > 30 && timeInterval < 365 {
                if timeInterval / 30 == 1 {
                    date = "\(timeInterval / 30) месяц назад"
                } else if (2...4).contains(timeInterval / 30) {
                    date = "\(timeInterval / 30) месяца назад"
                } else {
                    date = "\(timeInterval / 30) месяцев назад"
                }
            } else if timeInterval >= 365 {
                if (11...14).contains(timeInterval / 365) {
                    date = "\(timeInterval / 365) лет назад"
                } else if timeInterval / 365 % 10 == 1 {
                    date = "\(timeInterval / 365) год назад"
                } else if timeInterval / 365 % 10 == 2 || timeInterval / 365 % 10 == 4 || timeInterval / 365 % 10 == 3 {
                    date = "\(timeInterval) года назад"
                } else {
                    date = "\(timeInterval) лет назад"
                }
            } else {
                if timeInterval == 11 || timeInterval == 12 || timeInterval == 13 || timeInterval == 14 {
                    date = "\(timeInterval) дней назад"
                } else if timeInterval % 10 == 1 {
                    date = "\(timeInterval) день назад"
                } else if timeInterval % 10 == 2 || timeInterval % 10 == 4 || timeInterval % 10 == 3 {
                    date = "\(timeInterval) дня назад"
                } else if timeInterval == 0 {
                    date = "Сегодня"
                } else {
                    date = "\(timeInterval) дней назад"
                }
            }
            
        } else {
            if timeInterval > 30 && timeInterval < 365 {
                if timeInterval / 30 == 1 {
                    date = "\(timeInterval / 30) month ago"
                } else {
                    date = "\(timeInterval / 30) months ago"
                }
            } else if timeInterval >= 365 {
                if timeInterval / 365 == 1 {
                    date = "\(timeInterval / 365) year ago"
                } else {
                    date = "\(timeInterval / 365) years ago"
                }
            } else {
                if timeInterval == 1 {
                    date = "\(timeInterval) day ago"
                } else if timeInterval == 0 {
                    date = "Today"
                } else {
                    date = "\(timeInterval) days ago"
                }
            }
        }
        
        return date
    }
}
