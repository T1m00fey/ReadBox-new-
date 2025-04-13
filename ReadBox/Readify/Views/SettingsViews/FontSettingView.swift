//
//  FontSettingView.swift
//  Readify
//
//  Created by Тимофей Юдин on 05.01.2025.
//

import SwiftUI

struct FontSettingView: View {
    @Binding var isPopupPresented: Bool
    @Binding var successText: String
    @Binding var isSuccessPopupPresented: Bool
    
    @State private var fontSize: Double = 0
    
    var body: some View {
        VStack {
            Capsule()
                .frame(width: 25, height: 5)
                .foregroundStyle(Color.gray)
                .padding(.top, 5)
            
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
                .padding(.bottom, 150)
        }
        .onAppear {
            fontSize = Double(StorageManager.shared.getFontSize())
            
            if fontSize == 0 {
                fontSize = 18
                StorageManager.shared.setFont(size: 18)
            }
        }
        .onChange(of: isPopupPresented) { newValue in
            if !isPopupPresented {
                if StorageManager.shared.getFontSize() != Int(fontSize) {
                    StorageManager.shared.setFont(size: Int(fontSize))
                    successText = NSLocalizedString("fontSizeChangedAlert", comment: "")
                    isSuccessPopupPresented = true
                }
            }
        }
        .frame(width: UIScreen.main.bounds.width)
        .frame(minHeight: 100)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 30))
    }
}

#Preview {
    FontSettingView(isPopupPresented: .constant(true), successText: .constant(""), isSuccessPopupPresented: .constant(true))
}
