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
    @Binding var isPresented: Bool
    
    @StateObject var viewModel = SignInViewModel()
    
    @FocusState var isFirstTFFocused: Bool
    @FocusState var isSecondTFFocused: Bool
    @FocusState var isThirdTFFocused: Bool
    
    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()
                .onTapGesture {
                    isFirstTFFocused = false
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
                                    .onChange(of: viewModel.emailText) { _ in
                                        if viewModel.emailText.count > 0 {
                                            viewModel.isSignInButtonEnabled()
                                        }
                                    }
                                
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
                                    .onChange(of: viewModel.passwordText) { _ in
                                        if viewModel.emailText.count > 0 {
                                            viewModel.isSignInButtonEnabled()
                                        }
                                    }
                                
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
                            try await viewModel.signIn()
                            isPresented = false
                            
                            viewModel.emailText = ""
                            viewModel.passwordText = ""
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
            }
            
            VStack {
                Spacer()
                
                HStack(spacing: 40) {
                    Button {
                        viewModel.isSignUpViewPresented = true
                    } label: {
                        Text(LocalizedStringKey("signUpLabel"))
                            .font(.system(size: 18))
                            .fontDesign(.rounded)
                            .underline()
                    }
                    
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
                .font(.system(size: 16))
                .padding(.bottom, 20)
            }
            .ignoresSafeArea(.keyboard)
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
                .foregroundStyle(Color.white)
                .background(Color.green)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        } customize: {
            $0
                .type(.floater())
                .position(.top)
                .animation(.bouncy)
                .dragToDismiss(true)
                .autohideIn(5)
        }
        .fullScreenCover(isPresented: $viewModel.isSignUpViewPresented) {
            SignUpView(isPresented: $viewModel.isSignUpViewPresented, isSignInViewPresented: $isPresented)
        }
    }
}

#Preview {
    SignInView(isPresented: .constant(true))
}
