//
//  CreateView.swift
//  Readify
//
//  Created by Тимофей Юдин on 20.01.2025.
//

import SwiftUI
import PopupView
import FirebaseStorage
import SwiftfulLoadingIndicators
import Shimmer
import TipKit

struct CreatedPostsView: View {
    @Binding var isSignInViewPresented: Bool
    
    @StateObject var viewModel = CreatedPostsViewModel()
    
    @FocusState var isAuthorNameFocused: Bool
    @FocusState var isDescriptionFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemBackground)
                    .ignoresSafeArea()
                    .onTapGesture {
                        isAuthorNameFocused = false
                        isDescriptionFocused = false
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
                            
                            return
                        }
                        
                        Task {
                            do {
                                try await viewModel.loadUser()
                                
                                withAnimation {
                                    viewModel.authorNameText = viewModel.user?.authorName ?? ""
                                    viewModel.descriptionText = viewModel.user?.authorDescription ?? ""
                                    
                                    viewModel.getAvatar()
                                }
                            } catch {
                                viewModel.isErrorPopupPresented = true
                                viewModel.errorText = error.localizedDescription
                            }
                        }
                    }
                    
                    .fullScreenCover(isPresented: $viewModel.isCreateViewPresented, content: {
                        CreateView(
                            isCreateViewPresented: $viewModel.isCreateViewPresented,
                            id:  viewModel.id,
                            title: viewModel.title,
                            image: viewModel.image,
                            description: viewModel.description,
                            text: viewModel.text,
                            isEditing: viewModel.isEditing,
                            mediaURLs: viewModel.mediaURLs,
                            isVideo: viewModel.isVideoCover,
                            videoURL: viewModel.videoURL,
                            postsCount: $viewModel.postsCount,
                            posts: $viewModel.posts,
                            archivePosts: $viewModel.archivePosts
                        )
                    })
                    .fullScreenCover(isPresented: $viewModel.isReadViewPresented) {
                        ReadView(
                            id: viewModel.id,
                            title: viewModel.title,
                            text: viewModel.text,
                            dateCreated: viewModel.dateCreated,
                            likesCount: viewModel.likesCount,
                            authorId: viewModel.user?.userId ?? "",
                            authorName: viewModel.user?.authorName ??  NSLocalizedString("notFoundLabel", comment: ""),
                            isCheckmark: viewModel.user?.isCheckmark ?? false,
                            isArchive: false,
                            user: $viewModel.user,
                            isChannelViewPresented: .constant(false)
                        )
                    }
                    .fullScreenCover(isPresented: $viewModel.isZoomableImageViewPresented, content: {
                        ZoomableImageView(image: viewModel.avatarImage)
                    })
                    .makeToolbarForCreatedPostsView(with: viewModel)
                    .trackChangesOnCreatedPostsView(
                        viewModel: viewModel,
                        isSignInViewPresented: isSignInViewPresented
                    )
                    .makePopupsForCreatedPostsView(
                        viewModel: viewModel,
                        isErrorPopupPresented: $viewModel.isErrorPopupPresented,
                        isDescriptionPopupPresented: $viewModel.isDescriptionPopupPresented,
                        isSuccessPopupPresented: $viewModel.isSuccessPopupPresented,
                        isLoadingPopupPresented: $viewModel.isLoadingPopupPresented,
                        isReadViewPresented: $viewModel.isReadViewPresented,
                        errorText: $viewModel.errorText
                    )
                
                if viewModel.user?.authorName != "" && !viewModel.isSettingViewPresented {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 20) {
                            if viewModel.isLoadingShowing {
                                
                                Text("HelloWorldHelloWorld HelloWorld HelloWorld HelloWorldHelloWorld HelloWorld HelloWorld")
                                    .padding(.vertical, 20)
                                    .padding(.horizontal, 16)
                                    .frame(width: UIScreen.main.bounds.width, alignment: .leading)
                                    .background(Color(uiColor: .secondarySystemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                                    .padding(.top, 50)
                                    .redacted(reason: .placeholder)
                                    .shimmering()
                                
                                Text(NSLocalizedString("publicationsLabel", comment: ""))
                                    .font(.title)
                                    .fontWeight(.light)
                                    .fontDesign(.rounded)
                                    .frame(width: UIScreen.main.bounds.width - 20, alignment: .leading)
                                    .padding(.top, 20)
                                    .redacted(reason: .placeholder)
                                
                                ForEach(0..<4) { num in
                                    PostView(
                                        id: "-1",
                                        title: "Hello, World!",
                                        likesCount: 10,
                                        viewsCount: 10,
                                        isArchive: false,
                                        isAuthorView: true,
                                        postOption: $viewModel.postOption,
                                        selectedId: $viewModel.id
                                    )
                                    .padding(.horizontal)
                                    .redacted(reason: .placeholder)
                                    .shimmering()
                                }
                                
                            } else if viewModel.posts.count > 0 ||  viewModel.archivePosts.count > 0 {
                                
                                let isArchivePresented = viewModel.isArchivePresented
                                
                                if viewModel.user?.authorDescription ?? "" != "" {
                                    Text(viewModel.user?.authorDescription ?? NSLocalizedString("notFoundLabel", comment: ""))
                                        .font(.title3)
                                        .padding(.vertical, 20)
                                        .padding(.horizontal, 16)
                                        .frame(width: UIScreen.main.bounds.width, alignment: .leading)
                                        .background(Color(uiColor: .secondarySystemBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 20))
                                        .padding(.top, 50)
                                }
                                
                                Text(
                                    isArchivePresented
                                    ? NSLocalizedString("archiveLabel", comment: "")
                                    : NSLocalizedString("publicationsLabel", comment: "")
                                )
                                    .font(.system(size: 26))
                                    .fontWeight(.light)
                                    .fontDesign(.rounded)
                                    .frame(minWidth: UIScreen.main.bounds.width - 20, alignment: .leading)
                                    .padding(.top, viewModel.user?.authorDescription == "" ? 50 : 20)
                                
                                if (viewModel.isArchivePresented && viewModel.archivePosts.count != 0)
                                    || (!viewModel.isArchivePresented && viewModel.posts.count != 0) {
                                    ForEach(
                                        isArchivePresented
                                        ? viewModel.archivePosts
                                        : viewModel.posts
                                    ) { post in
                                        PostView(
                                            id: post.id,
                                            title: post.title ?? NSLocalizedString("noFoundLabel", comment: ""),
                                            likesCount: post.likesCount ?? 0,
                                            viewsCount: post.viewsCount ?? 0,
                                            isArchive: post.isArchive ?? false,
                                            isAuthorView: true,
                                            postOption: $viewModel.postOption,
                                            selectedId: $viewModel.id
                                        )
                                        .padding(
                                            .bottom, viewModel.getBottomPadding(by: post.id)
                                        )
                                        .onTapGesture {
                                            viewModel.tapGestureHandler(on: post)
                                        }
                                        .onAppear {
                                            let lastPost = viewModel.isArchivePresented
                                            ? viewModel.archivePosts.last
                                            : viewModel.posts.last
                                            
                                            if post == lastPost, !viewModel.isAllLoaded {
                                                Task {
                                                    viewModel.isArchivePresented
                                                    ? try? await viewModel.getPosts()
                                                    : try? await viewModel.getArchivedPost()
                                                }
                                            }
                                        }
                                    }
                                } else if viewModel.archivePosts.count == 0 || viewModel.posts.count == 0 {
                                    if viewModel.isArchivePresented {
                                        VStack(spacing: 20) {
                                            Text(LocalizedStringKey("noArticlesAddedLabel"))
                                                .font(.title)
                                                .bold()
                                                .fontDesign(.rounded)
                                                .foregroundStyle(Color.gray)
                                                .multilineTextAlignment(.center)
                                                .frame(width: UIScreen.main.bounds.width - 32)
                                            
                                            Text(NSLocalizedString("toPublicationsLabel", comment: ""))
                                                .frame(width: UIScreen.main.bounds.width - 10, height: 50, alignment: .center)
                                                .font(.title3)
                                                .fontDesign(.rounded)
                                                .background(Color(uiColor: .secondarySystemBackground))
                                                .foregroundStyle(Color(uiColor: .label))
                                                .clipShape(RoundedRectangle(cornerRadius: 15))
                                                .shadow(radius: 3)
                                                .padding(.bottom, 10)
                                                .onTapGesture {
                                                    withAnimation {
                                                        viewModel.isArchivePresented = false
                                                        VibrationsService.shared.softImpact()
                                                    }
                                                }
                                                .frame(width: UIScreen.main.bounds.width - 32)
                                        }
                                    } else if viewModel.posts.count == 0 {
                                        VStack(spacing: 20) {
                                            Image(systemName: "pencil.and.scribble")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 100)
                                                .foregroundStyle(Color.gray)
                                            
                                            Text(LocalizedStringKey("noArticlesAddedLabel"))
                                                .font(.title)
                                                .bold()
                                                .fontDesign(.rounded)
                                                .foregroundStyle(Color.gray)
                                                .multilineTextAlignment(.center)
                                            
                                        }
                                        .frame(width: UIScreen.main.bounds.width - 32)
                                        .padding(.top, 100)
                                    }
                                }
                                
                            } else {
                                if viewModel.user?.authorDescription ?? "" != "" {
                                    Text(viewModel.user?.authorDescription ?? NSLocalizedString("notFoundLabel", comment: ""))
                                        .font(.title3)
                                        .padding(.vertical, 20)
                                        .padding(.horizontal, 16)
                                        .frame(width: UIScreen.main.bounds.width, alignment: .leading)
                                        .background(Color(uiColor: .secondarySystemBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 20))
                                        .padding(.top, 50)
                                }
                                
                                VStack(spacing: 20) {
                                    
                                    Image(systemName: "pencil.and.scribble")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 100)
                                        .foregroundStyle(Color.gray)
                                    
                                    Text(LocalizedStringKey("noArticlesAddedLabel"))
                                        .font(.system(size: 25))
                                        .bold()
                                        .fontDesign(.rounded)
                                        .foregroundStyle(Color.gray)
                                        .multilineTextAlignment(.center)
                                    
                                }
                                .frame(width: UIScreen.main.bounds.width - 32)
                                .padding(.top, 100)
                            }
                            
                            if !viewModel.isLoading
                                && ((viewModel.isArchivePresented && !viewModel.isAllArchivedLoaded && viewModel.archivePosts.count >= 20)
                                    || (!viewModel.isArchivePresented && !viewModel.isAllLoaded && viewModel.posts.count >= 20)) {
                                Button {
                                    Task {
                                        do {
                                            if viewModel.isArchivePresented {
                                                try await viewModel.getPosts()
                                            } else {
                                                try await viewModel.getArchivedPost()
                                            }
                                            return
                                        } catch {
                                            withAnimation {
                                                viewModel.errorText = error.localizedDescription
                                            }
                                        }
                                        
                                        viewModel.isErrorPopupPresented = true
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "arrow.down")
                                            .foregroundStyle(Color(uiColor: .label))
                                            .font(.title3)
                                            .fontWeight(.light)
                                        
                                        Text(LocalizedStringKey("loadMore"))
                                            .font(.title3)
                                            .fontDesign(.rounded)
                                            .fontWeight(.light)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(Color(uiColor: .secondarySystemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .shadow(radius: 2)
                                    .padding(.bottom, 20)
                                }
                                .padding(.bottom, 10)
                                .offset(y: -30)
                                
                            }
                            
                        }
                    }
                    .frame(width: UIScreen.main.bounds.width)
                    .padding(.top, 20)
                    .refreshable {
                        viewModel.reload()
                    }
                    .task {
                        try? Tips.configure()
                    }
                    
                    if !viewModel.isLoading && viewModel.isNewPublicationButtonPresented && viewModel.user?.authorName != "" {
                        VStack {
                            Spacer()
                            
                            Text(NSLocalizedString("newPublicationLabel", comment: ""))
                                .frame(width: UIScreen.main.bounds.width - 10, height: 50, alignment: .center)
                                .font(.title3)
                                .fontDesign(.rounded)
                                .background(Color(uiColor: .label))
                                .foregroundStyle(Color(uiColor: .systemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 15))
                                .shadow(radius: 3)
                                .padding(.bottom, 10)
                                .popoverTip(AuthorMultiLanguageTip())
                                .onTapGesture {
                                    viewModel.vibrationsService.lightImpact()
                                    
                                    viewModel.title = NSLocalizedString("titlePlaceholder", comment: "")
                                    viewModel.description = NSLocalizedString("descriptionPlaceholder", comment: "")
                                    viewModel.image = nil
                                    viewModel.isEditing = false
                                    viewModel.isCreateViewPresented = true
                                }
                        }
                    }
                } else if viewModel.user?.authorName ?? "" == "" || viewModel.isSettingViewPresented == true {
                    VStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: 30)
                                .foregroundStyle(Color(uiColor: .secondarySystemBackground))
                                .frame(width: UIScreen.main.bounds.width - 60, height: 270)
                                .shadow(radius: 2)
                            
                            VStack(spacing: 25) {
                                AvatarControlView(
                                    authorId: viewModel.user?.userId ?? "",
                                    avatarImage: $viewModel.avatarImage
                                )
                                
                                VStack {
                                    TextField(LocalizedStringKey("nameLabel"), text: $viewModel.authorNameText)
                                        .frame(width: UIScreen.main.bounds.width - 92)
                                        .font(.title2)
                                        .focused($isAuthorNameFocused)
                                        .textInputAutocapitalization(.never)
                                        .onChange(of: viewModel.authorNameText) {
                                            viewModel.isButtonEnable()
                                        }
                                        .tint(Color(uiColor: .label))
                                    
                                    RoundedRectangle(cornerRadius: 0)
                                        .frame(width: UIScreen.main.bounds.width - 92, height: 2)
                                        .foregroundStyle(isAuthorNameFocused ? Color(uiColor: .label) : Color.gray)
                                }
                                
                                VStack {
                                    TextField(NSLocalizedString("descriptionLabel", comment: ""), text: $viewModel.descriptionText)
                                        .frame(width: UIScreen.main.bounds.width - 92)
                                        .font(.title2)
                                        .focused($isDescriptionFocused)
                                        .textInputAutocapitalization(.never)
                                        .tint(Color(uiColor: .label))
                                        
                                    RoundedRectangle(cornerRadius: 0)
                                        .frame(width: UIScreen.main.bounds.width - 92, height: 2)
                                        .foregroundStyle(isDescriptionFocused ? Color(uiColor: .label) : Color.gray)
                                }
                            }
                            .padding(.vertical, 5)
                            .onAppear {
                                viewModel.isButtonEnable()
                            }
                        }
                        
                        Button {
                            if viewModel.authorNameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                withAnimation {
                                    viewModel.errorText = NSLocalizedString("nameErrorLabel", comment: "")
                                    viewModel.isErrorPopupPresented = true
                                }
                            } else {
                                Task {
                                    do {
                                        withAnimation {
                                            viewModel.isLoading = true
                                            viewModel.isButtonEnabled = false
                                        }
                                        
                                        viewModel.vibrationsService.softImpact()
                                        
                                        if let avatar =  viewModel.avatarImage,
                                           let data = avatar.jpegData(compressionQuality: 0.8),
                                           let userId = viewModel.user?.userId
                                        {
                                            let ref = Storage.storage().reference().child("avatars/\(userId).jpg")
                                            _ = try await ref.putDataAsync(data)
                                        } else {
                                            if let userId = viewModel.user?.userId {
                                                let ref = Storage.storage().reference().child("avatars/\(userId).jpg")
                                                do {
                                                    try await ref.delete()
                                                    StorageManager.shared.deleteImage(id: userId)
                                                } catch {
                                                    print("Ошибка при удалении аватара: \(error.localizedDescription)")
                                                }
                                            }
                                        }
                                    
                                        if viewModel.user?.authorName != viewModel.authorNameText {
                                            try await viewModel.removeCheckmarkStatus()
                                        }
                                        try await viewModel.changeAuthorName(to: viewModel.authorNameText, description: viewModel.descriptionText)
                                        
                                        withAnimation {
                                            viewModel.isLoading = false
                                            viewModel.isSettingViewPresented = false
                                            viewModel.user?.authorName = viewModel.authorNameText
                                            viewModel.user?.authorDescription = viewModel.descriptionText
                                        }
                                        
                                        withAnimation {
                                            viewModel.isButtonEnabled = false
                                        }
                                    } catch {
                                        withAnimation {
                                            viewModel.errorText = error.localizedDescription
                                            viewModel.isErrorPopupPresented = true
                                            viewModel.isLoading = false
                                            viewModel.isButtonEnabled = false
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Text(
                                    viewModel.isLoading
                                    ? LocalizedStringKey("shortNextLabel")
                                    : LocalizedStringKey("nextLabel")
                                )
                                    .foregroundStyle(
                                        viewModel.isButtonEnabled
                                        ? Color(uiColor: .label)
                                        : Color.gray
                                    )
                                
                                if viewModel.isLoading {
                                    LoadingIndicator(
                                        animation: .circleRunner,
                                        color: Color(.label),
                                        size: .small,
                                        speed: .fast
                                    )
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
                    .padding(.horizontal)
                }
            }
        }
        .navigationBarBackButtonHidden()
    }
}

