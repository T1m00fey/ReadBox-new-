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
    
    @StateObject var viewModel = FeedViewModel()
    
    var body: some View {
        NavigationStack {
            
            ZStack {
                
                ScrollView(showsIndicators: false) {
                    
                    LazyVStack {
                        
                        Color.clear.frame(height: 60)
                        
                        TabView {
                            
                            if viewModel.isLoadingShowing {
                                ForEach(0..<1) { num in
                                    TopArticleView(
                                        id: String(num),
                                        title: "",
                                        isArchive: false
                                    )
                                    .redacted(reason: .placeholder)
                                }
                            } else {
                                ForEach(viewModel.topArticles) { post in
                                    if post.id != "" {
                                        TopArticleView(id: post.id, title: post.title, isArchive: post.isArchive)
                                            .tabItem {}
                                            .onAppear {
                                                viewModel.onPostAppearing(post: post)
                                            }
                                            .onTapGesture {
                                                viewModel.tapGestureHandler(on: post)
                                            }
                                    }
                                }
                                
                            }
                        }
                        .tabViewStyle(.page)
                        .frame(height: 270)
                        
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
                                    user: .constant(nil),
                                    isZoomableViewPresented: .constant(false),
                                    zoomableImage: .constant(nil),
                                    selectedAuthorId: $viewModel.authorId,
                                    isChannelViewPresented: .constant(false)
                                )
                                .redacted(reason: .placeholder)
                                .padding(.top, 20)
                                .shimmering()
                            }
                        } else {
                            ForEach(viewModel.articles) { post in
                                ArticleView(
                                    id: post.id,
                                    title: post.title ?? "",
                                    authorId: post.authorId ?? "",
                                    authorName: viewModel.authorsNames[post.authorId ?? ""] ?? "",
                                    isCheckmark: viewModel.authorsCheckmarks[post.authorId ?? ""] ?? false,
                                    isArchive: post.isArchive ?? true,
                                    isShortPost: post.isShortPost ?? false,
                                    mediaCount: post.mediaCount ?? 1,
                                    mediaVersion: post.mediaVersion ?? 1,
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
                                    viewModel.tapGestureHandler(on: post)
                                }
                                .padding(.top, 20)
                                
                            }
                        }
                        
//                        if let _ = viewModel.lastDocument {
//                            if viewModel.articles != [] && !viewModel.isLoading {
//                                Button {
//                                    Task {
//                                        do {
//                                            try await viewModel.getArticles()
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
//                                    .padding(.top, 20)
//                                }
//                                .padding(.bottom, 10)
//                                
//                            }
//                        }
                        
                    }
                }
//                .disabled(viewModel.isBlur ? true : false)
//                .blur(radius: viewModel.isBlur ? 5 : 0)
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
                    authorName: viewModel.authorsNames[viewModel.authorId] ?? "",
                    isCheckmark: viewModel.authorsCheckmarks[viewModel.authorId] ?? false,
                    isArchive: viewModel.isArchive,
                    mediaCount: viewModel.mediaCount,
                    mediaVersion: viewModel.mediaVersion,
                    user: $viewModel.user,
                    isChannelViewPresented: $viewModel.isChannelViewPresented
                )
            })
            .fullScreenCover(isPresented: $viewModel.isChannelViewPresented, content: {
                ChannelView(
                    user: $viewModel.user,
                    authorId: viewModel.authorId as String,
                    authorName: viewModel.authorsNames[viewModel.authorId] ?? NSLocalizedString("notFoundLabel", comment: ""),
                    isCheckmark: viewModel.authorsCheckmarks[viewModel.authorId] ?? false
                )
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
        ZStack {
            RoundedRectangle(cornerRadius: 15)
                .frame(width: UIScreen.main.bounds.width, height: 120)
//                .foregroundStyle(Color(uiColor: .secondarySystemBackground))
                .foregroundStyle(.thinMaterial)
                .shadow(radius: 3)
        
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
            }
            .frame(width: UIScreen.main.bounds.width - 32, alignment: .leading)
            .padding(.top, 30)
            
        }
    }
}




