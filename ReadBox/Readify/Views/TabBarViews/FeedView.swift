//
//  FeedView.swift
//  Readify
//
//  Created by Тимофей Юдин on 28.10.2024.
//

import SwiftUI
import FirebaseStorage
import SwiftfulLoadingIndicators
import Shimmer
import TipKit
import PopupView

struct FeedView: View {
    @Binding var isWelcomeViewPresented: Bool
    @Binding var selectedTab: TabType
    @Binding var isConfirmationViewPresented: Bool
    @Binding var isPremiumViewPresented: Bool
    
    @StateObject var viewModel = FeedViewModel()
    
    @EnvironmentObject var subManager: SubscriptionManager
    @EnvironmentObject var sessionManager: SessionManager
    @EnvironmentObject var changedPostsManager: ChangedPostsManager
    
    var body: some View {
        NavigationStack {
            
            ZStack {
                
                ScrollView(showsIndicators: false) {
                    
                    LazyVStack {
                        
                        Text("")
                        VisibilityTracker(id: "headerTracker")
                        
                        TabView {
                            
                            if viewModel.isLoadingShowing {
                                ForEach(0..<1) { num in
                                    TopArticleView(
                                        id: String(num),
                                        title: "",
                                        isArchive: false,
                                        isPremiumPost: false,
                                        isAccessToPremiumDenied: false
                                    )
                                    .redacted(reason: .placeholder)
                                }
                            } else {
                                ForEach(viewModel.topArticles) { post in
                                    if post.id != "" {
                                        TopArticleView(
                                            id: post.id,
                                            title: post.title,
                                            isArchive: post.isArchive,
                                            isPremiumPost: post.isPremiumPost ?? false,
                                            isAccessToPremiumDenied: (post.isPremiumPost ?? false) && !subManager.hasPremium && post.authorId != viewModel.user?.userId
                                        )
                                            .tabItem {}
                                            .onAppear {
                                                viewModel.onPostAppearing(post: post)
                                            }
                                            .onTapGesture {
                                                if let isPremiumPost = post.isPremiumPost,
                                                   isPremiumPost && !subManager.hasPremium,
                                                   post.authorId != viewModel.user?.userId {
                                                    isPremiumViewPresented = true
                                                } else {
                                                    viewModel.tapGestureHandler(on: post)
                                                }
                                            }
                                    }
                                }
                                
                            }
                        }
                        .tabViewStyle(.page)
                        .frame(height: 270)
                        .padding(.top, 30)
                        
                        if viewModel.isLoadingShowing {
                            ForEach(0..<2) { num in
                                ArticleView(
                                    id: String(num),
                                    title: "Hello, World! Hello, World! Hello, World!",
                                    authorId: "",
                                    authorName: "Hello, World!",
                                    isCheckmark: true,
                                    isArchive: false,
                                    isShortPost: false,
                                    mediaCount: 0,
                                    mediaVersion: 2,
                                    mediaPosition: 0,
                                    lastVersionOfAvatar: 0,
                                    locCount: 0,
                                    isLocalizedVersion: false,
                                    isPremiumPost: false,
                                    user: .constant(nil),
                                    isZoomableViewPresented: .constant(false),
                                    zoomableImage: .constant(nil),
                                    selectedAuthorId: $viewModel.authorId,
                                    isChannelViewPresented: .constant(false)
                                )
                                .redacted(reason: .placeholder)
                                .padding(.top, 10)
                                .shimmering()
                            }
                        } else {
                            ForEach(viewModel.articles) { post in
                                ArticleView(
                                    id: post.id,
                                    title: post.title ?? "",
                                    authorId: post.authorId ?? "",
                                    authorName: viewModel.authorsInfo[post.authorId ?? ""]?.name ?? "",
                                    dateCreated: post.dateCreated,
                                    isCheckmark: viewModel.authorsInfo[post.authorId ?? ""]?.isCheckmark ?? false,
                                    isArchive: post.isArchive ?? true,
                                    isShortPost: post.isShortPost ?? false,
                                    mediaCount: post.mediaCount ?? 1,
                                    mediaVersion: post.mediaVersion ?? 1,
                                    mediaPosition: post.mediaPosition ?? 0,
                                    lastVersionOfAvatar: viewModel.authorsInfo[post.authorId ?? ""]?.avatarVersion ?? 0,
                                    locCount: post.localizationCount ?? 0,
                                    isLocalizedVersion: post.isLocalizedVersion ?? false,
                                    isPremiumPost: post.isPremiumPost ?? false,
                                    user: $viewModel.user,
                                    isZoomableViewPresented: $viewModel.isZoomableImageViewPresented,
                                    zoomableImage: $viewModel.zoomableImage,
                                    selectedAuthorId: $viewModel.authorId,
                                    isChannelViewPresented: $viewModel.isChannelViewPresented
                                )
                                .onAppear {
                                    print("👀 VIEW \(post.id)")
                                    viewModel.onPostAppearing(post: post)
                                }
                                .onTapGesture {
                                    if let isPremiumPost = post.isPremiumPost, (isPremiumPost && !subManager.hasPremium), (post.authorId != viewModel.user?.userId) {
                                        isPremiumViewPresented = true
                                    } else {
                                        viewModel.tapGestureHandler(on: post)
                                    }
                                }
                                .padding(.top, 10)
                                
                            }
                        }
                        
                    }
                }
                .refreshable {
                    if !viewModel.isReadViewPresented {
                        viewModel.refresh()
                    } else {
                        viewModel.isReadViewPresented = false
                    }
                }
                
                VStack {
                    headerView
                    
                    Spacer()
                }.ignoresSafeArea()
                
            }
            .makePopupsForFeedView(
                viewModel: viewModel,
                isLoadingPopupPresented: $viewModel.isLoadingPopupPresented,
                isErrorPopupPresented: $viewModel.isErrorPopupPresented,
                isDescriptionPopupPresented: $viewModel.isDescriptionPopupPresented,
                isReadViewPresented: $viewModel.isReadViewPresented,
                errorText: $viewModel.errorText
            )
            .trackChangesOnFeedView(
                viewModel: viewModel,
                isWelcomeViewPresented: isWelcomeViewPresented
            )
            .task {
                try? Tips.configure()
            }
            .onPreferenceChange(VisibilityPreferenceKey.self) { values in
                if let minY = values["headerTracker"] {
                    let isVisible = minY > 60
                    print("TRECCECEC: \(minY)")

                    if viewModel.isLargeHeaderVisible != isVisible {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.isLargeHeaderVisible = isVisible
                        }
                    }
                }
            }
            .onAppear {
                if viewModel.isLoading {
                    viewModel.isLoading = false
                    
                    Task {
                        viewModel.isLoading = true
                    }
                }
                
                viewModel.primaryLanguage = StorageManager.shared.getLanguage() ?? "en"
                
                if viewModel.user == nil {
                    Task {
                        try? await viewModel.loadUser()
                    }
                }
                
                viewModel.getViews()
            }
            .navigationDestination(isPresented: $viewModel.isReadViewPresented, destination: {
                ReadView(
                    id: viewModel.id,
                    title: viewModel.title,
                    text: viewModel.text,
                    dateCreated: viewModel.dateCreated,
                    likesCount: viewModel.likesCount,
                    authorId: viewModel.authorId,
                    authorName: viewModel.authorsInfo[viewModel.authorId]?.name ?? "",
                    isCheckmark: viewModel.authorsInfo[viewModel.authorId]?.isCheckmark ?? false,
                    isArchive: viewModel.isArchive,
                    mediaCount: viewModel.mediaCount,
                    mediaVersion: viewModel.mediaVersion,
                    mediaPosition: viewModel.mediaPosition,
                    lastVersionOfAvatar: viewModel.authorsInfo[viewModel.authorId]?.avatarVersion ?? 0,
                    articleLanguage: viewModel.articleLanguage,
                    isPremiumPost: viewModel.isPremiumPost,
                    user: $viewModel.user,
                    isChannelViewPresented: $viewModel.isChannelViewPresented,
                    isPresented: $viewModel.isReadViewPresented,
                    isLocalizedVersion: viewModel.isLocalizedVersion,
                    rootId: viewModel.rootId
                )
                .environmentObject(sessionManager)
                .environmentObject(changedPostsManager)
                .environmentObject(subManager)
            })
            .navigationDestination(isPresented: $viewModel.isChannelViewPresented, destination: {
                ChannelView(
                    user: $viewModel.user,
                    authorId: viewModel.authorId as String,
                    authorName: viewModel.authorsInfo[viewModel.authorId]?.name ?? NSLocalizedString("notFoundLabel", comment: ""),
                    isCheckmark: viewModel.authorsInfo[viewModel.authorId]?.isCheckmark ?? false,
                    lastVersionOfAvatar: viewModel.authorsInfo[viewModel.authorId]?.avatarVersion ?? 0,
                    isPremiumViewPresented: $isPremiumViewPresented
                )
                .environmentObject(sessionManager)
                .environmentObject(changedPostsManager)
                .environmentObject(subManager)
            })
            .fullScreenCover(isPresented: $viewModel.isZoomableImageViewPresented, content: {
                if let image = viewModel.zoomableImage {
                    ZoomableImageView(image: image)
                }
            })
            
        }
    }
}

private extension FeedView {
    var headerView: some View {
        VStack(spacing: 0) {
            ZStack {
                if viewModel.isLargeHeaderVisible {
                    RoundedRectangle(cornerRadius: 15)
                        .frame(width: UIScreen.main.bounds.width, height: 120)
                        .foregroundStyle(Color.clear)
                } else {
                    RoundedRectangle(cornerRadius: 15)
                        .frame(width: UIScreen.main.bounds.width, height: 120)
                        .foregroundStyle(.thinMaterial)
                }
                
                HStack {
                    HStack(spacing: 1) {
                        Text("ReadBox")
                            .font(.system(size: 32))
                            .fontWeight(.light)
                            .popoverTip(LanguageSwitchTip())
                        
                        Text(viewModel.primaryLanguage.uppercased())
                            .foregroundStyle(Color.gray)
                            .font(.system(size: 14))
                            .fontDesign(.rounded)
                            .offset(y: -7)
                    }
                    .onTapGesture {
                        withAnimation {
                            if !viewModel.isLoading {
                                StorageManager.shared.setLanguage(
                                    to: viewModel.primaryLanguage == "en"
                                    ? "ru"
                                    : "en"
                                )
                                
                                viewModel.refresh()
                            }
                        }
                    }
                    
                    if viewModel.isLoading {
                        LoadingIndicator(
                            animation: .circleRunner,
                            color: Color(uiColor: .label),
                            size: .small, speed: .fast
                        )
                    }
                    
                    Spacer()
                    
                    Image(systemName: "plus")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20)
                        .onTapGesture {
                            VibrationsService.shared.lightImpact()
                            
                            selectedTab = .create
                            isConfirmationViewPresented = true
                        }
                }
                .frame(width: UIScreen.main.bounds.width - 32, alignment: .leading)
                .padding(.top, 30)
                
            }
        }
    }
}
