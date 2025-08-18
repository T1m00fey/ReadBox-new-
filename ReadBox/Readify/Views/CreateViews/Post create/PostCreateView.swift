//
//  PostCreateView.swift
//  ReadBox
//
//  Created by Тимофей Юдин on 18.08.2025.
//

import SwiftUI

struct PostCreateView: View {
    @StateObject private var viewModel = PostCreateViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                
                VStack {
                    
                    
                    TextEditor(text: $viewModel.text)
                        .frame(
                            width: UIScreen.main.bounds.width - 32,
                            height: 300
                        )
                        .font(.system(size: 18))
                        .fontDesign(.rounded)
                        .fontWeight(.light)
                }
                
            }
            .scrollClipDisabled()
        }
    }
}

#Preview {
    PostCreateView()
}
