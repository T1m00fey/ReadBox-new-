//
//  ChannelView.swift
//  Readify
//
//  Created by Тимофей Юдин on 31.03.2025.
//

import SwiftUI
import PopupView
import SwiftfulLoadingIndicators
import Shimmer
import FirebaseStorage

struct ChannelView: View {
    @StateObject private var viewModel = ChannelViewModel()
    @Namespace private var channelPostsTabsNamespace

    @Environment(\.dismiss) var dismiss

    @Binding var user: DBUser?

    let authorId: String
    let authorName: String
    let isCheckmark: Bool
    let lastVersionOfAvatar: Int
    @Binding var isPremiumViewPresented: Bool

    @EnvironmentObject var sessionManager: SessionManager
    @EnvironmentObject var changedPostsManager: ChangedPostsManager
    @EnvironmentObject var subManager: SubscriptionManager

    private func un_subscribe(isSubscribed: Bool) {
        if !viewModel.isSubscribeLoading {
            Task {
                do {
                    withAnimation {
                        viewModel.isSubscribeLoading = true
                    }

                    try await viewModel.un_subscribeUser(on: authorId, isNeedToSubscribe: isSubscribed ? false : true)

                    if isSubscribed {
                        VibrationsService.shared.lightImpact()
                    } else {
                        VibrationsService.shared.successFeedback()
                    }

                    withAnimation {
                        if isSubscribed {
                            user?.subscribes?.removeAll { $0 == authorId }
                        } else {
                            user?.subscribes?.append(authorId)
                        }

                        viewModel.isSubscribed?.toggle()
                        viewModel.subscribersCount += isSubscribed ? -1 : 1
                    }

                    viewModel.pushRoute = await decidePushRoute()

                    withAnimation {
                        viewModel.isSubscribeLoading = false
                    }

                    guard let route = viewModel.pushRoute else { return }

                    if !isSubscribed && route != .ok {
                        viewModel.isNotificationPopupPresented = true
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

    var body: some View {
        ZStack {

            Color(uiColor: .systemBackground)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 10) {
                    headerView
                    publicationsSection

                    //                        if !viewModel.isLoading && !viewModel.isAllLoading && viewModel.posts.count >= 20 {
                    //                            Button {
                    //                                Task {
                    //                                    do {
                    //                                        try await viewModel.loadPosts(by: authorId)
                    //                                        return
                    //                                    } catch {
                    //                                        withAnimation {
                    //                                            viewModel.errorText = error.localizedDescription
                    //                                        }
                    //                                    }
                    //
                    //                                    viewModel.isErrorPopupPresented = true
                    //                                }
                    //                            } label: {
                    //                                HStack {
                    //                                    Image(systemName: "arrow.down")
                    //                                        .foregroundStyle(Color(uiColor: .label))
                    //                                        .font(.title3)
                    //                                        .fontWeight(.light)
                    //
                    //                                    Text(LocalizedStringKey("loadMore"))
                    //                                        .font(.title3)
                    //                                        .fontDesign(.rounded)
                    //                                        .fontWeight(.light)
                    //                                }
                    //                                .padding(.horizontal, 16)
                    //                                .padding(.vertical, 10)
                    //                                .background(Color(uiColor: .secondarySystemBackground))
                    //                                .clipShape(RoundedRectangle(cornerRadius: 10))
                    //                                .shadow(radius: 2)
                    //                                .padding(.top, 20)
                    //                            }
                    //                            .padding(.bottom, 10)
                    //                        }

                }
                .padding(.horizontal)

            }
            .coordinateSpace(name: "readScroll")
            .onPreferenceChange(VisibilityPreferenceKey.self) { values in
                if let minY = values["publicationsLabel"] {
                    let isVisible = minY > -20
                    print("TRECCECEC: \(minY)")

                    if viewModel.isPublicationsLabelVisible != isVisible {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.isPublicationsLabelVisible = isVisible
                        }
                    }
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
                    .padding(.top, 20)
            } customize: {
                $0
                    .type(.floater())
                    .position(.top)
                    .animation(.bouncy)
                    .dragToDismiss(true)
                    .autohideIn(5)
                    .displayMode(.overlay)
            }
            .sheet(isPresented: $viewModel.isLoadingPopupPresented, content: {
                LoadingPopup()
                    .presentationDetents([.height(150)])
                    .presentationCornerRadius(30)
                    .presentationDragIndicator(.visible)
            })
//            .popup(isPresented: $viewModel.isNotificationPopupPresented) {
//                NotificationPermissionView(
//                    isPopupPresented: $viewModel.isNotificationPopupPresented,
//                    route: viewModel.pushRoute ?? .goToSettings
//                )
//                .shadow(radius: 2)
//            } customize: {
//                $0
//                    .type(.toast)
//                    .appearFrom(.bottomSlide)
//                    .dragToDismiss(true)
//                    .displayMode(.sheet)
//            }
            .sheet(isPresented: $viewModel.isNotificationPopupPresented, content: {
                NotificationPermissionView(
                    isPopupPresented: $viewModel.isNotificationPopupPresented,
                    route: viewModel.pushRoute ?? .goToSettings
                )
                .presentationDetents([.height(250)])
                .presentationCornerRadius(30)
                .presentationDragIndicator(.visible)
            })
            .fullScreenCover(isPresented: $viewModel.isZoomableImageViewPresented) {
                if let image = viewModel.zoomableImage {
                    ZoomableImageView(image: image)
                }
            }
            .navigationDestination(isPresented: $viewModel.isReadViewPresented, destination: {
                ReadView(
                    id: viewModel.postToView?.id ?? "",
                    title: viewModel.postToView?.title ?? "",
                    text: viewModel.postToRead?.text ?? "",
                    dateCreated: viewModel.postToRead?.dateCreated ?? Date(),
                    likesCount: viewModel.postToView?.likesCount ?? 0,
                    authorId: authorId,
                    authorName: authorName,
                    isCheckmark: isCheckmark,
                    isArchive: false,
                    mediaCount: viewModel.postToView?.mediaCount ?? 1,
                    mediaVersion: viewModel.postToView?.mediaVersion ?? 1,
                    mediaPosition: viewModel.postToView?.mediaPosition ?? 0,
                    lastVersionOfAvatar: lastVersionOfAvatar,
                    articleLanguage: viewModel.postToView?.originalLanguage ?? "",
                    isPremiumPost: viewModel.postToView?.isPremiumPost ?? false,
                    user: $user,
                    isChannelViewPresented: .constant(false),
                    isPresented: $viewModel.isReadViewPresented,
                    isLocalizedVersion: viewModel.postToView?.isLocalizedVersion ?? false,
                    rootId: viewModel.postToView?.rootId ?? "",
                    originalPrePost: originalPost(for: viewModel.postToView)
                )
                .environmentObject(sessionManager)
                .environmentObject(changedPostsManager)
                .environmentObject(subManager)
            })
            .onAppear(perform: {
                if !viewModel.isDataLoaded {
                    viewModel.isLoading = false
                    viewModel.authorId = authorId
                    viewModel.updatePrimaryLanguage(user: user)

                    viewModel.isSubscribed = viewModel.isSubscribed(user, on: authorId)

                    Task {
                        viewModel.isLoading = true

                        let ava = await MediaManager.shared.getAvatar(authorId: authorId, lastVersion: lastVersionOfAvatar)

                        withAnimation {
                            viewModel.avatarImage = ava
                        }

                        do {
                            try await viewModel.getAuthorDescription(id: authorId)
                            try await viewModel.getSubscribersCount(authorId: authorId)
                            try await viewModel.getPostsCount(authorId: authorId)
                        } catch {
                            withAnimation {
                                viewModel.errorText = error.localizedDescription
                                viewModel.isErrorPopupPresented = true
                            }
                        }
                    }

                    Task {
                        do {
                            try await viewModel.loadPosts(by: authorId)
                        } catch {
                            withAnimation {
                                viewModel.errorText = NSLocalizedString("loadDataErrorLabel", comment: "")
                                viewModel.isErrorPopupPresented = true
                            }
                        }
                    }

                    viewModel.isDataLoaded = true
                }
            })
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Image(systemName: "arrow.left")
                        .onTapGesture {
                            dismiss()
                        }
                }

                ToolbarItem(placement: .principal) {
                    toolbarTitleView
                }

                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: URL(string: "https://readbox-links.online/authors/?index=\(authorId)")!) {
                        Image(systemName: "arrowshape.turn.up.right")
                    }
                }
            }
            .refreshable {
                if !viewModel.isLoading {
                    withAnimation {
                        viewModel.isLoading = true
                        viewModel.isLoadingShowing = true
                        viewModel.isDataLoaded = false
                        viewModel.lastDocument = nil

                        viewModel.allPosts = []
                        viewModel.posts = []
                    }

                    viewModel.updatePrimaryLanguage(user: user)

                    Task {
                        let ava = await MediaManager.shared.getAvatar(authorId: authorId, lastVersion: lastVersionOfAvatar)

                        withAnimation {
                            viewModel.avatarImage = ava
                        }

                        do {
                            try await viewModel.getAuthorDescription(id: authorId)
                            try await viewModel.getSubscribersCount(authorId: authorId)
                            try await viewModel.getPostsCount(authorId: authorId)
                        } catch {
                            withAnimation {
                                viewModel.errorText = error.localizedDescription
                                viewModel.isErrorPopupPresented = true
                            }
                        }
                    }

                    Task {
                        do {
                            try await viewModel.loadPosts(by: authorId)
                            viewModel.isDataLoaded = true
                        } catch {
                            withAnimation {
                                viewModel.errorText = NSLocalizedString("loadDataErrorText", comment: "")
                                viewModel.isErrorPopupPresented = true
                            }
                        }
                    }
                }
            }

//                VStack {
//                    headerView
//
//                    Spacer()
//                }.ignoresSafeArea()

        }
        .navigationBarBackButtonHidden()
        .overlay(
            EnableSwipeBack()
                .frame(width: 0, height: 0)
        )
    }
}


private extension ChannelView {
    @ViewBuilder
    var publicationsSection: some View {
        if viewModel.isLoading {
            ForEach(0..<3, id: \.self) { num in
                loadingPostPlaceholder(index: num)
            }
        } else if !viewModel.currentPosts.isEmpty {
            ForEach(viewModel.currentPosts) { post in
                postRow(post)
            }
        } else {
            noPostsView
        }
    }

    func loadingPostPlaceholder(index: Int) -> some View {
        ArticleView(
            id: "-1",
            title: "Hello, World!",
            authorId: "",
            authorName: "",
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
        .padding(.top, index == 0 ? 10 : 0)
        .padding(.bottom, index == 6 ? 100 : 0)
        .shimmering()
    }

    func postRow(_ post: PrePost) -> some View {
        ArticleView(
            id: post.id,
            title: post.title ?? NSLocalizedString("notFoundLabel", comment: ""),
            authorId: post.authorId ?? "",
            authorName: authorName,
            isCheckmark: isCheckmark,
            isArchive: false,
            isShortPost: post.isShortPost ?? false,
            mediaCount: post.mediaCount ?? 1,
            mediaVersion: post.mediaVersion ?? 1,
            mediaPosition: post.mediaPosition ?? 0,
            lastVersionOfAvatar: lastVersionOfAvatar,
            locCount: post.localizationCount ?? 0,
            isLocalizedVersion: post.isLocalizedVersion ?? false,
            isPremiumPost: post.isPremiumPost ?? false,
            user: $user,
            isZoomableViewPresented: $viewModel.isZoomableImageViewPresented,
            zoomableImage: $viewModel.zoomableImage,
            selectedAuthorId: .constant(""),
            isChannelViewPresented: .constant(true)
        )
        .padding(.bottom, post.id == viewModel.currentPosts.last?.id ? 100 : 0)
        .padding(.top, 10)
        .onAppear {
            if post.id == viewModel.currentPosts.last?.id, !viewModel.isAllLoading {
                Task {
                    try? await viewModel.loadPosts(by: authorId)
                }
            }
        }
        .onTapGesture {
            handlePostTap(post)
        }
    }

    var noPostsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "pencil.and.scribble")
                .resizable()
                .scaledToFit()
                .frame(width: 100, alignment: .center)
                .foregroundStyle(Color.gray)

            Text(LocalizedStringKey("noArticlesAddedLabel"))
                .font(.title)
                .bold()
                .fontDesign(.rounded)
                .foregroundStyle(Color.gray)
                .multilineTextAlignment(.center)
                .frame(width: UIScreen.main.bounds.width - 32)
        }
        .frame(height: UIScreen.main.bounds.height - 200, alignment: .center)
        .padding(.top, -150)
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

    func selectChannelPostsSection(_ section: ChannelPostsSection) {
        viewModel.showSection(section)

        Task {
            await viewModel.loadCurrentSectionUntilAvailableIfNeeded(authorId: authorId)
        }
    }

    var channelPostsTabsView: some View {
        ZStack(alignment: .bottom) {
            Divider()
                .frame(width: UIScreen.main.bounds.width)

            VisibilityTracker(id: "publicationsLabel")

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 24) {
                        ForEach(ChannelPostsSection.allCases, id: \.self) { section in
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    selectChannelPostsSection(section)
                                    proxy.scrollTo(section, anchor: .center)
                                }
                            } label: {
                                Group {
                                    if viewModel.isLoadingShowing {
                                        channelPostsTabLabel(for: section)
                                            .redacted(reason: .placeholder)
                                            .shimmering()
                                    } else {
                                        channelPostsTabLabel(for: section)
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
        .frame(width: UIScreen.main.bounds.width - 20)
        .background(Color(.systemBackground))
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: viewModel.currentSection)
    }

    func channelPostsTabLabel(for section: ChannelPostsSection) -> some View {
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
                        .matchedGeometryEffect(id: "channelPostsTabIndicator", in: channelPostsTabsNamespace)
                } else {
                    Color.clear
                        .frame(height: 3)
                }
            }
        }
    }

    func subscribeButtonView(isSubscribed: Bool) -> some View {
        Group {
            if !viewModel.isLoading {
                HStack {
                    if viewModel.isSubscribeLoading {
                        LoadingIndicator(
                            animation: .circleRunner,
                            color: Color(
                                isSubscribed
                                ? .label
                                : .systemBackground
                            ),
                            size: .small,
                            speed: .fast
                        )
                    } else {
                        Text(
                            isSubscribed
                            ? NSLocalizedString("youSubscribedLabel", comment: "")
                            : NSLocalizedString("subscribeLabel", comment: "")
                        )
                        .font(.system(size: 17))
                        .fontDesign(.rounded)
                        .foregroundStyle(
                            isSubscribed
                            ? Color(.label)
                            : Color(uiColor: .systemBackground)
                        )
                    }
                }
                .frame(width: UIScreen.main.bounds.width - 20, height: 35, alignment: .center)
                .background(
                    Capsule()
                        .foregroundStyle(
                            isSubscribed
                            ? AnyShapeStyle(.ultraThinMaterial)
                            : AnyShapeStyle(Color(.label))
                        )

                )
                .onTapGesture {
                    un_subscribe(isSubscribed: isSubscribed)
                }
            }
        }
    }

    func handlePostTap(_ post: PrePost) {
        if let isPremiumPost = post.isPremiumPost,
           isPremiumPost && !subManager.hasPremium,
           post.authorId != user?.userId {
            isPremiumViewPresented = true
            return
        }

        viewModel.isLoadingPopupPresented = true

        Task {
            do {
                let postToRead = try await ArticlesManager.shared.getPostToRead(id: post.id)

                viewModel.isLoadingPopupPresented = false

                viewModel.postToView = post

                viewModel.postToRead = PostToRead(
                    dateCreated: postToRead.dateCreated,
                    text: postToRead.text,
                    mediaURLs: postToRead.mediaURLs
                )

                viewModel.isReadViewPresented = true
            } catch {
                withAnimation {
                    viewModel.errorText = error.localizedDescription
                    viewModel.isErrorPopupPresented = true
                }
            }
        }

        viewModel.isLoadingPopupPresented = false
    }

    func originalPost(for post: PrePost?) -> PrePost? {
        guard
            let post,
            post.isLocalizedVersion ?? false,
            let rootId = post.rootId
        else {
            return nil
        }

        return viewModel.allPosts.first { $0.id == rootId }
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
                                viewModel.zoomableImage = avatar
                            }
                    }

                    VStack {
                        HStack(spacing: 0) {
                            Text(authorName)
                                .font(.system(size: 24))
                                .fontWeight(.light)
                                .lineLimit(1)

                            if isCheckmark {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundStyle(Color.blue)
                                    .font(.system(size: 14))
                                    .padding(.top, 1)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        if viewModel.isLoading {
                            HStack {
                                Text("100000 \(NSLocalizedString("subscribersCountLabel", comment: ""))")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.gray)
                                    .redacted(reason: .placeholder)
                                    .shimmering()

                                Text("•")
                                    .font(.system(size: 20))
                                    .foregroundStyle(Color.gray)

                                Text("100000 \(NSLocalizedString("publicationsCountLabel", comment: ""))")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.gray)
                                    .redacted(reason: .placeholder)
                                    .shimmering()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            HStack(spacing: 2) {
                                Text("\(viewModel.subscribersCount) \(NSLocalizedString("subscribersCountLabel", comment: ""))")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.gray)

                                Text("•")
                                    .font(.system(size: 20))
                                    .foregroundStyle(Color.gray)

                                Text("\(viewModel.postsCount) \(NSLocalizedString("publicationsCountLabel", comment: ""))")
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

//                if viewModel.isLoading {
//                    HStack {
//                        makeNumberView(viewModel.subscribersCount, for: NSLocalizedString("subscribersCountLabel", comment: ""))
//                            .redacted(reason: .placeholder)
//                            .shimmering()
//
//                        Spacer()
//
//                        makeNumberView(viewModel.postsCount, for: NSLocalizedString("publicationsCountLabel", comment: ""))
//                            .redacted(reason: .placeholder)
//                            .shimmering()
//                    }
//                    .frame(width: UIScreen.main.bounds.width - 30)
//                } else {
////                    HStack {
////                        Text("\(viewModel.subscribersCount) \(NSLocalizedString("subscribersCountLabel", comment: ""))")
////                            .font(.system(size: 17))
////                            .foregroundStyle(Color.gray)
////
////                        Text("•")
////                            .font(.system(size: 25))
////                            .foregroundStyle(Color.gray)
////
////                        Text("\(viewModel.postsCount) \(NSLocalizedString("publicationsCountLabel", comment: ""))")
////                            .font(.system(size: 17))
////                            .foregroundStyle(Color.gray)
////
////                    }
////                    .frame(width: UIScreen.main.bounds.width - 20, alignment: .leading)
//
//                    HStack {
//                        makeNumberView(viewModel.subscribersCount, for: NSLocalizedString("subscribersCountLabel", comment: ""))
//
//                        Spacer()
//
//                        makeNumberView(viewModel.postsCount, for: NSLocalizedString("publicationsCountLabel", comment: ""))
//                    }
//                    .frame(width: UIScreen.main.bounds.width - 30)
//                }

            }

            if let isSubscribed = viewModel.isSubscribed {
                subscribeButtonView(isSubscribed: isSubscribed)
                    .padding(.top, 15)
            }

            if !viewModel.isLoading && viewModel.authorDescription != "" {
                Text(channelDescriptionAttributedString)
                    .font(.system(size: 18))
                    .fontDesign(.rounded)
                    .frame(width: UIScreen.main.bounds.width - 20, alignment: .leading)
                    .padding(.top, 15)
            }

            channelPostsTabsView
            .padding(.top, 15)
            .padding(.bottom, -15)
        }
        .padding(.vertical, 15)
//        .background(
//            RoundedRectangle(cornerRadius: 25)
//                .foregroundStyle(Color(.secondarySystemBackground))
////                .shadow(radius: 1)
//                .frame(width: UIScreen.main.bounds.width)
//        )
    }

    var channelDescriptionAttributedString: AttributedString {
        var attributedString = viewModel.authorDescription.markdownAttributedStringPreservingLineBreaks

        for run in attributedString.runs where run.link != nil {
            attributedString[run.range].foregroundColor = .blue
            attributedString[run.range].underlineStyle = .single
        }

        return attributedString
    }

    @ViewBuilder
    func makeNumberView(_ num: Int, for text: String) -> some View {
        VStack {
            Text("\(num)")
                .font(.system(size: 19))
                .frame(width: (UIScreen.main.bounds.width - 25) / 2 - 30)
                .fontDesign(.rounded)

            Text(text)
                .font(.system(size: 16))
                .frame(width: (UIScreen.main.bounds.width - 25) / 2 - 30)
                .foregroundStyle(Color.gray)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .foregroundStyle(Color(.systemBackground))
        )
    }

//    var headerView: some View {
//        ZStack {
//            RoundedRectangle(cornerRadius: 15)
//                .frame(width: UIScreen.main.bounds.width, height: 140)
////                .foregroundStyle(Color(uiColor: .secondarySystemBackground))
//                .foregroundStyle(.thinMaterial)
//                .shadow(radius: 5)
//
//            VStack(spacing: -3) {
//                HStack {
//                    if let avatar = viewModel.avatarImage {
//                        Image(uiImage: avatar)
//                            .resizable()
//                            .scaledToFill()
//                            .frame(width: 50, height: 50)
//                            .clipShape(Circle())
//                            .overlay {
//                                Circle()
//                                    .stroke(
//                                        Color(.label),
//                                        lineWidth: 0.1
//                                    )
//                            }
//                            .onTapGesture {
//                                viewModel.isZoomableImageViewPresented = true
//                                viewModel.zoomableImage = avatar
//                            }
//                    }
//
//                    HStack(spacing: 0) {
//                        Text(authorName)
//                            .font(.system(size: 25))
//                            .fontWeight(.light)
//                            .lineLimit(1)
//
//                        if isCheckmark {
//                            Image(systemName: "checkmark.seal.fill")
//                                .foregroundStyle(Color.blue)
//                                .font(.system(size: 14))
//                                .padding(.top, 1)
//                        }
//                    }
//
//                    if viewModel.isLoading {
//                        LoadingIndicator(animation: .circleRunner, color: Color(uiColor: .label), size: .small, speed: .fast)
//                    }
//
//                    Spacer()
//
//                    ShareLink(item: URL(string: "https://readbox-links.online/authors/?index=\(authorId)")!) {
//                        Image(systemName: "arrowshape.turn.up.right")
//                            .font(.system(size: 22))
//                    }
//                    .padding(.trailing, 2)
//
//                    Button {
//                        dismiss()
//                    } label: {
//                        Image(systemName: "xmark")
//                            .font(.system(size: 22))
//                    }
//                }
//
//                if viewModel.isLoading {
//                    HStack {
//                        Text("100 000 \(NSLocalizedString("subscribersCountLabel", comment: ""))")
//                        .font(.callout)
//                        .foregroundStyle(Color.gray)
//                        .redacted(reason: .placeholder)
//                        .shimmering()
//
//                        Text("•")
//                            .font(.title)
//                            .foregroundStyle(Color.gray)
//
//                        Text("100 \(NSLocalizedString("publicationsCountLabel", comment: ""))")
//                        .font(.callout)
//                        .foregroundStyle(Color.gray)
//                        .redacted(reason: .placeholder)
//                        .shimmering()
//
//                    }
//                    .frame(width: UIScreen.main.bounds.width - 32, alignment: .leading)
//                } else {
//                    HStack {
//                        Text("\(viewModel.subscribersCount) \(NSLocalizedString("subscribersCountLabel", comment: ""))")
//                        .font(.callout)
//                        .foregroundStyle(Color.gray)
//
//                        Text("•")
//                            .font(.title)
//                            .foregroundStyle(Color.gray)
//
//                        Text("\(viewModel.postsCount) \(NSLocalizedString("publicationsCountLabel", comment: ""))")
//                        .font(.callout)
//                        .foregroundStyle(Color.gray)
//
//                    }
//                    .frame(width: UIScreen.main.bounds.width - 32, alignment: .leading)
//                }
//
//            }
//            .padding(.top, 50)
//            .padding(.horizontal, 16)
//        }
//    }
}
