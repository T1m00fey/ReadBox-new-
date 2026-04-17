//
//  FontSettingView.swift
//  Readify
//
//  Created by Тимофей Юдин on 05.01.2025.
//

import SwiftUI

struct FontSettingView: View {
    @Binding var isPopupPresented: Bool
    @Binding var selectedFontSize: Int
    @Binding var successText: String
    @Binding var isSuccessPopupPresented: Bool
    
    @State private var fontSize: Double = 0
    @State private var startFontSize = 0
    
    var body: some View {
        VStack {
            Text("\(NSLocalizedString("fontLabel", comment: "")): \(Int(fontSize))")
                .font(.title)
                .fontWeight(.light)
                .fontDesign(.rounded)
                .frame(width: UIScreen.main.bounds.width - 32, alignment: .leading)
            
            Slider(value: $fontSize, in: 14...32, step: 1) {
                
            } minimumValueLabel: {
                Text("14")
                    .font(.title2)
                    .fontDesign(.rounded)
                    .fontWeight(.light)
            } maximumValueLabel: {
                Text("32")
                    .font(.title2)
                    .fontDesign(.rounded)
                    .fontWeight(.light)
            }
                .foregroundStyle(Color(uiColor: .label))
                .frame(width: UIScreen.main.bounds.width - 32, height: 50)
                .tint(Color(uiColor: .label))
                .padding(.bottom, 100)
        }
        .onAppear {
            startFontSize = selectedFontSize == 0
            ? StorageManager.shared.getFontSize()
            : selectedFontSize
            fontSize = Double(startFontSize)
            
            if startFontSize == 0 {
                fontSize = 18
                startFontSize = 18
                StorageManager.shared.setFont(size: 18)
                selectedFontSize = 18
            }
        }
        .onChange(of: fontSize) {
            let newFontSize = Int(fontSize)
            selectedFontSize = newFontSize
            StorageManager.shared.setFont(size: newFontSize)
        }
        .onDisappear {
            if startFontSize != Int(fontSize) {
                successText = NSLocalizedString("fontSizeChangedAlert", comment: "")
                isSuccessPopupPresented = true
            }
        }
    }
}

#Preview {
    FontSettingView(
        isPopupPresented: .constant(true),
        selectedFontSize: .constant(18),
        successText: .constant(""),
        isSuccessPopupPresented: .constant(true)
    )
}
