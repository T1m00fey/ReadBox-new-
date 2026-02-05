//
//  PostCreateSettingsView.swift
//  ReadBox
//
//  Created by Тимофей Юдин on 13.01.2026.
//

import SwiftUI

struct PostCreateSettingsView: View {
    @Binding var selectedLanguage: Int
    @Binding var selectedMediaPosition: Int
    
    var body: some View {
        VStack(spacing: 20) {
            
            Text("Настройки")
                .font(.system(size: 28))
                .fontDesign(.rounded)
                .frame(width: UIScreen.main.bounds.width - 32, alignment: .leading)
                .padding(.bottom, 5)
            
            VStack(spacing: 10) {
                Text(NSLocalizedString("whichFeedUploadingToLabel", comment: ""))
                    .font(.system(size: 17))
                    .foregroundStyle(.gray)
                    .frame(width: UIScreen.main.bounds.width - 32, alignment: .leading)
                
                CustomSegmentedControl(selected: $selectedLanguage)
            }
            
            VStack(spacing: 10) {
                Text("Расположение медиа")
                    .font(.system(size: 17))
                    .foregroundStyle(.gray)
                    .frame(width: UIScreen.main.bounds.width - 32, alignment: .leading)
                
                CustomSegmentedControl(selected: $selectedMediaPosition, type: .postCreateSettings)
            }
            
        }
    }
}
