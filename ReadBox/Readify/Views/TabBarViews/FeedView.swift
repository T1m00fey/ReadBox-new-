//
//  FeedView.swift
//  Readify
//
//  Created by Тимофей Юдин on 28.10.2024.
//

import SwiftUI
import FirebaseStorage
import SwiftfulLoadingIndicators

@MainActor
final class FeedViewModel: ObservableObject {
    @Published var topArticlesIndexes: [String] = []
    @Published var topArticles: [Article] = []
    @Published var articles: [Article] = []
    @Published var errorText = ""
    @Published var isErrorPopupPresented = false
    @Published var isDescriptionPopupPresented = false
    @Published var isReadViewPresented = false
    @Published var fromIndex = -1
    @Published var maxIndex = ""
    @Published var likedPosts: [String] = []
    @Published var primaryLanguage = ""
    @Published var loadCount = 0
    @Published var authorsNames: [String: String] = [:]
    @Published var authorsCheckmarks: [String: Bool] = [:]
    @Published var isChannelViewPresented = false
    @Published var postToView: Article? = nil
    @Published var isLoading = true
    @Published var height: CGFloat = 0.0
    
    @Published var user: DBUser? = nil
    
    var description = ""
    var title = ""
    var image = UIImage()
    var dateCreated = Date()
    var text = ""
    var likesCount = 0
    var id = ""
    var userId = ""
    var authorId = ""
    
    func loadUser() async throws {
        let authDataResult = try AuthenticationManager.shared.getAuthenticatedUser()
        let user = try await UserManager.shared.getUser(userId: authDataResult.uid)
        
        self.user = user
    }
    
    func getAuthorName(id: String) async throws -> String {
        try await UserManager.shared.getAuthorName(id: id) ?? ""
    }
    
    func getAuthorIsCheckmarkStatus(id: String) async throws -> Bool {
        try await UserManager.shared.getIsCheckmarkStatus(id: id) ?? false
    }
    
    func getMaxIndex() async throws {
        maxIndex = try await ArticlesManager.shared.getMaxIndex() ?? "10"
    }
    
    func getArticle(id: String) async throws -> Article {
        try await ArticlesManager.shared.getArticle(id: id)
    }
    
    func getOriginalLanguageOfArticle(id: String) async throws -> String {
        try await ArticlesManager.shared.getOriginalLanguageOfArticle(id: id)
    }
    
    func getTopArticles() async throws {
        
        var article = Article(
            id: "",
            dateCreated: nil,
            title: nil,
            text: nil,
            description: nil,
            likesCount: nil,
            isArchive: nil,
            authorId: nil,
            viewsCount: nil,
            originalLanguage: nil
        )
        
        topArticles = []
        
        for index in topArticlesIndexes {
            do {
                article = try await getArticle(id: index)
                
                withAnimation {
                    
                    if article.isArchive ?? true {
                        topArticles.append(
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
                        topArticles.append(article)
                    }
                    
                }
            } catch {
                withAnimation {
                    
                    topArticles.append(
                        Article(
                            id: index,
                            dateCreated: nil,
                            title: NSLocalizedString("articleErrorLabel", comment: ""),
                            text: "",
                            description: "",
                            likesCount: 0,
                            isArchive: nil,
                            authorId: nil,
                            viewsCount: 0,
                            originalLanguage: nil
                        )
                    )
                    
                }
            }
        }
        
    }
    
    func getTopIndexes() async throws {
        topArticlesIndexes = try await ArticlesManager.shared.getTopArticlesIndexes() ?? ["0"]
    }
    
    func getArticles() async throws {
        var article: Article = Article(id: "", dateCreated: nil, title: nil, text: nil, description: nil, likesCount: nil, isArchive: nil, authorId: nil, viewsCount: nil, originalLanguage: nil)
        
        while loadCount != 20 && fromIndex > -1 {
            if !topArticlesIndexes.contains(String(fromIndex)) {
                
                print(fromIndex)
                
                do {
                    article = try await getArticle(id: String(fromIndex))
                    
                    if article.originalLanguage == primaryLanguage && !(article.isArchive ?? true) {
                        withAnimation {
                            articles.append(article)
                        }
                        
                        loadCount += 1
                    }
                } catch {
                    //                    withAnimation {
                    //                        errorText = error.localizedDescription
                    //                        isErrorPopupPresented = true
                    //                    }
                }
            }
            
            fromIndex -= 1
        }
        
        withAnimation {
            isLoading = false
        }
        
        loadCount = 0
    }
}

struct FeedView: View {
    @StateObject var viewModel = FeedViewModel()
    
    var body: some View {
        NavigationStack {
            
            ZStack {
                
                Color(uiColor: .systemBackground)
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    
                    VStack {
                        
                        TabView {
                            
                            if viewModel.isLoading {
                                ForEach(0..<5) { num in
                                    TopArticleView(
                                        id: String(num),
                                        title: "",
                                        isArchive: false
                                    )
                                    .redacted(reason: .placeholder)
                                }
                            } else {
                                ForEach(viewModel.topArticles) { article in
                                    TopArticleView(id: article.id, title: article.title, isArchive: article.isArchive)
                                        .tabItem {}
                                        .onAppear {
                                            if !viewModel.authorsNames.keys.contains(article.authorId ?? "") {
                                                Task {
                                                    do {
                                                        viewModel.authorsNames[article.authorId ?? ""] = try await viewModel.getAuthorName(id: article.authorId ?? "")
                                                        viewModel.authorsCheckmarks[article.authorId ?? ""] = try await viewModel.getAuthorIsCheckmarkStatus(id: article.authorId ?? "")
                                                    } catch {
                                                        //                                                    withAnimation {
                                                        //                                                        viewModel.errorText = error.localizedDescription
                                                        //                                                        viewModel.isErrorPopupPresented = true
                                                        //                                                    }
                                                    }
                                                }
                                            }
                                        }
                                        .onTapGesture {
                                            viewModel.description = article.description ?? NSLocalizedString("notFoundLabel", comment: "")
                                            viewModel.title = article.title ?? NSLocalizedString("notFoundLabel", comment: "")
                                            viewModel.text = article.text ?? NSLocalizedString("notFoundLabel", comment: "")
                                            viewModel.dateCreated = article.dateCreated ?? Date()
                                            viewModel.likesCount = article.likesCount ?? 0
                                            viewModel.id = article.id
                                            viewModel.authorId = article.authorId ?? ""
                                            
                                            if article.isArchive ?? true {
                                                viewModel.image = UIImage()
                                            }
                                            
                                            if viewModel.user != nil {
                                                if viewModel.likedPosts == [] {
                                                    viewModel.likedPosts = viewModel.user?.likedPosts ?? []
                                                }
                                                
                                                if viewModel.userId == "" {
                                                    viewModel.userId = viewModel.user?.userId ?? ""
                                                }
                                                
                                                if viewModel.description == "" {
                                                    viewModel.isReadViewPresented = true
                                                } else {
                                                    viewModel.isDescriptionPopupPresented = true
                                                }
                                                
                                                
                                                if (viewModel.user?.createdPosts ?? [viewModel.id]).contains(viewModel.id) == false {
                                                    Task {
                                                        do {
                                                            try await ArticlesManager.shared.updateViews(at: viewModel.id)
                                                        } catch {
                                                            //                                                        withAnimation {
                                                            //                                                            viewModel.errorText = error.localizedDescription
                                                            //                                                            viewModel.isErrorPopupPresented = true
                                                            //                                                        }
                                                        }
                                                    }
                                                }
                                            } else {
                                                withAnimation {
                                                    viewModel.errorText = NSLocalizedString("loadDataErrorText", comment: "")
                                                    viewModel.isErrorPopupPresented = true
                                                }
                                            }
                                        }
                                }
                                
                            }
                        }
                        .tabViewStyle(.page)
                        .frame(height: 270)
                        .padding(.top, 20)
                        
                        if viewModel.isLoading {
                            ForEach(0..<5) { num in
                                ArticleView(
                                    id: String(num),
                                    title: "Hello, World! Hello, World! Hello, World!",
                                    authorName: "Hello, World!",
                                    isCheckmark: true,
                                    isArchive: false
                                )
                                .redacted(reason: .placeholder)
                                .padding(.top, 20)
                            }
                        } else {
                            ForEach(viewModel.articles) { article in
                                ArticleView(
                                    id: article.id,
                                    title: article.title ?? "",
                                    authorName: viewModel.authorsNames[article.authorId ?? ""] ?? "",
                                    isCheckmark: viewModel.authorsCheckmarks[article.authorId ?? ""] ?? false,
                                    isArchive: article.isArchive ?? true
                                )
                                .onAppear {
                                    if !viewModel.authorsNames.keys.contains(article.authorId ?? "") {
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
                                    viewModel.text =  article.text ?? NSLocalizedString("notFoundLabel", comment: "")
                                    viewModel.image = StorageManager.shared.getImage(id: article.id) ?? UIImage()
                                    viewModel.dateCreated = article.dateCreated ?? Date()
                                    viewModel.likesCount = article.likesCount ?? 0
                                    viewModel.id = article.id
                                    viewModel.authorId = article.authorId ?? ""
                                    
                                    if article.isArchive ?? true {
                                        viewModel.image = UIImage()
                                    }
                                    
                                    if viewModel.user != nil {
                                        if viewModel.likedPosts == [] {
                                            viewModel.likedPosts = viewModel.user?.likedPosts ?? []
                                        }
                                        
                                        if viewModel.userId == "" {
                                            viewModel.userId = viewModel.user?.userId ?? ""
                                        }
                                        
                                        if viewModel.description == "" {
                                            viewModel.isReadViewPresented = true
                                        } else {
                                            viewModel.isDescriptionPopupPresented = true
                                        }
                                        
                                        if (viewModel.user?.createdPosts ?? [viewModel.id]).contains(viewModel.id) == false {
                                            Task {
                                                do {
                                                    try await ArticlesManager.shared.updateViews(at: viewModel.id)
                                                } catch {
    //                                                withAnimation {
    //                                                    viewModel.errorText = error.localizedDescription
    //                                                    viewModel.isErrorPopupPresented = true
    //                                                }
                                                }
                                            }
                                        }
                                    } else {
                                        withAnimation {
                                            viewModel.errorText = NSLocalizedString("loadDataErrorText", comment: "")
                                            viewModel.isErrorPopupPresented = true
                                        }
                                    }
                                }
                                .padding(.top, 20)

                            }
                        }
                        
                        if viewModel.articles != [] && viewModel.fromIndex >= 0 && !viewModel.isLoading {
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
                .padding(.top, 10)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
//                        Text("ReadBox")
//                            .font(.largeTitle)
//                            .fontDesign(.rounded)
//                            .fontWeight(.light)
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .frame(width: UIScreen.main.bounds.width, height: 130)
                                .foregroundStyle(Color(uiColor: .secondarySystemBackground))
                                .padding(.bottom, 40)
                                .shadow(radius: 10)
                            
                            HStack {
                                Text("ReadBox")
                                    .font(.largeTitle)
                                    .fontWeight(.light)
//                                    .fontDesign(.rounded)
                                
                                
                                if viewModel.isLoading {
                                    LoadingIndicator(animation: .circleRunner, color: Color(uiColor: .label), size: .small, speed: .fast)
                                }
                            }
                            .frame(width: UIScreen.main.bounds.width - 32, alignment: .leading)
                            
                        }
                        .padding(.leading, 6)
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
                .onChange(of: viewModel.topArticlesIndexes) { newValue in
                    if viewModel.topArticlesIndexes.count == 5 {
                        Task {
                            do {
                                try await viewModel.getTopArticles()
                                
                                return
                            } catch {
//                                withAnimation {
//                                    viewModel.errorText = error.localizedDescription
//                                }
                            }
                            
//                            viewModel.isErrorPopupPresented = true
                        }
                    }
                }
                .onChange(of: viewModel.topArticles) { newValue in
                    if viewModel.topArticles.count == 5 {
                        Task {
                            do {
                                try await viewModel.getArticles()
                                
                                return
                            } catch {
//                                withAnimation {
//                                    viewModel.errorText = error.localizedDescription
//                                }
                            }
                            
//                            viewModel.isErrorPopupPresented = true
                        }
                    }
                }
                .onAppear {
                    viewModel.primaryLanguage = StorageManager.shared.getLanguage()
                    
                    Task {
                        try? await viewModel.loadUser()
                    }
                    
                    if viewModel.maxIndex == "" && viewModel.fromIndex == -1 {
                        Task {
                            do {
                                try await viewModel.getMaxIndex()
                                viewModel.fromIndex = Int(viewModel.maxIndex) ?? 1
                                return
                            } catch {
                                withAnimation {
                                    viewModel.errorText = error.localizedDescription
                                }
                            }
                            
                            viewModel.isErrorPopupPresented = true
                        }
                    }
                    
                    Task {
                        do {
                            if viewModel.topArticlesIndexes == [] {
                                try await viewModel.getTopIndexes()
                            }
                
                            return
                        } catch {
                            withAnimation {
                                viewModel.errorText = error.localizedDescription
                            }
                        }
                        
                        viewModel.isErrorPopupPresented = true
                    }
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
                .onChange(of: viewModel.isReadViewPresented) { newValue in
                    if !newValue {
                        viewModel.postToView = nil
                    }
                }
                .onChange(of: viewModel.postToView) { newValue in
                    if newValue != nil {
                        viewModel.id = viewModel.postToView?.id ?? ""
                        viewModel.title = viewModel.postToView?.title ?? ""
                        viewModel.text = viewModel.postToView?.text ?? ""
                        viewModel.dateCreated = viewModel.postToView?.dateCreated ?? Date()
                        viewModel.likesCount = viewModel.postToView?.likesCount ?? 0
                        viewModel.authorId = viewModel.postToView?.authorId ?? ""
                        
                        viewModel.isReadViewPresented = true
                    }
                }
                .refreshable {
                    viewModel.primaryLanguage = StorageManager.shared.getLanguage()
                    
                    withAnimation {
                        viewModel.isLoading = true
                    }
                    
                    withAnimation {
                        viewModel.topArticlesIndexes = []
                        viewModel.topArticles = []
                        viewModel.articles = []
                        viewModel.authorsNames = [:]
                        viewModel.authorsCheckmarks = [:]
                    }
                    
                    Task {
                        do {
                            try await viewModel.getTopIndexes()
                            
                            return
                        } catch {
                            withAnimation {
                                viewModel.errorText = error.localizedDescription
                            }
                        }
                        
                        viewModel.isErrorPopupPresented = true
                    }
                    
                    Task {
                        try? await viewModel.loadUser()
                    }
                    
                    Task {
                        do {
                            try await viewModel.getMaxIndex()
                            viewModel.fromIndex = Int(viewModel.maxIndex) ?? 0
            
                            return
                        } catch {
                            withAnimation {
                                viewModel.errorText = error.localizedDescription
                            }
                        }
                        
                        viewModel.isErrorPopupPresented = true
                    }
                }
            }
            
        }
    }
}


#Preview {
    FeedView()
}


