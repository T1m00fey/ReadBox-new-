//
//  VersionPopupView.swift
//  ReadBox
//
//  Created by Macbook Pro on 19.06.2025.
//

import SwiftUI

struct VersionPopupView: View {
    let isCritical: Bool
    
    @Environment(\.openURL) var openURL
    
    var body: some View {
        VStack {
            Text(NSLocalizedString("newVersionAlert", comment: ""))
                .font(.system(size: 25))
                .fontWeight(.light)
                .fontDesign(.rounded)
                .frame(width: UIScreen.main.bounds.width - 32, alignment: .center)
                .multilineTextAlignment(.center)
                .padding(.bottom, 10)
                .padding(.top, 5)
                
            if isCritical {
                Text(NSLocalizedString("criticalUpdateAlert", comment: ""))
                    .font(.system(size: 16))
                    .foregroundStyle(Color.gray)
                    .fontWeight(.light)
                    .fontDesign(.rounded)
                    .frame(width: UIScreen.main.bounds.width - 32, alignment: .center)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 20)
            }

            Text(NSLocalizedString("updateLabel", comment: ""))
                .font(.system(size: 21))
                .foregroundStyle(Color(uiColor: .systemBackground))
                .frame(width: UIScreen.main.bounds.width - 40, height: 45)
                .background(Color(.label))
                .clipShape(Capsule())
                .onTapGesture {
                    openURL(
                        URL(
                            string: "https://apps.apple.com/ru/app/readbox-%D1%81%D1%82%D0%B0%D1%82%D1%8C%D0%B8-%D0%B8-%D0%B8%D1%81%D1%82%D0%BE%D1%80%D0%B8%D0%B8/id6745975985"
                        )!
                    )
                }
        }
    }
}

#Preview {
    VersionPopupView(isCritical: true)
}
