//
//  HUDService.swift
//  ReadBox
//
//  Created by Macbook Pro on 27.10.2025.
//

import SwiftUI
import SwiftfulLoadingIndicators

final class HUDService: ObservableObject {
    enum LoadingToastType {
        case post
        case delete
    }
    
    @Published var isLoading = false
    
    @Published var popupMessage = ""
    
    @Published var loadingTitle = ""
    
    @Published var isErrorPopupPresented = false
    @Published var isSuccessPopupPresented = false
    
    @Published var isNeedToShowShortLoading = false
    
    private var vibrationsService = VibrationsService.shared
    
    func showLoading(type: LoadingToastType = .post) {
        if type == .post {
             loadingTitle = NSLocalizedString("uploadingHUDLabel", comment: "")
        } else {
            loadingTitle = NSLocalizedString("deletingHUDLabel", comment: "")
        }
        
        withAnimation {
            isLoading = true
        }
    }
    
    func showSuccessPopup(type: LoadingToastType = .post) {
        if type == .post {
            popupMessage = NSLocalizedString("postSuccessfullyUploadedHUDLabel", comment: "")
        } else {
            popupMessage = NSLocalizedString("postSuccessfullyDeletedHUDLabel", comment: "")
        }
        
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
    func makeLoadingPopup(screenWidth: CGFloat) -> some View {
        if isNeedToShowShortLoading {
            
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .frame(width: 50, height: 50)
                        .foregroundStyle(.thinMaterial)
                    
                    LoadingIndicator(
                        animation: .circleRunner,
                        color: Color(.label),
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
            
            if #available(iOS 26.0, *) {
                GlassEffectContainer {
                    HStack {
                        VStack(spacing: 2) {
                            Text(loadingTitle)
                                .font(.system(size: 16))
                                .fontWeight(.semibold)
                                .fontDesign(.rounded)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text(NSLocalizedString("pleaseDontCloseAppHUDLabel", comment: ""))
                                .font(.system(size: 12))
                                .foregroundStyle(Color(.label))
                                .fontDesign(.rounded)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        Spacer()
                        
                        LoadingIndicator(
                            animation: .circleRunner,
                            color: Color(.label),
                            size: .small,
                            speed: .fast
                        )
                    }
                    .padding(.all, 10)
                    .glassEffect(.regular)
                    .padding(.horizontal, 22.5)
                    .padding(.bottom, 60)
                }
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .frame(width: screenWidth - 10, height: 50)
                        .foregroundStyle(.thinMaterial)
                    
                    HStack {
                        VStack(spacing: 2) {
                            Text(loadingTitle)
                                .font(.system(size: 16))
                                .foregroundStyle(Color(.label))
                                .fontWeight(.semibold)
                                .fontDesign(.rounded)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text(NSLocalizedString("pleaseDontCloseAppHUDLabel", comment: ""))
                                .font(.system(size: 12))
                                .foregroundStyle(Color(.label))
                                .fontDesign(.rounded)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        Spacer()
                        
                        LoadingIndicator(
                            animation: .circleRunner,
                            color: Color(.label),
                            size: .small,
                            speed: .fast
                        )
                    }
                    .frame(width: screenWidth - 30)
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
    
    @ViewBuilder
    func makeSuccessPopup(screenWidth: CGFloat) -> some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer {
                HStack {
                    Image(systemName: "checkmark.circle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .foregroundStyle(Color(.label))
                    
                    Text(popupMessage)
                        .font(.system(size: 16))
                        .fontWeight(.semibold)
                        .fontDesign(.rounded)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.all, 10)
                .glassEffect(.regular)
                .overlay(
                    Capsule()
                        .stroke(
                            Color.green,
                            lineWidth: 1
                        )
                )
                .padding(.horizontal, 22.5)
                .padding(.bottom, 60)
                .onTapGesture {
                    withAnimation {
                        self.clearAllNow()
                    }
                }
            }
        } else {
            if isNeedToShowShortLoading {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 15)
                            .frame(width: 50, height: 50)
                            .foregroundStyle(.thinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(
                                        Color.green,
                                        lineWidth: 1
                                    )
                            )
                        
                        Image(systemName: "checkmark.circle")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .foregroundStyle(Color(.label))
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
                    RoundedRectangle(cornerRadius: 15)
                        .frame(width: screenWidth - 10, height: 50)
                        .foregroundStyle(.thinMaterial)
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
                            .foregroundStyle(Color(.label))
                        
                        Text(popupMessage)
                            .font(.system(size: 16))
                            .foregroundStyle(Color(.label))
                            .fontWeight(.semibold)
                            .fontDesign(.rounded)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(width: screenWidth - 30)
                }
                .padding(.bottom, 60)
                .onTapGesture {
                    withAnimation {
                        self.clearAllNow()
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    func makeErrorPopup(screenWidth: CGFloat, bottomPadding: CGFloat) -> some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer {
                HStack {
                    Image(systemName: "xmark.circle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .foregroundStyle(Color.red)
                    
                    Text(popupMessage)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.white)
                        .fontWeight(.semibold)
                        .fontDesign(.rounded)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(2)
                }
                .padding(.all, 10)
                .glassEffect(.regular)
                .overlay(
                    Capsule()
                        .stroke(
                            Color.red,
                            lineWidth: 1
                        )
                )
                .padding(.horizontal, 22.5)
                .padding(.bottom, 60)
                .onTapGesture {
                    withAnimation {
                        self.clearAllNow()
                    }
                }
            }
        } else {
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
}
