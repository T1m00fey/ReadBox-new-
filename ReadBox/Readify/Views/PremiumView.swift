//
//  PremiumView.swift
//  ReadBox
//
//  Created by Тимофей Юдин on 24.02.2026.
//

import SwiftUI

struct PremiumView: View {
    @EnvironmentObject var sub: SubscriptionManager
    
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.secondarySystemBackground)
                    .ignoresSafeArea()
                
                VStack {
                    ZStack {
                        Image("premiumImage")
                            .resizable()
                            .scaledToFit()
                            .frame(width: UIScreen.main.bounds.width)
                        
                        Text("Read+")
                            .font(.custom("Borel-Regular", size: 60))
                            .foregroundStyle(Color(.gray))
                            .offset(x: 10, y: 10)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 12) {
                        VStack(spacing: 20) {
                            makeArgument(title: "Title 1 Title 1 Title 1 Title 1Title 1", subTitle: "Title 1Title 1Title 1Title 1Title 1Title 1Title 1Title 1Title 1")
                            
                            makeArgument(title: "Title 1 Title 1 Title 1 Title 1Title 1", subTitle: "Title 1Title 1Title 1Title 1Title 1Title 1Title 1Title 1Title 1")
                        }
                        .padding(.top, 30)
                        .padding(.horizontal, 20)
                        
                        Spacer()
                        
                        if let p = sub.product {
                            Text("Оформить \(p.displayPrice) / месяц")
                                .font(.system(size: 18))
                                .fontDesign(.rounded)
                                .frame(width: UIScreen.main.bounds.width - 24, height: 50)
                                .background(Color(.label))
                                .foregroundStyle(Color(.systemBackground))
                                .clipShape(Capsule())
                                .onTapGesture {
                                    if !sub.hasPremium {
                                        Task { await sub.buy() }
                                    }
                                }
                        } else {
                            Text("Загрузка...")
                                .font(.system(size: 18))
                                .fontDesign(.rounded)
                                .frame(width: UIScreen.main.bounds.width - 24, height: 50)
                                .background(Color(.label))
                                .foregroundStyle(Color(.systemBackground))
                                .clipShape(Capsule())
                        }
                        
                        Button("Восстановить покупки") {
                            Task { await sub.refreshEntitlements() }
                        }
                        .font(.footnote)
                        .padding(.bottom, 10)
                        
                        HStack(spacing: 8) {
                            Circle()
                                .frame(width: 8, height: 8)
                                .foregroundStyle(sub.hasPremium ? .green : .red)
                            
                            Text(sub.hasPremium ? "Подписка активна" : "Подписка не активна")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                            
                            Button("Обновить") {
                                Task { await sub.refreshEntitlements() }
                            }
                            .font(.caption)
                        }
                        .padding(.horizontal, 10)
                        .padding(.bottom, 20)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .foregroundStyle(Color(.systemBackground))
                            .shadow(radius: 1)
                            .padding(.bottom, -100)
                    )
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Image(systemName: "xmark")
                        .onTapGesture {
                            dismiss()
                        }
                }
            }
        }
    }
}

private extension PremiumView {
    @ViewBuilder
    func makeArgument(title: String, subTitle: String) -> some View {
        VStack {
            HStack(spacing: 5) {
                Circle()
                    .frame(width: 5, height: 5)
                    .foregroundStyle(Color(.label))
                
                Text(title)
                    .font(.system(size: 19))
                    .foregroundStyle(Color(.label))
                    .fontDesign(.rounded)
                    .multilineTextAlignment(.leading)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.leading, -10)
            
            Text(subTitle)
                .font(.system(size: 15))
                .foregroundStyle(Color(.gray))
                .fontDesign(.rounded)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, 20)
        }
    }
}
