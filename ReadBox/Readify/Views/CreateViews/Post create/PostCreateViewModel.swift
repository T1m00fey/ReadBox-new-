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
    @Published var imageItem: PhotosPickerItem? = nil
}
