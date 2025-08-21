//
//  RuLikedPostsView.swift
//  Readify
//
//  Created by Тимофей Юдин on 15.11.2024.
//

import SwiftUI
import SwiftfulLoadingIndicators
import Shimmer

struct LikedPostsView: View {
    @Binding var isWelcomeViewPresented: Bool
    
    @StateObject var viewModel = LikedPostsViewModel()
    
    var body: some View {
        
        NavigationStack {
            ZStack {
                
                ScrollView(showsIndicators: false) {
                    
                    LazyVStack {
                        
                        if viewModel.isLoadingShowed {
                            
                            ForEach(0..<5) { _ in
                                ArticleView(
                                    id: "-1",
                                    title: "Hello, World!",
                                    authorId: "",
                                    authorName: "ReadBox Author",
                                    isCheckmark: true,
                                    isArchive: false,
                                    isShortPost: false,
                                    user: .constant(nil),
                                    isZoomableViewPresented: .constant(false),
                                    zoomableImage: .constant(nil)
                                )
                                .redacted(reason: .placeholder)
                                .padding(.top, 20)
                                .padding(.horizontal)
                                .shimmering()
                            }
                            
                        } else if viewModel.articles == [] && !viewModel.isLoading {
                            
                            VStack(spacing: 20) {
                                
                                Image(systemName: "list.bullet.below.rectangle")
                                    .resizable()
                                    .frame(width: 100, height: 100)
                                    .foregroundStyle(Color.gray)
                                
                                Text(LocalizedStringKey("noArticlesAddedLabel"))
                                    .font(.title)
                                    .bold()
                                    .fontDesign(.rounded)
                                    .foregroundStyle(Color.gray)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .padding(.horizontal, 32)
                            }
                            .frame(height: UIScreen.main.bounds.height - 200, alignment: .center)
                            
                        } else {
                            ForEach(viewModel.articles) { article in
                                ArticleView(
                                    id: article.id,
                                    title: article.title ?? "",
                                    authorId: article.authorId ?? "",
                                    authorName: viewModel.authorsNames[article.authorId ?? ""] ?? "",
                                    isCheckmark: viewModel.authorsCheckmarks[article.authorId ?? ""] ?? false,
                                    isArchive: article.isArchive ?? false,
                                    isShortPost: article.isShortPost ?? false,
                                    user: $viewModel.user,
                                    isZoomableViewPresented: $viewModel.isZoomableViewPresented,
                                    zoomableImage: $viewModel.zoomableImage
                                )
                                .padding(.top, 20)
                                .padding(.horizontal)
                                .onAppear {
                                    viewModel.onPostAppearing(article)
                                }
                                .onTapGesture {
                                    viewModel.tapGestureHandler(on: article)
                                }
                            }
                            
                            if viewModel.indexesNeedToLoad.count > 0 && !viewModel.isLoading {
                                Button {
                                    Task {
                                        do {
                                            try await viewModel.getArticles()
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
                                    .padding(.top, 20)
                                }
                                .padding(.bottom, 10)
                                
                            }
                        }
                        
                    }
                    
                }
                .padding(.top, 60)
                .refreshable {
                    viewModel.reload()
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
                        user: $viewModel.user,
                        isChannelViewPresented: $viewModel.isChannelViewPresented
                    )
                })
                .fullScreenCover(isPresented: $viewModel.isChannelViewPresented, content: {
                    ChannelView(
                        user: $viewModel.user,
                        authorId: viewModel.authorId,
                        authorName: viewModel.authorsNames[viewModel.authorId] ?? NSLocalizedString("notFoundLabel", comment: ""),
                        isCheckmark: viewModel.authorsCheckmarks[viewModel.authorId] ?? false
                    )
                })
                .fullScreenCover(isPresented: $viewModel.isZoomableViewPresented, content: {
                    if let image = viewModel.zoomableImage {
                        ZoomableImageView(image: image)
                    }
                })
                .makePopupsForLikedView(
                    viewModel: viewModel,
                    isErrorPopupPresented: $viewModel.isErrorPopupPresented,
                    isLoadingPopupPresented: $viewModel.isLoadingPopupPresented,
                    isDescriptionPopupPresented: $viewModel.isDescriptionPopupPresented,
                    isReadViewPresented: $viewModel.isReadViewPresented,
                    errorText: $viewModel.errorText
                )
                .trackChangesOnLikedPosts(
                    viewModel: viewModel,
                    isWelcomeViewPresented: isWelcomeViewPresented
                )
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
                            try? await viewModel.loadUser()
                        }
                    }
                }
                
                VStack {
                    headerView
                    
                    Spacer()
                }.ignoresSafeArea()
            }
        }
        
    }
}

private extension LikedPostsView {
    var headerView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15)
                .frame(width: UIScreen.main.bounds.width, height: 120)
                .foregroundStyle(Color(uiColor: .secondarySystemBackground))
                .shadow(radius: 10)
            
            HStack {
                Text(LocalizedStringKey("favoritesLabel"))
                    .font(.system(size: 32))
                    .fontWeight(.light)
                
                if viewModel.isLoading {
                    LoadingIndicator(
                        animation: .circleRunner,
                        color: Color(uiColor: .label),
                        size: .small,
                        speed: .fast
                    )
                }
            }
            .frame(width: UIScreen.main.bounds.width - 32, alignment: .leading)
            .padding(.top, 30)
        }
    }
}
