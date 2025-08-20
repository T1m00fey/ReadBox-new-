//
//  CustomSegmentedControl.swift
//  ReadBox
//
//  Created by Macbook Pro on 14.07.2025.
//

import SwiftUI

struct CustomSegmentedControl: View {
    @Binding var selectedLanguage: String
    
    private var titles = ["En", "Ru"]
    
    init(selectedLanguage: Binding<String>) {
        self._selectedLanguage = selectedLanguage
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .frame(width: (UIScreen.main.bounds.width - 32) / 2, height: 45)
                .foregroundStyle(Color(.label))
                .offset(x: selectedLanguage == "en" ? -UIScreen.main.bounds.width / 4 + 10 : UIScreen.main.bounds.width / 4 - 10)
            
            HStack(spacing: 0) {
                ForEach(titles, id: \.self) { title in
                    Text(title)
                        .font(
                            .system(
                                size: isSelected(title) ? 25 : 18,
                                weight: .light,
                                design: .rounded
                            )
                        )
                        .foregroundStyle(
                            isSelected(title)
                            ? Color(.secondarySystemBackground)
                            : Color(.label)
                        )
                        .frame(width: (UIScreen.main.bounds.width - 32) / 2, height: 50)
//                        .background(
//                            isSelected(title)
//                            ? Color(.label)
//                            : Color(.secondarySystemBackground)
//                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .onTapGesture {
                            withAnimation {
                                selectedLanguage = title.lowercased()
                            }
                        }
                    
                }
            }
            .frame(width: UIScreen.main.bounds.width - 32, height: 50)
        }
    }
    
    private func isSelected(_ title: String) -> Bool {
        title.lowercased() == selectedLanguage
        ? true
        : false
    }
}
