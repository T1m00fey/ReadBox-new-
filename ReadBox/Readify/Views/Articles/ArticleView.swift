//
//  ArtcleView.swift
//  Readify
//
//  Created by Тимофей Юдин on 05.11.2024.
//

import SwiftUI
import FirebaseStorage
import AVFoundation
import SwiftfulLoadingIndicators
import UIKit

struct ArticleView: View {
    let id: String
    let title: String
    let authorId: String
    let authorName: String
    let dateCreated: Date?
    let isCheckmark: Bool
    let isArchive: Bool
    let isShortPost: Bool
    let mediaCount: Int
    let mediaVersion: Int
    let mediaPosition: Int
    let lastVersionOfAvatar: Int
    let locCount: Int
    let isCreatedView: Bool
    let isLocalizedVersion: Bool
    let isPremiumPost: Bool
    let viewsCount: Int
    let likesCount: Int
    let commentsCount: Int
    let replyAuthorName: String?
    let onReplyTap: (() -> Void)?
    let onCommentTap: (() -> Void)?
    let isReplyMenuVisible: Bool
    let onDeleteReply: (() -> Void)?
    let exportMediaImage: UIImage?

    @Binding var user: DBUser?
    @Binding var isZoomableViewPresented: Bool
    @Binding var zoomableImage: UIImage?
    @Binding var selectedAuthorId: String
    @Binding var isChannelViewPresented: Bool
    @Binding var postOption: PostOptions
    @Binding var selectedId: String

    @State private var videoURL: URL? = nil
    @State private var avatarImage: UIImage? = nil
    @State private var isExpanded = false
    @State private var isLiked = false
    @State private var currentIndex = 0
    @State private var effectiveMediaCount = 0
    @State private var isSharePopupPresented = false

    @State private var images: [MediaKind?] = []

    @EnvironmentObject var sessionManager: SessionManager
    @EnvironmentObject var subscriptionMnaager: SubscriptionManager
    @Environment(\.colorScheme) private var colorScheme

    private let maxTitleLen = 250

    init(
        id: String,
        title: String,
        authorId: String,
        authorName: String,
        dateCreated: Date? = nil,
        isCheckmark: Bool,
        isArchive: Bool,
        isShortPost: Bool,
        mediaCount: Int,
        mediaVersion: Int,
        mediaPosition: Int,
        lastVersionOfAvatar: Int,
        locCount: Int,
        isCreatedView: Bool = false,
        isLocalizedVersion: Bool,
        isPremiumPost: Bool,
        viewsCount: Int = 0,
        likesCount: Int = 0,
        commentsCount: Int = 0,
        replyAuthorName: String? = nil,
        onReplyTap: (() -> Void)? = nil,
        onCommentTap: (() -> Void)? = nil,
        isReplyMenuVisible: Bool = false,
        onDeleteReply: (() -> Void)? = nil,
        exportMediaImage: UIImage? = nil,
        user: Binding<DBUser?>,
        isZoomableViewPresented: Binding<Bool>,
        zoomableImage: Binding<UIImage?>,
        selectedAuthorId: Binding<String>,
        isChannelViewPresented: Binding<Bool>,
        postOption: Binding<PostOptions> = .constant(.nothing),
        selectedId: Binding<String> = .constant("")
    ) {
        self.id = id
        self.title = title
        self.authorId = authorId
        self.authorName = authorName
        self.dateCreated = dateCreated
        self.isCheckmark = isCheckmark
        self.isArchive = isArchive
        self.isShortPost = isShortPost
        self.mediaCount = mediaCount
        self.mediaVersion = mediaVersion
        self.mediaPosition = mediaPosition
        self.lastVersionOfAvatar = lastVersionOfAvatar
        self.locCount = locCount
        self.isCreatedView = isCreatedView
        self.isLocalizedVersion = isLocalizedVersion
        self.isPremiumPost = isPremiumPost
        self.viewsCount = viewsCount
        self.likesCount = likesCount
        self.commentsCount = commentsCount
        self.replyAuthorName = replyAuthorName
        self.onReplyTap = onReplyTap
        self.onCommentTap = onCommentTap
        self.isReplyMenuVisible = isReplyMenuVisible
        self.onDeleteReply = onDeleteReply
        self.exportMediaImage = exportMediaImage
        self._user = user
        self._isZoomableViewPresented = isZoomableViewPresented
        self._zoomableImage = zoomableImage
        self._selectedAuthorId = selectedAuthorId
        self._isChannelViewPresented = isChannelViewPresented
        self._postOption = postOption
        self._selectedId = selectedId
        self._effectiveMediaCount = State(initialValue: mediaCount)
        self._isLiked = State(
            initialValue: user.wrappedValue?.likedPosts?.contains(id) ?? false
        )
        self._avatarImage = State(
            initialValue: StorageManager.shared.getImage(
                id: "avatar_\(authorId)_\(lastVersionOfAvatar)"
            )
        )
    }

    private func isAccessToPremiumDenied() -> Bool {
        isPremiumPost && !subscriptionMnaager.hasPremium && authorId != user?.userId
    }

    private func updateLike() async throws {
        let likesCount = try await ArticlesManager.shared.getLikesCount(byPostId: id)

        if isLiked {
            withAnimation {
                isLiked.toggle()
            }
            VibrationsService.shared.lightImpact()

            try await UserManager.shared.removeLikedPost(id: user?.userId ?? "", likedPost: id)
            try await ArticlesManager.shared.updateLikes(at: id, likesCount: likesCount - 1)

            user?.likedPosts?.removeAll {
                $0 == id
            }
        } else {
            withAnimation {
                isLiked.toggle()
            }
            VibrationsService.shared.lightImpact()

            AnalyticsManager.shared.logArticleLike(
                id: id,
                contentType: isShortPost ? "post" : "article",
                source: "unknown"
            )

            try await UserManager.shared.addLikedPost(id: user?.userId ?? "", likedPost: id)
            try await ArticlesManager.shared.updateLikes(at: id, likesCount: likesCount + 1)

            user?.likedPosts?.append(id)
        }
    }

    var body: some View {

        VStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .bottom) {
                    if shouldReserveAvatarSlot {
                        avatarSlotView
                    }

                    HStack(spacing: authorSectionSpacing) {
                        VStack(alignment: .leading, spacing: authorTextStackSpacing) {
                            if let replyTitle {
                                Text(replyTitle)
                                    .font(.system(size: replyTitleFontSize))
                                    .foregroundStyle(Color.gray)
                                    .lineLimit(1)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.bottom, isReplyArticleCard ? 0 : 1)
                                    .onTapGesture {
                                        onReplyTap?()
                                    }
                            }

                            HStack(spacing: 0) {
                                Text(authorName)
                                    .font(.system(size: authorNameFontSize))
                                //                            .font(.custom("Mulish", size: 18))
                                    .lineLimit(1)
//                                .underline()
//                                .bold()
                                    .fontWeight(.semibold)
                                    .onTapGesture {
                                        selectedAuthorId = authorId
                                        isChannelViewPresented = true
                                    }

                                if isCheckmark {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundStyle(Color.blue)
                                        .font(.system(size: authorCheckmarkFontSize))
                                        .padding(.top, 1)
                                }

                                if isReplyArticleCard, let articleDateText {
                                    Text(" · ")
                                        .font(.system(size: authorDateFontSize))
                                        .foregroundStyle(Color.gray)

                                    Text(articleDateText)
                                        .font(.system(size: authorDateFontSize))
                                        .foregroundStyle(Color.gray)
                                        .lineLimit(1)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            if !isReplyArticleCard, let articleDateText {
                                Text("\(articleDateText)")
                                    .font(.system(size: authorDateFontSize))
                                    .foregroundStyle(Color.gray)
                                    .lineLimit(1)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .offset(y: -1)

                        Spacer()

                        if isLocalizedVersion {
                            Image("translateIcon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 15)
                                .foregroundStyle(Color(.systemGray6))
                                .padding(.all, 5)
                                .background(Color(.systemGray4))
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                        }

                        if !isShortPost {
                            Text(NSLocalizedString("articleLabel", comment: ""))
                                .font(.system(size: 12))
                                .foregroundStyle(Color(.systemGray6))
                                .padding(.all, 5)
                                .background(Color(.systemGray4))
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                        }

                        if isPremiumPost {
    //                        Image(systemName: "plus")
    //                            .resizable()
    //                            .scaledToFit()
    //                            .frame(width: 15)
    //                            .foregroundStyle(Color(.label))
    //                            .padding(.all, 5)
    //                            .background(Color(.systemGray4))
    //                            .clipShape(RoundedRectangle(cornerRadius: 5))
                            Text("R+")
                                .font(.custom("PlaywriteIE-Regular", size: 12))
                                .foregroundStyle(Color(.systemGray6))
                                .frame(height: 15)
                                .padding(.all, 5)
                                .background(Color(.systemGray4))
                                .clipShape(RoundedRectangle(cornerRadius: 5))

                        }

                        if (isCreatedView && !isChannelViewPresented) || isReplyMenuVisible {
                            Menu {
                                if !isReplyMenuVisible {
                                    Button {
                                        postOption = .editing
                                        selectedId = id
                                    } label: {
                                        Label(NSLocalizedString("editingLabel", comment: ""), systemImage: "pencil")
                                    }

                                    Button {
                                        selectedId = id

                                        if isArchive {
                                            postOption = .publish
                                        } else {
                                            postOption = .toArchive
                                        }

                                    } label: {
                                        if isArchive {
                                            Label(NSLocalizedString("publishLabel", comment: ""), systemImage: "paperplane")
                                        } else {
                                            Label(NSLocalizedString("saveToArchiveLabel", comment: ""), systemImage: "archivebox")
                                        }
                                    }

                                    if locCount == 0 && !isLocalizedVersion {
                                        Button {
                                            postOption = .localize
                                            selectedId = id
                                        } label: {
                                            Label(NSLocalizedString("toLocalizeMenuActionLabel", comment: ""), systemImage: "globe")
                                        }
                                    }
                                }

                                Button {
                                    if isReplyMenuVisible {
                                        onDeleteReply?()
                                        return
                                    }

                                    postOption = .delete
                                    selectedId = id


                                    StorageManager.shared.deleteImage(id: id)
                                } label: {
                                    Label(NSLocalizedString("deleteLabel", comment: ""), systemImage: "xmark.circle")
                                }
                            } label: {
                                Image(systemName: "ellipsis")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 15, height: 15)
                                    .foregroundStyle(Color(.gray))
                                    .padding(.all, 5)
                                    .background(Color(.systemGray4))
                                    .clipShape(RoundedRectangle(cornerRadius: 5))
                            }
                        }
                    }
                }
            }
            .frame(width: UIScreen.main.bounds.width - 42, height: 40, alignment: .leading)
            .padding(.top, authorSectionTopPadding)
            .padding(.bottom, 2)
//            .padding(.vertical, 3)

            if mediaPosition == 1 && isShortPost && hasTitleText && !isAccessToPremiumDenied() {
                titleSectionView
            }

            if mediaCount > 0 {
                ZStack {
                    Group {
                        if let exportMediaImage {
                            Image(uiImage: exportMediaImage)
                                .resizable()
                                .scaledToFit()
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 23))
                                .frame(
                                    maxWidth: UIScreen.main.bounds.width - 25,
                                    maxHeight: 350,
                                    alignment: .leading
                                )
                        } else {
                            MediaViews(
                                id: id,
                                authorId: authorId,
                                mediaCount: effectiveMediaCount,
                                mediaVersion: mediaVersion,
                                zoomableImage: $zoomableImage,
                                isZoomableViewPresented: $isZoomableViewPresented,
                                currentIndex: $currentIndex
                            )
                            .id("\(id)-\(effectiveMediaCount)")
                        }
                    }
                    .padding(.bottom, mediaBottomPadding)
                    .blur(radius: isAccessToPremiumDenied() ? 10 : 0)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .disabled(isAccessToPremiumDenied())

                    if isAccessToPremiumDenied() {
                        subscriptionAlertView
                            .padding(.all, 10)
                            .background(.thinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                }
            } else if isAccessToPremiumDenied() {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .frame(width: UIScreen.main.bounds.width - 32, height: 200)
                        .foregroundStyle(Color("availableInRead+"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    Color(.systemGray5),
                                    lineWidth: 2
                                )
                        )

                    subscriptionAlertView
                }
                .padding(.bottom, 5)
            }

            ZStack {
                VStack(spacing: 0) {
//                    Text(title)
//                        .font(.system(size: 18))
//                        .lineLimit(!isExpanded && title.count >= maxTitleLen ? 4 : nil)
//                        .fontDesign(.rounded)
//                        .frame(width: UIScreen.main.bounds.width - 42, alignment: .leading)
//                        .padding(.bottom, isShortPost ? 10 : 20)
//                        .padding(.top, mediaCount == 0 && isChannelViewPresented ? 16 : 0)
//                        .padding(.bottom, !isExpanded && title.count >= maxTitleLen && isShortPost ? 10 : 0)
//                        .padding(.bottom, !isExpanded && title.count >= maxTitleLen ? 17 : 0)

                    if hasTitleText && (mediaPosition == 0 || !isShortPost) && !(isShortPost && isAccessToPremiumDenied() && isPremiumPost) {
                        titleSectionView
                            .padding(.top, titleSectionTopPadding)
                            .padding(.bottom, titleSectionBottomPadding)
                    }

                    if isShortPost || isCreatedView {
                        HStack(spacing: 12) {
                            if isShortPost {
                                Image(systemName: isLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                                    .foregroundStyle(Color.gray)
                                    .font(.system(size: 18))
                                    .onTapGesture {
                                        Task {
                                            do {
                                                try? await updateLike()
                                            }
                                        }
                                    }

                                if isCreatedView {
                                    Text("\(likesCount)")
                                        .font(.system(size: 14))
                                        .foregroundStyle(Color.gray)
                                        .fontDesign(.rounded)
                                        .padding(.leading, -7)
                                        .padding(.top, 5)
                                }

                                if let onCommentTap {
                                    Button(action: onCommentTap) {
                                        Image(systemName: "bubble.right")
                                            .foregroundStyle(Color.gray)
                                            .font(.system(size: 17))
                                    }
                                    .buttonStyle(.plain)

                                    if isCreatedView {
                                        Text("\(commentsCount)")
                                            .font(.system(size: 14))
                                            .foregroundStyle(Color.gray)
                                            .fontDesign(.rounded)
                                            .padding(.leading, -7)
                                            .padding(.top, 5)
                                    }
                                }

                                if isCreatedView {
                                    Button {
                                        presentSharePopup()
                                    } label: {
                                        Image(systemName: "arrowshape.turn.up.right")
                                            .foregroundStyle(Color.gray)
                                            .font(.system(size: 18))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            Spacer()

                            if isShortPost && !isCreatedView {
                                Button {
                                    presentSharePopup()
                                } label: {
                                    Image(systemName: "arrowshape.turn.up.right")
                                        .foregroundStyle(Color.gray)
                                        .font(.system(size: 18))
                                }
                                .buttonStyle(.plain)
                            }

                            if isCreatedView {
                                HStack(spacing: 10) {
                                    if !isShortPost {
                                        HStack(spacing: 2) {
                                            Text("\(commentsCount)")
                                                .font(.system(size: 13))
                                                .fontDesign(.rounded)
                                                .foregroundStyle(Color.gray)

                                            Image(systemName: "bubble.right")
                                                .foregroundStyle(Color.gray)
                                                .font(.system(size: 15))
                                        }

                                        HStack(spacing: 2) {
                                            Text("\(likesCount)")
                                                .font(.system(size: 13))
                                                .fontDesign(.rounded)
                                                .foregroundStyle(Color.gray)

                                            Image(systemName: "hand.thumbsup")
                                                .foregroundStyle(Color.gray)
                                                .font(.system(size: 15))
                                        }
                                    }

                                    HStack(spacing: 2) {
                                        Text("\(viewsCount)")
                                            .font(.system(size: 13))
                                            .fontDesign(.rounded)
                                            .foregroundStyle(Color.gray)

                                        Image(systemName: "eye.fill")
                                            .foregroundStyle(Color.gray)
                                            .font(.system(size: 15))
                                    }
                                }
                                .padding(.trailing, -10)
                                .padding(.top, isShortPost ? 10 : -10)
                            }
                        }
                        .padding(.bottom, 15)
                        .frame(width: UIScreen.main.bounds.width - 50, alignment: .leading)
                    }
                }

            }

        }
        .onReceive(NotificationCenter.default.publisher(for: .postMediaDidUpdate)) { note in
            guard let pid = note.userInfo?["postId"] as? String, pid == id else { return }
            if let newCount = note.userInfo?["mediaCount"] as? Int {
                effectiveMediaCount = newCount
            }
        }
        .frame(width: UIScreen.main.bounds.width - 10)
        .background(
            RoundedRectangle(cornerRadius: 23)
                .foregroundStyle(articleBackgroundColor)
//                .shadow(radius: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 23)
                .stroke(
                    Color(.secondarySystemBackground),
                    lineWidth: 2
                )
        )
        .onAppear {
            if let user, let likedPosts = user.likedPosts {
                isLiked = likedPosts.contains(id)
            }
        }
        .onAppear {
            effectiveMediaCount = mediaCount
        }
        .task(id: "\(authorId)_\(lastVersionOfAvatar)") {
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

            avatarImage = ava
        }
        .sheet(isPresented: $isSharePopupPresented) {
            SharePublicationView(
                articleView: shareArticleView,
                url: shareURL
            )
            .presentationCornerRadius(30)
            .presentationDragIndicator(.visible)
        }
        .hiddenOnScreenshots(isPremiumPost)
    }
}

private extension ArticleView {
    var shareURL: URL {
        URL(string: "https://readbox.online/posts/?index=\(id)")!
    }

    var shareArticleView: ArticleView {
        ArticleView(
            id: id,
            title: title,
            authorId: authorId,
            authorName: authorName,
            dateCreated: dateCreated,
            isCheckmark: isCheckmark,
            isArchive: isArchive,
            isShortPost: isShortPost,
            mediaCount: mediaCount,
            mediaVersion: mediaVersion,
            mediaPosition: mediaPosition,
            lastVersionOfAvatar: lastVersionOfAvatar,
            locCount: locCount,
            isCreatedView: false,
            isLocalizedVersion: isLocalizedVersion,
            isPremiumPost: isPremiumPost,
            likesCount: likesCount,
            commentsCount: commentsCount,
            onCommentTap: {},
            exportMediaImage: shareMediaImage,
            user: .constant(user),
            isZoomableViewPresented: .constant(false),
            zoomableImage: .constant(nil),
            selectedAuthorId: .constant(""),
            isChannelViewPresented: .constant(false)
        )
    }

    var shareMediaImage: UIImage? {
        StorageManager.shared.getImage(id: "\(id)_0")
            ?? StorageManager.shared.getImage(id: "\(id)_0_preview")
            ?? StorageManager.shared.getImage(id: id)
    }

    func presentSharePopup() {
        AnalyticsManager.shared.logPublicationShared(
            id: id,
            contentType: isShortPost ? "post" : "article",
            source: "card"
        )
        isSharePopupPresented = true
    }
}

private extension View {
    @ViewBuilder
    func hiddenOnScreenshots(_ isHidden: Bool) -> some View {
        if isHidden {
            mask {
                ScreenShotPreventerMask()
            }
        } else {
            self
        }
    }
}

private struct ScreenShotPreventerMask: UIViewRepresentable {
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

private extension ArticleView {
    var articleBackgroundColor: Color {
        colorScheme == .dark
        ? Color(red: 0.08, green: 0.08, blue: 0.085)
        : Color(red: 0.975, green: 0.975, blue: 0.98)
    }

    var shouldReserveAvatarSlot: Bool {
        lastVersionOfAvatar > 0 || avatarImage != nil
    }

    var avatarSlotView: some View {
        ZStack {
            Circle()
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    Circle()
                        .stroke(Color(.label), lineWidth: 0.1)
                )

            if let avatarImage {
                Image(uiImage: avatarImage)
                    .resizable()
                    .scaledToFill()
            }
        }
        .frame(width: authorAvatarSize, height: authorAvatarSize)
        .clipShape(Circle())
        .contentShape(Circle())
        .onTapGesture {
            if let avatarImage {
                withAnimation {
                    zoomableImage = avatarImage
                    isZoomableViewPresented = true
                }
            }
        }
    }

    var articleDateText: String? {
        guard let dateCreated else { return nil }
        return formattedArticleDate(dateCreated)
    }

    var titleSectionView: some View {
        ZStack(alignment: .bottomTrailing) {
            titleView
                .padding(.bottom, shouldShowExpandButton ? 24 : 0)

            if shouldShowExpandButton {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(
                                colors: [Color.clear, articleBackgroundColor]
                            ),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: UIScreen.main.bounds.width - 38, height: 50)
                    .allowsHitTesting(false)

                Text(NSLocalizedString("expandButtonLabel", comment: ""))
                    .font(.system(size: 16))
                    .fontDesign(.rounded)
                    .foregroundStyle(.gray)
                    .padding(.trailing, 8)
                    .padding(.bottom, 4)
                    .onTapGesture {
                        withAnimation {
                            isExpanded = true
                        }
                    }
            }
        }
        .frame(width: UIScreen.main.bounds.width - 42, alignment: .leading)
    }

    var shouldShowExpandButton: Bool {
        !isExpanded && title.count >= maxTitleLen
    }

    var hasTitleText: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var hasMediaContent: Bool {
        return mediaCount > 0
    }

    var isTextOnlyPost: Bool {
        !hasMediaContent && hasTitleText
    }

    var hasReplyTitle: Bool {
        replyTitle != nil
    }

    var authorSectionTopPadding: CGFloat {
        isTextOnlyPost && hasReplyTitle ? 10 : 12
    }

    var isReplyArticleCard: Bool {
        hasReplyTitle
    }

    var authorAvatarSize: CGFloat {
        40
    }

    var authorSectionSpacing: CGFloat {
        5
    }

    var authorTextStackSpacing: CGFloat {
        isReplyArticleCard ? 0 : 1
    }

    var authorNameFontSize: CGFloat {
        16
    }

    var authorDateFontSize: CGFloat {
        11
    }

    var authorCheckmarkFontSize: CGFloat {
        14
    }

    var replyTitleFontSize: CGFloat {
        12
    }

    var mediaBottomPadding: CGFloat {
        if mediaPosition == 1 && isShortPost && hasTitleText {
            return 10
        }

        if isShortPost && !hasTitleText {
            return 5
        }

        return 0
    }

    var titleSectionBottomPadding: CGFloat {
        return shouldShowExpandButton ? 0 : (isShortPost ? 10 : 20)
    }

    var titleSectionTopPadding: CGFloat {
        if hasMediaContent {
            return 6
        }

        return 0
    }

    var titleAttributedString: AttributedString {
        var attributedString = title.markdownAttributedStringPreservingLineBreaks

        for run in attributedString.runs where run.link != nil {
            attributedString[run.range].foregroundColor = .blue
            attributedString[run.range].underlineStyle = .single
        }

        return attributedString
    }

    var replyTitle: String? {
        let name = replyAuthorName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !name.isEmpty else { return nil }

        return "\(NSLocalizedString("replyToLabel", comment: "")) \(name)"
    }

    var titleView: some View {
        Text(titleAttributedString)
            .font(.system(size: 17))
//            .font(.custom("ChironGoRoundTC", size: 17))
            .lineLimit(!isExpanded && title.count >= maxTitleLen ? 4 : nil)
//            .fontDesign(.rounded)
            .frame(width: UIScreen.main.bounds.width - 42, alignment: .leading)
    }

    var subscriptionAlertView: some View {
        VStack(spacing: 1) {
            Text(LocalizedStringKey("availableOnlyWithLabel"))
                .font(.system(size: 16))
                .fontDesign(.rounded)
                .foregroundStyle(Color(.gray))


            Text("Read+")
//                                    .font(.custom("PlaywriteIE-Regular", size: 28))
                .font(.custom("Borel-Regular", size: 28))
                .foregroundStyle(Color(.gray))
                .padding(.bottom, -20)
        }
    }

    func formattedArticleDate(_ date: Date) -> String {
        let now = Date()
        let seconds = max(0, Int(now.timeIntervalSince(date)))
        let minute = 60
        let hour = 60 * minute
        let day = 24 * hour

        if seconds < hour {
            return relativeArticleDate(value: max(1, seconds / minute), ruForms: ("минуту", "минуты", "минут"), enUnit: "minute")
        } else if seconds < day {
            return relativeArticleDate(value: seconds / hour, ruForms: ("час", "часа", "часов"), enUnit: "hour")
        } else if seconds < 31 * day {
            return relativeArticleDate(value: seconds / day, ruForms: ("день", "дня", "дней"), enUnit: "day")
        }

        if Calendar.current.isDate(date, equalTo: now, toGranularity: .year) {
            return formattedDate(date, format: isRussianLanguage ? "d MMMM" : "MMM d")
        }

        return formattedDate(date, format: "dd.MM.yy")
    }

    func relativeArticleDate(value: Int, ruForms: (one: String, few: String, many: String), enUnit: String) -> String {
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

    func formattedDate(_ date: Date, format: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: isRussianLanguage ? "ru_RU" : "en_US")
        formatter.dateFormat = format
        return formatter.string(from: date)
    }

    var isRussianLanguage: Bool {
        StorageManager.shared.getLanguage() == "ru"
    }
}
