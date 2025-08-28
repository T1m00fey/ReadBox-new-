//
//  SignInView.swift
//  Readify
//
//  Created by Тимофей Юдин on 27.10.2024.
//

import SwiftUI
import PopupView
import SwiftfulLoadingIndicators

struct SignInView: View {
    @Binding var isWelcomeViewPresented: Bool
    
    @StateObject var viewModel = SignInViewModel()
    
    @FocusState var isSecondTFFocused: Bool
    @FocusState var isThirdTFFocused: Bool
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemBackground)
                    .ignoresSafeArea()
                    .onTapGesture {
                        isSecondTFFocused = false
                        isThirdTFFocused = false
                    }
                
                VStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 30)
                            .foregroundStyle(Color(uiColor: .secondarySystemBackground))
                            .frame(width: UIScreen.main.bounds.width - 60, height: 250)
                            .shadow(radius: 2)
                        
                        VStack {
                            Text(LocalizedStringKey("signInLabel"))
                                .fontDesign(.rounded)
                                .fontWeight(.light)
                                .font(.title)
                                .padding(.top, 30)
                            
                            VStack(spacing: 40) {
                                VStack {
                                    TextField("Email", text: $viewModel.emailText)
                                        .frame(width: UIScreen.main.bounds.width - 92)
                                        .font(.title2)
                                        .focused($isSecondTFFocused)
                                        .textInputAutocapitalization(.never)
                                        .onChange(of: viewModel.emailText) {
                                            if viewModel.emailText.count > 0 {
                                                viewModel.isSignInButtonEnabled()
                                            }
                                        }
                                        .tint(Color(uiColor: .label))
                                    
                                    RoundedRectangle(cornerRadius: 0)
                                        .frame(width: UIScreen.main.bounds.width - 92, height: 2)
                                        .foregroundStyle(isSecondTFFocused ? Color(uiColor: .label) : Color(uiColor: .gray))
                                }
                                
                                VStack {
                                    SecureField(LocalizedStringKey("passwordTFPlaceholder"), text: $viewModel.passwordText)
                                        .frame(width: UIScreen.main.bounds.width - 92)
                                        .font(.title2)
                                        .focused($isThirdTFFocused)
                                        .textInputAutocapitalization(.never)
                                        .onChange(of: viewModel.passwordText) {
                                            if viewModel.emailText.count > 0 {
                                                viewModel.isSignInButtonEnabled()
                                            }
                                        }
                                        .tint(Color(uiColor: .label))
                                    
                                    RoundedRectangle(cornerRadius: 0)
                                        .frame(width: UIScreen.main.bounds.width - 92, height: 2)
                                        .foregroundStyle(isThirdTFFocused ? Color(uiColor: .label) : Color(uiColor: .gray))
                                }
                            }
                            .padding(.top, 10)
                            
                            Spacer()
                        }
                        .frame(height: 250)
                    }
                    
                    Button {
                        withAnimation {
                            viewModel.isLoading = true
                            viewModel.isButtonEnable = false
                        }
                        
                        Task {
                            do {
                                viewModel.vibrationsService.softImpact()
                                try await viewModel.signIn()
                                
                                isWelcomeViewPresented = false
                                
                                viewModel.emailText = ""
                                viewModel.passwordText = ""
                                
                                viewModel.isLoading = false
                                return
                            } catch {
                                print("Error: \(error.localizedDescription)")
                                
                                withAnimation {
                                    viewModel.errorText = error.localizedDescription
                                    viewModel.isLoading = false
                                    viewModel.isButtonEnable = true
                                }
                            }
                            
                            viewModel.isErrorPopupPresented = true
                        }
                    } label: {
                        HStack {
                            Text(LocalizedStringKey("signInButton"))
                                .foregroundStyle(
                                    viewModel.isButtonEnable
                                    ? Color(uiColor: .label)
                                    : Color.gray
                                )
                            
                            if viewModel.isButtonEnable {
                                Text("👋")
                            } else if viewModel.isLoading {
                                LoadingIndicator(animation: .circleRunner, color: Color(uiColor: .label), size: .small, speed: .fast)
                            }
                        }
                        .frame(width: UIScreen.main.bounds.width - 60, height: 50)
                        .background(Color(uiColor: .secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .font(.title2)
                        .shadow(radius: viewModel.isButtonEnable ? 2 : 0)
                    }
                    .disabled(!viewModel.isButtonEnable)
                    .padding(.top, 10)
                    
                    Text(.init(viewModel.privacyText))
                        .font(.footnote)
                        .frame(width: UIScreen.main.bounds.width - 20)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.gray)
                        .padding(.top, 10)
                        .ignoresSafeArea(.keyboard)
                }
                
                VStack {
                    Spacer()
                    
                    HStack(spacing: 40) {
//                        Button {
//                            viewModel.isSignUpViewPresented = true
//                        } label: {
//                            Text(LocalizedStringKey("signUpLabel"))
//                                .font(.system(size: 18))
//                                .fontDesign(.rounded)
//                                .underline()
//                        }
                        
                        Button {
                            viewModel.isForgotPasswordPresented = true
                        } label: {
                            Text(LocalizedStringKey("forgotPasswordButton"))
                                .font(.system(size: 18))
                                .fontDesign(.rounded)
                                .underline()
                        }
                        .sheet(isPresented: $viewModel.isForgotPasswordPresented) {
                            ForgotPasswordView(isPresented: $viewModel.isForgotPasswordPresented, isSuccessPopupPresented: $viewModel.isSuccessPopupPresented)
                        }
                        
                    }
                    .font(.system(size: 14))
                }
                .padding(.bottom, 20)
                .ignoresSafeArea(.keyboard)
            }
            .navigationBarBackButtonHidden()
            .overlay(
                EnableSwipeBack()
                    .frame(width: 0, height: 0)
            )
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Image(systemName: "arrow.left")
                        .onTapGesture {
                            dismiss()
                        }
                }
            }
            .popup(isPresented: $viewModel.isErrorPopupPresented) {
                Text(viewModel.errorText)
                    .frame(width: UIScreen.main.bounds.width - 72, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .foregroundStyle(Color.white)
                    .background(Color.red)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } customize: {
                $0
                    .type(.floater())
                    .position(.top)
                    .animation(.bouncy)
                    .dragToDismiss(true)
                    .autohideIn(5)
            }
            .popup(isPresented: $viewModel.isSuccessPopupPresented) {
                Text(LocalizedStringKey("resetPasswordLink"))
                    .frame(width: UIScreen.main.bounds.width - 72, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .foregroundStyle(Color(.label))
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .foregroundStyle(Color(.systemBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                Color.green, lineWidth: 1
                            )
                    )
            } customize: {
                $0
                    .type(.floater())
                    .position(.top)
                    .animation(.bouncy)
                    .dragToDismiss(true)
                    .autohideIn(5)
            }
            .fullScreenCover(isPresented: $viewModel.isSignUpViewPresented) {
                SignUpView(isWelcomeViewPresented: $isWelcomeViewPresented)
            }
            .onDisappear {
                isSecondTFFocused = false
                isThirdTFFocused = false
            }
        }
    }
}
