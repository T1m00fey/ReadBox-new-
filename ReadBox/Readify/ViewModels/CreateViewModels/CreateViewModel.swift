//
//  CreateViewModel.swift
//  ReadBox
//
//  Created by Тимофей Юдин on 24.05.2025.
//

import SwiftUI
import _PhotosUI_SwiftUI

final class CreateViewModel: ObservableObject {
    @Published var isDescriptionAdded = false
    
    @Published var isFirstTapOnTitleTE = true
    @Published var isFirstTapOnDescriptionTE = true
    
    @Published var titleText = NSLocalizedString("titlePlaceholder", comment: "")
    @Published var isTitleTESelected = false
    
    @Published var image: UIImage? = nil
    @Published var imageItem: PhotosPickerItem? = nil
    
    @Published var videoURL: URL? = nil
    @Published var isVideoCover = false
    
    @Published var descriptionText = NSLocalizedString("descriptionPlaceholder", comment: "")
    @Published var isDescriptionTESelected = false
    
    @Published var isErrorPopupPresented = false
    
    @Published var isTextCreateViewPresented = false
    
    @Published var navigationTitle = ""
    
    @Published var errorText = ""
    
    @Published var isFirstAppear = true
    
    @Published var languageSelection = StorageManager.shared.getLanguage()
    
    @Published var mediaURLs: [URL] = []
    
    @Published var titleTEHeight: CGFloat = 200
    
    func getNavigationTitle(_ isEditing: Bool) -> String {
        isEditing ? NSLocalizedString("editingLabel", comment: "") : NSLocalizedString("creationLabel", comment: "")
    }
}
