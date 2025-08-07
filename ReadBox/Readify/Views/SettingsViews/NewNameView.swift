//
//  NewNameView.swift
//  Readify
//
//  Created by Тимофей Юдин on 31.10.2024.
//
import SwiftUI

struct NewNameView: View {
    @Binding var isSuccessPopupPresented: Bool
    @Binding var successText: String
    @Binding var user: DBUser?
    
    @FocusState var isNameTFFocused: Bool
    
    @StateObject var viewModel = NewNameViewModel()
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(uiColor: .systemBackground)
                    .ignoresSafeArea()
                    .onTapGesture {
                        isNameTFFocused = false
                    }
                
                VStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 30)
                            .foregroundStyle(Color(uiColor: .secondarySystemBackground))
                            .frame(width: UIScreen.main.bounds.width - 60, height: 150)
                            .shadow(radius: 2)
                        
                        VStack {
                            Text(LocalizedStringKey("nameChangeLabel"))
                                .font(.title2)
                                .fontDesign(.rounded)
                                .fontWeight(.light)
                                .padding(.top, 20)
                            
                            VStack {
                                TextField(LocalizedStringKey("nameTFPlaceholder"), text: $viewModel.nameText)
                                    .frame(width: UIScreen.main.bounds.width - 92)
                                    .font(.title2)
                                    .focused($isNameTFFocused)
                                    .textInputAutocapitalization(.never)
                                    .onChange(of: viewModel.nameText) {
                                        viewModel.isButtonEnable()
                                    }
                                    .tint(Color(uiColor: .label))
                                
                                RoundedRectangle(cornerRadius: 0)
                                    .frame(width: UIScreen.main.bounds.width - 92, height: 2)
                                    .foregroundStyle(isNameTFFocused ? Color(uiColor: .label) : Color.gray)
                            }
                            .padding(.top, 20)
                            
                            Spacer()
                        }
                        .frame(height: 150)
                    }
                    
                    Button {
                        Task {
                            do {
                                try await viewModel.changeName(userID: user?.userId ?? "", to: viewModel.nameText)
                                
                                user?.name = viewModel.nameText
                                
                                isNameTFFocused = false
                                viewModel.nameText = ""
                                
                                dismiss()
                                
                                withAnimation {
                                    successText = NSLocalizedString("nameChangedAlert", comment: "")
                                }
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
                            Text(LocalizedStringKey("changeButton"))
                                .foregroundStyle(
                                    viewModel.isButtonEnabled
                                    ? Color(uiColor: .label)
                                    : Color.gray
                                )
                            
                            if viewModel.isButtonEnabled {
                                Text("👤")
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
                    .padding(.top, 20)
            } customize: {
                $0
                    .type(.floater())
                    .position(.top)
                    .animation(.bouncy)
                    .dragToDismiss(true)
                    .autohideIn(5)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "arrow.left")
                            .foregroundStyle(Color(uiColor: .label))
                    }
                }
            }
        }
        .navigationBarBackButtonHidden()
        .overlay(EnableSwipeBack().frame(width: 0, height: 0))
    }
}
