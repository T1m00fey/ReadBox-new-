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

struct FeedView: View {
    @Binding var isWelcomeViewPresented: Bool
    
    @StateObject var viewModel = FeedViewModel()
    
    var body: some View {
        NavigationView {
            
            ZStack {
                
                Color(uiColor: .systemBackground)
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    
                    LazyVStack {
                        
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
                                    user: .constant(nil),
                                    isZoomableViewPresented: .constant(false),
                                    zoomableImage: .constant(nil)
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
                                    user: $viewModel.user,
                                    isZoomableViewPresented: $viewModel.isZoomableImageViewPresented,
                                    zoomableImage: $viewModel.zoomableImage
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
                .disabled(viewModel.isBlur ? true : false)
                .blur(radius: viewModel.isBlur ? 5 : 0)
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
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .frame(width: UIScreen.main.bounds.width, height: 130)
                                .foregroundStyle(Color(uiColor: .secondarySystemBackground))
                                .padding(.bottom, 40)
                                .shadow(radius: 10)
                            
                            HStack {
                                HStack(spacing: 1) {
                                    Text("ReadBox")
                                        .font(.largeTitle)
                                        .fontWeight(.light)
                                        .popoverTip(LanguageSwitchTip())
                                    
                                    Text(StorageManager.shared.getLanguage() == "ru" ? "RU" : "EN")
                                        .foregroundStyle(Color.gray)
                                        .font(.system(size: 14))
                                        .fontDesign(.rounded)
                                        .offset(y: -7)
                                }
                                .onTapGesture {
                                    let currentLanguage = StorageManager.shared.getLanguage()
                                    
                                    withAnimation {
                                        if !viewModel.isLoading {
                                            viewModel.refresh()
                                            
                                            StorageManager.shared.setLanguage(
                                                to: currentLanguage == "en"
                                                    ? "ru"
                                                    : "en"
                                            )
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
                            
                        }
                        .padding(.leading, 6)
                    }
                }
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
                    
                    Task {
                        try? await viewModel.loadUser()
                    }
                    
                    viewModel.getViews()
                    
                    viewModel.getRelevantVersion()
                }
                .fullScreenCover(isPresented: $viewModel.isReadViewPresented, content: {
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
                        user: $viewModel.user,
                        isChannelViewPresented: $viewModel.isChannelViewPresented
                    )
                })
                .fullScreenCover(isPresented: $viewModel.isChannelViewPresented, content: {
                    ChannelView(
                        user: $viewModel.user,
                        authorId: viewModel.authorId,
                        authorName: viewModel.authorsNames[viewModel.authorId] ?? NSLocalizedString("notFoundLabel", comment: ""),
                        isCheckmark: viewModel.authorsCheckmarks[viewModel.authorId] ?? false,
                        postToView: $viewModel.postToView,
                        postToRead: $viewModel.postToRead
                    )
                })
                .fullScreenCover(isPresented: $viewModel.isZoomableImageViewPresented, content: {
                    if let image = viewModel.zoomableImage {
                        ZoomableImageView(image: image)
                    }
                })
                .refreshable {
                    if !viewModel.isReadViewPresented {
                        viewModel.refresh()
                    } else {
                        viewModel.isReadViewPresented = false
                    }
                }
                
            }
            .popup(isPresented: $viewModel.isVersionPopupViewPresented) {
                VersionPopupView(isCritical: viewModel.relevantVersion?.isCritical ?? false)
                    .shadow(radius: 3)
            } customize: {
                $0
                    .type(.toast)
                    .appearFrom(.bottomSlide)
                    .dragToDismiss(!(viewModel.relevantVersion?.isCritical ?? true))
            }
            
        }
        .navigationBarBackButtonHidden()
    }
}






