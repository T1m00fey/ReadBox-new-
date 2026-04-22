//
//  CommentariesView.swift
//  ReadBox
//
//  Created by Тимофей Юдин on 14.04.2026.
//

import SwiftUI

struct CommentariesView: View {
    var body: some View {
        VStack {
            Text("Комментарии")
                .frame(width: UIScreen.main.bounds.width - 20, alignment: .leading)
                .font(.system(size: 20))
                .fontWeight(.semibold)
            
            
        }
    }
}

#Preview {
    CommentariesView()
}
