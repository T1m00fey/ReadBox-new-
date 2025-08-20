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
                    viewModel.likedPosts = viewModel.user?.likedPosts ?? []
                    
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
    func makeToolbarForCreatedPostsView(
        with viewModel: CreatedPostsViewModel
    ) -> some View  {
        self
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .frame(width: UIScreen.main.bounds.width, height: viewModel.isSettingViewPresented ? 130 : 170)
                            .foregroundStyle(Color(uiColor: .secondarySystemBackground))
                            .padding(.bottom, 40)
                            .shadow(radius: 10)
                        
                        if viewModel.isSettingViewPresented {
                            Text(NSLocalizedString("editingLabel", comment: ""))
                                .font(.largeTitle)
                                .fontWeight(.light)
                                .frame(width: UIScreen.main.bounds.width - 32, alignment: .leading)
                        } else {
                            if viewModel.isLoadingShowing {
                                VStack(spacing: -30) {
                                    HStack {
                                        Circle()
                                            .stroke(
                                                Color(.label),
                                                lineWidth: 0.1
                                            )
                                            .frame(width: 50, height: 50)
                                            .shimmering()
                                        
                                        HStack(spacing: 0) {
                                            Text("Hello, World!")
                                                .font(.system(size: 27))
                                                .fontWeight(.light)
                                                .redacted(reason: .placeholder)
                                                .shimmering()
                                            
                                            Image(systemName: "checkmark.seal.fill")
                                                .foregroundStyle(Color.blue)
                                                .font(.footnote)
                                                .padding(.top, 1)
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
                                        if let avatar = viewModel.avatarImage {
                                            Image(uiImage: avatar)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 50, height: 50)
                                                .clipShape(Circle())
                                                .overlay {
                                                    Circle()
                                                        .stroke(
                                                            Color(.label),
                                                            lineWidth: 0.1
                                                        )
                                                }
                                                .onTapGesture {
                                                    viewModel.isZoomableImageViewPresented = true
                                                }
                                        }
                                        
                                        HStack(spacing: 0) {
                                            Text(viewModel.user?.name ?? "")
                                                .font(.system(size: 27))
                                                .fontWeight(.light)
                                                .lineLimit(1)
                                            
                                            if viewModel.user?.isCheckmark ?? false {
                                                Image(systemName: "checkmark.seal.fill")
                                                    .foregroundStyle(Color.blue)
                                                    .font(.footnote)
                                                    .padding(.top, 1)
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
                                            
                                            if viewModel.archivePosts.count > 0 {
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
        isWelcomeViewPresented: Bool
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
            .onChange(of: isWelcomeViewPresented) {
                if !isWelcomeViewPresented {
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
                    viewModel.videoURL = nil
                    viewModel.isVideoCover = false
                }
            }
            .onChange(of: viewModel.id) {
                if viewModel.id != "" {
                    var prePost: PrePost? = nil
                    
                    if viewModel.isArchivePresented {
                        prePost = viewModel.archivePosts.first { $0.id == viewModel.id }
                    } else {
                        prePost = viewModel.posts.first { $0.id == viewModel.id }
                    }
                    
                    switch viewModel.postOption {
                    case .editing:
                        if let prePost, let isShortPost = prePost.isShortPost {
                            if isShortPost == false {
                                viewModel.isLoadingPopupPresented = true
                                
                                Task {
                                    do {
                                        try await viewModel.getPostToRead(id: viewModel.id)
                                        
                                        viewModel.title = prePost.title ?? NSLocalizedString("notFoundLabel", comment: "")
                                        viewModel.image = StorageManager.shared.getImage(id: viewModel.id)
                                        viewModel.isEditing = true
                                        
                                        if viewModel.image == nil {
                                            do {
                                                let videoRef = Storage.storage().reference().child("images/\(viewModel.id).mp4")
                                                let url = try await videoRef.downloadURL()
                                                viewModel.videoURL = url

                                                let asset = AVAsset(url: url)
                                                let _ = try await asset.loadTracks(withMediaType: .video)

                                                let generator = AVAssetImageGenerator(asset: asset)
                                                generator.appliesPreferredTrackTransform = true
                                                let cgImage = try generator.copyCGImage(at: .zero, actualTime: nil)
                                                let preview = UIImage(cgImage: cgImage)

                                                await MainActor.run {
                                                    withAnimation {
                                                        viewModel.image = preview
                                                        viewModel.isVideoCover = true
                                                    }
                                                }
                                            } catch {
                                                print("❌ Видео не найдено или ошибка при генерации превью: \(error)")
                                            }
                                        }
                                        
                                        viewModel.isCreateViewPresented = true
                                    } catch {
                                        withAnimation {
                                            viewModel.errorText = error.localizedDescription
                                            viewModel.isErrorPopupPresented = true
                                        }
                                    }
                                    
                                    viewModel.isLoadingPopupPresented = false
                                }
                            } else {
                                if let title = prePost.title {
                                    viewModel.postId = prePost.id
                                    viewModel.title = title
                                    
                                    viewModel.isPostCreateViewPresented = true
                                }
                            }
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
            .onChange(of: viewModel.addingMode) {
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
            .popup(isPresented: isSuccessPopupPresented) {
                Text(viewModel.errorText)
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
            .popup(isPresented: isLoadingPopupPresented) {
                LoadingPopup()
                    .shadow(radius: 3)
            } customize: {
                $0
                    .type(.toast)
                    .appearFrom(.bottomSlide)
            }
            .popup(isPresented: isConfirmationPopupPresented) {
                ConfirmationView(
                    addingMode: addingMode,
                    popupType: .postType
                )
                .shadow(radius: 3)
            } customize: {
                $0
                    .type(.toast)
                    .appearFrom(.bottomSlide)
                    .dragToDismiss(true)
            }
    }
}

