//
//  CommentView.swift
//  ReadBox
//
//  Created by Тимофей Юдин on 22.04.2026.
//

import SwiftUI

struct CommentView: View {
    let id: String
    let authorId: String
    let text: String
    let likesCount: Int
    
    var body: some View {
        VStack {
            HStack {
                Circle()
                    .frame(width: 35, height: 35)
                
                VStack {
                    HStack(spacing: 2) {
                        Text("AuthorName")
                            .font(.system(size: 15))
                            .lineLimit(1)
                            .fontWeight(.semibold)
                        
                        Text("·")
                            .font(.system(size: 15))
                            .foregroundStyle(Color.gray)
                        
                        Text("@tim_yud")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.gray)
                            .lineLimit(1)
                            
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("2 дня назад")
                        .foregroundStyle(Color.gray)
                        .font(.system(size: 11))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            
            Text(text)
                .font(.system(size: 16))
            
            HStack {
                HStack(spacing: 2) {
                    Image(systemName: "heart")
                        .foregroundStyle(Color.gray)
                        .font(.system(size: 20))
                    
                    Text("\(likesCount)")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.gray)
                }
                .padding(.all, 5)
                .background(
                    Capsule()
                        .foregroundStyle(Color(.secondarySystemBackground))
                )
                
                Spacer()
            }
            .padding(.top, 1)
            
            Divider()
            
        }
        .frame(width: UIScreen.main.bounds.width - 20)
    }
}

#Preview {
    CommentView(
        id: "",
        authorId: "",
        text: "TestTestTestTestTestTestTestTestTestTestTestTestTestTestTestTestTestTestTestTest",
        likesCount: 100
    )
}
