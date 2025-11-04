//
//  HUDService.swift
//  ReadBox
//
//  Created by Macbook Pro on 27.10.2025.
//

import SwiftUI
import SwiftfulLoadingIndicators

final class HUDService: ObservableObject {
    @Published var isLoading = false
    
    @Published var popupMessage = ""
    
    @Published var isErrorPopupPresented = false
    @Published var isSuccessPopupPresented = false
    
    @Published var isNeedToShowShortLoading = false
    
    private var vibrationsService = VibrationsService.shared
    
    func showLoading() {
        withAnimation {
            isLoading = true
        }
    }
    
    func hideLoading() {
        withAnimation {
            isLoading = false
        }
    }
    
    func showSuccessPopup(with message: String) {
        withAnimation {
            isErrorPopupPresented = false
            popupMessage = message
            
            vibrationsService.successFeedback()
            isSuccessPopupPresented = true
        }
    }
    
    func showErrorPopup(with message: String) {
        withAnimation {
            isSuccessPopupPresented = false
            popupMessage = message
            
            vibrationsService.errorFeedback()
            isErrorPopupPresented = true
        }
    }
    
    func clearAll() {
        isLoading = false
        popupMessage = ""
        isErrorPopupPresented = false
        isSuccessPopupPresented = false
    }
    
}

extension HUDService {
    @ViewBuilder
    func makeLoadingPopup(screenWidth: CGFloat) -> some View {
        if isNeedToShowShortLoading {
            
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .frame(width: 70, height: 70)
                        .foregroundStyle(.ultraThinMaterial)
                    
                    LoadingIndicator(
                        animation: .circleRunner,
                        color: Color.white,
                        size: .small,
                        speed: .fast
                    )
                }
            }
            .frame(width: screenWidth - 20, alignment: .trailing)
            .padding(.bottom, 60)
            .onTapGesture {
                withAnimation {
                    self.isNeedToShowShortLoading.toggle()
                }
            }
            
        } else {
            
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .frame(width: screenWidth - 20, height: 70)
                    .foregroundStyle(.ultraThinMaterial)
                
                HStack {
                    VStack(spacing: 5) {
                        Text("Загружаем")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.white)
                            .fontWeight(.semibold)
                            .fontDesign(.rounded)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("Пожалуйста, не закрывайте приложение")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.white)
                            .fontDesign(.rounded)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    Spacer()
                    
                    LoadingIndicator(
                        animation: .circleRunner,
                        color: Color.white,
                        size: .small,
                        speed: .fast
                    )
                }
                .frame(width: screenWidth - 40)
            }
            .padding(.bottom, 60)
            .onTapGesture {
                withAnimation {
                    self.isNeedToShowShortLoading.toggle()
                }
            }
        }
        
    }
}
