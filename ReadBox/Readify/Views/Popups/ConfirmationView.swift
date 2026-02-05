//
//  ConfirmationView.swift
//  Readify
//
//  Created by Тимофей Юдин on 25.02.2025.
//

import SwiftUI

struct ConfirmationView: View {
    @Binding var addingMode: Int
    
    let popupType: PopupType
    
    private let vibrationsService = VibrationsService.shared
    
    enum PopupType {
        case publishType
        case postType
    }
    
    init(
        addingMode: Binding<Int>,
        popupType: PopupType = .publishType
    ) {
        self._addingMode = addingMode
        self.popupType = popupType
    }
    
    var body: some View {
        VStack {
            Text(
                popupType == .publishType
                ? LocalizedStringKey("publishItLabel")
                : LocalizedStringKey("whatWePostingLabel")
            )
                .font(.system(size: 27))
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
                        .shadow(radius: 1)
                    
                    HStack {
                        Image(systemName: "paperplane")
                            .foregroundStyle(Color(uiColor: .systemBackground))
                            .font(.system(size: 25))
                        
                        Text(
                            popupType == .publishType
                            ? LocalizedStringKey("publishLabel")
                            : LocalizedStringKey("postLabel")
                        )
                            .font(.system(size: 21))
                            .fontWeight(.light)
                            .fontDesign(.rounded)
                            .foregroundStyle(Color(uiColor: .systemBackground))
                    }
                    .frame(width: UIScreen.main.bounds.width - 64)
                }
            }
            .frame(width: UIScreen.main.bounds.width - 32, height: 60)
            
            Button {
                vibrationsService.softImpact()
                
                addingMode = 2
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .foregroundStyle(Color(uiColor: .systemBackground))
                        .shadow(radius: 1)
                    
                    HStack {
                        Image(systemName: "archivebox")
                            .foregroundStyle(Color.gray)
                            .font(.system(size: 25))
                        
                        Text(
                            popupType == .publishType
                            ? LocalizedStringKey("saveToArchiveLabel")
                            : LocalizedStringKey("articleLabel")
                        )
                            .font(.system(size: 21))
                            .fontWeight(.light)
                            .fontDesign(.rounded)
                            .foregroundStyle(Color.gray)
                    }
                    .frame(width: UIScreen.main.bounds.width - 64)
                }
            }
            .frame(width: UIScreen.main.bounds.width - 32, height: 60)
        }
    }
}

#Preview {
    ConfirmationView(addingMode: .constant(0))
}
