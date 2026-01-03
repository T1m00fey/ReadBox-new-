//
//  LoadingPopup.swift
//  ReadBox
//
//  Created by Тимофей Юдин on 25.05.2025.
//

import SwiftUI
import SwiftfulLoadingIndicators

struct LoadingPopup: View {
    var body: some View {
        VStack {
            HStack {
                Text("\(NSLocalizedString("loadingLabel", comment: ""))")
                    .font(.largeTitle)
                    .fontWeight(.light)
                    .fontDesign(.rounded)
                
                LoadingIndicator(animation: .circleRunner, color: Color(uiColor: .label), size: .small, speed: .fast)
                    
            }
            .padding(.top, 20)
            .frame(width: UIScreen.main.bounds.width - 32, alignment: .leading)
            .padding(.bottom, 100)
        }
        .frame(width: UIScreen.main.bounds.width)
//        .background(Color(uiColor: .secondarySystemBackground))
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30))
    }
}

#Preview {
    LoadingPopup()
}
