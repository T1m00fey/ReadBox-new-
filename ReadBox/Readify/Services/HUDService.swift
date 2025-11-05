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
    
    func showSuccessPopup() {
        withAnimation {
            isLoading = false
            isErrorPopupPresented = false
            
            vibrationsService.successFeedback()
            isSuccessPopupPresented = true
        }
        
        clearAll()
    }
    
    func showErrorPopup(with message: String) {
        withAnimation {
            isLoading = false
            isSuccessPopupPresented = false
            popupMessage = message
            
            vibrationsService.errorFeedback()
            isErrorPopupPresented = true
        }
                    
        clearAll()
    }
    
    func clearAll() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            withAnimation {
                guard let self else { return }
                self.isLoading = false
                self.popupMessage = ""
                self.isErrorPopupPresented = false
                self.isSuccessPopupPresented = false
            }
        }
    }
    
    func clearAllNow() {
        withAnimation {
            isLoading = false
            popupMessage = ""
            isErrorPopupPresented = false
            isSuccessPopupPresented = false
        }
    }
    
}

extension HUDService {
    @ViewBuilder
    func makeLoadingPopup(screenWidth: CGFloat, bottomPadding: CGFloat) -> some View {
        if isNeedToShowShortLoading {
            
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .frame(width: 50, height: 50)
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
            .padding(.bottom, bottomPadding)
            .onTapGesture {
                withAnimation {
                    self.isNeedToShowShortLoading.toggle()
                }
            }
            
        } else {
            
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .frame(width: screenWidth - 10, height: 50)
                    .foregroundStyle(.ultraThinMaterial)
                
                HStack {
                    VStack(spacing: 2) {
                        Text("Загружаем")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.white)
                            .fontWeight(.semibold)
                            .fontDesign(.rounded)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("Пожалуйста, не закрывайте приложение")
                            .font(.system(size: 12))
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
                .frame(width: screenWidth - 30)
            }
            .padding(.bottom, bottomPadding)
            .onTapGesture {
                withAnimation {
                    self.isNeedToShowShortLoading.toggle()
                }
            }
            
        }
        
    }
    
    @ViewBuilder
    func makeSuccessPopup(screenWidth: CGFloat, bottomPadding: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15)
                .frame(width: screenWidth - 10, height: 50)
                .foregroundStyle(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(
                            Color.green,
                            lineWidth: 1
                        )
                )
            
            HStack {
                Image(systemName: "checkmark.circle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundStyle(Color.white)
                
                Text("Пост успешно загружен")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.white)
                    .fontWeight(.semibold)
                    .fontDesign(.rounded)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(width: screenWidth - 30)
        }
        .padding(.bottom, bottomPadding)
        .onTapGesture {
            withAnimation {
                self.clearAllNow()
            }
        }
    }
    
    @ViewBuilder
    func makeErrorPopup(screenWidth: CGFloat, bottomPadding: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15)
                .frame(width: screenWidth - 10, height: 50)
                .foregroundStyle(Color.red)
            
            HStack {
                Image(systemName: "xmark.circle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundStyle(Color.white)
                
                Text(popupMessage)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.white)
                    .fontWeight(.semibold)
                    .fontDesign(.rounded)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(2)
            }
            .frame(width: screenWidth - 30)
            .frame(maxHeight: 30)
        }
        .padding(.bottom, bottomPadding)
        .onTapGesture {
            withAnimation {
                self.clearAllNow()
            }
        }
    }
}
