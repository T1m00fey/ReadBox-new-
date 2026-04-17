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
    
    @State private var isSubscriptionSheetPresented = false
    
    private let privacyURL = URL(string: "https://readbox-links.online/privacy.html")!
    private let termsURL = URL(string: "https://readbox-links.online/terms.html")!

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
                        VStack(spacing: 25) {
                            makeArgument(
                                title: NSLocalizedString("premiumArgument1Title", comment: ""),
                                subTitle: NSLocalizedString("premiumArgument1Subtitle", comment: "")
                            )
                            
                            makeArgument(
                                title: NSLocalizedString("premiumArgument2Title", comment: ""),
                                subTitle: NSLocalizedString("premiumArgument2Subtitle", comment: "")
                            )
                            
                            makeArgument(
                                title: NSLocalizedString("premiumArgument3Title", comment: ""),
                                subTitle: NSLocalizedString("premiumArgument3Subtitle", comment: "")
                            )
                        }
                        .padding(.top, 30)
                        .padding(.horizontal, 20)
                        
                        Spacer()
                        
                        purchaseButtonView
                            .padding(.bottom, 20)
                        
//                        HStack(spacing: 8) {
//                            Circle()
//                                .frame(width: 8, height: 8)
//                                .foregroundStyle(sub.hasPremium ? .green : .red)
//                            
//                            Text(sub.hasPremium ? "Подписка активна" : "Подписка не активна")
//                                .font(.subheadline)
//                                .foregroundStyle(.secondary)
//                            
//                            Spacer()
//                            
//                            Button("Обновить") {
//                                Task { await sub.refreshEntitlements() }
//                            }
//                            .font(.caption)
//                        }
//                        .padding(.horizontal, 10)
//                        .padding(.bottom, 20)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .foregroundStyle(Color(.systemBackground))
                            .shadow(radius: 2)
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
            .sheet(isPresented: $isSubscriptionSheetPresented) {
                PremiumSubscriptionSheet(
                    privacyURL: privacyURL,
                    termsURL: termsURL
                )
                .environmentObject(sub)
            }
        }
    }
}

private extension PremiumView {
    @ViewBuilder
    var purchaseButtonView: some View {
        if isSubscriptionSheetPresented {
            EmptyView()
        } else if let _ = sub.product {
            Text(LocalizedStringKey("premiumOpenSheetButtonLabel"))
                .font(.system(size: 19))
                .fontDesign(.rounded)
                .frame(width: UIScreen.main.bounds.width - 24, height: 50)
                .background(Color(.label))
                .foregroundStyle(Color(.systemBackground))
                .clipShape(Capsule())
                .onTapGesture {
                    if !sub.hasPremium {
                        isSubscriptionSheetPresented = true
                    }
                }
        } else {
            Text(LocalizedStringKey("loadingLabel"))
                .font(.system(size: 19))
                .fontDesign(.rounded)
                .frame(width: UIScreen.main.bounds.width - 24, height: 50)
                .background(Color(.label))
                .foregroundStyle(Color(.systemBackground))
                .clipShape(Capsule())
        }
    }

    @ViewBuilder
    func makeArgument(title: String, subTitle: String) -> some View {
        VStack {
            HStack(spacing: 7) {
                Circle()
                    .frame(width: 6, height: 6)
                    .foregroundStyle(Color(.label))
                
                Text(title)
                    .font(.system(size: 20))
                    .foregroundStyle(Color(.label))
                    .fontDesign(.rounded)
                    .multilineTextAlignment(.leading)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.leading, -10)
            
            Text(subTitle)
                .font(.system(size: 16))
                .foregroundStyle(Color(.gray))
                .fontDesign(.rounded)
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 4)
        }
    }
}

private struct PremiumSubscriptionSheet: View {
    @EnvironmentObject var sub: SubscriptionManager
    @Environment(\.dismiss) var dismiss
    
    let privacyURL: URL
    let termsURL: URL
    
    var body: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 14) {
                subscriptionDetailsView
                
                purchaseButtonView
                
                Button(LocalizedStringKey("restorePurchasesLabel")) {
                    Task { await sub.refreshEntitlements() }
                }
                .font(.system(size: 16))
                .foregroundStyle(Color(.label))
                .padding(.bottom, 3)
                .padding(.top, -3)
                
                VStack(spacing: 5) {
                    Link(LocalizedStringKey("privacyPolicy"), destination: privacyURL)
                        .font(.system(size: 14))
                        .fontDesign(.rounded)
                        .foregroundStyle(Color.blue)
                        .underline()
                    
                    Link(LocalizedStringKey("termsOfUse"), destination: termsURL)
                        .font(.system(size: 14))
                        .fontDesign(.rounded)
                        .foregroundStyle(Color.blue)
                        .underline()
                }
            }
        }
        .padding(.horizontal, 16)
        .presentationDetents([.height(360)])
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    var purchaseButtonView: some View {
        if let p = sub.product {
            Text(String(format: NSLocalizedString("premiumSubscribeButtonFormat", comment: ""), p.displayPrice))
                .font(.system(size: 18))
                .fontDesign(.rounded)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(Color(.label))
                .foregroundStyle(Color(.systemBackground))
                .clipShape(Capsule())
                .onTapGesture {
                    if !sub.hasPremium {
                        Task { await sub.buy() }
                    }
                }
        } else {
            Text(LocalizedStringKey("loadingLabel"))
                .font(.system(size: 18))
                .fontDesign(.rounded)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(Color(.label))
                .foregroundStyle(Color(.systemBackground))
                .clipShape(Capsule())
        }
    }
    
    var subscriptionDetailsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizedStringKey("premiumSubscriptionInfoTitle"))
                .font(.system(size: 19))
                .fontDesign(.rounded)
                .fontWeight(.semibold)
                .foregroundStyle(Color(.label))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            infoRow(
                title: NSLocalizedString("premiumSubscriptionNameLabel", comment: ""),
                value: sub.product?.displayName ?? NSLocalizedString("premiumSubscriptionFallbackName", comment: "")
            )
            
            infoRow(
                title: NSLocalizedString("premiumSubscriptionLengthLabel", comment: ""),
                value: NSLocalizedString("premiumSubscriptionLengthValue", comment: "")
            )
            
            infoRow(
                title: NSLocalizedString("premiumSubscriptionPriceLabel", comment: ""),
                value: sub.product?.displayPrice ?? NSLocalizedString("loadingLabel", comment: "")
            )
            
            Text(LocalizedStringKey("premiumSubscriptionAutoRenewableNote"))
                .font(.system(size: 13))
                .fontDesign(.rounded)
                .foregroundStyle(Color(.gray))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)
        }
        .padding(14)
//        .background(
//            RoundedRectangle(cornerRadius: 22)
//                .foregroundStyle(Color(.secondarySystemBackground))
//        )
    }
    
    func infoRow(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(title)
                .font(.system(size: 15))
                .fontDesign(.rounded)
                .foregroundStyle(Color(.gray))
            
            Spacer(minLength: 8)
            
            Text(value)
                .font(.system(size: 15))
                .fontDesign(.rounded)
                .foregroundStyle(Color(.label))
                .multilineTextAlignment(.trailing)
        }
    }
}
