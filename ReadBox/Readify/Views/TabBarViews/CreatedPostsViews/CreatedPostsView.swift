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
    @Binding var isWelcomeViewPresented: Bool
    @Binding var isConfirmationPopupPresented: Bool
    
    @StateObject var viewModel = CreatedPostsViewModel()
    
    @FocusState var isAuthorNameFocused: Bool
    @FocusState var isDescriptionFocused: Bool
    
    @EnvironmentObject var hudService: HUDService
    @EnvironmentObject var sessionManager: SessionManager
    @EnvironmentObject var changedPostsManager: ChangedPostsManager
    @EnvironmentObject var subManager: SubscriptionManager
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemBackground)
                    .ignoresSafeArea()
                    .onTapGesture {
                        isAuthorNameFocused = false
                        isDescriptionFocused = false
                    }
                    .onReceive(NotificationCenter.default.publisher(for: .postsDidChange)) { _ in
                        viewModel.isNeedToReload = true
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
                        
                        if viewModel.user == nil {
                            Task {
                                do {
                                    try await viewModel.loadUser()
                                    if let id = viewModel.user?.userId {
                                        let ava = await MediaManager.shared.getAvatar(
                                            authorId: id,
                                            lastVersion: viewModel.avatarVersion
                                        )
                                        
                                        withAnimation {
                                            viewModel.avatarImage = ava
                                        }
                                    }
                                } catch {
                                    viewModel.isErrorPopupPresented = true
                                    viewModel.errorText = error.localizedDescription
                                }
                            }
                        }
                    }
                    
                    .fullScreenCover(isPresented: $viewModel.isCreateViewPresented, content: {
                        CreateView(
                            isCreateViewPresented: $viewModel.isCreateViewPresented,
                            id:  viewModel.id,
                            title: viewModel.title,
                            image: viewModel.image,
                            text: viewModel.text,
                            isEditing: viewModel.isEditing,
                            mediaURLs: viewModel.mediaURLs,
                            isLocalizing: viewModel.isLocalizing,
                            localizationCount: viewModel.localizationCount,
                            rootId: viewModel.id,
                            rootLang: viewModel.rootLang,
                            rootIsPremium: viewModel.rootIsPremiumPost,
                            isPremiumAuthor: viewModel.isPremiumAuthor,
                            media: $viewModel.mediaKind,
                            postsCount: $viewModel.postsCount,
                            posts: $viewModel.posts,
                            archivePosts: $viewModel.archivePosts
                        )
                    })
                    .navigationDestination(isPresented: $viewModel.isReadViewPresented) {
                        ReadView(
                            id: viewModel.id,
                            title: viewModel.title,
                            text: viewModel.text,
                            dateCreated: viewModel.dateCreated,
                            likesCount: viewModel.likesCount,
                            authorId: viewModel.user?.userId ?? "",
                            authorName: viewModel.user?.name ??  NSLocalizedString("notFoundLabel", comment: ""),
                            isCheckmark: viewModel.user?.isCheckmark ?? false,
                            isArchive: false,
                            mediaCount: viewModel.mediaCount,
                            mediaVersion: viewModel.mediaVersion,
                            mediaPosition: viewModel.mediaPosition,
                            lastVersionOfAvatar: viewModel.avatarVersion,
                            user: $viewModel.user,
                            isChannelViewPresented: .constant(false),
                            isPresented: $viewModel.isReadViewPresented
                        )
                        .environmentObject(sessionManager)
                        .environmentObject(changedPostsManager)
                        .environmentObject(subManager)
                    }
                    .navigationDestination(isPresented: $viewModel.isSettingViewPresented) {
                        SettingsView(
                            authorId: viewModel.user?.userId ?? "",
                            email: viewModel.user?.email ?? "",
                            lastVersionOfAvatar: $viewModel.avatarVersion,
                            avatar: $viewModel.avatarImage,
                            nameText: $viewModel.name,
                            descriptionText: $viewModel.description,
                            isScreenPresented: $viewModel.isSettingViewPresented,
                            isWelcomeViewPresented: $isWelcomeViewPresented
                        )
                    }
                    .fullScreenCover(isPresented: $viewModel.isZoomableImageViewPresented, content: {
                        ZoomableImageView(image: viewModel.avatarImage)
                    })
                    .fullScreenCover(isPresented: $viewModel.isPostCreateViewPresented, content: {
                        PostCreateView(
                            postId: viewModel.postId,
                            title: viewModel.title,
                            authorId: viewModel.user?.userId ?? "",
                            authorName: viewModel.user?.name ?? NSLocalizedString("notFoundLabel", comment: ""),
                            isCheckmark: viewModel.user?.isCheckmark ?? false,
                            isArchived: viewModel.isArchivePresented,
                            lastVersionOfAvatar: viewModel.avatarVersion,
                            isLocalizing: viewModel.isLocalizing,
                            localizationCount: viewModel.localizationCount,
                            rootId: viewModel.id,
                            rootLang: viewModel.rootLang,
                            rootIsPremium: viewModel.rootIsPremiumPost,
                            rootMediaPosition: viewModel.rootMediaPosition,
                            isPremiumAuthor: viewModel.isPremiumAuthor,
                            media: $viewModel.mediaKind,
                            posts: $viewModel.posts,
                            archivedPosts: $viewModel.archivePosts,
                            postsCount: $viewModel.postsCount
                        )
                    })
                
                if viewModel.user?.name != "" && !viewModel.isSettingViewPresented {
                    ScrollView(showsIndicators: false) {
                        
                        LazyVStack(spacing: 12) {
                            headerView
                            
                            if viewModel.isLoadingShowing {
//                                
//                                Text("HelloWorldHelloWorld HelloWorld HelloWorld HelloWorldHelloWorld HelloWorld HelloWorld")
//                                    .padding(.vertical, 20)
//                                    .padding(.horizontal, 16)
//                                    .frame(width: UIScreen.main.bounds.width, alignment: .leading)
//                                    .background(Color(uiColor: .secondarySystemBackground))
//                                    .clipShape(RoundedRectangle(cornerRadius: 20))
//                                    .padding(.top, 50)
//                                    .redacted(reason: .placeholder)
//                                    .shimmering()
                                
                                Text(NSLocalizedString("publicationsLabel", comment: ""))
                                    .font(.system(size: 26))
                                    .fontWeight(.light)
                                    .fontDesign(.rounded)
                                    .frame(width: UIScreen.main.bounds.width - 20, alignment: .leading)
                                    .redacted(reason: .placeholder)
                                    .padding(.top, -5)
                                
                                ForEach(0..<4) { num in
                                    PostView(
                                        id: "-1",
                                        title: "Hello, World!",
                                        likesCount: 10,
                                        viewsCount: 10,
                                        isArchive: false,
                                        mediaCount: 0,
                                        postOption: $viewModel.postOption,
                                        selectedId: $viewModel.id
                                    )
                                    .padding(.horizontal)
                                    .redacted(reason: .placeholder)
                                    .shimmering()
                                }
                                
                            } else if viewModel.posts.count > 0 ||  viewModel.archivePosts.count > 0 {

//                                if viewModel.user?.authorDescription ?? "" != "" {
//                                    Text(viewModel.user?.authorDescription ?? NSLocalizedString("notFoundLabel", comment: ""))
//                                        .font(.system(size: 20))
//                                        .padding(.vertical, 20)
//                                        .padding(.horizontal, 16)
//                                        .frame(width: UIScreen.main.bounds.width, alignment: .leading)
//                                        .background(Color(uiColor: .secondarySystemBackground))
//                                        .clipShape(RoundedRectangle(cornerRadius: 20))
//                                        .padding(.top, 50)
//                                }
                                
                                Text(viewModel.currentSectionTitle)
                                    .font(.system(size: 26))
                                    .fontWeight(.light)
                                    .fontDesign(.rounded)
                                    .frame(minWidth: UIScreen.main.bounds.width - 20, alignment: .leading)
                                    .padding(.bottom, 10)
                                
                                if !viewModel.currentPosts.isEmpty {
                                    ForEach(viewModel.currentPosts) { post in
//                                        PostView(
//                                            id: post.id,
//                                            title: post.title ?? NSLocalizedString("noFoundLabel", comment: ""),
//                                            likesCount: post.likesCount ?? 0,
//                                            viewsCount: post.viewsCount ?? 0,
//                                            isArchive: post.isArchive ?? false,
//                                            mediaCount: post.mediaCount ?? 0,
//                                            postOption: $viewModel.postOption,
//                                            selectedId: $viewModel.id
//                                        )
                                        
                                        ArticleView(
                                            id: post.id,
                                            title: post.title ?? NSLocalizedString("noFoundLabel", comment: ""),
                                            authorId: post.authorId ?? "",
                                            authorName: viewModel.user?.name ?? NSLocalizedString("noFoundLabel", comment: ""),
                                            isCheckmark: viewModel.user?.isCheckmark ?? false,
                                            isArchive: post.isArchive ?? false,
                                            isShortPost: post.isShortPost ?? false,
                                            mediaCount: post.mediaCount ?? 1,
                                            mediaVersion: post.mediaVersion ?? 1,
                                            mediaPosition: post.mediaPosition ?? 0,
                                            lastVersionOfAvatar: viewModel.user?.avatarVersion ?? 0,
                                            locCount: post.localizationCount ?? 0,
                                            isCreatedView: true,
                                            isLocalizedVersion: post.isLocalizedVersion ?? false,
                                            isPremiumPost: post.isPremiumPost ?? false,
                                            user: $viewModel.user,
                                            isZoomableViewPresented: .constant(false),
                                            zoomableImage: .constant(nil),
                                            selectedAuthorId: .constant(""),
                                            isChannelViewPresented: .constant(false),
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
                                            let lastPost = viewModel.currentPosts.last
                                            
                                            guard post.id == lastPost?.id else { return }
                                            
                                            Task {
                                                if viewModel.currentSection == .archive {
                                                    guard !viewModel.isAllArchivedLoaded else { return }
                                                    try? await viewModel.getArchivedPost()
                                                } else {
                                                    guard !viewModel.isAllLoaded else { return }
                                                    try? await viewModel.getPosts()
                                                }
                                            }
                                        }
                                    }
                                } else if viewModel.currentSection == .archive {
                                        VStack(spacing: 20) {
                                            Text(LocalizedStringKey("noArticlesAddedLabel"))
                                                .font(.system(size: 26))
                                                .bold()
                                                .fontDesign(.rounded)
                                                .foregroundStyle(Color.gray)
                                                .multilineTextAlignment(.center)
                                                .frame(width: UIScreen.main.bounds.width - 32)
                                            
                                            Text(NSLocalizedString("toPublicationsLabel", comment: ""))
                                                .frame(width: UIScreen.main.bounds.width - 10, height: 50, alignment: .center)
                                                .font(.system(size: 22))
                                                .fontDesign(.rounded)
                                                .background(Color(uiColor: .secondarySystemBackground))
                                                .foregroundStyle(Color(uiColor: .label))
                                                .clipShape(RoundedRectangle(cornerRadius: 15))
                                                .shadow(radius: 1)
                                                .padding(.bottom, 10)
                                                .onTapGesture {
                                                    withAnimation {
                                                        viewModel.showAllPosts()
                                                        VibrationsService.shared.softImpact()
                                                    }
                                                }
                                                .frame(width: UIScreen.main.bounds.width - 32)
                                        }
                                } else if viewModel.currentSection == .localizedPublished
                                            || viewModel.currentSection == .localizedArchive {
                                    VStack(spacing: 20) {
                                        Text(LocalizedStringKey("noArticlesAddedLabel"))
                                            .font(.system(size: 26))
                                            .bold()
                                            .fontDesign(.rounded)
                                            .foregroundStyle(Color.gray)
                                            .multilineTextAlignment(.center)
                                            .frame(width: UIScreen.main.bounds.width - 32)
                                        
                                        Text(NSLocalizedString("toPublicationsLabel", comment: ""))
                                            .frame(width: UIScreen.main.bounds.width - 10, height: 50, alignment: .center)
                                            .font(.system(size: 22))
                                            .fontDesign(.rounded)
                                            .background(Color(uiColor: .secondarySystemBackground))
                                            .foregroundStyle(Color(uiColor: .label))
                                            .clipShape(RoundedRectangle(cornerRadius: 15))
                                            .shadow(radius: 1)
                                            .padding(.bottom, 10)
                                            .onTapGesture {
                                                withAnimation {
                                                    viewModel.showAllPosts()
                                                    VibrationsService.shared.softImpact()
                                                }
                                            }
                                            .frame(width: UIScreen.main.bounds.width - 32)
                                    }
                                } else {
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
                                
                            } else {
                                
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
                            
//                            if !viewModel.isLoading
//                                && ((viewModel.isArchivePresented && !viewModel.isAllArchivedLoaded && viewModel.archivePosts.count >= 20)
//                                    || (!viewModel.isArchivePresented && !viewModel.isAllLoaded && viewModel.posts.count >= 20)) {
//                                Button {
//                                    Task {
//                                        do {
//                                            if viewModel.isArchivePresented {
//                                                try await viewModel.getPosts()
//                                            } else {
//                                                try await viewModel.getArchivedPost()
//                                            }
//                                            return
//                                        } catch {
//                                            withAnimation {
//                                                viewModel.errorText = error.localizedDescription
//                                            }
//                                        }
//                                        
//                                        viewModel.isErrorPopupPresented = true
//                                    }
//                                } label: {
//                                    HStack {
//                                        Image(systemName: "arrow.down")
//                                            .foregroundStyle(Color(uiColor: .label))
//                                            .font(.title3)
//                                            .fontWeight(.light)
//                                        
//                                        Text(LocalizedStringKey("loadMore"))
//                                            .font(.title3)
//                                            .fontDesign(.rounded)
//                                            .fontWeight(.light)
//                                    }
//                                    .padding(.horizontal, 16)
//                                    .padding(.vertical, 10)
//                                    .background(Color(uiColor: .secondarySystemBackground))
//                                    .clipShape(RoundedRectangle(cornerRadius: 10))
//                                    .shadow(radius: 2)
//                                    .padding(.bottom, 20)
//                                }
//                                .padding(.bottom, 10)
//                                .offset(y: -30)
//                                
//                            }
                            
                        }
                    }
                    .frame(width: UIScreen.main.bounds.width)
                    .refreshable {
                        viewModel.reload()
                    }
                    .task {
                        try? Tips.configure()
                    }
                    .onPreferenceChange(VisibilityPreferenceKey.self) { values in
                        if let minY = values["publicationsLabel"] {
                            let isVisible = minY > -10
                            print("TRECCECEC: \(minY)")

                            if viewModel.isPublicationsLabelVisible != isVisible {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.isPublicationsLabelVisible = isVisible
                                }
                            }
                        }
                    }
                    
                    if !viewModel.isLoading
                        && !hudService.isLoading
                        && viewModel.isNewPublicationButtonPresented
                        && viewModel.user?.name != ""
                        && !hudService.isSuccessPopupPresented
                        && !hudService.isErrorPopupPresented
                    {
                        VStack {
                            Spacer()
                            
//                            if #available(iOS 26.0, *) {
//                                Button {
//                                    isConfirmationPopupPresented = true
//                                } label: {
//                                    Text(NSLocalizedString("newPublicationLabel", comment: ""))
//                                        .font(.system(size: 19))
//                                        .fontDesign(.rounded)
//                                        .foregroundStyle(Color(.systemBackground))
//                                        .popoverTip(AuthorMultiLanguageTip())
//                                        .frame(maxWidth: .infinity, alignment: .center)
//                                        .frame(height: 35)
//                                }
//                                .tint(Color(.label))
//                                .buttonStyle(.glassProminent)
//                                .padding(.bottom, 10)
//                                .padding(.horizontal, 22.5)
//                            } else {
//                                Text(NSLocalizedString("newPublicationLabel", comment: ""))
//                                    .frame(width: UIScreen.main.bounds.width - 10, height: 50, alignment: .center)
//                                    .font(.system(size: 19))
//                                    .fontDesign(.rounded)
//                                    .background(Color(uiColor: .label))
//                                    .foregroundStyle(Color(uiColor: .systemBackground))
//                                    .clipShape(RoundedRectangle(cornerRadius: 15))
//                                    .shadow(radius: 3)
//                                    .padding(.bottom, 10)
//                                    .popoverTip(AuthorMultiLanguageTip())
//                                    .onTapGesture {
//                                        isConfirmationPopupPresented = true
//                                    }
//                            }
                            
                            Text(NSLocalizedString("newPublicationLabel", comment: ""))
                                .frame(
                                    width: UIScreen.main.bounds.width - 45,
                                    height: 40,
                                    alignment: .center
                                )
                                .font(.system(size: 19))
                                .fontDesign(.rounded)
                                .background(Color(.label))
                                .foregroundStyle(Color(.systemBackground))
                                .clipShape(Capsule())
                                .padding(.bottom, 10)
                                .onTapGesture {
                                    isConfirmationPopupPresented = true
                                }
                        }
                    }
                }
                
            }
            .trackChangesOnCreatedPostsView(
                viewModel: viewModel,
                isWelcomeViewPresented: isWelcomeViewPresented,
                hudService: hudService,
                isConfirmationPopupPresented: $isConfirmationPopupPresented
            )
            .makePopupsForCreatedPostsView(
                viewModel: viewModel,
                isErrorPopupPresented: $viewModel.isErrorPopupPresented,
                isDescriptionPopupPresented: $viewModel.isDescriptionPopupPresented,
                isSuccessPopupPresented: $viewModel.isSuccessPopupPresented,
                isLoadingPopupPresented: $viewModel.isLoadingPopupPresented,
                isReadViewPresented: $viewModel.isReadViewPresented,
                isConfirmationPopupPresented: $isConfirmationPopupPresented,
                addingMode: $viewModel.addingMode,
                errorText: $viewModel.errorText
            )
            .toolbar {
                ToolbarItem(placement: .principal) {
                    toolbarTitleView
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    if !viewModel.isLoading {
                        HStack {
                            Button {
                                withAnimation {
                                    viewModel.isSettingViewPresented.toggle()
                                }
                            } label: {
                                Image(systemName: "gearshape.fill")
                                    .foregroundStyle(Color.gray)
                                    .bold()
                            }
                            
                            if viewModel.hasLocalizedPosts {
                                Menu {
                                    Button {
                                        withAnimation {
                                            viewModel.showAllPosts()
                                        }
                                    } label: {
                                        toolbarMenuLabel(
                                            title: NSLocalizedString("publicationsLabel", comment: ""),
                                            systemImage: "doc.text",
                                            isSelected: viewModel.currentSection == .all
                                        )
                                    }
                                    
                                    if viewModel.hasRegularArchivePosts {
                                        Button {
                                            withAnimation {
                                                viewModel.showArchivePosts()
                                            }
                                        } label: {
                                            toolbarMenuLabel(
                                                title: NSLocalizedString("archiveLabel", comment: ""),
                                                systemImage: "archivebox",
                                                isSelected: viewModel.currentSection == .archive
                                            )
                                        }
                                    }
                                    
                                    Menu {
                                        if !viewModel.localizedPosts.isEmpty {
                                            Button {
                                                withAnimation {
                                                    viewModel.showLocalizedPosts()
                                                }
                                            } label: {
                                                toolbarMenuLabel(
                                                    title: NSLocalizedString("publicationsLabel", comment: ""),
                                                    systemImage: "doc.text",
                                                    isSelected: viewModel.currentSection == .localizedPublished
                                                )
                                            }
                                        }
                                        
                                        if !viewModel.localizedArchivePosts.isEmpty {
                                            Button {
                                                withAnimation {
                                                    viewModel.showLocalizedArchivePosts()
                                                }
                                            } label: {
                                                toolbarMenuLabel(
                                                    title: NSLocalizedString("archiveLabel", comment: ""),
                                                    systemImage: "archivebox",
                                                    isSelected: viewModel.currentSection == .localizedArchive
                                                )
                                            }
                                        }
                                    } label: {
                                        toolbarMenuLabel(
                                            title: NSLocalizedString("localizedPostsLabel", comment: ""),
                                            systemImage: "globe",
                                            isSelected: viewModel.currentSection == .localizedPublished
                                                || viewModel.currentSection == .localizedArchive
                                        )
                                    }
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                        .foregroundStyle(Color.gray)
                                        .bold()
                                }
                            } else if viewModel.hasRegularArchivePosts {
                                Button {
                                    withAnimation {
                                        viewModel.isLocalizedPostsPresented = false
                                        viewModel.isArchivePresented.toggle()
                                    }
                                } label: {
                                    if viewModel.isArchivePresented {
                                        Image(systemName: "rectangle.on.rectangle")
                                            .foregroundStyle(Color.gray)
                                            .bold()
                                    } else {
                                        Image(systemName: "archivebox")
                                            .foregroundStyle(Color.gray)
                                            .bold()
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .environmentObject(subManager)
        }
    }
}

private extension CreatedPostsView {
    @ViewBuilder
    var toolbarTitleView: some View {
        if !viewModel.isPublicationsLabelVisible {
            if #available(iOS 26, *) {
                Text(viewModel.currentSectionTitle)
                .padding()
                .glassEffect(.regular)
            } else {
                Text(viewModel.currentSectionTitle)
            }
        }
    }
    
    @ViewBuilder
    func toolbarMenuLabel(title: String, systemImage: String, isSelected: Bool) -> some View {
        HStack {
            Image(systemName: systemImage)
            Text(title)
            
            if isSelected {
                Image(systemName: "checkmark")
            }
        }
    }
    
    var headerView: some View {
        VStack(spacing: -3) {
            VStack {
                HStack {
                    if let avatar = viewModel.avatarImage {
                        Image(uiImage: avatar)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 70, height: 70)
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
                    
                    VStack {
                        HStack(spacing: 0) {
                            if viewModel.isLoading {
                                Text("HelloWorldHello")
                                    .font(.system(size: 24))
                                    .fontWeight(.light)
                                    .lineLimit(1)
                                    .redacted(reason: .placeholder)
                                    .shimmering()
                                
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundStyle(Color.blue)
                                    .font(.system(size: 14))
                                    .padding(.top, 1)
                                    .redacted(reason: .placeholder)
                                    .shimmering()
                            } else {
                                Text(viewModel.name)
                                    .font(.system(size: 24))
                                    .fontWeight(.light)
                                    .lineLimit(1)
                                
                                if viewModel.isCheckmark {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundStyle(Color.blue)
                                        .font(.system(size: 14))
                                        .padding(.top, 1)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        if viewModel.isLoading {
                            HStack {
                                Text("100000 \(viewModel.subscribersCountLabel)")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.gray)
                                    .redacted(reason: .placeholder)
                                    .shimmering()
                                
                                Text("•")
                                    .font(.system(size: 20))
                                    .foregroundStyle(Color.gray)
                                
                                Text("100000 \(viewModel.postsCountLabel)")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.gray)
                                    .redacted(reason: .placeholder)
                                    .shimmering()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            HStack(spacing: 2) {
                                Text("\(viewModel.subscribersCount) \(viewModel.subscribersCountLabel)")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.gray)
                                
                                Text("•")
                                    .font(.system(size: 20))
                                    .foregroundStyle(Color.gray)
                                
                                Text("\(viewModel.postsCount) \(viewModel.postsCountLabel)")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.gray)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .frame(maxHeight: 60)
                    
                    if viewModel.isLoading {
                        LoadingIndicator(animation: .circleRunner, color: Color(uiColor: .label), size: .small, speed: .fast)
                    }
                }
                .frame(width: UIScreen.main.bounds.width - 20, alignment: .leading)
                
            }
            
            if !viewModel.isLoading && viewModel.description != "" {
                Text(viewModel.description)
                    .font(.system(size: 18))
                    .fontDesign(.rounded)
                    .frame(width: UIScreen.main.bounds.width - 20, alignment: .leading)
                    .padding(.top, 15)
            }
            
            VisibilityTracker(id: "publicationsLabel")
            
            Capsule()
                .foregroundStyle(.gray)
                .frame(width: UIScreen.main.bounds.width - 20, height: 1)
                .padding(.top, 20)
        }
        .padding(.vertical, 15)
    }
}
