//
//  ForgotPasswordView.swift
//  Readify
//
//  Created by Тимофей Юдин on 28.10.2024.
//

import SwiftUI

struct ForgotPasswordView: View {
    @Binding var isPresented: Bool
    @Binding var isSuccessPopupPresented: Bool
    
    @FocusState var isEmailTFFocused: Bool
    
    @StateObject var viewModel = ForgotPasswordViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(uiColor: .systemBackground)
                    .ignoresSafeArea()
                    .onTapGesture {
                        isEmailTFFocused = false
                    }
                
                VStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 30)
                            .foregroundStyle(Color(uiColor: .secondarySystemBackground))
                            .frame(width: UIScreen.main.bounds.width - 60, height: 150)
                            .shadow(radius: 2)
                        
                        VStack {
                            Text(LocalizedStringKey("resetPasswordLabel"))
                                .font(.title2)
                                .fontDesign(.rounded)
                                .fontWeight(.light)
                                .padding(.top, 20)
                            
                            VStack {
                                TextField("Email", text: $viewModel.emailText)
                                    .frame(width: UIScreen.main.bounds.width - 92)
                                    .font(.title2)
                                    .focused($isEmailTFFocused)
                                    .textInputAutocapitalization(.never)
                                    .onChange(of: viewModel.emailText) { _ in
                                        viewModel.isButtonEnable()
                                    }
                                
                                RoundedRectangle(cornerRadius: 0)
                                    .frame(width: UIScreen.main.bounds.width - 92, height: 2)
                                    .foregroundStyle(isEmailTFFocused ? Color(uiColor: .label) : Color.gray)
                            }
                            .padding(.top, 20)
                            
                            Spacer()
                        }
                        .frame(height: 150)
                    }
                    
                    Button {
                        Task {
                            do {
                                try await viewModel.resetPassword()
                                print("PASSWORD RESET")
                                
                                isEmailTFFocused = false
                                viewModel.emailText = ""
                                
                                isPresented = false
                                
                                isSuccessPopupPresented = true
                                
                                return
                            } catch {
                                print("Error: \(error.localizedDescription)")
                                
                                withAnimation {
                                    viewModel.errorText = error.localizedDescription
                                }
                            }
                            
                            viewModel.isErrorPopupPresented = true
                        }
                    } label: {
                        HStack {
                            Text(LocalizedStringKey("resetButton"))
                                .foregroundStyle(
                                    viewModel.isButtonEnabled
                                    ? Color(uiColor: .label)
                                    : Color.gray
                                )
                            
                            if viewModel.isButtonEnabled {
                                Text("📲")
                            }
                        }
                        .frame(width: UIScreen.main.bounds.width - 60, height: 50)
                        .background(Color(uiColor: .secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .font(.title2)
                        .shadow(radius: viewModel.isButtonEnabled ? 2 : 0)
                    }
                    .disabled(!viewModel.isButtonEnabled)
                    .padding(.top, 10)
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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(Color(uiColor: .label))
                    }
                }
            }
        }
    }
}

#Preview {
    ForgotPasswordView(isPresented: .constant(true), isSuccessPopupPresented: .constant(false))
}
