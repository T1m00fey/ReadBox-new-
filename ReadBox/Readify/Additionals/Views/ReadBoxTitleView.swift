//
//  ReadBoxTitleView.swift
//  ReadBox
//
//  Created by Тимофей Юдин on 06.07.2026.
//

import SwiftUI

struct ReadBoxTitleView: View {
    var body: some View {
        HStack(spacing: 11) {
            Image("logo")
                .resizable()
                .scaledToFill()
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(uiColor: .label).opacity(0.09), lineWidth: 1)
                }

            Text("ReadBox")
                .font(.system(size: 21, weight: .regular))
                .tracking(-0.63)
        }
        .foregroundStyle(Color(uiColor: .label))
        .accessibilityElement(children: .combine)
    }
}
