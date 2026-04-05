//
//  PostCreateSettingsView.swift
//  ReadBox
//
//  Created by Тимофей Юдин on 13.01.2026.
//

import SwiftUI

struct PostCreateSettingsView: View {
    let isLocalizing: Bool
    let isPremiumAuthor: Bool
    let localizationCount: Int
    
    @Binding var selectedLanguage: Int
    @Binding var selectedMediaPosition: Int
    @Binding var premiumSetting: Int
    
    var body: some View {
        VStack(spacing: 20) {
            
            Text(NSLocalizedString("settingsPostCreateLabel", comment: ""))
                .font(.system(size: 28))
                .fontDesign(.rounded)
                .frame(width: UIScreen.main.bounds.width - 32, alignment: .leading)
                .padding(.bottom, 5)
            
            VStack(spacing: 10) {
                if !isLocalizing && localizationCount == 0 {
                    CustomSegmentedControl(selected: $selectedLanguage)
                }
                
                CustomSegmentedControl(selected: $selectedMediaPosition, type: .postCreateSettings)
                
                if isPremiumAuthor && !isLocalizing {
                    CustomSegmentedControl(selected: $premiumSetting, type: .premiumSetting)
                }
            }                        
            
        }
    }
}
