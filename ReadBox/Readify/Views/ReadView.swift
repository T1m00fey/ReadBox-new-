//
//  TestReadView.swift
//  Readify
//
//  Created by Тимофей Юдин on 17.12.2024.
//

import SwiftUI
import PopupView
import MarkdownUI
import SwiftfulLoadingIndicators
import SDWebImageSwiftUI
import FirebaseStorage
import UIKit

struct ReadView: View {

    let id: String
    let title: String
    let text: String
    let dateCreated: Date
    let likesCount: Int
    let authorId: String
    let authorName: String
    let isCheckmark: Bool
    let isArchive: Bool
    let mediaCount: Int
    let mediaVersion: Int
    let mediaPosition: Int
    let lastVersionOfAvatar: Int
    let articleLanguage: String
    let isPremiumPost: Bool
    let isLocalizedVersion: Bool
    let rootId: String
    let originalPrePost: PrePost?
    let replyAuthorName: String?
    let replyRootPostId: String?

    @Binding var user: DBUser?
    @Binding var isChannelViewPresented: Bool
    @Binding var isPresented: Bool

    @State private var isSubscribed = false
    @State private var currentPrePost: PrePost? = nil
    @State private var currentPostToRead: PostToRead? = nil
    @State private var originalArticleLanguage = ""
    @State private var cachedOriginalPrePost: PrePost? = nil
    @State private var cachedOriginalPostToRead: PostToRead? = nil
    @State private var originalArticleCanBeOpened: Bool? = nil
    @State private var localizedPrePost: PrePost? = nil
    @State private var cachedLocalizedPostToRead: PostToRead? = nil
    @State private var localizedArticleLanguage = ""
    @State private var viewedArticleIdsInReadSession: Set<String> = []
    @State private var commentText = ""
    @State private var isCommentAuthorChannelPresented = false
    @State private var isCommentArticleAuthorTapRequested = false
    @State private var commentChannelAuthorId = ""
    @State private var commentChannelAuthorName = ""
    @State private var commentChannelIsCheckmark = false
    @State private var commentChannelLastVersionOfAvatar = 0
    @State private var isCommentChannelPremiumViewPresented = false
    @State private var isCommentReadViewPresented = false
    @State private var commentToRead: Comment? = nil
    @State private var isReplyRootReadViewPresented = false
    @State private var replyRootPrePost: PrePost? = nil
    @State private var replyRootPostToRead: PostToRead? = nil
    @State private var replyRootAuthorName = ""
    @State private var replyRootIsCheckmark = false
    @State private var replyRootLastVersionOfAvatar = 0

    @StateObject var viewModel = ReadViewModel()

    @FocusState private var isCommentInputFocused: Bool

    @Namespace var namespace

    @EnvironmentObject var sessionManager: SessionManager
    @EnvironmentObject var changedPostsManager: ChangedPostsManager
    @EnvironmentObject var subManager: SubscriptionManager

    init(
        id: String,
        title: String,
        text: String,
        dateCreated: Date,
        likesCount: Int,
        authorId: String,
        authorName: String,
        isCheckmark: Bool,
        isArchive: Bool,
        mediaCount: Int,
        mediaVersion: Int,
        mediaPosition: Int,
        lastVersionOfAvatar: Int,
        articleLanguage: String = "",
        isPremiumPost: Bool = false,
        user: Binding<DBUser?>,
        isChannelViewPresented: Binding<Bool>,
        isPresented: Binding<Bool>,
        isLocalizedVersion: Bool = false,
        rootId: String = "",
        originalPrePost: PrePost? = nil,
        replyAuthorName: String? = nil,
        replyRootPostId: String? = nil
    ) {
        self.id = id
        self.title = title
        self.text = text
        self.dateCreated = dateCreated
        self.likesCount = likesCount
        self.authorId = authorId
        self.authorName = authorName
        self.isCheckmark = isCheckmark
        self.isArchive = isArchive
        self.mediaCount = mediaCount
        self.mediaVersion = mediaVersion
        self.mediaPosition = mediaPosition
        self.lastVersionOfAvatar = lastVersionOfAvatar
        self.articleLanguage = articleLanguage
        self.isPremiumPost = isPremiumPost
        self._user = user
        self._isChannelViewPresented = isChannelViewPresented
        self._isPresented = isPresented
        self.isLocalizedVersion = isLocalizedVersion
        self.rootId = rootId
        self.originalPrePost = originalPrePost
        self.replyAuthorName = replyAuthorName
        self.replyRootPostId = replyRootPostId
    }

    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack {

                    if !currentText.isEmpty {
                        Text(currentTitle)
                            .fontWeight(.light)
                            .fontDesign(.rounded)
                            .font(.system(size: 24))
                            .frame(width: UIScreen.main.bounds.width - 32, alignment: .leading)
                            .hiddenReadContentOnScreenshots(currentIsPremiumPost)

                        RoundedRectangle(cornerRadius: 0)
                            .frame(width: UIScreen.main.bounds.width, height: 1)
                            .foregroundStyle(Color.gray)
                            .padding(.bottom, 4)
                    }

                    ZStack {
                        VisibilityTracker(id: "authorBlock")

                        HStack {
//                            Text("by")
//                                .font(.system(size: 20))
//                                .fontDesign(.rounded)
//                                .foregroundStyle(Color.gray)

                            if let avatar = viewModel.avatarImage {
                                Image(uiImage: avatar)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 45, height: 45)
                                    .clipShape(Circle())
                                    .overlay {
                                        Circle()
                                            .stroke(
                                                Color(.label),
                                                lineWidth: 0.1
                                            )
                                    }
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                if let replyTitle {
                                    Text(replyTitle)
                                        .font(.system(size: 12))
                                        .foregroundStyle(Color.gray)
                                        .lineLimit(1)
                                        .onTapGesture {
                                            openReplyRootPost()
                                        }
                                }

                                HStack(spacing: 0) {
                                    Button {
                                        withAnimation {
                                            if authorName != "" {
                                                isChannelViewPresented = true

                                                isPresented = false
                                            }
                                        }
                                    } label: {
                                        Text(authorName == "" ? NSLocalizedString("notFoundLabel", comment: "") : authorName)
                                            .font(.system(size: 18))
                                            .multilineTextAlignment(.leading)
                                            .lineLimit(2)
                                            .underline()

                                    }

                                    if isCheckmark {
                                        Image(systemName: "checkmark.seal.fill")
                                            .foregroundStyle(Color.blue)
                                            .font(.system(size: 14))
                                            .padding(.top, 1)
                                    }
                                }
                            }
                        }
                        .frame(width: UIScreen.main.bounds.width - 32, alignment: .leading)
                        .padding(.bottom, currentIsShortPost ? 0 : 5)
                        .padding(.top, viewModel.images.count == 0 ? 10 : 0)
                    }

//                        if viewModel.image != UIImage() {
//                            Image(uiImage: viewModel.image)
//                                .resizable()
//                                .scaledToFit()
//                                .frame(width: UIScreen.main.bounds.width - 20)
//                                .clipShape(RoundedRectangle(cornerRadius: 20))
//                                .padding(.horizontal)
//                                .onTapGesture {
//                                    viewModel.isImageFullscreenPresented = true
//                                }
//                        } else if let videoURL = viewModel.videoURL {
//                            TappableVideoPreview(url: videoURL, cornerRadius: 20, width: UIScreen.main.bounds.width - 20)
//                                .frame(width: UIScreen.main.bounds.width - 20)
//                        }

                    if currentMediaPosition == 0 && currentMediaCount > 0 {
                        mediaViews
                    }
//                    else if currentMediaPosition == 1 && !currentTitle.isEmpty {
//                        titleView
////                            .padding(.top, 10)
////                            .padding(.bottom, -20)
//                    }

                    if !currentIsShortPost {
                        HStack {
                            Text(currentDateCreatedText)
                                .font(.system(size: 19))
                                .fontWeight(.light)
                                .fontDesign(.rounded)
                                .foregroundStyle(Color.gray)

                            Spacer()

                            likeButton

                            if canShowSubscribeButton {
                                subscribeButton
                            }
                        }
                        .frame(width: UIScreen.main.bounds.width - 32)
                        .padding(.horizontal)
                        .padding(.top, mediaCount == 0 || currentMediaPosition == 1 ? -15 : 0)
                        .padding(.bottom, 10)
                    }

                    if currentMediaPosition == 1 && !currentTitle.isEmpty {
                        titleView
                            .padding(.bottom, currentIsShortPost ? 14 : 25)
                    }

                    if !currentText.isEmpty {
                        Markdown(
                            currentText.replacingOccurrences(of: "\n", with: "  \n").normalizeEmptyLines()
                        )
                        .markdownImageProvider(
                            WebImageProvider(onImageTap: { url in
                                viewModel.selectedImageURL = url
                                viewModel.isZoomableViewPresented = true
                            })
                        )
                        .markdownTextStyle(\.text) {
                            FontSize(CGFloat(viewModel.fontSize))
                        }
                        .markdownTheme(.gitHub)
                        .id("\(currentId)-\(viewModel.fontSize)")
                        .frame(width: UIScreen.main.bounds.width - 32, alignment: .topLeading)
                        .padding(.bottom, currentIsShortPost ? 12 : 20)
                        .hiddenReadContentOnScreenshots(currentIsPremiumPost)

                        if currentMediaPosition == 1 && currentMediaCount > 0 {
                            mediaViews
                                .padding(.top, -5)
                                .padding(.bottom, 20)
                        }
                    } else if currentMediaPosition == 0 && currentTitle != "" {
                        titleView
                            .padding(.top, currentIsShortPost ? 8 : 0)
                            .padding(.bottom, currentIsShortPost ? 12 : 20)
                    } else if currentMediaPosition == 1 {
                        mediaViews
                            .padding(.top, -15)
                            .padding(.bottom, currentIsShortPost ? 12 : 20)
                    }

                    if currentIsShortPost {
                        HStack {
                            Text(currentDateCreatedText)
                                .font(.system(size: 19))
                                .fontWeight(.light)
                                .fontDesign(.rounded)
                                .foregroundStyle(Color.gray)

                            Spacer()

                            likeButton

                            if canShowSubscribeButton {
                                subscribeButton
                            }
                        }
                        .frame(width: UIScreen.main.bounds.width - 32)
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }

                    commentariesSection
                }

            }
            .coordinateSpace(name: "readScroll")
            .fullScreenCover(isPresented: $viewModel.isZoomableViewPresented) {
                if let image = viewModel.zoomableImage {
                    ZoomableImageView(image: image)
                } else if let url = viewModel.selectedImageURL {
                    ZoomableImageView(imageURL: url)
                }
            }
            .navigationDestination(isPresented: $isCommentAuthorChannelPresented) {
                ChannelView(
                    user: $user,
                    authorId: commentChannelAuthorId,
                    authorName: commentChannelAuthorName,
                    isCheckmark: commentChannelIsCheckmark,
                    lastVersionOfAvatar: commentChannelLastVersionOfAvatar,
                    isPremiumViewPresented: $isCommentChannelPremiumViewPresented
                )
                .tint(Color(uiColor: .label))
                .environmentObject(sessionManager)
                .environmentObject(changedPostsManager)
                .environmentObject(subManager)
            }
            .navigationDestination(isPresented: $isCommentReadViewPresented) {
                let commentAuthorId = commentToRead?.authorId ?? ""
                let replyAuthorId = commentToRead?.rootAuthorId ?? authorId
                let authorInfo = viewModel.commentAuthorsInfo[commentAuthorId]
                let replyAuthorInfo = viewModel.commentAuthorsInfo[replyAuthorId]
                let replyAuthorName = replyAuthorInfo?.name ?? authorName

                ReadView(
                    id: commentToRead?.id ?? "",
                    title: commentToRead?.text ?? "",
                    text: "",
                    dateCreated: commentToRead?.dateCreated ?? Date(),
                    likesCount: commentToRead?.likesCount ?? 0,
                    authorId: commentAuthorId,
                    authorName: authorInfo?.name ?? "",
                    isCheckmark: authorInfo?.isCheckmark ?? false,
                    isArchive: false,
                    mediaCount: 0,
                    mediaVersion: 1,
                    mediaPosition: 0,
                    lastVersionOfAvatar: authorInfo?.avatarVersion ?? 0,
                    user: $user,
                    isChannelViewPresented: $isCommentAuthorChannelPresented,
                    isPresented: $isCommentReadViewPresented,
                    replyAuthorName: replyAuthorName,
                    replyRootPostId: commentToRead?.rootPostId
                )
                .environmentObject(sessionManager)
                .environmentObject(changedPostsManager)
                .environmentObject(subManager)
            }
            .navigationDestination(isPresented: $isReplyRootReadViewPresented) {
                ReadView(
                    id: replyRootPrePost?.id ?? "",
                    title: replyRootPrePost?.title ?? "",
                    text: replyRootPostToRead?.text ?? "",
                    dateCreated: replyRootPostToRead?.dateCreated ?? Date(),
                    likesCount: replyRootPrePost?.likesCount ?? 0,
                    authorId: replyRootPrePost?.authorId ?? "",
                    authorName: replyRootAuthorName,
                    isCheckmark: replyRootIsCheckmark,
                    isArchive: false,
                    mediaCount: replyRootPrePost?.mediaCount ?? 0,
                    mediaVersion: replyRootPrePost?.mediaVersion ?? 1,
                    mediaPosition: replyRootPrePost?.mediaPosition ?? 0,
                    lastVersionOfAvatar: replyRootLastVersionOfAvatar,
                    articleLanguage: replyRootPrePost?.originalLanguage ?? "",
                    isPremiumPost: replyRootPrePost?.isPremiumPost ?? false,
                    user: $user,
                    isChannelViewPresented: $isCommentAuthorChannelPresented,
                    isPresented: $isReplyRootReadViewPresented,
                    isLocalizedVersion: replyRootPrePost?.isLocalizedVersion ?? false,
                    rootId: replyRootPrePost?.rootId ?? ""
                )
                .environmentObject(sessionManager)
                .environmentObject(changedPostsManager)
                .environmentObject(subManager)
            }
            .fullScreenCover(isPresented: $isCommentChannelPremiumViewPresented) {
                PremiumView()
                    .environmentObject(subManager)
            }
            .onPreferenceChange(VisibilityPreferenceKey.self) { values in
                if let minY = values["authorBlock"] {
                    let isVisible = minY > -20

                    if viewModel.isAuthorBlockVisible != isVisible {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.isAuthorBlockVisible = isVisible
                        }
                    }
                }
            }
            .onAppear {
                viewedArticleIdsInReadSession.insert(id)

                withAnimation {
                    if let subscribes = user?.subscribes {
                        isSubscribed = subscribes.contains(authorId)
                    }

                    viewModel.isPostLiked = (user?.likedPosts ?? []).contains(currentId)
                }

                viewModel.likesCount = currentLikesCount

                viewModel.fontSize = StorageManager.shared.getFontSize()

                if originalArticleLanguage.isEmpty {
                    originalArticleLanguage = formattedLanguageCode(originalPrePost?.originalLanguage)
                }
            }
            .task {
                let avatarVersion: Int

                do {
                    avatarVersion = try await UserManager.shared.resolveAvatarVersion(
                        id: authorId,
                        fallback: lastVersionOfAvatar
                    )
                } catch {
                    avatarVersion = lastVersionOfAvatar
                }

                let ava = await MediaManager.shared.getAvatar(authorId: authorId, lastVersion: avatarVersion)

                withAnimation {
                    viewModel.avatarImage = ava
                }
            }
            .task(id: currentRootId) {
                await loadOriginalArticleLanguageIfNeeded()
            }
            .task(id: id) {
                await loadLocalizedArticleIfNeeded()
            }
            .task(id: currentId) {
                await viewModel.loadCommentaries(rootPostId: currentId)
            }
            .onChange(of: viewModel.isZoomableViewPresented) {
                if !viewModel.isZoomableViewPresented {
                    viewModel.selectedImageURL = nil
                }
            }
            .onChange(of: isCommentArticleAuthorTapRequested) {
                if isCommentArticleAuthorTapRequested {
                    let authorId = commentChannelAuthorId
                    isCommentArticleAuthorTapRequested = false
                    openCommentAuthorChannel(authorId)
                }
            }
            .popup(isPresented: $viewModel.isErrorPopupPresented) {
                Text(viewModel.errorText)
                    .frame(width: UIScreen.main.bounds.width - 72, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .foregroundStyle(Color.white)
                    .background(Color.red)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            } customize: {
                $0
                    .type(.floater())
                    .position(.top)
                    .animation(.bouncy)
                    .dragToDismiss(true)
                    .autohideIn(5)
                    .displayMode(.overlay)
            }
            .sheet(isPresented: $viewModel.isFontSettingPopupPresented, content: {
                FontSettingView(
                    isPopupPresented: $viewModel.isFontSettingPopupPresented,
                    selectedFontSize: $viewModel.fontSize,
                    successText: .constant(""),
                    isSuccessPopupPresented: .constant(false)
                )
                .presentationDetents([.height(300)])
                .presentationCornerRadius(30)
                .presentationDragIndicator(.visible)
            })
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {

                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "arrow.left")
                    }

                }

                ToolbarItem(placement: .principal) {
                    if !viewModel.isAuthorBlockVisible {
                        if #available(iOS 26, *) {
                            principalToolView
                                .padding(.all, 10)
                                .glassEffect(.regular)
                        } else {
                            principalToolView
                        }
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.isOriginalArticleLoading {
                        ProgressView()
                    } else if hasExtraToolbarActions {
                        Menu {
                            if currentText != "" {
                                Button {
                                    viewModel.isFontSettingPopupPresented.toggle()
                                } label: {
                                    Label(
                                        NSLocalizedString("fontLabel", comment: ""),
                                        systemImage: "book.pages"
                                    )
                                }
                            }

                            if canSwitchArticleLanguage {
                                originalArticleMenuButton
                            }

                            if !currentIsArchive {
                                ShareLink(item: URL(string: "https://readbox-links.online/posts/?index=\(currentId)")!) {
                                    Label(
                                        NSLocalizedString("shareLabel", comment: ""),
                                        systemImage: "arrowshape.turn.up.right"
                                    )
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                        }
                    } else if !currentIsArchive {
                        ShareLink(item: URL(string: "https://readbox-links.online/posts/?index=\(currentId)")!) {
                            Image(systemName: "arrowshape.turn.up.right")
                        }
                    }
                }
            }
            .background(Color(uiColor: .systemBackground))

        }
        .simultaneousGesture(backSwipeGesture)
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .bottom) {
            commentInputBar
        }
        .navigationBarBackButtonHidden()
        .overlay(
            EnableSwipeBack()
                .frame(width: 0, height: 0)
        )
    }
}

private extension ReadView {
    var backSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 20, coordinateSpace: .global)
            .onEnded { value in
                let isFromLeftEdge = value.startLocation.x <= 30
                let isHorizontalSwipe = value.translation.width > 80
                    && abs(value.translation.width) > abs(value.translation.height)

                guard isFromLeftEdge && isHorizontalSwipe else { return }

                withAnimation {
                    isPresented = false
                }
            }
    }

    var mediaViews: some View {
        MediaViews(
            id: currentId,
            authorId: authorId,
            mediaCount: currentMediaCount,
            mediaVersion: currentMediaVersion,
            zoomableImage: $viewModel.zoomableImage,
            isZoomableViewPresented: $viewModel.isZoomableViewPresented,
            currentIndex: $viewModel.currentIndex
        )
        .id(currentId)
        .hiddenReadContentOnScreenshots(currentIsPremiumPost)
    }

    var titleView: some View {
        Text(currentTitleAttributedString)
            .font(.system(size: 17))
//            .fontDesign(.rounded)
            .frame(width: UIScreen.main.bounds.width - 32, alignment: .leading)
            .hiddenReadContentOnScreenshots(currentIsPremiumPost)
    }

    var commentariesSection: some View {
        VStack(spacing: 10) {
            if !viewModel.commentaries.isEmpty {
                Divider()
            }

            if viewModel.isCommentariesLoading {
                ProgressView()
                    .frame(width: UIScreen.main.bounds.width - 20)
                    .padding(.vertical, 10)
            } else {
                ForEach(viewModel.commentaries) { comment in
                    let commentAuthorId = comment.authorId ?? ""
                    let authorInfo = viewModel.commentAuthorsInfo[commentAuthorId]
                    let avatarVersion = authorInfo?.avatarVersion ?? 0

                    ArticleView(
                        id: comment.id,
                        title: comment.text ?? "",
                        authorId: commentAuthorId,
                        authorName: authorInfo?.name ?? "",
                        dateCreated: comment.dateCreated,
                        isCheckmark: authorInfo?.isCheckmark ?? false,
                        isArchive: false,
                        isShortPost: true,
                        mediaCount: 0,
                        mediaVersion: 1,
                        mediaPosition: 0,
                        lastVersionOfAvatar: avatarVersion,
                        locCount: 0,
                        isLocalizedVersion: false,
                        isPremiumPost: false,
                        viewsCount: comment.viewsCount ?? 0,
                        likesCount: comment.likesCount ?? 0,
                        user: $user,
                        isZoomableViewPresented: $viewModel.isZoomableViewPresented,
                        zoomableImage: $viewModel.zoomableImage,
                        selectedAuthorId: $commentChannelAuthorId,
                        isChannelViewPresented: $isCommentArticleAuthorTapRequested
                    )
                    .id("\(comment.id)-\(avatarVersion)")
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard !isCommentArticleAuthorTapRequested else { return }
                        openCommentReadView(comment)
                    }
                }
            }
        }
        .padding(.bottom, 30)
    }

    var commentInputBar: some View {
        HStack(spacing: 10) {
            TextField(
                NSLocalizedString("commentPlaceholderLabel", comment: ""),
                text: $commentText,
                axis: .vertical
            )
            .focused($isCommentInputFocused)
            .lineLimit(1...4)
            .font(.system(size: 16))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(uiColor: .systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            //            .overlay(
            //                RoundedRectangle(cornerRadius: 18)
            //                    .stroke(
            //                        Color(.secondarySystemBackground),
            //                        lineWidth: 2
            //                    )
            //            )

            Button {
                sendCurrentComment()
            } label: {
                ZStack {
                    Circle()
                        .foregroundStyle(canSendComment ? Color(.label) : Color.gray.opacity(0.45))
                        .frame(width: 40, height: 40)

                    if viewModel.isCommentSending {
                        ProgressView()
                            .tint(Color(.systemBackground))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 17))
                            .foregroundStyle(Color(.systemBackground))
                    }
                }
            }
            .disabled(!canSendComment)
            .animation(.default, value: canSendComment)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .foregroundStyle(.ultraThinMaterial)
//                .overlay(
//                    RoundedRectangle(cornerRadius: 15)
//                        .stroke(
//                            Color(.secondarySystemBackground),
//                            lineWidth: 2
//                        )
//                )
                .padding(.bottom, -150)
        )
    }

    var currentTitleAttributedString: AttributedString {
        var attributedString = currentTitle.markdownAttributedStringPreservingLineBreaks

        for run in attributedString.runs where run.link != nil {
            attributedString[run.range].foregroundColor = .blue
            attributedString[run.range].underlineStyle = .single
        }

        return attributedString
    }

    var currentId: String {
        currentPrePost?.id ?? id
    }

    var normalizedCommentText: String {
        commentText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canSendComment: Bool {
        !normalizedCommentText.isEmpty
            && !viewModel.isCommentSending
            && !(user?.userId ?? "").isEmpty
            && !currentId.isEmpty
    }

    var canShowSubscribeButton: Bool {
        authorId != "" && authorId != user?.userId
    }

    var replyTitle: String? {
        let name = self.replyAuthorName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !name.isEmpty else { return nil }

        return "\(NSLocalizedString("replyToLabel", comment: "")) \(name)"
    }

    var likeButton: some View {
        Button {
            if viewModel.isPostLiked {
                withAnimation {
                    viewModel.isPostLiked.toggle()
                }

                user?.likedPosts?.removeAll {
                    currentId == $0

                }

                viewModel.likesCount -= 1

                Task {
                    do {
                        viewModel.vibrationsService.lightImpact()
                        try await viewModel.removeLikedPost(userId: user?.userId ?? "", articleId: currentId)
                    } catch {
                        withAnimation {
                            viewModel.errorText = error.localizedDescription
                            viewModel.isErrorPopupPresented = true
                        }
                    }

                    try? await viewModel.updateLikes(at: currentId, likesCount: viewModel.likesCount)
                }
            } else {
                if currentId != "" {
                    withAnimation {
                        viewModel.isPostLiked.toggle()
                    }

                    viewModel.likesCount += 1

                    user?.likedPosts?.append(currentId)

                    Task {
                        do {
                            viewModel.vibrationsService.lightImpact()
                            try await viewModel.addLikedPost(userId: user?.userId ?? "", articleId: currentId)
                        } catch {
                            withAnimation {
                                viewModel.errorText = error.localizedDescription
                                viewModel.isErrorPopupPresented = true
                            }
                        }

                        try? await viewModel.updateLikes(at: currentId, likesCount: viewModel.likesCount)
                    }
                } else {
                    withAnimation {
                        viewModel.errorText = NSLocalizedString("addPostToFavoritesLabel", comment: "")
                        viewModel.isErrorPopupPresented = true
                    }
                }
            }
        } label: {
            if #available(iOS 26.0, *) {
                Image(systemName: viewModel.isPostLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                    .scaleEffect(1.2)
                    .frame(width: 50, height: 50)
                    .glassEffect(.regular, in: .rect(cornerRadius: 20))
            } else {
                Image(systemName: viewModel.isPostLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                    .scaleEffect(1.2)
                    .frame(width: 50, height: 50)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(radius: 1)
            }
        }
    }

    var subscribeButton: some View {
        ZStack {
            if #available(iOS 26.0, *) {
                if viewModel.isSubscribeLoading {
                    LoadingIndicator(
                        animation: .circleRunner,
                        color: Color(.label),
                        size: .small,
                        speed: .fast
                    )
                    .padding(.vertical, 10)
                    .frame(width: 130)
                    .glassEffect(.regular, in: .rect(cornerRadius: 20))
                } else {
                    Text(
                        isSubscribed
                        ? NSLocalizedString("youSubscribedLabel", comment: "")
                        : NSLocalizedString("subscribeLabel", comment: "")
                    )
                    .font(.system(size: 14))
                    .fontDesign(.rounded)
                    .padding()
                    .glassEffect(.regular, in: .rect(cornerRadius: 20))
                }
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .foregroundStyle(
                        isSubscribed
                        ? Color(uiColor: .secondarySystemBackground)
                        : Color(uiColor: .label)
                    )
                    .shadow(radius: isSubscribed ? 1 : 0)
                    .frame(width: 120)

                if viewModel.isSubscribeLoading {
                    LoadingIndicator(
                        animation: .circleRunner,
                        color:  isSubscribed
                        ? Color(uiColor: .label)
                        : Color(uiColor: .systemBackground),
                        size: .small,
                        speed: .fast
                    )
                } else {
                    Text(
                        isSubscribed
                        ? NSLocalizedString("youSubscribedLabel", comment: "")
                        : NSLocalizedString("subscribeLabel", comment: "")
                    )
                    .font(.system(size: 14))
                    .fontDesign(.rounded)
                    .foregroundStyle(
                        isSubscribed
                        ? Color(uiColor: .label)
                        : Color(uiColor: .systemBackground)
                    )
                }
            }
        }
        .onTapGesture {
            if !viewModel.isSubscribeLoading {
                Task {
                    do {
                        withAnimation {
                            viewModel.isSubscribeLoading = true
                        }

                        try await viewModel.un_subcribeUser(
                            on: authorId,
                            isNeedToSubscribe: !isSubscribed
                        )

                        withAnimation {
                            if isSubscribed {
                                user?.subscribes?.removeAll { $0 == authorId }
                                viewModel.vibrationsService.lightImpact()
                            } else {
                                user?.subscribes?.append(authorId)
                                viewModel.vibrationsService.successFeedback()
                            }

                            viewModel.isSubscribeLoading = false
                            isSubscribed.toggle()
                        }
                    } catch {
                        withAnimation {
                            viewModel.isSubscribeLoading = false
                            viewModel.errorText = error.localizedDescription
                            viewModel.isErrorPopupPresented = true
                        }
                    }
                }
            }
        }
    }

    func sendCurrentComment() {
        let text = normalizedCommentText
        let authorId = user?.userId ?? ""
        let postId = currentId

        guard !text.isEmpty, !authorId.isEmpty, !postId.isEmpty else { return }

        withAnimation {
            commentText = ""
            isCommentInputFocused = false
        }

        Task {
            do {
                try await viewModel.sendComment(
                    rootPostId: postId,
                    rootAuthorId: self.authorId,
                    authorId: authorId,
                    text: text
                )

                await MainActor.run {
                    viewModel.vibrationsService.successFeedback()
                }
            } catch {
                await MainActor.run {
                    withAnimation {
                        commentText = text
                        viewModel.errorText = error.localizedDescription
                        viewModel.isErrorPopupPresented = true
                    }
                }
            }
        }
    }

    func openCommentReadView(_ comment: Comment) {
        withAnimation {
            commentToRead = comment
            isCommentReadViewPresented = true
        }
    }

    func openCommentAuthorChannel(_ authorId: String) {
        guard !authorId.isEmpty else { return }

        Task {
            do {
                let cachedInfo = await MainActor.run {
                    viewModel.commentAuthorsInfo[authorId]
                }
                let info: PostAuthorInfo?

                if let cachedInfo {
                    info = cachedInfo
                } else {
                    info = try await UserManager.shared.getPostAuthorInfo(for: authorId)
                }

                await MainActor.run {
                    commentChannelAuthorId = authorId
                    commentChannelAuthorName = info?.name ?? NSLocalizedString("notFoundLabel", comment: "")
                    commentChannelIsCheckmark = info?.isCheckmark ?? false
                    commentChannelLastVersionOfAvatar = info?.avatarVersion ?? 0
                    isCommentAuthorChannelPresented = true
                }
            } catch {
                await MainActor.run {
                    withAnimation {
                        viewModel.errorText = error.localizedDescription
                        viewModel.isErrorPopupPresented = true
                    }
                }
            }
        }
    }

    func openReplyRootPost() {
        guard let replyRootPostId, !replyRootPostId.isEmpty else { return }

        Task {
            do {
                let prePost = try await ArticlesManager.shared.getPrePost(id: replyRootPostId)
                let postToRead = try await ArticlesManager.shared.getPostToRead(id: replyRootPostId)
                let authorInfo = try await UserManager.shared.getPostAuthorInfo(for: prePost.authorId ?? "")

                await MainActor.run {
                    replyRootPrePost = prePost
                    replyRootPostToRead = postToRead
                    replyRootAuthorName = authorInfo?.name ?? NSLocalizedString("notFoundLabel", comment: "")
                    replyRootIsCheckmark = authorInfo?.isCheckmark ?? false
                    replyRootLastVersionOfAvatar = authorInfo?.avatarVersion ?? 0
                    isReplyRootReadViewPresented = true
                }
            } catch {
                await MainActor.run {
                    withAnimation {
                        viewModel.errorText = error.localizedDescription
                        viewModel.isErrorPopupPresented = true
                    }
                }
            }
        }
    }

    var currentTitle: String {
        currentPrePost?.title ?? title
    }

    var currentText: String {
        currentPostToRead?.text ?? text
    }

    var currentDateCreated: Date {
        currentPostToRead?.dateCreated ?? dateCreated
    }

    var currentDateCreatedText: String {
        formattedReadDate(currentDateCreated)
    }

    var currentIsShortPost: Bool {
        currentText.isEmpty
    }

    var currentLikesCount: Int {
        currentPrePost?.likesCount ?? likesCount
    }

    var currentIsArchive: Bool {
        currentPrePost?.isArchive ?? isArchive
    }

    var currentMediaCount: Int {
        currentPrePost?.mediaCount ?? mediaCount
    }

    var currentMediaVersion: Int {
        currentPrePost?.mediaVersion ?? mediaVersion
    }

    var currentMediaPosition: Int {
        currentPrePost?.mediaPosition ?? mediaPosition
    }

    var currentIsLocalizedVersion: Bool {
        currentPrePost?.isLocalizedVersion ?? isLocalizedVersion
    }

    var currentIsPremiumPost: Bool {
        currentPrePost?.isPremiumPost ?? isPremiumPost
    }

    func formattedReadDate(_ date: Date) -> String {
        let now = Date()
        let seconds = max(0, Int(now.timeIntervalSince(date)))
        let minute = 60
        let hour = 60 * minute
        let day = 24 * hour

        if seconds < hour {
            return relativeReadDate(value: max(1, seconds / minute), ruForms: ("минуту", "минуты", "минут"), enUnit: "minute")
        } else if seconds < day {
            return relativeReadDate(value: seconds / hour, ruForms: ("час", "часа", "часов"), enUnit: "hour")
        } else if seconds < 31 * day {
            return relativeReadDate(value: seconds / day, ruForms: ("день", "дня", "дней"), enUnit: "day")
        }

        if Calendar.current.isDate(date, equalTo: now, toGranularity: .year) {
            return formattedReadDate(date, format: isRussianLanguage ? "d MMMM" : "MMM d")
        }

        return formattedReadDate(date, format: "dd.MM.yy")
    }

    func relativeReadDate(value: Int, ruForms: (one: String, few: String, many: String), enUnit: String) -> String {
        if isRussianLanguage {
            return "\(value) \(russianPlural(value, one: ruForms.one, few: ruForms.few, many: ruForms.many)) назад"
        }

        return "\(value) \(enUnit)\(value == 1 ? "" : "s") ago"
    }

    func russianPlural(_ value: Int, one: String, few: String, many: String) -> String {
        let mod100 = value % 100
        let mod10 = value % 10

        if (11...14).contains(mod100) {
            return many
        } else if mod10 == 1 {
            return one
        } else if (2...4).contains(mod10) {
            return few
        } else {
            return many
        }
    }

    func formattedReadDate(_ date: Date, format: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: isRussianLanguage ? "ru_RU" : "en_US")
        formatter.dateFormat = format
        return formatter.string(from: date)
    }

    var isRussianLanguage: Bool {
        StorageManager.shared.getLanguage() == "ru"
    }

    var currentRootId: String {
        currentPrePost?.rootId ?? rootId
    }

    var canSwitchArticleLanguage: Bool {
        if isLocalizedVersion {
            return !rootId.isEmpty && (
                originalArticleCanBeOpened ??
                originalPrePost.map { !($0.isArchive ?? false) } ??
                false
            )
        }

        return localizedPrePost != nil && !(localizedPrePost?.isArchive ?? false)
    }

    var isShowingOriginalArticle: Bool {
        if isLocalizedVersion {
            return currentPrePost != nil
        }

        return currentPrePost == nil
    }

    var hasExtraToolbarActions: Bool {
        currentText != "" || canSwitchArticleLanguage
    }

    @ViewBuilder
    var originalArticleButton: some View {
        if viewModel.isOriginalArticleLoading {
            LoadingIndicator(
                animation: .circleRunner,
                color: Color(uiColor: .label),
                size: .small,
                speed: .fast
            )
        } else {
            Button {
                toggleArticleLanguage()
            } label: {
                Image("switchLanguageIcon")
            }
        }
    }

    @ViewBuilder
    var originalArticleMenuButton: some View {
        if viewModel.isOriginalArticleLoading {
            HStack {
                Image("switchLanguageIcon")
                Text(NSLocalizedString("loadingLabel", comment: ""))
            }
        } else {
            Button {
                toggleArticleLanguage()
            } label: {
                HStack {
                    Image("switchLanguageIcon")
                    Text(languageSwitchButtonTitle)
                }
            }
        }
    }

    var languageSwitchButtonTitle: String {
        let languageCode = targetArticleLanguageCode
        let title = isShowingOriginalArticle
            ? NSLocalizedString("translationLabel", comment: "")
            : NSLocalizedString("originalLabel", comment: "")
        return languageCode.isEmpty ? title : "\(title) (\(languageCode))"
    }

    var targetArticleLanguageCode: String {
        if isShowingOriginalArticle {
            return isLocalizedVersion
                ? formattedLanguageCode(articleLanguage)
                : displayedLocalizedArticleLanguage
        }

        return displayedOriginalArticleLanguage
    }

    func toggleArticleLanguage() {
        if isShowingOriginalArticle {
            if !isLocalizedVersion {
                showLocalizedArticle()
                return
            }

            withAnimation {
                currentPrePost = nil
                currentPostToRead = nil
                viewModel.likesCount = likesCount
                viewModel.isPostLiked = (user?.likedPosts ?? []).contains(id)
                viewModel.currentIndex = 0
                viewModel.selectedImageURL = nil
            }
            return
        }

        if isLocalizedVersion {
            showOriginalArticle()
        } else {
            showInitialArticle()
        }
    }

    func showInitialArticle() {
        withAnimation {
            currentPrePost = nil
            currentPostToRead = nil
            viewModel.likesCount = likesCount
            viewModel.isPostLiked = (user?.likedPosts ?? []).contains(id)
            viewModel.currentIndex = 0
            viewModel.selectedImageURL = nil
        }
    }

    func showOriginalArticle() {
        guard !currentRootId.isEmpty, !viewModel.isOriginalArticleLoading else { return }

        if let cachedOriginalPrePost, let cachedOriginalPostToRead {
            guard !(cachedOriginalPrePost.isArchive ?? false) else {
                originalArticleCanBeOpened = false
                return
            }
            showLoadedArticle(prePost: cachedOriginalPrePost, postToRead: cachedOriginalPostToRead)
            return
        }

        Task {
            do {
                await MainActor.run {
                    withAnimation {
                        viewModel.isOriginalArticleLoading = true
                    }
                }

                let loadedOriginalPrePost: PrePost

                if let cachedOriginalPrePost {
                    loadedOriginalPrePost = cachedOriginalPrePost
                } else if let originalPrePostFromChannel = self.originalPrePost {
                    loadedOriginalPrePost = originalPrePostFromChannel
                } else {
                    loadedOriginalPrePost = try await ArticlesManager.shared.getPrePost(id: currentRootId)
                }

                guard !(loadedOriginalPrePost.isArchive ?? false) else {
                    await MainActor.run {
                        withAnimation {
                            originalArticleCanBeOpened = false
                            cachedOriginalPrePost = nil
                            cachedOriginalPostToRead = nil
                            viewModel.isOriginalArticleLoading = false
                        }
                    }
                    return
                }

                let originalPostToRead: PostToRead

                if let cachedOriginalPostToRead {
                    originalPostToRead = cachedOriginalPostToRead
                } else {
                    originalPostToRead = try await ArticlesManager.shared.getPostToRead(id: currentRootId)
                }

                await MainActor.run {
                    withAnimation {
                        cachedOriginalPrePost = loadedOriginalPrePost
                        cachedOriginalPostToRead = originalPostToRead
                        originalArticleCanBeOpened = true
                        originalArticleLanguage = formattedLanguageCode(loadedOriginalPrePost.originalLanguage)
                        showLoadedArticle(prePost: loadedOriginalPrePost, postToRead: originalPostToRead)
                        viewModel.isOriginalArticleLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    withAnimation {
                        viewModel.isOriginalArticleLoading = false
                        viewModel.errorText = error.localizedDescription
                        viewModel.isErrorPopupPresented = true
                    }
                }
            }
        }
    }

    func showLocalizedArticle() {
        guard !viewModel.isOriginalArticleLoading else { return }

        if let localizedPrePost, let cachedLocalizedPostToRead {
            guard !(localizedPrePost.isArchive ?? false) else {
                self.localizedPrePost = nil
                self.cachedLocalizedPostToRead = nil
                return
            }
            showLoadedArticle(prePost: localizedPrePost, postToRead: cachedLocalizedPostToRead)
            return
        }

        Task {
            do {
                await MainActor.run {
                    withAnimation {
                        viewModel.isOriginalArticleLoading = true
                    }
                }

                let loadedLocalizedPrePost: PrePost

                if let localizedPrePost {
                    loadedLocalizedPrePost = localizedPrePost
                } else if let loadedPrePost = try await loadPreferredLocalizedPrePost() {
                    loadedLocalizedPrePost = loadedPrePost
                } else {
                    await MainActor.run {
                        withAnimation {
                            viewModel.isOriginalArticleLoading = false
                        }
                    }
                    return
                }

                let localizedPostToRead = try await ArticlesManager.shared.getPostToRead(id: loadedLocalizedPrePost.id)

                await MainActor.run {
                    withAnimation {
                        localizedPrePost = loadedLocalizedPrePost
                        cachedLocalizedPostToRead = localizedPostToRead
                        localizedArticleLanguage = formattedLanguageCode(loadedLocalizedPrePost.originalLanguage)
                        showLoadedArticle(prePost: loadedLocalizedPrePost, postToRead: localizedPostToRead)
                        viewModel.isOriginalArticleLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    withAnimation {
                        viewModel.isOriginalArticleLoading = false
                        viewModel.errorText = error.localizedDescription
                        viewModel.isErrorPopupPresented = true
                    }
                }
            }
        }
    }

    func showLoadedArticle(prePost: PrePost, postToRead: PostToRead) {
        countViewForSwitchedArticleIfNeeded(prePost)

        currentPrePost = prePost
        currentPostToRead = postToRead
        viewModel.likesCount = prePost.likesCount ?? 0
        viewModel.isPostLiked = (user?.likedPosts ?? []).contains(prePost.id)
        viewModel.currentIndex = 0
        viewModel.selectedImageURL = nil
    }

    func countViewForSwitchedArticleIfNeeded(_ prePost: PrePost) {
        guard !viewedArticleIdsInReadSession.contains(prePost.id) else { return }
        guard prePost.authorId != user?.userId else { return }

        viewedArticleIdsInReadSession.insert(prePost.id)

        Task {
            try? await ArticlesManager.shared.updateViews(at: prePost.id)
        }
    }

    func loadPreferredLocalizedPrePost() async throws -> PrePost? {
        let localizedVersions = try await ArticlesManager.shared.getLocalizedVersions(rootId: id)
            .filter { !($0.isArchive ?? false) }

        let preferredLanguage = preferredArticleLanguage

        return localizedVersions.first {
            formattedLanguageCode($0.originalLanguage).lowercased() == preferredLanguage
        } ?? localizedVersions.first
    }

    var displayedOriginalArticleLanguage: String {
        if !isLocalizedVersion {
            return formattedLanguageCode(articleLanguage)
        }

        let currentLanguage = formattedLanguageCode(currentPrePost?.originalLanguage)

        if !currentLanguage.isEmpty {
            return currentLanguage
        }

        return originalArticleLanguage
    }

    var displayedLocalizedArticleLanguage: String {
        let currentLanguage = formattedLanguageCode(currentPrePost?.originalLanguage)

        if !currentLanguage.isEmpty && (currentPrePost?.isLocalizedVersion ?? false) {
            return currentLanguage
        }

        return localizedArticleLanguage
    }

    var preferredArticleLanguage: String {
        let fallbackLanguage = Locale.preferredLanguages.first?.components(separatedBy: "-").first == "ru"
            ? "ru"
            : "en"

        let userLanguage = user?.originalLanguage?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: "-")
            .first
            .map(String.init)?
            .lowercased()

        return (userLanguage?.isEmpty == false ? userLanguage : nil) ?? fallbackLanguage
    }

    func formattedLanguageCode(_ language: String?) -> String {
        language?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: "-")
            .first
            .map(String.init)?
            .uppercased() ?? ""
    }

    func loadOriginalArticleLanguageIfNeeded() async {
        guard isLocalizedVersion, !currentRootId.isEmpty, displayedOriginalArticleLanguage.isEmpty else { return }

        do {
            let loadedOriginalPrePost: PrePost

            if let originalPrePost {
                loadedOriginalPrePost = originalPrePost
            } else {
                loadedOriginalPrePost = try await ArticlesManager.shared.getPrePost(id: currentRootId)
            }

            let canOpenOriginalArticle = !(loadedOriginalPrePost.isArchive ?? false)

            await MainActor.run {
                originalArticleCanBeOpened = canOpenOriginalArticle

                if canOpenOriginalArticle {
                    cachedOriginalPrePost = loadedOriginalPrePost
                    originalArticleLanguage = formattedLanguageCode(loadedOriginalPrePost.originalLanguage)
                } else {
                    cachedOriginalPrePost = nil
                    cachedOriginalPostToRead = nil
                    originalArticleLanguage = ""
                }
            }
        } catch {
            await MainActor.run {
                originalArticleCanBeOpened = false
                viewModel.errorText = error.localizedDescription
                viewModel.isErrorPopupPresented = true
            }
        }
    }

    func loadLocalizedArticleIfNeeded() async {
        guard !isLocalizedVersion, localizedPrePost == nil else { return }

        do {
            guard let localizedPrePost = try await loadPreferredLocalizedPrePost() else { return }

            await MainActor.run {
                self.localizedPrePost = localizedPrePost
                localizedArticleLanguage = formattedLanguageCode(localizedPrePost.originalLanguage)
            }
        } catch {
            await MainActor.run {
                viewModel.errorText = error.localizedDescription
                viewModel.isErrorPopupPresented = true
            }
        }
    }
}

private extension View {
    @ViewBuilder
    func hiddenReadContentOnScreenshots(_ isHidden: Bool) -> some View {
        if isHidden {
            mask {
                ReadViewScreenShotPreventerMask()
            }
        } else {
            self
        }
    }
}

private struct ReadViewScreenShotPreventerMask: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UITextField()
        view.isSecureTextEntry = true
        view.text = ""
        view.isUserInteractionEnabled = false

        if let autoHideLayer = findAutoHideLayer(view: view) {
            autoHideLayer.backgroundColor = UIColor.white.cgColor
        } else {
            view.layer.sublayers?.last?.backgroundColor = UIColor.white.cgColor
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let autoHideLayer = findAutoHideLayer(view: uiView) {
            autoHideLayer.backgroundColor = UIColor.white.cgColor
        } else {
            uiView.layer.sublayers?.last?.backgroundColor = UIColor.white.cgColor
        }
    }

    private func findAutoHideLayer(view: UIView) -> CALayer? {
        guard let layers = view.layer.sublayers else { return nil }

        return layers.first { layer in
            String(describing: layer.delegate).contains("UITextLayoutCanvasView")
        }
    }
}

private extension ReadView {
    var principalToolView: some View {
        HStack(spacing: 0) {
            if let avatar = viewModel.avatarImage {
                Image(uiImage: avatar)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 35, height: 35)
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .stroke(
                                Color(.label),
                                lineWidth: 0.1
                            )
                    }
                    .padding(.trailing, authorName == "" ? 0 : 2)
            }

            if authorName != "" {
                Text(authorName)
                    .font(.system(size: 17))
            }


            if isCheckmark {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(Color.blue)
                    .font(.system(size: 10))
            }
        }
    }
}

//class TextViewDelegate: NSObject, UITextViewDelegate {
//    var didChangeHeight: ((CGFloat) -> Void)?
//
//    func textViewDidChange(_ textView: UITextView) {
//        // Отправляем высоту контента
//        let height = textView.contentSize.height
//        didChangeHeight?(height)
//    }
//}
//
//
//struct MarkdownText: UIViewRepresentable {
//    @Binding var contentHeight: CGFloat
//    @Binding var fontSize: Int
//    let markdownText: String
//
//    // Создаем UITextView для отображения Markdown текста
//    func makeUIView(context: Context) -> UITextView {
//        let textView = UITextView()
//        textView.isEditable = false
//        textView.isSelectable = false
//        textView.backgroundColor = .clear
//        textView.delegate = context.coordinator // Связываем делегата
//        textView.isScrollEnabled = true
//        textView.textContainer.lineBreakMode = .byWordWrapping // Разрывы строк по словам
//        textView.textContainerInset = .zero // Убираем отступы
//        textView.layoutManager.allowsNonContiguousLayout = false
//        textView.translatesAutoresizingMaskIntoConstraints = false
//        textView.font = .systemFont(ofSize: CGFloat(fontSize))
//        return textView
//    }
//
//    // Обновляем UI с атрибутированным текстом
//    func updateUIView(_ uiView: UITextView, context: Context) {
//        let markdownString = SwiftyMarkdown(string: markdownText)
//
//        markdownString.bold.fontSize = CGFloat(fontSize)
//        markdownString.body.fontSize = CGFloat(fontSize)
//        markdownString.body.fontStyle = .bold
//        markdownString.blockquotes.fontSize = CGFloat(fontSize)
//        markdownString.italic.fontSize = CGFloat(fontSize)
//        markdownString.code.fontSize = CGFloat(fontSize)
//        markdownString.strikethrough.fontSize = CGFloat(fontSize)
//        markdownString.link.fontSize = CGFloat(fontSize)
//        markdownString.h1.fontSize = CGFloat(fontSize)
//        markdownString.h2.fontSize = CGFloat(fontSize)
//        markdownString.h3.fontSize = CGFloat(fontSize)
//        markdownString.h4.fontSize = CGFloat(fontSize)
//        markdownString.h5.fontSize = CGFloat(fontSize)
//        markdownString.h6.fontSize = CGFloat(fontSize)
//
//
//        UIView.transition(with: uiView, duration: 0.3, options: .curveEaseIn, animations: {
//            uiView.attributedText = markdownString.attributedString()
//        }, completion: nil)
//
//        uiView.sizeToFit()
//
//        DispatchQueue.main.async {
//            self.contentHeight = uiView.contentSize.height // Обновляем высоту
//        }
//    }
//
//    func makeCoordinator() -> TextViewDelegate {
//        let coordinator = TextViewDelegate()
//        coordinator.didChangeHeight = { height in
//            self.contentHeight = height // Обновляем высоту
//        }
//
//        return coordinator
//    }
