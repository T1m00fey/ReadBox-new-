//
//  SubscribesView.swift
//  ReadBox
//
//  Created by Тимофей Юдин on 20.01.2026.
//

import SwiftUI
import Shimmer
import SwiftfulLoadingIndicators
import FirebaseFirestore
import PopupView

@MainActor
final class SubscribesViewModel: ObservableObject {
    @Published var isLoading = true
    @Published var channels: [ChannelInfo] = []
    @Published var allPosts: [PrePost] = []
    @Published var articles: [PrePost] = []
    @Published var errorText = ""
    @Published var isErrorPopupPresented = false
    @Published var isReadViewPresented = false
    @Published var authorsInfo: [String: PostAuthorInfo] = [:]
    @Published var isChannelViewPresented = false
    @Published var isLoadingPopupPresented = false
    @Published var isZoomableImageViewPresented = false
    @Published var zoomableImage: UIImage? = nil
    @Published var authorId = ""
    @Published var user: DBUser?
    @Published var lastDocument: DocumentSnapshot? = nil
    @Published var isLargeHeaderVisible = true
    @Published var primaryLanguage = "en"
    @Published var shouldOpenCommentsOnRead = false
    @Published var views: [String] = []

    private let db = Firestore.firestore()
    private let inQueryLimit = 30

    var title = ""
    var dateCreated = Date()
    var text = ""
    var likesCount = 0
    var id = ""
    var isArchive = false
    var mediaCount = 0
    var mediaVersion = 0
    var mediaPosition = 0
    var articleLanguage = ""
    var isPremiumPost = false
    var isLocalizedVersion = false
    var rootId = ""

    func getViews() {
        views = StorageManager.shared.getViews()
    }

    func saveViews() {
        StorageManager.shared.save(views: views)
    }

    func loadUser() async throws {
        let auth = try AuthenticationManager.shared.getAuthenticatedUser()
        self.user = try await UserManager.shared.getUser(userId: auth.uid)
    }

    func updatePrimaryLanguage() {
        let fallbackLanguage = Locale.preferredLanguages.first?.components(separatedBy: "-").first == "ru"
        ? "ru"
        : "en"

        let userLanguage = user?.originalLanguage?.trimmingCharacters(in: .whitespacesAndNewlines)

        primaryLanguage = (userLanguage?.isEmpty == false ? userLanguage : nil) ?? fallbackLanguage
    }

    func refresh() async {
        withAnimation {
            isLoading = true
            channels = []
            allPosts = []
            articles = []
            authorsInfo = [:]
            user = nil
            lastDocument = nil
            errorText = ""
            isErrorPopupPresented = false
        }

        do {
            try await loadUser()
            updatePrimaryLanguage()

            guard let subscribes = user?.subscribes, !subscribes.isEmpty else {
                withAnimation {
                    isLoading = false
                }
                return
            }

            try await getChannels()
            try await getArticles()

            withAnimation {
                isLoading = false
            }
        } catch {
            withAnimation {
                errorText = error.localizedDescription
                isErrorPopupPresented = true
                isLoading = false
            }
        }
    }

    func getChannels() async throws {
        let ids = Array((user?.subscribes ?? []).reversed())
        guard !ids.isEmpty else {
            channels = []
            return
        }

        let chunks: [[String]] = stride(from: 0, to: ids.count, by: inQueryLimit).map { start in
            Array(ids[start..<min(start + inQueryLimit, ids.count)])
        }

        let docs: [QueryDocumentSnapshot] = try await withThrowingTaskGroup(of: [QueryDocumentSnapshot].self) { group in
            for chunk in chunks {
                group.addTask { [db] in
                    let snap = try await db.collection("users")
                        .whereField("id", in: chunk)
                        .getDocuments()
                    return snap.documents
                }
            }

            var all: [QueryDocumentSnapshot] = []
            for try await part in group {
                all.append(contentsOf: part)
            }
            return all
        }

        var channels = docs.compactMap { ChannelInfo(document: $0) }

        let order = Dictionary(uniqueKeysWithValues: ids.enumerated().map { ($0.element, $0.offset) })
        channels.sort { (order[$0.id] ?? .max) < (order[$1.id] ?? .max) }

        withAnimation {
            self.channels = channels
        }
    }

    func getArticles() async throws {
        let ids = Array((user?.subscribes ?? []).prefix(inQueryLimit))
        guard !ids.isEmpty else {
            withAnimation {
                articles = []
            }
            return
        }

        var query = db.collection("articles")
            .whereField("author_id", in: ids)
            .whereField("is_archive", isEqualTo: false)
            .order(by: "date_created", descending: true)
            .limit(to: 20)

        if let last = lastDocument {
            query = query.start(afterDocument: last)
        }

        do {
            let snapshot = try await query.getDocuments()
            let newPosts = snapshot.documents.compactMap { PrePost(document: $0) }

            withAnimation {
                allPosts.append(contentsOf: newPosts)
                articles = localizedPosts(from: allPosts)
                lastDocument = snapshot.documents.count == 20 ? snapshot.documents.last : nil
            }
        } catch {
            withAnimation {
                errorText = error.localizedDescription
                isErrorPopupPresented = true
            }
            throw error
        }
    }

    private func localizedPosts(from posts: [PrePost]) -> [PrePost] {
        var bestPostsByRoot: [String: (post: PrePost, index: Int)] = [:]

        for (index, post) in posts.enumerated() {
            let rootKey = post.rootId ?? post.id

            if let current = bestPostsByRoot[rootKey] {
                if localizationPriority(for: post) < localizationPriority(for: current.post) {
                    bestPostsByRoot[rootKey] = (post, index)
                }
            } else {
                bestPostsByRoot[rootKey] = (post, index)
            }
        }

        return bestPostsByRoot
            .values
            .sorted { $0.index < $1.index }
            .map(\.post)
    }

    private func localizationPriority(for post: PrePost) -> Int {
        if post.originalLanguage == primaryLanguage {
            return 0
        }

        if !(post.isLocalizedVersion ?? false) {
            return 1
        }

        return 2
    }

    func getPostToRead(id: String) {
        Task {
            do {
                let post = try await ArticlesManager.shared.getPostToRead(id: id)

                dateCreated = post.dateCreated ?? Date()
                text = post.text ?? NSLocalizedString("notFoundLabel", comment: "")
            } catch {
                dateCreated = Date()
                text = ""
            }

            isLoadingPopupPresented = false
            isReadViewPresented = true
        }
    }

    func onPostAppearing(_ post: PrePost) {
        guard let authorId = post.authorId else { return }

        if !authorsInfo.keys.contains(authorId) {
            Task {
                do {
                    let info = try await UserManager.shared.getPostAuthorInfo(for: authorId)

                    withAnimation {
                        authorsInfo[authorId] = info
                    }
                } catch {
                    withAnimation {
                        errorText = error.localizedDescription
                        isErrorPopupPresented = true
                    }
                }
            }
        }

        if articles.last == post && lastDocument != nil {
            Task {
                do {
                    try await getArticles()
                } catch {
                    print("ERROR TO FETCH MORE POSTS: \(error.localizedDescription)")
                }
            }
        }
    }

    func tapGestureHandler(on post: PrePost, openComments: Bool = false) {
        title = post.title ?? NSLocalizedString("notFoundLabel", comment: "")
        likesCount = post.likesCount ?? 0
        id = post.id
        authorId = post.authorId ?? ""
        isArchive = post.isArchive ?? true
        mediaCount = post.mediaCount ?? 1
        mediaVersion = post.mediaVersion ?? 1
        mediaPosition = post.mediaPosition ?? 0
        articleLanguage = post.originalLanguage ?? ""
        isPremiumPost = post.isPremiumPost ?? false
        isLocalizedVersion = post.isLocalizedVersion ?? false
        rootId = post.rootId ?? ""
        shouldOpenCommentsOnRead = openComments

        Task {
            await countPostViewIfNeeded(post)
        }

        isLoadingPopupPresented = true
        getPostToRead(id: post.id)
    }

    func countPostViewIfNeeded(_ post: PrePost) async {
        guard post.authorId != user?.userId else { return }
        guard !views.contains(post.id) else { return }

        do {
            try await ArticlesManager.shared.updateViews(at: post.id)
            views.append(post.id)
            saveViews()
        } catch {
            print("SUBSCRIBES VIEW COUNT ERROR: \(error.localizedDescription)")
        }
    }
}

struct SubscribesView: View {
    @StateObject private var viewModel = SubscribesViewModel()
    @Binding var isPremiumViewPresented: Bool

    @EnvironmentObject var sessionManager: SessionManager
    @EnvironmentObject var changedPostsManager: ChangedPostsManager
    @EnvironmentObject var subManager: SubscriptionManager

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView(showsIndicators: false) {
                    LazyVStack {
                        Text("")
                        VisibilityTracker(id: "subscribesHeader")

                        SubscribesHStackView(
                            isLoading: $viewModel.isLoading,
                            channels: $viewModel.channels,
                            selectedAuthorId: $viewModel.authorId,
                            authorsInfo: $viewModel.authorsInfo,
                            isChannelViewPresented: $viewModel.isChannelViewPresented
                        )
                        .padding(.top, 30)
                        .padding(.bottom, -40)

                        if viewModel.isLoading {
                            ForEach(0..<3) { num in
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
                                    onCommentTap: {
                                        if let isPremiumPost = post.isPremiumPost,
                                           isPremiumPost && !subManager.hasPremium,
                                           post.authorId != viewModel.user?.userId {
                                            isPremiumViewPresented = true
                                        } else {
                                            viewModel.tapGestureHandler(on: post, openComments: true)
                                        }
                                    }, user: $viewModel.user,
                                    isZoomableViewPresented: $viewModel.isZoomableImageViewPresented,
                                    zoomableImage: $viewModel.zoomableImage,
                                    selectedAuthorId: $viewModel.authorId,
                                    isChannelViewPresented: $viewModel.isChannelViewPresented
                                )
                                .padding(.top, 10)
                                .onAppear {
                                    viewModel.onPostAppearing(post)
                                    AnalyticsManager.shared.logFeedImpression(
                                        publicationId: post.id,
                                        authorId: post.authorId ?? "",
                                        contentType: (post.isShortPost ?? false) ? "post" : "article",
                                        source: "subscriptions_feed"
                                    )
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
                .refreshable {
                    await viewModel.refresh()
                }

                VStack {
                    headerView

                    Spacer()
                }
                .ignoresSafeArea()
            }
            .onAppear {
                viewModel.getViews()

                if viewModel.isLoading && viewModel.channels.isEmpty && viewModel.articles.isEmpty {
                    Task {
                        await viewModel.refresh()
                    }
                }
            }
            .onPreferenceChange(VisibilityPreferenceKey.self) { values in
                if let minY = values["subscribesHeader"] {
                    let isVisible = minY > 60

                    if viewModel.isLargeHeaderVisible != isVisible {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.isLargeHeaderVisible = isVisible
                        }
                    }
                }
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
                    originalPrePost: originalPost(for: viewModel.id),
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
            .fullScreenCover(isPresented: $viewModel.isZoomableImageViewPresented, content: {
                if let image = viewModel.zoomableImage {
                    ZoomableImageView(image: image)
                }
            })
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
        }
    }
}

private extension SubscribesView {
    func originalPost(for postId: String) -> PrePost? {
        guard let post = viewModel.allPosts.first(where: { $0.id == postId }),
              post.isLocalizedVersion ?? false,
              let rootId = post.rootId
        else {
            return nil
        }

        return viewModel.allPosts.first { $0.id == rootId }
    }

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

            HStack(spacing: 5) {
                Text(NSLocalizedString("subscribesLabel", comment: ""))
                    .font(.system(size: 32))
                    .fontWeight(.light)

                if viewModel.isLoading {
                    LoadingIndicator(
                        animation: .circleRunner,
                        color: Color(.label),
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

#Preview {
    SubscribesView(isPremiumViewPresented: .constant(false))
}
