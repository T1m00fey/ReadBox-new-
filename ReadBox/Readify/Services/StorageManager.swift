//
//  StorageManager.swift
//  Readify
//
//  Created by Тимофей Юдин on 09.11.2024.
//

import SwiftUI

final class StorageManager {
    static let shared = StorageManager()
    private init() {}
    
    private let userDefaults = UserDefaults.standard
    
    func saveImage(id: String, image: UIImage) {
        let article = ArticleImage(id: id, image: image.jpegData(compressionQuality: 1))
        
        guard let data = try? JSONEncoder().encode(article) else { return }
        userDefaults.set(data, forKey: id)
    }
    
    func getImage(id: String) -> UIImage? {
        guard let data = userDefaults.data(forKey: id) else { return nil }
        guard let articleImage = try? JSONDecoder().decode(ArticleImage.self, from: data) else { return nil }
        
        if let imageData = articleImage.image {
            return UIImage(data: imageData)
        } else {
            return nil
        }
    }
    
    func deleteImage(id: String) {
        userDefaults.removeObject(forKey: id)
    }
    
    func setLanguage(to language: String) {
        userDefaults.set(language, forKey: "language")
    }
    
    func getLanguage() -> String {
        userDefaults.string(forKey: "language") ?? ""
    }
    
    func getFontSize() -> Int {
        let fontSize = userDefaults.integer(forKey: "fontSize")
        
        if fontSize == 0 {
            return 18
        }
        
        return fontSize
    }
    
    func getViewedPosts() -> [String] {
        userDefaults.array(forKey: "viewedPosts") as? [String] ?? []
    }
    
    func setViewedPosts(_ posts: [String]) {
        userDefaults.set(posts, forKey: "viewedPosts")
    }
    
    func setFont(size: Int) {
        userDefaults.set(size, forKey: "fontSize")
    }
    
    func save(text: String) {
        userDefaults.set(text, forKey: "createText")
    }
    
    func deleteText() {
        userDefaults.removeObject(forKey: "createText")
    }
    
    func getText() -> String {
        userDefaults.string(forKey: "createText") ?? ""
    }
    
    func save(views: [String]) {
        userDefaults.set(views, forKey: "views")
    }
    
    func getViews() -> [String] {
        userDefaults.array(forKey: "views") as? [String] ?? []
    }
    
    func set(fcmToken: String) {
        userDefaults.set(fcmToken, forKey: "fcmToken")
    }
    
    func getFcmToken() -> String {
        userDefaults.string(forKey: "fcmToken") ?? ""
    }
}
