//
//  CustomSegmentedControl.swift
//  ReadBox
//
//  Created by Macbook Pro on 14.07.2025.
//

import SwiftUI

enum SegmentedTypes {
    case language
    case postCreateSettings
}

struct CustomSegmentedControl: View {
    @Binding var selected: Int
    let type: SegmentedTypes
    
    var titles: [String] {
        switch type {
        case .language:
            ["En", "Ru"]
        case .postCreateSettings:
            ["Сверху", "Снизу"]
        }
    }
    
    init(
        selected: Binding<Int>,
        type: SegmentedTypes = .language
    ) {
        self._selected = selected
        self.type = type
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .frame(width: (UIScreen.main.bounds.width - 32) / 2, height: 45)
                .foregroundStyle(Color(.label))
                .offset(x: selected == 0 ? -UIScreen.main.bounds.width / 4 + 10 : UIScreen.main.bounds.width / 4 - 10)
            
            HStack(spacing: 0) {
                ForEach(0..<2, id: \.self) { i in
                    Text(titles[i])
                        .font(
                            .system(
                                size: isSelected(i) ? 25 : 18,
                                weight: .light,
                                design: .rounded
                            )
                        )
                        .foregroundStyle(
                            isSelected(i)
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
                                selected = i
                            }
                        }
                    
                }
            }
            .frame(width: UIScreen.main.bounds.width - 32, height: 50)
        }
    }
    
    private func isSelected(_ i: Int) -> Bool {
        selected == i
        ? true
        : false
    }
}
