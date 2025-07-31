//
//  ConfirmationView.swift
//  Readify
//
//  Created by Тимофей Юдин on 25.02.2025.
//

import SwiftUI

struct ConfirmationView: View {
    @Binding var addingMode: Int
    
    private let vibrationsService = VibrationsService.shared
    
    var body: some View {
        VStack {
            Capsule()
                .frame(width: 25, height: 5)
                .foregroundStyle(Color.gray)
                .padding(.top, 5)
            
            Text(LocalizedStringKey("publishItLabel"))
                .font(.title)
                .fontWeight(.light)
                .fontDesign(.rounded)
                .frame(width: UIScreen.main.bounds.width - 32, alignment: .leading)
            
            Button {
                vibrationsService.lightImpact()
                addingMode = 1
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .foregroundStyle(Color(uiColor: .label))
                        .shadow(radius: 2)
                    
                    HStack {
                        Image(systemName: "paperplane")
                            .foregroundStyle(Color(uiColor: .systemBackground))
                            .font(.system(size: 25))
                        
                        Text(LocalizedStringKey("publishLabel"))
                            .font(.title2)
                            .fontWeight(.light)
                            .fontDesign(.rounded)
                            .foregroundStyle(Color(uiColor: .systemBackground))
                    }
                    .frame(width: UIScreen.main.bounds.width - 64)
                }
            }
            .frame(width: UIScreen.main.bounds.width - 32, height: 60)
            
            Button {
                addingMode = 2
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .foregroundStyle(Color(uiColor: .systemBackground))
                        .shadow(radius: 2)
                    
                    HStack {
                        Image(systemName: "archivebox")
                            .foregroundStyle(Color.gray)
                            .font(.system(size: 25))
                        
                        Text(LocalizedStringKey("saveToArchiveLabel"))
                            .font(.title2)
                            .fontWeight(.light)
                            .fontDesign(.rounded)
                            .foregroundStyle(Color.gray)
                    }
                    .frame(width: UIScreen.main.bounds.width - 64)
                }
            }
            .frame(width: UIScreen.main.bounds.width - 32, height: 60)
            .padding(.bottom, 100)
            
        }
        .frame(width: UIScreen.main.bounds.width)
        .frame(minHeight: 100)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 30))
    }
}

#Preview {
    ConfirmationView(addingMode: .constant(0))
}
