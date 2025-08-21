//
//  ProfileView.swift
//  Readify
//
//  Created by Тимофей Юдин on 29.10.2024.
//

import SwiftUI
import SwiftUIMailView
import SwiftfulLoadingIndicators

struct ProfileView: View {
    @Binding var isWelcomeViewPresented: Bool
    
    @StateObject var viewModel = ProfileViewModel()
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemBackground)
                    .ignoresSafeArea()
                ScrollView {
                    VStack {
                        VStack {
                            if let user = viewModel.user, !((user.subscribes ?? []).isEmpty) {
                                NavigationLink {
                                    SubscribesView(user: $viewModel.user)
                                } label: {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 20)
                                            .frame(width: UIScreen.main.bounds.width - 32)
                                            .foregroundStyle(Color(.secondarySystemBackground))
                                            .shadow(radius: 2)
                                        
                                        HStack {
                                            Image(systemName: "bookmark.circle")
                                                .font(.system(size: 35))
                                                .foregroundStyle(Color.gray)
                                            
                                            Text(NSLocalizedString("yourSubscribesLabel", comment: ""))
                                                .font(.system(size: 23))
                                                .fontWeight(.light)
                                                .fontDesign(.rounded)
                                            
                                            Spacer()
                                            
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 25))
                                                .foregroundStyle(Color.gray)
                                        }
                                        .frame(width: UIScreen.main.bounds.width - 64)
                                        .padding(.vertical, 10)
                                    }
                                }
                                .padding(.top, 10)
                            }
                            
                            Text(LocalizedStringKey("settingsLabel"))
                                .font(.system(size: 25))
                                .fontWeight(.light)
                                .fontDesign(.rounded)
                                .frame(width: UIScreen.main.bounds.width - 32, alignment: .leading)
                                .padding(.top, 25)
                            
                            if let _ = viewModel.user {
                                NavigationLink(
                                    destination: NewNameView(
                                        isSuccessPopupPresented: $viewModel.isSuccessPopupPresented,
                                        successText: $viewModel.successText,
                                        user: $viewModel.user
                                    )
                                ) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 20)
                                                .foregroundStyle(Color(uiColor: .secondarySystemBackground))
                                            .shadow(radius: 2)
                                        
                                        HStack {
                                            Image(systemName: "person.circle.fill")
                                                .foregroundStyle(Color.gray)
                                                .font(.system(size: 35))
                                            
                                            Text(LocalizedStringKey("nameLabel"))
                                                .font(.system(size: 23))
                                                .fontWeight(.light)
                                                .fontDesign(.rounded)
                                            
                                            Spacer()
                                            
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 25))
                                                .foregroundStyle(Color.gray)
                                        }
                                        .padding(.horizontal, 16)
                                    }
                                }
                                .frame(width: UIScreen.main.bounds.width - 32, height: 60)
                                
                                
                                NavigationLink {
                                    NewPasswordView(isSuccessPopupPresented: $viewModel.isSuccessPopupPresented, successText: $viewModel.successText, email: viewModel.user?.email ?? "")
                                } label: {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 20)
                                            .foregroundStyle(Color(uiColor: .secondarySystemBackground))
                                            .shadow(radius: 2)
                                        
                                        HStack {
                                            Image(systemName: "lock.circle.fill")
                                                .foregroundStyle(Color.blue)
                                                .font(.system(size: 35))
                                            
                                            Text(LocalizedStringKey("passwordTFPlaceholder"))
                                                .font(.system(size: 23))
                                                .fontWeight(.light)
                                                .fontDesign(.rounded)
                                            
                                            Spacer()
                                            
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 25))
                                                .foregroundStyle(Color.gray)
                                        }
                                        .padding(.horizontal, 16)
                                    }
                                }
                                .frame(width: UIScreen.main.bounds.width - 32, height: 60)
                                
                                Button {
                                    viewModel.isFontSettingPopupPresented = true
                                } label: {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 20)
                                            .foregroundStyle(Color(uiColor: .secondarySystemBackground))
                                            .shadow(radius: 2)
                                        
                                        HStack {
                                            Image(systemName: "book.pages")
                                                .foregroundStyle(Color.mint)
                                                .font(.system(size: 30))
                                            
                                            Text(LocalizedStringKey("fontLabel"))
                                                .font(.system(size: 23))
                                                .fontWeight(.light)
                                                .fontDesign(.rounded)
                                            
                                            Spacer()
                                            
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 25))
                                                .foregroundStyle(Color.gray)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.leading, 3)
                                    }
                                }
                                .frame(width: UIScreen.main.bounds.width - 32, height: 60)
                                
                                Button {
                                    viewModel.isMemorySettingsPopupPresented = true
                                    
                                    viewModel.getTotalCacheSize()
                                } label: {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 20)
                                            .foregroundStyle(Color(uiColor: .secondarySystemBackground))
                                            .shadow(radius: 2)
                                        
                                        HStack {
                                            Image(systemName: "brain.fill")
                                                .foregroundStyle(Color.pink)
                                                .font(.system(size: 25))
                                                .padding(.leading, 3)
                                            
                                            Text(LocalizedStringKey("memorySettingsLabel"))
                                                .font(.system(size: 23))
                                                .fontWeight(.light)
                                                .fontDesign(.rounded)
                                            
                                            Spacer()
                                            
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 25))
                                                .foregroundStyle(Color.gray)
                                        }
                                        .padding(.horizontal, 16)
                                    }
                                }
                                .frame(width: UIScreen.main.bounds.width - 32, height: 60)
                                
                                Button {
                                    viewModel.isMoreSettingPopupPresented.toggle()
                                } label: {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 20)
                                            .foregroundStyle(Color(uiColor: .secondarySystemBackground))
                                            .shadow(radius: 2)
                                        
                                        HStack {
                                            Image(systemName: "ellipsis.circle")
                                                .foregroundStyle(Color.gray)
                                                .font(.system(size: 35))
                                            
                                            Text(LocalizedStringKey("moreLabel"))
                                                .font(.system(size: 23))
                                                .fontWeight(.light)
                                                .fontDesign(.rounded)
                                            
                                            Spacer()
                                            
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 25))
                                                .foregroundStyle(Color.gray)
                                        }
                                        .padding(.horizontal, 16)
                                    }
                                }
                                .frame(width: UIScreen.main.bounds.width - 32, height: 60)
                            }
                            
                            HStack {
                                Button {
                                    viewModel.isSignOutDialogPresented = true
                                } label: {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 20)
                                            .foregroundStyle(Color(uiColor: .secondarySystemBackground))
                                            .frame(width: (UIScreen.main.bounds.width - 50) / 2, height: 60)
                                            .shadow(radius: 2)
                                        
                                        HStack {
                                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                                .font(.system(size: 20))
                                                .foregroundStyle(Color.red)
                                            
                                            Text(LocalizedStringKey("signOutLabel"))
                                                .foregroundStyle(Color.red)
                                                .fontWeight(.light)
                                                .font(.system(size: 23))
                                                .fontDesign(.rounded)
                                        }
                                    }
                                }
                                
                                Spacer()
                                
                                Button {
                                    viewModel.isDeleteAccDialogPresented = true
                                } label: {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 20)
                                            .foregroundStyle(Color(uiColor: .secondarySystemBackground))
                                            .frame(width: (UIScreen.main.bounds.width - 50) / 2, height: 60)
                                            .shadow(radius: 2)
                                        
                                        HStack {
                                            Image(systemName: "xmark.circle")
                                                .font(.system(size: 20))
                                                .foregroundStyle(Color.red)
                                            
                                            Text(LocalizedStringKey("deleteLabel"))
                                                .foregroundStyle(Color.red)
                                                .fontWeight(.light)
                                                .font(.system(size: 23))
                                                .fontDesign(.rounded)
                                        }
                                    }
                                }
                            }
                            .frame(width: UIScreen.main.bounds.width - 32)
                            .padding(.top, 10)
                            
                            Spacer()
                        }
                        .padding(.top, 20)
                        
                    }
                    .frame(width: UIScreen.main.bounds.width)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
//                            Text(viewModel.user?.name ?? "")
//                                .font(.largeTitle)
//                                .fontWeight(.light)
//                                .fontDesign(.rounded)
                            
                            ZStack {
                                RoundedRectangle(cornerRadius: 15)
                                    .frame(width: UIScreen.main.bounds.width, height: 130)
                                    .foregroundStyle(Color(uiColor: .secondarySystemBackground))
                                    .padding(.bottom, 40)
                                    .shadow(radius: 5)
                                
                                HStack {
                                    Text(viewModel.user?.name ?? "")
                                        .font(.largeTitle)
                                        .fontWeight(.light)
//                                        .fontDesign(.rounded)
                                    
                                    if viewModel.isLoading {
                                        HStack {
                                            Text(NSLocalizedString("loadingLabel", comment: ""))
                                                .font(.largeTitle)
                                                .fontWeight(.light)
                                                .fontDesign(.rounded)
                                            
                                            if viewModel.isLoading {
                                                LoadingIndicator(
                                                    animation: .circleRunner,
                                                    color: Color(uiColor: .label),
                                                    size: .small, speed: .fast
                                                )
                                            }
                                        }
                                    }
                                }
                                .frame(width: UIScreen.main.bounds.width - 32, alignment: .leading)
                                
                            }
                            .padding(.leading, 6)
                        }
                    }
                    .onAppear {
                        if viewModel.isLoading {
                            viewModel.isLoading = false
                            
                            Task {
                                viewModel.isLoading = true
                            }
                        }
                        
                        if viewModel.isNeedToReload {
                            viewModel.reload()
                            viewModel.isNeedToReload = false
                        }
                        
                        if viewModel.user == nil {
                            Task {
                                try? await viewModel.loadCurrentUser()
                            }
                        }
                    }
                }
                .padding(.top, 20)
                .refreshable {
                    viewModel.reload()
                }
                .onChange(of: isWelcomeViewPresented) {
                    if !isWelcomeViewPresented {
                        viewModel.reload()
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
                .confirmationDialog("", isPresented: $viewModel.isDeleteAccDialogPresented) {
                    Button(LocalizedStringKey("deleteLabel"), role: .destructive) {
                        Task {
                            do {
                                try await viewModel.delete()
                                isWelcomeViewPresented = true
                                return
                            } catch {
                                withAnimation {
                                    viewModel.errorText = error.localizedDescription
                                }
                            }
                            
                            viewModel.isErrorPopupPresented = true
                        }
                    }
                    
                    Button(LocalizedStringKey("cancelButton"), role: .cancel) {}
                } message: {
                    Text(LocalizedStringKey("youSureToDeleteAcc"))
                }
                .confirmationDialog("", isPresented: $viewModel.isSignOutDialogPresented) {
                    Button(LocalizedStringKey("signOutLabel"), role:.destructive) {
                        Task {
                            do {
                                try await viewModel.signOut()
                                isWelcomeViewPresented = true
                                return
                            } catch {
                                withAnimation {
                                    viewModel.errorText = error.localizedDescription
                                }
                            }
                            
                            viewModel.isErrorPopupPresented = true
                        }
                    }
                    
                    Button(LocalizedStringKey("cancelButton"), role: .cancel) {}
                } message: {
                    Text(LocalizedStringKey("youSureToSingOut"))
                }
                .popup(isPresented: $viewModel.isSuccessPopupPresented) {
                    Text(viewModel.successText)
                        .frame(width: UIScreen.main.bounds.width - 72, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .foregroundStyle(Color.white)
                        .background(Color(.secondarySystemBackground))
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
                .onChange(of: isWelcomeViewPresented) {
                    if !isWelcomeViewPresented {
                        viewModel.isNeedToReload = true
                    }
                }
                .popup(isPresented: $viewModel.isMemorySettingsPopupPresented) {
                    MemorySettingsView(
                        sizeOfData: viewModel.sizeOfData,
                        successText: $viewModel.successText,
                        isSuccessPopupPresented: $viewModel.isSuccessPopupPresented
                    )
                    .shadow(radius: 3)
                } customize: {
                    $0
                        .type(.toast)
                        .appearFrom(.bottomSlide)
                        .dragToDismiss(true)
                }
                .popup(isPresented: $viewModel.isMoreSettingPopupPresented) {
                    MoreSettingView(isMailViewPresented: $viewModel.isMailViewPresented)
                        .shadow(radius: 3)
                } customize: {
                    $0
                        .type(.toast)
                        .appearFrom(.bottomSlide)
                        .dragToDismiss(true)
                }
                .popup(isPresented: $viewModel.isFontSettingPopupPresented) {
                    FontSettingView(
                        isPopupPresented: $viewModel.isFontSettingPopupPresented,
                        successText: $viewModel.successText,
                        isSuccessPopupPresented: $viewModel.isSuccessPopupPresented
                    )
                    .shadow(radius: 3)
                } customize: {
                    $0
                        .type(.toast)
                        .appearFrom(.bottomSlide)
                        .dragToDismiss(true)
                }
                .sheet(isPresented: $viewModel.isMailViewPresented, content: {
                    MailView(data: $viewModel.mailData) { result in
                        print(result)
                    }
                })
            }
        }
    }
}

private extension ProfileView {
    var daysWithApp: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .foregroundStyle(Color(uiColor: .secondarySystemBackground))
                .frame(width: (UIScreen.main.bounds.width - 50) / 2, height: 120)
                .shadow(radius: 2)
            
            VStack(spacing: 10) {
                Text(LocalizedStringKey("youWithUsLabel"))
                    .font(.title3)
                    .foregroundStyle(Color.gray)
                    .fontDesign(.rounded)
                
                Text("\(viewModel.getDays(regDate: viewModel.user?.dateCreated))")
                    .font(.title)
                    .bold()
                    .fontDesign(.rounded)
                
                Text("\(viewModel.getStringOf(days: viewModel.getDays(regDate: viewModel.user?.dateCreated)))")
                    .font(.title3)
                    .foregroundStyle(Color.gray)
                    .fontDesign(.rounded)
            }
        }
    }
    
    var articlesRead: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .foregroundStyle(Color(uiColor: .secondarySystemBackground))
                .frame(width: (UIScreen.main.bounds.width - 50) / 2, height: 120)
                .shadow(radius: 2)
            
            VStack(spacing: 10) {
                Text(LocalizedStringKey("readArticlesLabel"))
                    .font(.title3)
                    .foregroundStyle(Color.gray)
                    .fontDesign(.rounded)
                
                Text("")
                    .font(.title)
                    .bold()
                    .fontDesign(.rounded)
                
                Text("")
                    .font(.title3)
                    .foregroundStyle(Color.gray)
                    .fontDesign(.rounded)
            }
        }
    }
}
