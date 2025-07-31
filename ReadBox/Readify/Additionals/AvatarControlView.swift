//
//  AvatarControlView.swift
//  ReadBox
//
//  Created by Macbook Pro on 28.07.2025.
//

import SwiftUI
import FirebaseStorage
import PhotosUI

struct AvatarControlView: View {
    let authorId: String
    
    @Binding var avatarImage: UIImage?
    
    @State private var pickerItem: PhotosPickerItem? = nil
    
    var body: some View {
        PhotosPicker(selection: $pickerItem, matching: .images) {
            if let avatarImage {
                ZStack {
                    Image(uiImage: avatarImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                        .overlay {
                            Circle()
                                .stroke(
                                    Color(.label),
                                    lineWidth: 0.1
                                )
                        }
                    
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color(.label))
                        .font(.system(size: 25))
                        .offset(x: 30, y: -30)
                        .shadow(radius: 3)
                        .onTapGesture {
                            withAnimation {
                                self.avatarImage = nil
                            }
                        }
                }
            } else {
                Image(systemName: "plus.circle")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundStyle(Color.gray)
            }
        }
        .onChange(of: pickerItem) {
            Task {
                if let data = try? await pickerItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    withAnimation {
                        avatarImage = image
                        StorageManager.shared.saveImage(id: authorId, image: image)
                    }
                }
            }
        }
    }
}
