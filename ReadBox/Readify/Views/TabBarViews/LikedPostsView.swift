//
//  RuLikedPostsView.swift
//  Readify
//
//  Created by Тимофей Юдин on 15.11.2024.
//

import SwiftUI
import SwiftfulLoadingIndicators

@MainActor
final class LikedPostsViewModel: ObservableObject {
    @Published var isReadViewPresented = false
    @Published var articles: [Article] = []
    @Published var errorText = ""
    @Published var isErrorPopupPresented = false
    @Published var isDescriptionPopupPresented = false
    @Published var user: DBUser? = nil
    @Published var likedPosts: [String] = []
    @Published var fromIndex = ""
    @Published var authorsNames: [String: String] = [:]
    @Published var authorsCheckmarks: [String: Bool] = [:]
    @Published var indexesNeedToLoad: [String] = []
    @Published var isLoading = true
    @Published var isChannelViewPresented = false
    @Published var postToView: Article? = nil
    
    
    var description = ""
    var title = ""
    var image = UIImage()
    var dateCreated = Date()
    var text = ""
    var likesCount = 0
    var id = ""
    var userId = ""
    var authorId = ""
    
    func getArticle(id: String) async throws -> Article {
        try await ArticlesManager.shared.getArticle(id: id)
    }
    
    func getAuthorName(id: String) async throws -> String {
        try await UserManager.shared.getUser(userId: id).authorName ?? ""
    }
    
    func getAuthorIsCheckmarkStatus(id: String) async throws -> Bool {
        try await UserManager.shared.getUser(userId: id).isCheckmark ?? false
    }
    
    func loadUser() async throws {
        let authDataResult = try AuthenticationManager.shared.getAuthenticatedUser()
        let user = try await UserManager.shared.getUser(userId: authDataResult.uid)
        
        self.user = user
    }
    
//    func getArticles() async throws {
//        articles = []
//        
//        for index in likedPosts {
//            do {
//                articles.append(try await ArticlesManager.shared.getRuArticle(id: index))
//            } catch {
//                withAnimation {
//                    errorText = NSLocalizedString("someArticlesNotFoundLabel", comment: "")
//                    isErrorPopupPresented = true
//                }
//            }
//        }
//    }
    
//    func getArticles() async throws {
//        var indexes = likedPosts
//        var posts: [Article] = []
//        var article = Article(id: "", dateCreated: nil, title: nil, text: nil, description: nil, likesCount: nil, isArchive: nil, authorId: nil, viewsCount: nil, originalLanguage: nil)
//        
//        print(indexes)
//        
//        if indexes.count > 0 {
//            do {
//                article = try await ArticlesManager.shared.getArticle(id: indexes[2])
//                
//                withAnimation {
//                    posts.append(article)
//                }
//            } catch {
//                withAnimation {
//                    posts.append(
//                        Article(
//                            id: indexes[0],
//                            dateCreated: nil,
//                            title: NSLocalizedString("articleErrorLabel", comment: ""),
//                            text: nil,
//                            description: nil,
//                            likesCount: nil,
//                            isArchive: nil,
//                            authorId: nil,
//                            viewsCount: nil,
//                            originalLanguage: nil
//                        )
//                    )
//                    
//                    let index = indexes[0]
//                    
//                    indexes.removeAll { $0 == index }
//                    loadedPostsCount += 1
//                }
//            }
//        }
//        
//        print(posts)
//        
//        for index in likedPosts {
//            if loadedPostsCount % 20 != 0 {
//                do {
//                    article = try await ArticlesManager.shared.getArticle(id: index)
//                    withAnimation {
//                        posts.append(article)
//                        indexes.removeAll { $0 == index }
//                    }
//                    
//                    loadedPostsCount += 1
//                    print("We here!")
//                } catch {
//                    withAnimation {
//                        posts.append(
//                            Article(
//                                id: "",
//                                dateCreated: nil,
//                                title: NSLocalizedString("articleErrorLabel", comment: ""),
//                                text: nil,
//                                description: nil,
//                                likesCount: nil,
//                                isArchive: nil,
//                                authorId: nil,
//                                viewsCount: nil,
//                                originalLanguage: nil
//                            )
//                        )
//                        
//                        indexes.removeAll { $0 == index }
//                        loadedPostsCount += 1
//                    }
//                }
//            }
//        }
//        
//        posts.reverse()
//        likedPosts = indexes
//        articles = posts
//        
//        print(articles)
//    }
    
    func getArticles() async throws {
        var indexesToAdd: [String] = []
        var postsToAdd: [Article] = []
        var article = Article(id: "", dateCreated: nil, title: nil, text: nil, description: nil, likesCount: nil, isArchive: nil, authorId: nil, viewsCount: nil, originalLanguage: nil)
        
        var count = 0
        
        for index in indexesNeedToLoad {
            if count < 20 {
                indexesToAdd.append(index)
                count += 1
            }
        }
        
        count = 0
        
        for index in indexesToAdd {
            do {
                article = try await ArticlesManager.shared.getArticle(id: index)
    
                if article.isArchive ?? true {
                    postsToAdd.append(
                        Article(
                            id: index,
                            dateCreated: article.dateCreated,
                            title: NSLocalizedString("archiveArticleLabel", comment: ""),
                            text: "",
                            description: "",
                            likesCount: article.likesCount,
                            isArchive: article.isArchive,
                            authorId: article.authorId,
                            viewsCount: article.viewsCount,
                            originalLanguage: article.originalLanguage
                        )
                    )
                } else {
                    postsToAdd.append(article)
                }
            } catch {
                article = Article(
                    id: index,
                    dateCreated: nil,
                    title: NSLocalizedString("articleErrorLabel", comment: ""),
                    text: "",
                    description: "",
                    likesCount: 0,
                    isArchive: false,
                    authorId: nil,
                    viewsCount: 0,
                    originalLanguage: StorageManager.shared.getLanguage()
                )
                
                postsToAdd.append(article)
            }
            
            indexesNeedToLoad.removeAll { $0 == index }
        }
        
        withAnimation {
            isLoading = false
        }
        
        for post in postsToAdd.reversed() {
            withAnimation {
                articles.append(post)
            }
        }
    }
}

struct LikedPostsView: View {
    @StateObject var viewModel = LikedPostsViewModel()
    
    var body: some View {
        
        NavigationStack {
            
            ScrollView(showsIndicators: false) {
                
                VStack {
                    
                    if viewModel.isLoading {
                        
                        ForEach(0..<7) { _ in
                            ArticleView(
                                id: "-1",
                                title: "Hello, World!",
                                authorName: "ReadBox Author",
                                isCheckmark: true,
                                isArchive: false
                            )
                            .redacted(reason: .placeholder)
                            .padding(.top, 30)
                            .padding(.horizontal)
                        }
                        
                    } else if viewModel.articles == [] {
                        
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
                        }
                        .frame(height: UIScreen.main.bounds.height - 200, alignment: .center)
                        
                    } else {
                        ForEach(viewModel.articles) { article in
                            ArticleView(
                                id: article.id,
                                title: article.title ?? "",
                                authorName: viewModel.authorsNames[article.authorId ?? ""] ?? "",
                                isCheckmark: viewModel.authorsCheckmarks[article.authorId ?? ""] ?? false,
                                isArchive: article.isArchive ?? false
                            )
                            .padding(.top, 30)
                            .padding(.horizontal)
                            .onAppear {
                                if !viewModel.authorsNames.keys.contains(article.authorId ?? "") && article.authorId != nil {
                                    Task {
                                        do {
                                            viewModel.authorsNames[article.authorId ?? ""] = try await viewModel.getAuthorName(id: article.authorId ?? "")
                                            viewModel.authorsCheckmarks[article.authorId ?? ""] = try await viewModel.getAuthorIsCheckmarkStatus(id: article.authorId ?? "")
                                        } catch {
//                                            withAnimation {
//                                                viewModel.errorText = error.localizedDescription
//                                                viewModel.isErrorPopupPresented = true
//                                            }
                                        }
                                    }
                                }
                            }
                            .onTapGesture {
                                viewModel.description = article.description ?? NSLocalizedString("notFoundLabel", comment: "")
                                viewModel.title = article.title ?? NSLocalizedString("notFoundLabel", comment: "")
                                viewModel.text = article.text ?? NSLocalizedString("notFoundLabel", comment: "")
                                viewModel.image = StorageManager.shared.getImage(id: article.id) ?? UIImage()
                                viewModel.dateCreated = article.dateCreated ?? Date()
                                viewModel.likesCount = article.likesCount ?? 0
                                viewModel.id = article.id
                                viewModel.authorId = article.authorId ?? ""
                                
                                if article.isArchive ?? true {
                                    viewModel.image = UIImage()
                                }
                                
                                if viewModel.user != nil {
                                    if viewModel.userId == "" {
                                        viewModel.userId = viewModel.user?.userId ?? ""
                                    }
                                    
                                    if viewModel.description == "" {
                                        viewModel.isReadViewPresented = true
                                        
                                        if !((viewModel.user?.createdPosts ?? [viewModel.id]).contains(viewModel.id)) {
                                            Task {
                                                do {
                                                    try await ArticlesManager.shared.updateViews(at: viewModel.id)
                                                } catch {
//                                                    withAnimation {
//                                                        viewModel.errorText = error.localizedDescription
//                                                        viewModel.isErrorPopupPresented = true
//                                                    }
                                                }
                                            }
                                        }

                                    } else {
                                        viewModel.isDescriptionPopupPresented = true
                                    }
                                } else {
                                    withAnimation {
                                        viewModel.errorText = NSLocalizedString("loadDataErrorText", comment: "")
                                        viewModel.isErrorPopupPresented = true
                                    }
                                }
                            }
                        }
                        
                        if viewModel.indexesNeedToLoad.count > 0 {
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
            .padding(.top, 10)
            .refreshable {
                viewModel.isLoading = true
                viewModel.likedPosts = []
                viewModel.articles = []
                viewModel.user = nil
                viewModel.authorsNames = [:]
                viewModel.authorsCheckmarks = [:]
                
                Task {
                    try? await viewModel.loadUser()
                }
            }
            .onChange(of: viewModel.likedPosts, perform: { newValue in
                if viewModel.likedPosts != [] {
                    Task {
                        do {
                            viewModel.indexesNeedToLoad = viewModel.likedPosts
                            try await viewModel.getArticles()
                            return
                        } catch {
//                            withAnimation {
//                                viewModel.errorText = error.localizedDescription
//                            }
                        }
                        
//                        viewModel.isErrorPopupPresented = true
                    }
                } else {
                    viewModel.articles = []
                }
            })
            .popup(isPresented: $viewModel.isDescriptionPopupPresented) {
                DescriptionView(
                    isReadViewPresented: $viewModel.isReadViewPresented,
                    errorText: $viewModel.errorText,
                    isErrorPopupPresented: $viewModel.isErrorPopupPresented,
                    id: viewModel.id,
                    description: viewModel.description
                )
                .shadow(radius: 3)
            } customize: {
                $0
                    .type(.toast)
                    .appearFrom(.bottomSlide)
                    .dragToDismiss(true)
            }
            .fullScreenCover(isPresented: $viewModel.isReadViewPresented, content: {
                ReadView(
                    id: viewModel.id,
                    userId: viewModel.userId,
                    title: viewModel.title,
                    text: viewModel.text,
                    dateCreated: viewModel.dateCreated,
                    likesCount: viewModel.likesCount,
                    authorName: viewModel.authorsNames[viewModel.authorId] ?? "",
                    isCheckmark: viewModel.authorsCheckmarks[viewModel.authorId] ?? false,
                    likedPosts: $viewModel.likedPosts,
                    isChannelViewPresented: $viewModel.isChannelViewPresented
                )
            })
            .fullScreenCover(isPresented: $viewModel.isChannelViewPresented, content: {
                ChannelView(
                    authorId: viewModel.authorId,
                    authorName: viewModel.authorsNames[viewModel.authorId] ?? NSLocalizedString("notFoundLabel", comment: ""),
                    isCheckmark: viewModel.authorsCheckmarks[viewModel.authorId] ?? false,
                    postToView: $viewModel.postToView
                )
            })
            .onChange(of: viewModel.postToView) { newValue in
                viewModel.id = viewModel.postToView?.id ?? ""
                viewModel.title = viewModel.postToView?.title ?? ""
                viewModel.text = viewModel.postToView?.text ?? ""
                viewModel.dateCreated = viewModel.postToView?.dateCreated ?? Date()
                viewModel.likesCount = viewModel.postToView?.likesCount ?? 0
                viewModel.authorId = viewModel.postToView?.authorId ?? ""
                
                viewModel.isReadViewPresented = true
            }
            .onChange(of: viewModel.isReadViewPresented) { newValue in
                if !newValue {
                    viewModel.postToView = nil
                }
            }
            .popup(isPresented: $viewModel.isErrorPopupPresented) {
                Text(viewModel.errorText)
                    .frame(width: UIScreen.main.bounds.width - 72, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .foregroundStyle(Color.white)
                    .background(Color.red)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.top, 20)
            } customize: {
                $0
                    .type(.floater())
                    .position(.top)
                    .animation(.bouncy)
                    .dragToDismiss(true)
                    .autohideIn(5)
            }
            .onAppear {
                if viewModel.user == nil {
                    Task {
                        try? await viewModel.loadUser()
                    }
                }
            }
            .onChange(of: viewModel.user) { newValue in
                viewModel.articles = []
                
                if viewModel.user?.likedPosts != nil {
                    viewModel.likedPosts = viewModel.user?.likedPosts ?? []
                    
                    if viewModel.likedPosts.count == 0 {
                        withAnimation {
                            viewModel.isLoading = false
                        }
                    }
                    
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
//                    Text(LocalizedStringKey("favoritesLabel"))
//                        .font(.largeTitle)
//                        .fontDesign(.rounded)
//                        .fontWeight(.light)
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .frame(width: UIScreen.main.bounds.width, height: 130)
                            .foregroundStyle(Color(uiColor: .secondarySystemBackground))
                            .padding(.bottom, 40)
                            .shadow(radius: 10)
                        
                        HStack {
                            Text(LocalizedStringKey("favoritesLabel"))
                                .font(.largeTitle)
                                .fontWeight(.light)
//                                .fontDesign(.rounded)
                            
                            if viewModel.isLoading {
                                LoadingIndicator(animation: .circleRunner, color: Color(uiColor: .label), size: .small, speed: .fast)
                            }
                        }
                        .frame(width: UIScreen.main.bounds.width - 32, alignment: .leading)
                    }
                    .padding(.leading, 6)
                }
            }
        }
    }
}

