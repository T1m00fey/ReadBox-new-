//
//  SignInView.swift
//  Readify
//
//  Created by Тимофей Юдин on 27.10.2024.
//

import SwiftUI
import SwiftfulLoadingIndicators

struct SignUpView: View {
    @Binding var isPresented: Bool
    @Binding var isSignInViewPresented: Bool
    
    @StateObject var viewModel = SignUpViewModel()
    
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
                        .frame(width: UIScreen.main.bounds.width - 60, height: 330)
                        .shadow(radius: 2)
                    
                    VStack {
                        Text(LocalizedStringKey("signUpLabel"))
                            
                            .fontWeight(.light)
                            .font(.title)
                            .padding(.top, 30)
                        
                        VStack(spacing: 40) {
                            VStack {
                                TextField(LocalizedStringKey("nameTFPlaceholder"), text: $viewModel.nameText)
                                    .frame(width: UIScreen.main.bounds.width - 92)
                                    .font(.title2)
                                    .focused($isFirstTFFocused)
                                    .textInputAutocapitalization(.never)
                                    .onChange(of: viewModel.nameText) { _ in
                                        if viewModel.emailText.count > 0 {
                                            viewModel.isSignUpButtonEnabled()
                                        }
                                    }
                                
                                RoundedRectangle(cornerRadius: 0)
                                    .frame(width: UIScreen.main.bounds.width - 92, height: 2)
                                    .foregroundStyle(isFirstTFFocused ? Color(uiColor: .label) : Color(uiColor: .gray))
                            }
                            
                            VStack {
                                TextField("Email", text: $viewModel.emailText)
                                    .frame(width: UIScreen.main.bounds.width - 92)
                                    .font(.title2)
                                    .focused($isSecondTFFocused)
                                    .textInputAutocapitalization(.never)
                                    .onChange(of: viewModel.emailText) { _ in
                                        if viewModel.emailText.count > 0 {
                                            viewModel.isSignUpButtonEnabled()
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
                                            viewModel.isSignUpButtonEnabled()
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
                    .frame(height: 330)
                }
                
                Button {
                    withAnimation {
                        viewModel.isLoading = true
                        viewModel.isButtonEnable = false
                    }
                    
                    Task {
                        do {
                            try await viewModel.signUp()
                            isSignInViewPresented = false
                            return
                        } catch {
                            print("Error: \(error.localizedDescription)")
                            
                            withAnimation {
                                viewModel.errorText = error.localizedDescription
                                viewModel.isLoading = false
                                viewModel.isButtonEnable = true
                            }
                        }
                        
                        viewModel.isPopupPresented = true
                    }
                } label: {
                    HStack {
                        Text(LocalizedStringKey("signUpButton"))
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
            .popup(isPresented: $viewModel.isPopupPresented) {
                Text(viewModel.errorText)
                    .frame(width: UIScreen.main.bounds.width - 72)
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
            
            VStack {
                Spacer()
                
                Button {
                    isPresented = false
                } label: {
                    Text(LocalizedStringKey("signInLabel"))
                        .font(.title3)
                        .fontDesign(.rounded)
                        .underline()
                }
                .padding(.bottom, 20)
            }
            .ignoresSafeArea(.keyboard)
        }
    }
}

#Preview {
    SignUpView(isPresented: .constant(true), isSignInViewPresented: .constant(false))
}
