//
//  CreateViewModel.swift
//  ReadBox
//
//  Created by Тимофей Юдин on 24.05.2025.
//

import SwiftUI
import _PhotosUI_SwiftUI
import FirebaseStorage

final class CreateViewModel: ObservableObject {
    private static var defaultLanguageSelection: Int {
        Locale.preferredLanguages.first?.components(separatedBy: "-").first == "ru" ? 1 : 0
    }
    
    @Published var isFirstTapOnTitleTE = true
    
    @Published var titleText = NSLocalizedString("titlePlaceholder", comment: "")
    @Published var isTitleTESelected = false
    
    @Published var imageItem: PhotosPickerItem? = nil
    
    @Published var oldMediaCount = 0
    
    @Published var isErrorPopupPresented = false
    
    @Published var isTextCreateViewPresented = false
    
    @Published var navigationTitle = ""
    
    @Published var errorText = ""
    
    @Published var isFirstAppear = true
    
    @Published var languageSelection = CreateViewModel.defaultLanguageSelection
    @Published var isPremiumPostSetting = 0
    
    @Published var mediaURLs: [URL] = []
    
//    @Published var titleTEHeight: CGFloat = 300
    
    @Published var isCoverLoading = false
    @Published var imagePickerTask: Task<Void, Never>? = nil
    
    func getNavigationTitle(_ isEditing: Bool, isLocalizing: Bool, rootLang: String) -> String {
        if isLocalizing {
            return (rootLang == "en" ? "RU" : "EN") + " \(NSLocalizedString("localizationLabel", comment: ""))"
        }
        return isEditing ? NSLocalizedString("editingLabel", comment: "") : NSLocalizedString("creationLabel", comment: "")
    }
}
