////
////  View extensions.swift
////  ReadBox
////
////  Created by Тимофей Юдин on 01.06.2025.
////
//
import SwiftUI
import PopupView
import SwiftfulLoadingIndicators
import Shimmer
import FirebaseStorage
import AVFoundation

// MARK: for FeedView
extension View {
    @MainActor func makePopupsForFeedView(
        viewModel: FeedViewModel,
        isLoadingPopupPresented: Binding<Bool>,
        isErrorPopupPresented: Binding<Bool>,
        isDescriptionPopupPresented: Binding<Bool>,
        isReadViewPresented: Binding<Bool>,
        errorText: Binding<String>
    ) -> some View {
        self
            .popup(isPresented: isLoadingPopupPresented) {
                LoadingPopup()
            } customize: {
                $0
                    .type(.toast)
                    .appearFrom(.bottomSlide)
                    .displayMode(.overlay)
            }
            .sheet(isPresented: isLoadingPopupPresented, content: {
                LoadingPopup()
                    .presentationDetents([.height(150)])
                    .presentationCornerRadius(30)
                    .presentationDragIndicator(.visible)
            })
            .popup(isPresented: isErrorPopupPresented) {
                Text(viewModel.errorText)
                    .frame(width: UIScreen.main.bounds.width - 72, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .foregroundStyle(Color.white)
                    .background(Color.red)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.top, 20)
            } customize: {
                $0
                    .type(.floater())
                    .position(.top)
                    .animation(.bouncy)
                    .dragToDismiss(true)
                    .autohideIn(5)
                    .displayMode(.overlay)
            }
    }
    
    @MainActor func trackChangesOnFeedView(
        viewModel: FeedViewModel,
        isWelcomeViewPresented: Bool
    ) -> some View {
        self
            .onChange(of: isWelcomeViewPresented) {
                if !isWelcomeViewPresented {
                    viewModel.refresh()
                }
            }
            .onChange(of: viewModel.topArticlesIndexes) {
                guard !viewModel.topArticlesIndexes.isEmpty else { return }
                
                Task {
                    do {                        
                        try await viewModel.getTopArticles()
                        
                        withAnimation {
                            viewModel.articles = []
                            viewModel.lastDocument = nil
                            viewModel.isLoadingShowing = true
                        }
                        viewModel.isLoading = true
                        
                        try await viewModel.getArticles()
                    } catch {
                        withAnimation {
                            viewModel.errorText = error.localizedDescription
                            viewModel.isErrorPopupPresented = true
                            viewModel.isLoading = false
                            viewModel.isLoadingShowing = false
                        }
                    }
                }
            }
//            .onChange(of: viewModel.topArticles) {
//                if viewModel.topArticles.count == 5 {
//                    withAnimation {
//                        viewModel.articles = []
//                        viewModel.lastDocument = nil
//                        viewModel.isLoadingShowing = true
//                    }
//                    
//                    Task {
//                        viewModel.isLoading = true
//                        
//                        do {
//                            try await viewModel.getArticles()
//                            
//                            return
//                        } catch {
////                                                            withAnimation {
////                                                                viewModel.errorText = error.localizedDescription
////                                                            }
//                        }
//                        
////                                                    viewModel.isErrorPopupPresented = true
//                    }
//                }
//            }
            .onChange(of: viewModel.user) {
                if viewModel.user != nil {
                    Task {
                        do {
                            if viewModel.topArticlesIndexes == [] {
                                try await viewModel.getTopIndexes()
                            }
                            
                            return
                        } catch {
                            withAnimation {
                                viewModel.errorText = error.localizedDescription
                            }
                        }
                        
                        viewModel.isErrorPopupPresented = true
                    }
                }
            }
    }
}

// MARK: for LikedPostsView
extension View {
    func makePopupsForLikedView(
        viewModel: LikedPostsViewModel,
        isErrorPopupPresented: Binding<Bool>,
        isLoadingPopupPresented: Binding<Bool>,
        isDescriptionPopupPresented: Binding<Bool>,
        isReadViewPresented: Binding<Bool>,
        errorText: Binding<String>
    ) -> some View {
        self
            .popup(isPresented: isErrorPopupPresented) {
                Text(viewModel.errorText)
                    .frame(width: UIScreen.main.bounds.width - 72, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .foregroundStyle(Color.white)
                    .background(Color.red)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.top, 20)
            } customize: {
                $0
                    .type(.floater())
                    .position(.top)
                    .animation(.bouncy)
                    .dragToDismiss(true)
                    .autohideIn(5)
                    .displayMode(.overlay)
            }
            .sheet(isPresented: isLoadingPopupPresented, content: {
                LoadingPopup()
                    .presentationDetents([.height(150)])
                    .presentationCornerRadius(30)
                    .presentationDragIndicator(.visible)
            })
    }
    
    func trackChangesOnLikedPosts(
        viewModel: LikedPostsViewModel,
        isWelcomeViewPresented: Bool
    ) -> some View {
        self
            .onChange(of: viewModel.user) {
                withAnimation {
                    viewModel.articles = []
                    viewModel.isLoadingShowed = true
                }
                
                viewModel.isLoading = true
                
                if viewModel.user?.likedPosts != nil {
                    viewModel.likedPosts = Array((viewModel.user?.likedPosts ?? []).reversed())
                    
                    if viewModel.likedPosts.count == 0 {
                        withAnimation {
                            viewModel.isLoading = false
                            viewModel.isLoadingShowed = false
                        }
                    }
                    
                }
            }            
            .onChange(of: isWelcomeViewPresented) {
                if !isWelcomeViewPresented {
                    viewModel.isNeedToReload = true
                }
            }
            .onChange(of: viewModel.likedPosts) {
                if viewModel.likedPosts != [] {
                    Task {
                        do {
                            viewModel.indexesNeedToLoad = viewModel.likedPosts
                            try await viewModel.getArticles()
                            return
                        } catch {
//                            withAnimation {
//                                viewModel.errorText = error.localizedDescription
//                            }
                        }
                        
//                        viewModel.isErrorPopupPresented = true
                    }
                } else {
                    viewModel.articles = []
                }
            }
        
    }
    
}

// MARK: for CreatedPostsView
extension View {
    func trackChangesOnCreatedPostsView(
        viewModel: CreatedPostsViewModel,
        isWelcomeViewPresented: Bool,
        hudService: HUDService,
        isConfirmationPopupPresented: Binding<Bool>
    ) -> some View {
        self
            .onChange(of: viewModel.isDescriptionPopupPresented) {
                if !viewModel.isDescriptionPopupPresented {
                    withAnimation {
                        viewModel.isNewPublicationButtonPresented = true
                    }
                }
            }
            .onChange(of: viewModel.user) {
                if viewModel.user != nil {
                    withAnimation {
                        viewModel.posts = []
                        viewModel.archivePosts = []
                        viewModel.isAllLoaded = false
                        viewModel.lastPostSnapshot = nil
                    }
                    
                    Task {
                        do {
                            try await viewModel.getPosts()
                            try await viewModel.getArchivedPost()
                            
                            if viewModel.archivePosts.count <= 0 {
                                withAnimation {
                                    viewModel.isArchivePresented = false
                                }
                            }
                            
                            viewModel.isNewPublicationButtonPresented = true
                            
                            withAnimation {
                                viewModel.isLoading = false
                                viewModel.isLoadingShowing = false
                            }
                        } catch {
                            withAnimation {
                                viewModel.errorText = error.localizedDescription
                                viewModel.isErrorPopupPresented = true
                            }
                        }
                    }
                }
            }
            .onChange(of: isWelcomeViewPresented) {
                if !isWelcomeViewPresented {
                    viewModel.isNeedToReload = true
                }
            }
            .onChange(of: viewModel.isReadViewPresented) {
                if !viewModel.isReadViewPresented {
                    viewModel.postOption = .nothing
                    viewModel.id = ""
                    viewModel.text = ""
                    viewModel.mediaURLs = []
                    viewModel.mediaCount = 0
                    viewModel.mediaVersion = 0
                    viewModel.mediaPosition = 0
                    viewModel.isLocalizing = false
                    viewModel.localizationCount = 0
                    viewModel.rootLang = ""
                    viewModel.title = ""
                    viewModel.rootMediaPosition = 0
                }
            }
            .onChange(of: viewModel.isCreateViewPresented) {
                if !viewModel.isCreateViewPresented {
                    viewModel.clearData()
                } else {
                    isConfirmationPopupPresented.wrappedValue = false
                }
            }
            .onChange(of: viewModel.isPostCreateViewPresented) {
                if !viewModel.isPostCreateViewPresented {
                    viewModel.clearData()
                } else {
                    isConfirmationPopupPresented.wrappedValue = false
                }
            }
            .onChange(of: viewModel.id) {
                handleCreatedPostIdChange(viewModel: viewModel, hudService: hudService)
            }
            .onChange(of: viewModel.addingMode) {
                handleCreatedPostAddingModeChange(
                    viewModel: viewModel,
                    isConfirmationPopupPresented: isConfirmationPopupPresented
                )
            }
    }
    
    private func handleCreatedPostIdChange(
        viewModel: CreatedPostsViewModel,
        hudService: HUDService
    ) {
        
        guard !viewModel.id.isEmpty else {
            viewModel.clearData()
            viewModel.isLoadingPopupPresented = false
            return
        }
        
        let prePost = viewModel.isArchivePresented
        ? viewModel.archivePosts.first { $0.id == viewModel.id }
        : viewModel.posts.first { $0.id == viewModel.id }
        
        switch viewModel.postOption {
        case .localize:
            guard let prePost, let isShortPost = prePost.isShortPost else {
                viewModel.clearData()
                viewModel.isLoadingPopupPresented = false
                return
            }
            viewModel.isLoadingPopupPresented = true
            viewModel.isLocalizing = true
            viewModel.localizationCount = prePost.localizationCount ?? 0
            viewModel.rootMediaPosition = prePost.mediaPosition ?? 0
            viewModel.rootIsPremiumPost = prePost.isPremiumPost ?? false
            viewModel.rootLang = prePost.originalLanguage ?? "en"
            
            Task {
                do {
                    await viewModel.getMedia(
                        mediaCount: prePost.mediaCount ?? 1,
                        postId: prePost.id,
                        ignoreCache: true
                    )
                    
                    if isShortPost {
                        viewModel.isPostCreateViewPresented = true
                    } else {
                        viewModel.isCreateViewPresented = true
                    }
                    
                    viewModel.isLoadingPopupPresented = false
                }
            }
            
        case .editing:
            guard let prePost else {
                viewModel.clearData()
                return
            }
            
            let isShortPost = prePost.isShortPost ?? false
            viewModel.isLoadingPopupPresented = true
            
            guard let title = prePost.title else {
                viewModel.isLoadingPopupPresented = false
                viewModel.clearData()
                return
            }
            
            if !isShortPost {
                viewModel.title = title
                viewModel.isEditing = true
                viewModel.rootIsPremiumPost = prePost.isPremiumPost ?? false
                viewModel.rootLang = prePost.originalLanguage ?? "en"
                
                Task {
                    do {
                        try await viewModel.getPostToRead(id: viewModel.id)
                        await viewModel.getMedia(
                            mediaCount: prePost.mediaCount ?? 1,
                            postId: prePost.id,
                            ignoreCache: true
                        )
                        
                        viewModel.isLoadingPopupPresented = false
                        viewModel.isCreateViewPresented = true
                    } catch {
                        viewModel.isCreateViewPresented = false
                        viewModel.isLoadingPopupPresented = false
                        viewModel.clearData()
                    }
                }
            } else {
                viewModel.postId = prePost.id
                viewModel.title = title
                viewModel.rootMediaPosition = prePost.mediaPosition ?? 0
                viewModel.rootIsPremiumPost = prePost.isPremiumPost ?? false
                viewModel.rootLang = prePost.originalLanguage ?? "en"
                
                Task {
                    await viewModel.getMedia(
                        mediaCount: prePost.mediaCount ?? 1,
                        postId: prePost.id,
                        ignoreCache: true
                    )
                    
                    viewModel.isLoadingPopupPresented = false
                    viewModel.isPostCreateViewPresented = true
                }
            }
            
        case .publish, .toArchive:
            viewModel.updateIsArchiveStatus()
            viewModel.postOption = .nothing
            
        case .delete:
            Task {
                do {
                    hudService.showLoading(type: .delete)
                    try await viewModel.deletePost(id: viewModel.id)
                    hudService.showSuccessPopup(type: .delete)
                } catch {
                    withAnimation {
                        hudService.showErrorPopup(with: error.localizedDescription)
                        viewModel.id = ""
                    }
                }
            }
            
            viewModel.postOption = .nothing
            
        default:
            break
        }
    }
    
    private func handleCreatedPostAddingModeChange(
        viewModel: CreatedPostsViewModel,
        isConfirmationPopupPresented: Binding<Bool>
    ) {
        isConfirmationPopupPresented.wrappedValue = false
        viewModel.isConfirmationPopupPresented = false
        
        if viewModel.addingMode == 1 {
            viewModel.postId = ""
            viewModel.title = ""
            viewModel.isPostCreateViewPresented = true
        } else if viewModel.addingMode == 2 {
            viewModel.vibrationsService.softImpact()
            viewModel.title = NSLocalizedString("titlePlaceholder", comment: "")
            viewModel.image = nil
            viewModel.isEditing = false
            viewModel.isCreateViewPresented = true
        }
        
        viewModel.addingMode = 0
    }
    
    func makePopupsForCreatedPostsView(
        viewModel: CreatedPostsViewModel,
        isErrorPopupPresented: Binding<Bool>,
        isDescriptionPopupPresented: Binding<Bool>,
        isSuccessPopupPresented: Binding<Bool>,
        isLoadingPopupPresented: Binding<Bool>,
        isReadViewPresented: Binding<Bool>,
        isConfirmationPopupPresented: Binding<Bool>,
        addingMode: Binding<Int>,
        errorText: Binding<String>
    ) -> some View {
        self
            .popup(isPresented: isErrorPopupPresented) {
                Text(viewModel.errorText)
                    .frame(width: UIScreen.main.bounds.width - 72, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .foregroundStyle(Color.white)
                    .background(Color.red)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.top, 20)
            } customize: {
                $0
                    .type(.floater())
                    .position(.top)
                    .animation(.bouncy)
                    .dragToDismiss(true)
                    .autohideIn(5)
                    .displayMode(.overlay)
            }
            .popup(isPresented: isSuccessPopupPresented) {
                Text(viewModel.errorText)
                    .frame(width: UIScreen.main.bounds.width - 72, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .foregroundStyle(Color(.label))
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .foregroundStyle(Color(.systemBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                Color.green, lineWidth: 1
                            )
                    )
                    .padding(.top, 20)
            } customize: {
                $0
                    .type(.floater())
                    .position(.top)
                    .animation(.bouncy)
                    .dragToDismiss(true)
                    .autohideIn(5)
                    .displayMode(.overlay)
            }
            .sheet(isPresented: isLoadingPopupPresented, content: {
                LoadingPopup()
                    .presentationDetents([.height(150)])
                    .presentationCornerRadius(30)
                    .presentationDragIndicator(.visible)
            })
//            .popup(isPresented: isConfirmationPopupPresented) {
//                ConfirmationView(
//                    addingMode: addingMode,
//                    popupType: .postType
//                )
//                .shadow(radius: 2)
//            } customize: {
//                $0
//                    .type(.toast)
//                    .appearFrom(.bottomSlide)
//                    .dragToDismiss(true)
//                    .displayMode(.sheet)
//            }
            .sheet(isPresented: isConfirmationPopupPresented, content: {
                ConfirmationView(addingMode: addingMode, popupType: .postType)
                    .presentationDetents([.height(250)])
                    .presentationCornerRadius(30)
                    .presentationDragIndicator(.visible)
            })
    }
}
