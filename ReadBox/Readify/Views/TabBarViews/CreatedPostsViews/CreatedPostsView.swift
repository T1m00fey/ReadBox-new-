//
//  CreateView.swift
//  Readify
//
//  Created by Тимофей Юдин on 20.01.2025.
//

import SwiftUI
import SwiftfulLoadingIndicators
import Shimmer
import TipKit

struct CreatedPostsView: View {
    @Binding var isWelcomeViewPresented: Bool
    @Binding var isConfirmationPopupPresented: Bool

    @StateObject var viewModel = CreatedPostsViewModel()
    @Namespace private var createdPostsTabsNamespace

    @FocusState var isAuthorNameFocused: Bool
    @FocusState var isDescriptionFocused: Bool

    @EnvironmentObject var hudService: HUDService
    @EnvironmentObject var sessionManager: SessionManager
    @EnvironmentObject var changedPostsManager: ChangedPostsManager
    @EnvironmentObject var subManager: SubscriptionManager

    private let feedSectionSpacing: CGFloat = 8
    private let sectionBottomPadding: CGFloat = 70

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
                            isArchived: viewModel.isArchivePresented,
                            isLocalizing: viewModel.isLocalizing,
                            localizationCount: viewModel.localizationCount,
                            isLocalizedVersion: viewModel.createIsLocalizedVersion,
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
                            authorId: viewModel.readAuthorId,
                            authorName: viewModel.readAuthorName,
                            isCheckmark: viewModel.readAuthorIsCheckmark,
                            isArchive: false,
                            mediaCount: viewModel.mediaCount,
                            mediaVersion: viewModel.mediaVersion,
                            mediaPosition: viewModel.mediaPosition,
                            lastVersionOfAvatar: viewModel.readAuthorAvatarVersion,
                            articleLanguage: viewModel.readArticleLanguage,
                            isPremiumPost: viewModel.readIsPremiumPost,
                            user: $viewModel.user,
                            isChannelViewPresented: .constant(false),
                            isPresented: $viewModel.isReadViewPresented,
                            isLocalizedVersion: viewModel.readIsLocalizedVersion,
                            rootId: viewModel.readRootId,
                            isCommentReadView: viewModel.isReadingReplyComment,
                            replyAuthorName: viewModel.readReplyAuthorName,
                            replyRootPostId: viewModel.readReplyRootPostId,
                            openCommentsOnAppear: viewModel.shouldOpenCommentsOnRead
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
                        ZoomableImageView(image: viewModel.zoomableImage ?? viewModel.avatarImage)
                    })
                    .onChange(of: viewModel.isZoomableImageViewPresented) {
                        if !viewModel.isZoomableImageViewPresented {
                            viewModel.zoomableImage = nil
                        }
                    }
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
                    .alert(
                        LocalizedStringKey("deletePublicationAlertTitle"),
                        isPresented: $viewModel.isDeletePostAlertPresented
                    ) {
                        Button(LocalizedStringKey("deleteLabel"), role: .destructive) {
                            let replyId = viewModel.pendingDeleteReplyId
                            let postId = viewModel.pendingDeletePostId
                            guard !postId.isEmpty || !replyId.isEmpty else { return }

                            Task {
                                do {
                                    hudService.showLoading(type: .delete)
                                    if !replyId.isEmpty {
                                        try await viewModel.deleteReply(id: replyId)
                                    } else {
                                        try await viewModel.deletePost(id: postId)
                                    }
                                    hudService.showSuccessPopup(type: .delete)

                                    await MainActor.run {
                                        viewModel.pendingDeletePostId = ""
                                        viewModel.pendingDeleteReplyId = ""
                                        viewModel.id = ""
                                    }
                                } catch {
                                    await MainActor.run {
                                        withAnimation {
                                            hudService.showErrorPopup(with: error.localizedDescription)
                                            viewModel.id = ""
                                            viewModel.pendingDeletePostId = ""
                                            viewModel.pendingDeleteReplyId = ""
                                        }
                                    }
                                }
                            }
                        }

                        Button(LocalizedStringKey("cancelButton"), role: .cancel) {
                            viewModel.pendingDeletePostId = ""
                            viewModel.pendingDeleteReplyId = ""
                            viewModel.id = ""
                        }
                    } message: {
                        Text(LocalizedStringKey(viewModel.deleteAlertMessageKey(for: viewModel.pendingDeletePostId)))
                    }

                if viewModel.user?.name != "" && !viewModel.isSettingViewPresented {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            headerView

                            createdPostsTabsView

                            createdPostsSectionContent(for: viewModel.currentSection)
                        }
                        .padding(.horizontal)
                    }
                    .frame(width: UIScreen.main.bounds.width)
                    .coordinateSpace(name: "readScroll")
                    .refreshable {
                        viewModel.reload()
                    }
                    .task {
                        try? Tips.configure()
                    }
                    .onPreferenceChange(VisibilityPreferenceKey.self) { values in
                        if let minY = values["publicationsLabel"] {
                            let isVisible = minY > -10

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
                        Button {
                            withAnimation {
                                viewModel.isSettingViewPresented.toggle()
                            }
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .foregroundStyle(Color.gray)
                                .bold()
                        }
                    }
                }
            }
            .environmentObject(subManager)
        }
    }
}

private extension CreatedPostsView {
    var registrationDateText: String? {
        guard let date = viewModel.user?.dateCreated else { return nil }
        return formattedRegistrationDate(date)
    }

    func formattedRegistrationDate(_ date: Date) -> String {
        let language = Locale.preferredLanguages.first?.components(separatedBy: "-").first == "ru"
        ? "ru_RU"
        : "en_US"

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language)
        formatter.dateFormat = "d MMMM yyyy"

        return formatter.string(from: date)
    }

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

    func selectCreatedPostsSection(_ section: CreatedPostsSection) {
        switch section {
        case .all:
            viewModel.showAllPosts()
        case .articles:
            viewModel.showArticles()
            Task {
                await viewModel.loadArticlesUntilAvailableIfNeeded()
            }
        case .replies:
            viewModel.showReplies()
            Task {
                await viewModel.loadRepliesIfNeeded()
            }
        case .archive:
            viewModel.showArchivePosts()
        case .localizedPublished:
            viewModel.showLocalizedPosts()
        case .localizedArchive:
            viewModel.showLocalizedArchivePosts()
        }
    }

    var createdPostsTabsView: some View {
        ZStack(alignment: .bottom) {
            Divider()
                .frame(width: UIScreen.main.bounds.width)

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 24) {
                        ForEach(CreatedPostsSection.allCases, id: \.self) { section in
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    selectCreatedPostsSection(section)
                                    proxy.scrollTo(section, anchor: .center)
                                }
                            } label: {
                                Group {
                                    if viewModel.isLoadingShowing {
                                        createdPostsTabLabel(for: section)
                                            .redacted(reason: .placeholder)
                                            .shimmering()
                                    } else {
                                        createdPostsTabLabel(for: section)
                                    }
                                }
                                .fixedSize(horizontal: true, vertical: false)
                                .padding(.top, 8)
                            }
                            .buttonStyle(.plain)
                            .id(section)
                        }
                    }
                    .padding(.horizontal, 10)
                }
                .onChange(of: viewModel.currentSection) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        proxy.scrollTo(viewModel.currentSection, anchor: .center)
                    }
                }
            }
        }
        .background(Color(.systemBackground))
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: viewModel.currentSection)
    }

    func createdPostsTabLabel(for section: CreatedPostsSection) -> some View {
        VStack(spacing: 7) {
            Text(section.title)
                .font(.system(size: 16))
                .fontDesign(.rounded)
                .fontWeight(viewModel.currentSection == section ? .semibold : .regular)
                .foregroundStyle(
                    viewModel.currentSection == section
                    ? Color(.label)
                    : Color(.secondaryLabel)
                )
                .lineLimit(1)
                .minimumScaleFactor(0.65)

            ZStack {
                if viewModel.currentSection == section {
                    Capsule()
                        .frame(height: 3)
                        .foregroundStyle(Color(.label))
                        .matchedGeometryEffect(id: "createdPostsTabIndicator", in: createdPostsTabsNamespace)
                } else {
                    Color.clear
                        .frame(height: 3)
                }
            }
        }
    }

    @ViewBuilder
    func createdPostsSectionContent(for section: CreatedPostsSection) -> some View {
        if section == .replies {
            repliesSectionContent
        } else {
            let posts = viewModel.posts(for: section)

            if viewModel.isLoadingShowing {
                ForEach(0..<4) { num in
                    loadingPostPlaceholder(index: num)
                }
            } else if viewModel.posts.count > 0 || viewModel.archivePosts.count > 0 {
                if !posts.isEmpty {
                    ForEach(posts) { post in
                        postRow(post, section: section, sectionPosts: posts)
                    }
                } else {
                    noPostsView
                }
            } else {
                noPostsView
            }
        }
    }

    @ViewBuilder
    var repliesSectionContent: some View {
        if viewModel.isRepliesLoading {
            ForEach(0..<4, id: \.self) { num in
                ArticleView(
                    id: "\(num)",
                    title: "Hello, World!",
                    authorId: viewModel.user?.userId ?? "",
                    authorName: viewModel.user?.name ?? "Hello",
                    dateCreated: Date(),
                    isCheckmark: viewModel.user?.isCheckmark ?? false,
                    isArchive: false,
                    isShortPost: true,
                    mediaCount: 0,
                    mediaVersion: 1,
                    mediaPosition: 0,
                    lastVersionOfAvatar: viewModel.user?.avatarVersion ?? 0,
                    locCount: 0,
                    isCreatedView: true,
                    isLocalizedVersion: false,
                    isPremiumPost: false,
                    viewsCount: 10,
                    likesCount: 10,
                    commentsCount: 10,
                    replyAuthorName: "Hello",
                    onReplyTap: {},
                    user: $viewModel.user,
                    isZoomableViewPresented: $viewModel.isZoomableImageViewPresented,
                    zoomableImage: $viewModel.zoomableImage,
                    selectedAuthorId: .constant(""),
                    isChannelViewPresented: .constant(false)
                )
                .redacted(reason: .placeholder)
                .padding(.top, 10)
                .padding(.bottom, num == 3 ? sectionBottomPadding : feedSectionSpacing)
                .shimmering()
            }
        } else if !viewModel.replies.isEmpty {
            ForEach(viewModel.replies) { reply in
                ArticleView(
                    id: reply.id,
                    title: reply.text ?? "",
                    authorId: reply.authorId ?? "",
                    authorName: viewModel.user?.name ?? NSLocalizedString("notFoundLabel", comment: ""),
                    dateCreated: reply.dateCreated,
                    isCheckmark: viewModel.user?.isCheckmark ?? false,
                    isArchive: false,
                    isShortPost: true,
                    mediaCount: 0,
                    mediaVersion: 1,
                    mediaPosition: 0,
                    lastVersionOfAvatar: viewModel.user?.avatarVersion ?? 0,
                    locCount: 0,
                    isCreatedView: true,
                    isLocalizedVersion: false,
                    isPremiumPost: false,
                    viewsCount: reply.viewsCount ?? 0,
                    likesCount: reply.likesCount ?? 0,
                    commentsCount: reply.repliesCount ?? 0,
                    replyAuthorName: viewModel.replyAuthorsInfo[reply.rootAuthorId ?? ""]?.name,
                    onReplyTap: {
                        viewModel.openReplyRootPost(reply)
                    },
                    onCommentTap: {
                        viewModel.openReplyComment(reply, openComments: true)
                    },
                    isReplyMenuVisible: true,
                    onDeleteReply: {
                        viewModel.requestReplyDeletion(reply)
                    },
                    user: $viewModel.user,
                    isZoomableViewPresented: $viewModel.isZoomableImageViewPresented,
                    zoomableImage: $viewModel.zoomableImage,
                    selectedAuthorId: .constant(""),
                    isChannelViewPresented: .constant(false)
                )
                .contentShape(Rectangle())
                .padding(.top, 10)
                .onTapGesture {
                    viewModel.openReplyComment(reply)
                }
                .padding(.bottom, reply.id == viewModel.replies.last?.id ? 70 : feedSectionSpacing)
            }
        } else {
            noPostsView
        }
    }

    func loadingPostPlaceholder(index: Int) -> some View {
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
        .redacted(reason: .placeholder)
        .padding(.top, 10)
        .padding(.bottom, index == 3 ? sectionBottomPadding : feedSectionSpacing)
        .shimmering()
    }

    func postRow(_ post: PrePost, section: CreatedPostsSection, sectionPosts: [PrePost]) -> some View {
        ArticleView(
            id: post.id,
            title: post.title ?? NSLocalizedString("noFoundLabel", comment: ""),
            authorId: post.authorId ?? "",
            authorName: viewModel.user?.name ?? NSLocalizedString("noFoundLabel", comment: ""),
            dateCreated: post.dateCreated,
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
            viewsCount: post.viewsCount ?? 0,
            likesCount: post.likesCount ?? 0,
            commentsCount: post.repliesCount,
            onCommentTap: {
                viewModel.tapGestureHandler(on: post, openComments: true)
            }, user: $viewModel.user,
            isZoomableViewPresented: $viewModel.isZoomableImageViewPresented,
            zoomableImage: $viewModel.zoomableImage,
            selectedAuthorId: .constant(""),
            isChannelViewPresented: .constant(false),
            postOption: $viewModel.postOption,
            selectedId: $viewModel.id
        )
        .padding(.top, 10)
        .padding(.bottom, post.id == sectionPosts.last?.id ? 70 : feedSectionSpacing)
        .onTapGesture {
            viewModel.tapGestureHandler(on: post)
        }
        .onAppear {
            guard post.id == sectionPosts.last?.id else { return }

            Task {
                if section == .archive || section == .localizedArchive {
                    guard !viewModel.isAllArchivedLoaded else { return }
                    try? await viewModel.getArchivedPost()
                } else {
                    guard !viewModel.isAllLoaded else { return }
                    try? await viewModel.getPosts()
                }
            }
        }
    }

    var noPostsView: some View {
        VStack(spacing: 20) {
            Text(LocalizedStringKey("noArticlesAddedLabel"))
                .font(.system(size: 25))
                .bold()
                .fontDesign(.rounded)
                .foregroundStyle(Color.gray)
                .multilineTextAlignment(.center)

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
        }
        .frame(width: UIScreen.main.bounds.width - 32)
        .padding(.top, 10)
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
                                viewModel.zoomableImage = viewModel.avatarImage
                                viewModel.isZoomableImageViewPresented = true
                            }
                    }

                    VStack(spacing: 1) {
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
                Text(createdPostsDescriptionAttributedString)
                    .font(.system(size: 18))
                    .fontDesign(.rounded)
                    .frame(width: UIScreen.main.bounds.width - 20, alignment: .leading)
                    .padding(.top, 15)
            }

            if !viewModel.isLoading, let registrationDateText {
                Text("\(NSLocalizedString("registrationDateLabel", comment: "")): \(registrationDateText)")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.gray)
                    .fontDesign(.rounded)
                    .lineLimit(1)
                    .frame(width: UIScreen.main.bounds.width - 20, alignment: .leading)
                    .padding(.top, viewModel.description.isEmpty ? 15 : 10)
            }

            VisibilityTracker(id: "publicationsLabel")
        }
        .padding(.vertical, 15)
    }

    var createdPostsDescriptionAttributedString: AttributedString {
        var attributedString = viewModel.description.markdownAttributedStringPreservingLineBreaks

        for run in attributedString.runs where run.link != nil {
            attributedString[run.range].foregroundColor = .blue
            attributedString[run.range].underlineStyle = .single
        }

        return attributedString
    }
}
