//
//  View extensions.swift
//  ReadBox
//
//  Created by Тимофей Юдин on 01.06.2025.
//

import SwiftUI
import PopupView
import SwiftfulLoadingIndicators
import Shimmer

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
                    .shadow(radius: 3)
            } customize: {
                $0
                    .type(.toast)
                    .appearFrom(.bottomSlide)
            }
            .popup(isPresented: isErrorPopupPresented) {
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
            .popup(isPresented: isDescriptionPopupPresented) {
                DescriptionView(
                    isReadViewPresented: isReadViewPresented,
                    errorText: errorText,
                    isErrorPopupPresented: isErrorPopupPresented,
                    id: viewModel.id,
                    description: viewModel.description
                )
                .shadow(radius: 3)
            } customize: {
                $0
                    .type(.toast)
                    .appearFrom(.bottomSlide)
                    .dragToDismiss(true)
            }
    }
    
    @MainActor func trackChangesOnFeedView(
        viewModel: FeedViewModel,
        isSignInViewPresented: Bool
    ) -> some View {
        self
            .onChange(of: isSignInViewPresented) {
                if !isSignInViewPresented {
                    viewModel.refresh()
                }
            }
            .onChange(of: viewModel.topArticlesIndexes) {
                if viewModel.topArticlesIndexes.count == 5 {
                    Task {
                        do {
                            try await viewModel.getTopArticles()
                            
                            return
                        } catch {
                            //                                withAnimation {
                            //                                    viewModel.errorText = error.localizedDescription
                            //                                }
                        }
                        
                        //                            viewModel.isErrorPopupPresented = true
                    }
                }
            }
            .onChange(of: viewModel.topArticles) {
                if viewModel.topArticles.count == 5 {
                    withAnimation {
                        viewModel.articles = []
                        viewModel.isLoadingShowing = true
                    }
                    
                    Task {
                        viewModel.isLoading = true
                        
                        do {
                            try await viewModel.getArticles()
                            
                            return
                        } catch {
                            //                                withAnimation {
                            //                                    viewModel.errorText = error.localizedDescription
                            //                                }
                        }
                        
                        //                            viewModel.isErrorPopupPresented = true
                    }
                }
            }
            .onChange(of: viewModel.user) {
                if viewModel.user != nil {
                    viewModel.primaryLanguage = StorageManager.shared.getLanguage()
                    
                    if viewModel.maxIndex == "" && viewModel.fromIndex == -1 {
                        Task {
                            do {
                                try await viewModel.getMaxIndex()
                                viewModel.fromIndex = Int(viewModel.maxIndex) ?? 1
                                return
                            } catch {
                                withAnimation {
                                    viewModel.errorText = error.localizedDescription
                                }
                            }
                            
                            viewModel.isErrorPopupPresented = true
                        }
                    }
                    
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
            .onChange(of: viewModel.isReadViewPresented) {
                if !viewModel.isReadViewPresented {
                    viewModel.postToView = nil
                }
            }
            .onChange(of: viewModel.postToView) {
                if viewModel.postToView != nil {
                    viewModel.id = viewModel.postToView?.id ?? ""
                    viewModel.title = viewModel.postToView?.title ?? ""
                    viewModel.text = viewModel.postToRead?.text ?? ""
                    viewModel.dateCreated = viewModel.postToRead?.dateCreated ?? Date()
                    viewModel.likesCount = viewModel.postToView?.likesCount ?? 0
                    viewModel.authorId = viewModel.postToView?.authorId ?? ""

                    viewModel.isReadViewPresented = true
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
            .popup(isPresented: isLoadingPopupPresented) {
                LoadingPopup()
                    .shadow(radius: 3)
            } customize: {
                $0
                    .type(.toast)
                    .appearFrom(.bottomSlide)
            }
            .popup(isPresented: isDescriptionPopupPresented) {
                DescriptionView(
                    isReadViewPresented: isReadViewPresented,
                    errorText: errorText,
                    isErrorPopupPresented: isErrorPopupPresented,
                    id: viewModel.id,
                    description: viewModel.description
                )
                .shadow(radius: 3)
            } customize: {
                $0
                    .type(.toast)
                    .appearFrom(.bottomSlide)
                    .dragToDismiss(true)
            }
    }
    
    func trackChangesOnLikedPosts(
        viewModel: LikedPostsViewModel,
        isSignInViewPresented: Bool
    ) -> some View {
        self
            .onChange(of: viewModel.user) {
                withAnimation {
                    viewModel.articles = []
                    viewModel.isLoadingShowed = true
                }
                
                viewModel.isLoading = true
                
                if viewModel.user?.likedPosts != nil {
                    viewModel.likedPosts = viewModel.user?.likedPosts ?? []
                    
                    if viewModel.likedPosts.count == 0 {
                        withAnimation {
                            viewModel.isLoading = false
                            viewModel.isLoadingShowed = false
                        }
                    }
                    
                }
            }
            .onChange(of: viewModel.postToView) {
                if viewModel.postToView != nil {
                    viewModel.id = viewModel.postToView?.id ?? ""
                    viewModel.title = viewModel.postToView?.title ?? ""
                    viewModel.text = viewModel.postToRead?.text ?? ""
                    viewModel.dateCreated = viewModel.postToRead?.dateCreated ?? Date()
                    viewModel.likesCount = viewModel.postToView?.likesCount ?? 0
                    viewModel.authorId = viewModel.postToView?.authorId ?? ""

                    viewModel.isReadViewPresented = true
                }
            }
            .onChange(of: viewModel.isReadViewPresented) {
                if !viewModel.isReadViewPresented {
                    viewModel.postToView = nil
                }
            }
            .onChange(of: isSignInViewPresented) {
                if !isSignInViewPresented {
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
    func makeToolbarForCreatedPostsView(
        with viewModel: CreatedPostsViewModel
    ) -> some View  {
        self
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .frame(width: UIScreen.main.bounds.width, height: viewModel.user?.authorName == "" || viewModel.isSettingViewPresented ? 130 : 170)
                            .foregroundStyle(Color(uiColor: .secondarySystemBackground))
                            .padding(.bottom, 40)
                            .shadow(radius: 10)
                        
                        if viewModel.user?.authorName == "" && !viewModel.isLoadingShowing {
                            Text(NSLocalizedString("becomeAuthorLabel", comment: ""))
                                .font(.largeTitle)
                                .fontWeight(.light)
                                .frame(width: UIScreen.main.bounds.width - 32, alignment: .leading)
                        } else if viewModel.isSettingViewPresented {
                            Text(NSLocalizedString("editingLabel", comment: ""))
                                .font(.largeTitle)
                                .fontWeight(.light)
                                .frame(width: UIScreen.main.bounds.width - 32, alignment: .leading)
                        } else {
                            if viewModel.isLoadingShowing {
                                VStack(spacing: -30) {
                                    HStack {
                                        HStack(spacing: 0) {
                                            Text("Hello, World!")
                                                .font(.largeTitle)
                                                .fontWeight(.light)
                                                .redacted(reason: .placeholder)
                                                .shimmering()
                                            
                                            Image(systemName: "checkmark.seal.fill")
                                                .foregroundStyle(Color.blue)
                                                .font(.footnote)
                                                .padding(.top, 4)
                                                .redacted(reason: .placeholder)
                                            
                                            Spacer()
                                            
                                            LoadingIndicator(
                                                animation: .circleRunner,
                                                color: Color(uiColor: .label),
                                                size: .small,
                                                speed: .fast
                                            )
                                            
                                        }
                                        
                                    }
                                    .frame(width: UIScreen.main.bounds.width - 32, alignment: .leading)
                                    
                                    HStack {
                                        Text("100 000 \(NSLocalizedString("subscribersCountLabel", comment: ""))")
                                        .font(.callout)
                                        .foregroundStyle(Color.gray)
                                        .redacted(reason: .placeholder)
                                        .shimmering()
                                            
                                        Text("•")
                                            .font(.title)
                                            .foregroundStyle(Color.gray)
                                        
                                        Text("100 \(NSLocalizedString("publicationsCountLabel", comment: ""))")
                                        .font(.callout)
                                        .foregroundStyle(Color.gray)
                                        .redacted(reason: .placeholder)
                                        .shimmering()
                                    }
                                    .frame(width: UIScreen.main.bounds.width - 32, alignment: .leading)
                                    .offset(y: 30)
                                }
                            } else {
                                VStack(spacing: -30) {
                                    HStack {
                                        HStack(spacing: 0) {
                                            Text(viewModel.user?.authorName ?? "")
                                                .font(.largeTitle)
                                                .fontWeight(.light)
                                                .lineLimit(1)
                                            
                                            if viewModel.user?.isCheckmark ?? false {
                                                Image(systemName: "checkmark.seal.fill")
                                                    .foregroundStyle(Color.blue)
                                                    .font(.footnote)
                                                    .padding(.top, 4)
                                            }
                                        }
                                        
                                        
                                        Spacer()
                                        
                                        if viewModel.isLoading {
                                            LoadingIndicator(
                                                animation: .circleRunner,
                                                color: Color(uiColor: .label),
                                                size: .small,
                                                speed: .fast
                                            )
                                        } else {
                                            Button {
                                                withAnimation {
                                                    viewModel.isSettingViewPresented.toggle()
                                                }
                                            } label: {
                                                Image(systemName: "gearshape.fill")
                                                    .foregroundStyle(Color.gray)
                                                    .font(.system(size: 17))
                                                    .fontWeight(.bold)
                                            }
                                            .offset(x: 10)
                                            
                                            Button {
                                                withAnimation {
                                                    viewModel.isArchivePresented.toggle()
                                                }
                                            } label: {
                                                if viewModel.isArchivePresented {
                                                    Image(systemName: "rectangle.on.rectangle")
                                                        .font(.system(size: 19))
                                                        .fontWeight(.bold)
                                                        .foregroundStyle(Color.gray)
                                                } else {
                                                    Image(systemName: "archivebox")
                                                        .font(.system(size: 19))
                                                        .fontWeight(.bold)
                                                        .foregroundStyle(Color.gray)
                                                }
                                            }
                                        }
                                        
                                    }
                                    .frame(width: UIScreen.main.bounds.width - 32, alignment: .leading)
                                    
                                    HStack {
                                        Text("\(viewModel.user?.subscribersCount ?? 0) \(NSLocalizedString("subscribersCountLabel", comment: ""))")
                                        .font(.callout)
                                        .foregroundStyle(Color.gray)
                                            
                                        Text("•")
                                            .font(.title)
                                            .foregroundStyle(Color.gray)
                                        
                                        Text("\(viewModel.postsCount) \(NSLocalizedString("publicationsCountLabel", comment: ""))")
                                        .font(.callout)
                                        .foregroundStyle(Color.gray)
                                    }
                                    .frame(width: UIScreen.main.bounds.width - 32, alignment: .leading)
                                    .offset(
                                        y: viewModel.isLoading
                                        ? 33
                                        : -50
                                    )
                                }
                            }
                        }
                    }
                    .padding(.leading, 6)
                }
                
            }
    }
    
    func trackChangesOnCreatedPostsView(
        viewModel: CreatedPostsViewModel,
        isSignInViewPresented: Bool
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
                    }
                    
                    Task {
                        do {
                            try await viewModel.getPosts()
                            try await viewModel.getArchivedPost()
                            
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
//            .onChange(of: viewModel.articlesIndexes) {
//                if viewModel.articlesIndexes != [] {
//                    withAnimation {
//                        viewModel.isLoadingShowing = true
//                    }
//                    
//                    Task {
//                        viewModel.isLoading = true
//                        
//                        do {
//                            viewModel.postsNeedToLoad = viewModel.articlesIndexes
//                            try await viewModel.getPosts()
//                        } catch {
//                            withAnimation {
//                                viewModel.errorText = error.localizedDescription
//                                viewModel.isErrorPopupPresented = true
//                            }
//                        }
//                    }
//                }
//            }
            .onChange(of: isSignInViewPresented) {
                if !isSignInViewPresented {
                    viewModel.reload()
                }
            }
            .onChange(of: viewModel.isReadViewPresented) {
                if !viewModel.isReadViewPresented {
                    viewModel.postOption = .nothing
                    viewModel.id = ""
                    viewModel.text = ""
                    viewModel.mediaURLs = []
                }
            }
            .onChange(of: viewModel.isCreateViewPresented) {
                if !viewModel.isCreateViewPresented {
                    viewModel.postOption = .nothing
                    viewModel.id = ""
                    viewModel.text = ""
                    viewModel.mediaURLs = []
                }
            }
            .onChange(of: viewModel.id) {
                if viewModel.id != "" {
                    var prePost: PrePost? = nil
                    
                    if viewModel.isArchivePresented {
                        prePost = viewModel.archivePosts.filter { $0.id == viewModel.id }[0]
                    } else {
                        prePost = viewModel.posts.filter { $0.id == viewModel.id }[0]
                    }
                    
                    switch viewModel.postOption {
                    case .editing:
                        viewModel.isLoadingPopupPresented = true
                        
                        Task {
                            do {
                                try await viewModel.getPostToRead(id: viewModel.id)
                                
                                viewModel.title = prePost?.title ?? NSLocalizedString("notFoundLabel", comment: "")
                                viewModel.image = StorageManager.shared.getImage(id: viewModel.id)
                                viewModel.isEditing = true

                                viewModel.isCreateViewPresented = true
                            } catch {
                                withAnimation {
                                    viewModel.errorText = error.localizedDescription
                                    viewModel.isErrorPopupPresented = true
                                }
                            }
                            
                            viewModel.isLoadingPopupPresented = false
                        }
                        
                    case .publish:
                        viewModel.updateIsArchiveStatus()
                        viewModel.postOption = .nothing
                    case .toArchive:
                        viewModel.updateIsArchiveStatus()
                        viewModel.postOption = .nothing
                    case .delete:
                        viewModel.deletePost(id: viewModel.id)
                        viewModel.postOption = .nothing
                    default:
                        print("OK")
                    }
                    
                }
            }
    }
    
    func makePopupsForCreatedPostsView(
        viewModel: CreatedPostsViewModel,
        isErrorPopupPresented: Binding<Bool>,
        isDescriptionPopupPresented: Binding<Bool>,
        isSuccessPopupPresented: Binding<Bool>,
        isLoadingPopupPresented: Binding<Bool>,
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
            .popup(isPresented: isDescriptionPopupPresented) {
                DescriptionView(
                    isReadViewPresented: isReadViewPresented,
                    errorText: errorText,
                    isErrorPopupPresented: isErrorPopupPresented,
                    id: viewModel.id,
                    description: viewModel.description
                )
                .shadow(radius: 3)
            } customize: {
                $0
                    .type(.toast)
                    .appearFrom(.bottomSlide)
                    .dragToDismiss(true)
            }
            .popup(isPresented: isSuccessPopupPresented) {
                Text(viewModel.errorText)
                    .frame(width: UIScreen.main.bounds.width - 72, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .foregroundStyle(Color.white)
                    .background(Color.green)
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
            .popup(isPresented: isLoadingPopupPresented) {
                LoadingPopup()
                    .shadow(radius: 3)
            } customize: {
                $0
                    .type(.toast)
                    .appearFrom(.bottomSlide)
            }
    }
}

