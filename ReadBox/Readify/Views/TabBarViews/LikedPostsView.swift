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
    @Binding var isPremiumViewPresented: Bool

    @StateObject var viewModel = LikedPostsViewModel()

    @EnvironmentObject var sessionManager: SessionManager
    @EnvironmentObject var changedPostsManager: ChangedPostsManager
    @EnvironmentObject var subManager: SubscriptionManager

    var body: some View {

        NavigationStack {
            ZStack {

                ScrollView(showsIndicators: false) {

                    LazyVStack {

                        Text("")
                        VisibilityTracker(id: "likedHeader")

                        if viewModel.isLoadingShowed {

                            ForEach(0..<5) { id in
                                ArticleView(
                                    id: "-1",
                                    title: "Hello, World!",
                                    authorId: "",
                                    authorName: "ReadBox Author",
                                    isCheckmark: true,
                                    isArchive: true,
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
                                    selectedAuthorId: .constant(""),
                                    isChannelViewPresented: .constant(false)
                                )
                                .redacted(reason: .placeholder)
                                .padding(.top, id == 0 ? 40 : 10)
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
                                    authorName: viewModel.authorsInfo[article.authorId ?? ""]?.name ?? "",
                                    dateCreated: article.dateCreated,
                                    isCheckmark: viewModel.authorsInfo[article.authorId ?? ""]?.isCheckmark ?? false,
                                    isArchive: article.isArchive ?? false,
                                    isShortPost: article.isShortPost ?? false,
                                    mediaCount: article.mediaCount ?? 1,
                                    mediaVersion: article.mediaVersion ?? 1,
                                    mediaPosition: article.mediaPosition ?? 0,
                                    lastVersionOfAvatar: viewModel.authorsInfo[article.authorId ?? ""]?.avatarVersion ?? 0,
                                    locCount: article.localizationCount ?? 0,
                                    isLocalizedVersion: article.isLocalizedVersion ?? false,
                                    isPremiumPost: article.isPremiumPost ?? false,
                                    onCommentTap: {
                                        if let isPremiumPost = article.isPremiumPost,
                                           isPremiumPost && !subManager.hasPremium,
                                           article.authorId != viewModel.user?.userId {
                                            isPremiumViewPresented = true
                                        } else {
                                            viewModel.tapGestureHandler(on: article, openComments: true)
                                        }
                                    }, user: $viewModel.user,
                                    isZoomableViewPresented: $viewModel.isZoomableViewPresented,
                                    zoomableImage: $viewModel.zoomableImage,
                                    selectedAuthorId: $viewModel.authorId,
                                    isChannelViewPresented: $viewModel.isChannelViewPresented
                                )
                                .padding(.top, article.id == viewModel.articles[0].id ? 40 : 10)
                                .padding(.horizontal)
                                .onAppear {
                                    viewModel.onPostAppearing(article)
                                }
                                .onTapGesture {
                                    if let isPremiumPost = article.isPremiumPost,
                                       isPremiumPost && !subManager.hasPremium,
                                       article.authorId != viewModel.user?.userId {
                                        isPremiumViewPresented = true
                                    } else {
                                        viewModel.tapGestureHandler(on: article)
                                    }
                                }
                            }

                        }

                    }

                }
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
                        rootId: viewModel.rootId,
                        openCommentsOnAppear: viewModel.shouldOpenCommentsOnRead
                    )
                    .environmentObject(sessionManager)
                    .environmentObject(changedPostsManager)
                    .environmentObject(subManager)
                })
                .navigationDestination(isPresented: $viewModel.isChannelViewPresented, destination: {
                    ChannelView(
                        user: $viewModel.user,
                        authorId: viewModel.authorId,
                        authorName: viewModel.authorsInfo[viewModel.authorId]?.name ?? NSLocalizedString("notFoundLabel", comment: ""),
                        isCheckmark: viewModel.authorsInfo[viewModel.authorId]?.isCheckmark ?? false,
                        lastVersionOfAvatar: viewModel.authorsInfo[viewModel.authorId]?.avatarVersion ?? 0,
                        isPremiumViewPresented: $isPremiumViewPresented
                    )
                    .environmentObject(sessionManager)
                    .environmentObject(changedPostsManager)
                    .environmentObject(subManager)
                })
                .fullScreenCover(isPresented: $viewModel.isZoomableViewPresented, content: {
                    if let image = viewModel.zoomableImage {
                        ZoomableImageView(image: image)
                    }
                })
                .onAppear {
                    viewModel.getViews()

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
            .onPreferenceChange(VisibilityPreferenceKey.self) { values in
                if let minY = values["likedHeader"] {
                    let isVisible = minY > 60

                    if viewModel.isLargeHeaderVisible != isVisible {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.isLargeHeaderVisible = isVisible
                        }
                    }
                }
            }
        }

    }
}

private extension LikedPostsView {
    var headerView: some View {
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
