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

    func loadUser() async throws {
        let auth = try AuthenticationManager.shared.getAuthenticatedUser()
        self.user = try await UserManager.shared.getUser(userId: auth.uid)
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
                articles.append(contentsOf: newPosts)
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
    
    func tapGestureHandler(on post: PrePost) {
        title = post.title ?? NSLocalizedString("notFoundLabel", comment: "")
        likesCount = post.likesCount ?? 0
        id = post.id
        authorId = post.authorId ?? ""
        isArchive = post.isArchive ?? true
        mediaCount = post.mediaCount ?? 1
        mediaVersion = post.mediaVersion ?? 1
        mediaPosition = post.mediaPosition ?? 0
        
        isLoadingPopupPresented = true
        getPostToRead(id: post.id)
    }
}

struct SubscribesView: View {
    @StateObject private var viewModel = SubscribesViewModel()
    
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
                        
                        ForEach(viewModel.articles) { post in
                            ArticleView(
                                id: post.id,
                                title: post.title ?? "",
                                authorId: post.authorId ?? "",
                                authorName: viewModel.authorsInfo[post.authorId ?? ""]?.name ?? "",
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
                            .padding(.top, 10)
                            .onAppear {
                                viewModel.onPostAppearing(post)
                            }
                            .onTapGesture {
                                viewModel.tapGestureHandler(on: post)
                            }
                        }
                    }
                }
                
                VStack {
                    headerView
                    
                    Spacer()
                }
                .ignoresSafeArea()
            }
            .onAppear {
                Task {
                    do {
                        try await viewModel.loadUser()
                        
                        if let subscribes = viewModel.user?.subscribes, !subscribes.isEmpty {
                            if viewModel.articles.isEmpty {
                                viewModel.lastDocument = nil
                            }
                            
                            try await viewModel.getChannels()
                            
                            if viewModel.articles.isEmpty {
                                try await viewModel.getArticles()
                            }
                            
                            withAnimation {
                                viewModel.isLoading = false
                            }
                        }
                    } catch {
                        print("error")
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
                    user: $viewModel.user,
                    isChannelViewPresented: $viewModel.isChannelViewPresented,
                    isPresented: $viewModel.isReadViewPresented
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
                    lastVersionOfAvatar: viewModel.authorsInfo[viewModel.authorId]?.avatarVersion ?? 0
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
                Text("Подписки")
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
    SubscribesView()
}
