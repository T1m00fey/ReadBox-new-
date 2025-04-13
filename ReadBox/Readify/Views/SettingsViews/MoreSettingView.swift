//
//  MoreSettingView.swift
//  Readify
//
//  Created by Тимофей Юдин on 05.01.2025.
//

import SwiftUI
import SwiftUIMailView

struct MoreSettingView: View {
    @Binding var isMailViewPresented: Bool
    
    var body: some View {
        VStack {
            Capsule()
                .frame(width: 25, height: 5)
                .foregroundStyle(Color.gray)
                .padding(.top, 5)
            
            Text(LocalizedStringKey("moreLabel"))
                .font(.title)
                .fontWeight(.light)
                .fontDesign(.rounded)
                .frame(width: UIScreen.main.bounds.width - 32, alignment: .leading)
            
            Button {
                isMailViewPresented.toggle()
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .foregroundStyle(Color(uiColor: .systemBackground))
                        .shadow(radius: 2)
                    
                    HStack {
                        Image(systemName: "envelope.circle")
                            .foregroundStyle(Color.gray)
                            .font(.system(size: 35))
                        
                        Text(LocalizedStringKey("writeToDeveloperLabel"))
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.title2)
                            .foregroundStyle(Color.gray)
                    }
                    .padding(.horizontal, 16)
                }
            }
            .frame(width: UIScreen.main.bounds.width - 32, height: 60)
            .padding(.bottom, 150)
        }
        .frame(width: UIScreen.main.bounds.width)
        .frame(minHeight: 100)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 30))
    }
}

#Preview {
    MoreSettingView(isMailViewPresented: .constant(true))
}
