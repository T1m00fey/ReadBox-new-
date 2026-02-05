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
            Capsule()
                .frame(width: 25, height: 5)
                .foregroundStyle(Color.gray)
                .padding(.top, 5)
            
            Text(NSLocalizedString("newVersionAlert", comment: ""))
                .font(.system(size: 25))
                .fontWeight(.light)
                .fontDesign(.rounded)
                .frame(width: UIScreen.main.bounds.width - 32, alignment: .center)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .padding(.bottom, 20)
                
            if isCritical {
                Text(NSLocalizedString("criticalUpdateAlert", comment: ""))
                    .font(.system(size: 16))
                    .foregroundStyle(Color.gray)
                    .fontWeight(.light)
                    .fontDesign(.rounded)
                    .frame(width: UIScreen.main.bounds.width - 32, alignment: .center)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 20)
            }
            
            if #available(iOS 26, *) {
                Button {
                    openURL(
                        URL(
                            string: "https://apps.apple.com/ru/app/readbox-%D1%81%D1%82%D0%B0%D1%82%D1%8C%D0%B8-%D0%B8-%D0%B8%D1%81%D1%82%D0%BE%D1%80%D0%B8%D0%B8/id6745975985"
                        )!
                    )
                } label: {
                    Text(NSLocalizedString("updateLabel", comment: ""))
                        .font(.system(size: 20))
                        .foregroundStyle(Color(uiColor: .systemBackground))
                        .frame(width: UIScreen.main.bounds.width - 80)
                }
                .tint(Color(.label))
                .buttonStyle(.glassProminent)
                .padding(.bottom, 50)
            } else {
                Button {
                    openURL(
                        URL(
                            string: "https://apps.apple.com/ru/app/readbox-%D1%81%D1%82%D0%B0%D1%82%D1%8C%D0%B8-%D0%B8-%D0%B8%D1%81%D1%82%D0%BE%D1%80%D0%B8%D0%B8/id6745975985"
                        )!
                    )
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .frame(width: UIScreen.main.bounds.width - 40, height: 50)
                            .foregroundStyle(Color(uiColor: .systemBackground))
                            .shadow(radius: 1)
                        
                        Text(NSLocalizedString("updateLabel", comment: ""))
                            .font(.system(size: 20))
                            .foregroundStyle(Color(uiColor: .label))
                    }
                }
                .padding(.bottom, 50)
            }
            
        }
        .frame(width: UIScreen.main.bounds.width)
        .frame(minHeight: 100)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 30))
    }
}

#Preview {
    VersionPopupView(isCritical: true)
}
