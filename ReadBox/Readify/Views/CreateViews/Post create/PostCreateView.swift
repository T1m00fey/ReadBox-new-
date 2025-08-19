//
//  PostCreateView.swift
//  ReadBox
//
//  Created by Тимофей Юдин on 18.08.2025.
//

import SwiftUI
import PhotosUI

struct PostCreateView: View {
    @StateObject private var viewModel = PostCreateViewModel()
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                
                VStack {
//                    PhotosPicker(selection: $viewModel.imageItem, matching: .any(of: [.images, .videos])) {
//                        Text("")
//                    }
                    
                    ZStack {
                        TextEditor(text: $viewModel.text)
                            .font(.system(size: 22))
                            .fontDesign(.rounded)
                            .frame(
                                width: UIScreen.main.bounds.width - 32,
                                height: 300,
                                alignment: .topLeading
                            )
                            .padding(.bottom, 20)
                        
                        Text("Что нового?")
                            .font(.system(size: 22))
                            .foregroundStyle(Color.gray)
                            .fontDesign(.rounded)
                            .frame(width: UIScreen.main.bounds.width - 32, height: 300, alignment: .topLeading)
                            .padding(.leading, 10)
                            .opacity(viewModel.text.isEmpty ? 1 : 0)
                    }
                }
                
            }
            .scrollClipDisabled()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Отмена")
                        .font(.system(size: 18))
                        .fontDesign(.rounded)
                        .onTapGesture {
                            dismiss()
                        }
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Новый пост")
                        .font(.system(size: 20))
                        .fontDesign(.rounded)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Image(systemName: "paperplane.circle.fill")
                        .foregroundStyle(Color(.label))
                        .font(.system(size: 26))
                }
            }
            
        }
    }
}

#Preview {
    PostCreateView()
}
