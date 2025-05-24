//
//  CreateView.swift
//  Readify
//
//  Created by Тимофей Юдин on 20.01.2025.
//

import SwiftUI
import PopupView
import FirebaseStorage
import SwiftfulLoadingIndicators

enum PostOptions {
    case nothing
    case editing
    case toArchive
    case publish
    case delete
}

@MainActor
final class CreatedPostsViewModel: ObservableObject {
    @Published var isErrorPopupPresented = false
    @Published var errorText = ""
    @Published var articlesIndexes: [String] = []
    @Published var articles: [Article] = []
    @Published var archivePosts: [Article] = []
    @Published var isDescriptionPopupPresented = false
    @Published var isReadViewPresented = false
    @Published var isNewNameAlertPresented = false
    @Published var isSuccessPopupPresented = false
    @Published var isCreateViewPresented = false
    @Published var isArchivePresented = false
    @Published var postsNeedToLoad: [String] = []
    @Published var isLoading = true
    @Published var postOption: PostOptions = .nothing
    @Published var likedPosts: [String] = []
    @Published var isNewPublicationButtonPresented = true
    @Published var authorNameText = ""
    @Published var isButtonEnabled = false
    @Published var isChannelViewPresented = false
    @Published var descriptionText = ""
    @Published var isSettingViewPresented = false
    
    @Published var user: DBUser? = nil
    
    @Published var id = ""
    
    var description = ""
    var title = ""
    var image: UIImage? = nil
    var text = ""
    var likesCount = 0
    var dateCreated = Date()
    var isEditing = false
    
    var alertText = ""
    
    func isButtonEnable() {
        withAnimation {
            if authorNameText.count > 0 {
                isButtonEnabled = true
            } else {
                isButtonEnabled = false
            }
        }
    }
    
    func loadUser() async throws {
        let authDataResult = try AuthenticationManager.shared.getAuthenticatedUser()
        let user = try await UserManager.shared.getUser(userId: authDataResult.uid)
        
        self.user = user
    }
    
    func getAuthorIsCheckmarkStatus(id: String) async throws -> Bool {
        try await UserManager.shared.getIsCheckmarkStatus(id: id) ?? false
    }
    
    func changeAuthorName(to name: String, description: String) async throws {
        try await UserManager.shared.changeAuthorName(userId: user?.userId ?? "", to: name, description: description)
    }
    
    func removeCheckmarkStatus() async throws {
        try await UserManager.shared.removeCheckmarkStatus(userId: user?.userId ?? "")
    }
    
    func getArticle(id: String) async throws -> Article {
        try await ArticlesManager.shared.getArticle(id: id)
    }
    
    func getIndexes() async throws {
        let indexes = try await UserManager.shared.getAuthorsCreatedPosts(id: user?.userId ?? "") ?? []
        articlesIndexes = indexes.reversed()
    }
    
    func deletePost(id: String) {
        Task {
            do {
                try await ArticlesManager.shared.deletePost(id: id)
                try await UserManager.shared.deleteCreatedPost(id: id)
            } catch {
                withAnimation {
                    errorText = error.localizedDescription
                    isErrorPopupPresented = true
                }
            }
        }
        
        Task {
            StorageManager.shared.deleteImage(id: id)
            
            let fileReference = Storage.storage().reference().child("images/\(id).jpg")
            
            try? await fileReference.delete()
        }
        
        withAnimation {
            if isArchivePresented {
                archivePosts.removeAll { $0.id == id }
            } else {
                articles.removeAll { $0.id == id }
            }
        }
        
        self.id = ""
    }
    
    func updateIsArchiveStatus() {
       Task {
            do {
                try await ArticlesManager.shared.updateIsArchiveStatus(id: id, isArchive: !isArchivePresented)
            } catch {
                withAnimation {
                    errorText = error.localizedDescription
                    isErrorPopupPresented = true
                }
                
                return
            }
            
            withAnimation {
                if isArchivePresented {
                    articles.insert(archivePosts.filter { $0.id == id }[0], at: 0)
                    articles[0].isArchive?.toggle()
                    archivePosts.removeAll { $0.id == id }
                } else {
                    archivePosts.insert(articles.filter { $0.id == id }[0], at: 0)
                    archivePosts[0].isArchive?.toggle()
                    articles.removeAll { $0.id == id }
                }
            }
           
           id = ""
        }
    }
    
    func getArticles() async throws {
        
        var indexes: [String] = []
        var posts: [Article] = []
        var archivedPosts: [Article] = []
        
        var count = 0
        
        for index in postsNeedToLoad {
            if count < 20 {
                indexes.append(index)
                count += 1
            }
        }
        
        count = 0
        
        for index in indexes {
            do {
                let article = try await getArticle(id: index)
                
                withAnimation {
                    if article.isArchive ?? true {
                        archivedPosts.append(article)
                    } else {
                        posts.append(article)
                    }
                    
                    postsNeedToLoad.removeAll { $0 == index }
                }
            } catch {
                withAnimation {
                    errorText = NSLocalizedString("someArticlesNotFoundLabel", comment: "")
                    isErrorPopupPresented = true
                }
                
                isLoading = false
                
                return
            }
        }
                
        withAnimation {
            isLoading = false
        }
        
        for post in posts {
            withAnimation {
                articles.append(post)
            }
        }
        
        for post in archivedPosts {
            withAnimation {
                archivePosts.append(post)
            }
        }
            
    }
}

struct CreatedPostsView: View {
    @StateObject var viewModel = CreatedPostsViewModel()
    
    @FocusState var isAuthorNameFocused: Bool
    @FocusState var isDescriptionFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemBackground)
                    .ignoresSafeArea()
                    .onTapGesture {
                        isAuthorNameFocused = false
                        isDescriptionFocused = false
                    }
                    .onAppear {
                        Task {
                            do {
                                try await viewModel.loadUser()
                                
                                withAnimation {
                                    viewModel.authorNameText = viewModel.user?.authorName ?? ""
                                    viewModel.descriptionText = viewModel.user?.authorDescription ?? ""
                                }
                            } catch {
                                viewModel.isErrorPopupPresented = true
                                viewModel.errorText = error.localizedDescription
                            }
                        }
                    }
                    .onChange(of: viewModel.isDescriptionPopupPresented) { newValue in
                        if !newValue {
                            withAnimation {
                                viewModel.isNewPublicationButtonPresented = true
                            }
                        }
                    }
                    .onChange(of: viewModel.id) { newValue in
                        if viewModel.id != "" {
                            var article: Article? = nil
                            
                            if viewModel.isArchivePresented {
                                article = viewModel.archivePosts.filter { $0.id == viewModel.id }[0]
                            } else {
                                article = viewModel.articles.filter { $0.id == viewModel.id }[0]
                            }
                            
                            switch viewModel.postOption {
                            case .editing:
                                viewModel.title = article?.title ?? NSLocalizedString("notFoundLabel", comment: "")
                                viewModel.image = StorageManager.shared.getImage(id: viewModel.id)
                                viewModel.description = article?.description ?? NSLocalizedString("notFoundLabel", comment: "")
                                viewModel.text = article?.text ?? NSLocalizedString("notFoundLabel", comment: "")
                                viewModel.isEditing = true
                                
                                viewModel.isCreateViewPresented = true
                            case .publish:
                                viewModel.updateIsArchiveStatus()
                                viewModel.postOption = .nothing
                            case .toArchive:
                                viewModel.updateIsArchiveStatus()
                                viewModel.postOption = .nothing
                            case .delete:
                                viewModel.deletePost(id: viewModel.id)
                                viewModel.postOption = .nothing
                            default:
                                print("OK")
                            }
                        }
                    }
                    .onChange(of: viewModel.user) { newValue in
                        if viewModel.user != nil {
                            Task {
                                do {
                                    try await viewModel.getIndexes()
                                    
                                    if viewModel.articlesIndexes.count == 0 {
                                        withAnimation {
                                            viewModel.isLoading = false
                                        }
                                    }
                                } catch {
                                    withAnimation {
                                        viewModel.errorText = error.localizedDescription
                                        viewModel.isErrorPopupPresented = true
                                    }
                                }
                            }
                        }
                    }
                    .onChange(of: viewModel.articlesIndexes) { newValue in
                        if viewModel.articlesIndexes != [] {
                            Task {
                                do {
                                    viewModel.postsNeedToLoad = viewModel.articlesIndexes
                                    try await viewModel.getArticles()
                                } catch {
                                    withAnimation {
                                        viewModel.errorText = error.localizedDescription
                                        viewModel.isErrorPopupPresented = true
                                    }
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
                            description: viewModel.description,
                            text: viewModel.text,
                            isEditing: viewModel.isEditing
                        )
                    })
                    .fullScreenCover(isPresented: $viewModel.isReadViewPresented) {
                        ReadView(
                            id: viewModel.id,
                            userId: viewModel.user?.userId ?? "",
                            title: viewModel.title,
                            text: viewModel.text,
                            dateCreated: viewModel.dateCreated,
                            likesCount: viewModel.likesCount,
                            authorName: viewModel.user?.authorName ??  NSLocalizedString("notFoundLabel", comment: ""),
                            isCheckmark: viewModel.user?.isCheckmark ?? false,
                            likedPosts: $viewModel.likedPosts,
                            isChannelViewPresented: .constant(false)
                        )
                    }
                    .onChange(of: viewModel.isReadViewPresented) { newValue in
                        if !newValue {
                            viewModel.postOption = .nothing
                            viewModel.id = ""
                        }
                    }
                    .onChange(of: viewModel.isCreateViewPresented) { newValue in
                        if !newValue {
                            viewModel.postOption = .nothing
                            viewModel.id = ""
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
                    .popup(isPresented: $viewModel.isSuccessPopupPresented) {
                        Text(viewModel.errorText)
                            .frame(width: UIScreen.main.bounds.width - 72, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            .foregroundStyle(Color.white)
                            .background(Color.green)
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
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            
                            ZStack {
                                RoundedRectangle(cornerRadius: 20)
                                    .frame(width: UIScreen.main.bounds.width, height: 170)
                                    .foregroundStyle(Color(uiColor: .secondarySystemBackground))
                                    .padding(.bottom, 40)
                                    .shadow(radius: 10)
                                
                                if viewModel.user?.authorName == "" && !viewModel.isLoading {
                                    Text(NSLocalizedString("becomeAuthorLabel", comment: ""))
                                        .font(.largeTitle)
                                        .fontWeight(.light)
//                                        .fontDesign(.rounded)
                                        .frame(width: UIScreen.main.bounds.width - 32, alignment: .leading)
                                } else if viewModel.isSettingViewPresented {
                                    Text(NSLocalizedString("editingLabel", comment: ""))
                                        .font(.largeTitle)
                                        .fontWeight(.light)
//                                        .fontDesign(.rounded)
                                        .frame(width: UIScreen.main.bounds.width - 32, alignment: .leading)
                                } else {
                                    if viewModel.isLoading {
                                        VStack(spacing: -30) {
                                            HStack {
                                                HStack(spacing: 0) {
                                                    Text("Hello, World!")
                                                        .font(.largeTitle)
                                                        .fontWeight(.light)
                                                        .redacted(reason: .placeholder)
                                                    
                                                    Image(systemName: "checkmark.seal.fill")
                                                        .foregroundStyle(Color.blue)
                                                        .font(.footnote)
                                                        .padding(.top, 4)
                                                        .redacted(reason: .placeholder)
                                                }
                                                
                                                
                                                Spacer()
                                                
                                                Button {
                                                    withAnimation {
                                                        viewModel.isSettingViewPresented.toggle()
                                                    }
                                                } label: {
                                                    Image(systemName: "gearshape.fill")
                                                        .foregroundStyle(Color.gray)
                                                        .font(.system(size: 17))
                                                        .fontWeight(.bold)
                                                }
                                                .offset(x: 10)
                                                .redacted(reason: .placeholder)
                                                
                                                Button {
                                                    withAnimation {
                                                        viewModel.isArchivePresented.toggle()
                                                    }
                                                } label: {
                                                    if viewModel.isArchivePresented {
                                                        Image(systemName: "rectangle.on.rectangle")
                                                            .font(.system(size: 19))
                                                            .fontWeight(.bold)
                                                            .foregroundStyle(Color.gray)
                                                    } else {
                                                        Image(systemName: "archivebox")
                                                            .font(.system(size: 19))
                                                            .fontWeight(.bold)
                                                            .foregroundStyle(Color.gray)
                                                    }
                                                }
                                                .redacted(reason: .placeholder)
                                                
                                            }
                                            .frame(width: UIScreen.main.bounds.width - 32, alignment: .leading)
                                            
                                            HStack {
                                                Text("\(viewModel.user?.subscribersCount ?? 0) \(NSLocalizedString("subscribersCountLabel", comment: ""))")
                                                .font(.callout)
                                                .foregroundStyle(Color.gray)
                                                    
                                                Text("•")
                                                    .font(.title)
                                                    .foregroundStyle(Color.gray)
                                                
                                                Text("\(viewModel.articles.count) \(NSLocalizedString("publicationsCountLabel", comment: ""))")
                                                .font(.callout)
                                                .foregroundStyle(Color.gray)
                                            }
                                            .frame(width: UIScreen.main.bounds.width - 32, alignment: .leading)
                                            .offset(y: -50)
                                        }
                                    } else {
                                        VStack(spacing: -30) {
                                            HStack {
                                                HStack(spacing: 0) {
                                                    Text(viewModel.user?.authorName ?? "")
                                                        .font(.largeTitle)
                                                        .fontWeight(.light)
    //                                                    .fontDesign(.rounded)
                                                    
                                                    if viewModel.user?.isCheckmark ?? false {
                                                        Image(systemName: "checkmark.seal.fill")
                                                            .foregroundStyle(Color.blue)
                                                            .font(.footnote)
                                                            .padding(.top, 4)
                                                    }
                                                }
                                                
                                                
                                                Spacer()
                                                
                                                Button {
                                                    withAnimation {
                                                        viewModel.isSettingViewPresented.toggle()
                                                    }
                                                } label: {
                                                    Image(systemName: "gearshape.fill")
                                                        .foregroundStyle(Color.gray)
                                                        .font(.system(size: 17))
                                                        .fontWeight(.bold)
                                                }
                                                .offset(x: 10)
                                                
                                                Button {
                                                    withAnimation {
                                                        viewModel.isArchivePresented.toggle()
                                                    }
                                                } label: {
                                                    if viewModel.isArchivePresented {
                                                        Image(systemName: "rectangle.on.rectangle")
                                                            .font(.system(size: 19))
                                                            .fontWeight(.bold)
                                                            .foregroundStyle(Color.gray)
                                                    } else {
                                                        Image(systemName: "archivebox")
                                                            .font(.system(size: 19))
                                                            .fontWeight(.bold)
                                                            .foregroundStyle(Color.gray)
                                                    }
                                                }
                                                
                                            }
                                            .frame(width: UIScreen.main.bounds.width - 32, alignment: .leading)
                                            
                                            HStack {
                                                if viewModel.isLoading {
                                                    
                                                }
                                                
                                                Text("\(viewModel.user?.subscribersCount ?? 0) \(NSLocalizedString("subscribersCountLabel", comment: ""))")
                                                .font(.callout)
                                                .foregroundStyle(Color.gray)
                                                    
                                                Text("•")
                                                    .font(.title)
                                                    .foregroundStyle(Color.gray)
                                                
                                                Text("\(viewModel.articles.count) \(NSLocalizedString("publicationsCountLabel", comment: ""))")
                                                .font(.callout)
                                                .foregroundStyle(Color.gray)
                                            }
                                            .frame(width: UIScreen.main.bounds.width - 32, alignment: .leading)
                                            .offset(y: -50)
                                        }
                                    }
                                }
                            }
                            .padding(.leading, 6)
                        }
                        
                    }
                
                if viewModel.isLoading || viewModel.articles.count > 0 || viewModel.archivePosts.count > 0 {
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            if viewModel.isLoading {
                                
                                Text("HelloWorldHelloWorld HelloWorld HelloWorld HelloWorldHelloWorld HelloWorld HelloWorld")
                                    .padding(.vertical, 20)
                                    .padding(.horizontal, 16)
                                    .frame(width: UIScreen.main.bounds.width, alignment: .leading)
                                    .background(Color(uiColor: .secondarySystemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                                    .padding(.top, 50)
                                    .redacted(reason: .placeholder)
                                
                                Text(NSLocalizedString("publicationsLabel", comment: ""))
                                    .font(.title)
                                    .fontWeight(.light)
                                    .fontDesign(.rounded)
                                    .frame(width: UIScreen.main.bounds.width - 20, alignment: .leading)
                                    .padding(.top, 20)
                                    .redacted(reason: .placeholder)
                                
                                ForEach(0..<7) { num in
                                    PostView(
                                        id: "-1",
                                        title: "Hello, World!",
                                        likesCount: 10,
                                        viewsCount: 10,
                                        isArchive: false,
                                        isAuthorView: true,
                                        postOption: $viewModel.postOption,
                                        selectedId: $viewModel.id
                                    )
                                    .padding(.horizontal)
                                    .redacted(reason: .placeholder)
                                }
                                
                            } else if viewModel.articles.count > 0 && !viewModel.isArchivePresented {
                                
                                if viewModel.user?.authorDescription ?? "" != "" {
                                    Text(viewModel.user?.authorDescription ?? NSLocalizedString("notFoundLabel", comment: ""))
                                        .font(.title3)
                                        .padding(.vertical, 20)
                                        .padding(.horizontal, 16)
                                        .frame(width: UIScreen.main.bounds.width, alignment: .leading)
                                        .background(Color(uiColor: .secondarySystemBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 20))
                                        .padding(.top, 50)
                                }
                                
                                Text(NSLocalizedString("publicationsLabel", comment: ""))
                                    .font(.title)
                                    .fontWeight(.light)
                                    .fontDesign(.rounded)
                                    .frame(width: UIScreen.main.bounds.width - 20, alignment: .leading)
                                    .padding(.top, 20)
                                
                                ForEach(viewModel.articles) { article in
                                    PostView(
                                        id: article.id,
                                        title: article.title ?? NSLocalizedString("noFoundLabel", comment: ""),
                                        likesCount: article.likesCount ?? 0,
                                        viewsCount: article.viewsCount ?? 0,
                                        isArchive: article.isArchive ?? false,
                                        isAuthorView: true,
                                        postOption: $viewModel.postOption,
                                        selectedId: $viewModel.id
                                    )
                                    .padding(.bottom, article.id == viewModel.articles[viewModel.articles.count - 1].id ? 70 : 0)
                                    .onTapGesture {
                                        viewModel.description = article.description ?? NSLocalizedString("notFoundLabel", comment: "")
                                        viewModel.title = article.title ?? NSLocalizedString("notFoundLabel", comment: "")
                                        viewModel.text = article.text ?? NSLocalizedString("notFoundLabel", comment: "")
                                        viewModel.image = StorageManager.shared.getImage(id: article.id) ?? UIImage()
                                        viewModel.dateCreated = article.dateCreated ?? Date()
                                        viewModel.likesCount = article.likesCount ?? 0
                                        viewModel.id = article.id
                                        
                                        if viewModel.user != nil {
                                            if viewModel.likedPosts == [] {
                                                viewModel.likedPosts = viewModel.user?.likedPosts ?? []
                                            }
                                            
                                            if viewModel.description == "" {
                                                viewModel.isReadViewPresented = true
                                                
                                            } else {
                                                viewModel.isDescriptionPopupPresented = true
                                                
                                                withAnimation {
                                                    viewModel.isNewPublicationButtonPresented = false
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
                                .padding(.horizontal)
                                
                            } else if viewModel.isArchivePresented && viewModel.archivePosts.count > 0 {
                                Text(NSLocalizedString("publicationsLabel", comment: ""))
                                    .font(.title)
                                    .fontWeight(.light)
                                    .fontDesign(.rounded)
                                    .frame(width: UIScreen.main.bounds.width - 20, alignment: .leading)
                                    .padding(.top, 20)
                                
                                ForEach(viewModel.archivePosts) { article in
                                    PostView(
                                        id: article.id,
                                        title: article.title ?? NSLocalizedString("noFoundLabel", comment: ""),
                                        likesCount: article.likesCount ?? 0,
                                        viewsCount: article.viewsCount ?? 0,
                                        isArchive: article.isArchive ?? false,
                                        isAuthorView: true,
                                        postOption: $viewModel.postOption,
                                        selectedId: $viewModel.id
                                    )
                                    .padding(.bottom, article.id == viewModel.archivePosts[viewModel.archivePosts.count - 1].id ? 70 : 0)
                                    .onTapGesture {
                                        viewModel.description = article.description ?? NSLocalizedString("notFoundLabel", comment: "")
                                        viewModel.title = article.title ?? NSLocalizedString("notFoundLabel", comment: "")
                                        viewModel.text = article.text ?? NSLocalizedString("notFoundLabel", comment: "")
                                        viewModel.dateCreated = article.dateCreated ?? Date()
                                        viewModel.likesCount = article.likesCount ?? 0
                                        viewModel.id = article.id
                                        
                                        if viewModel.user != nil {
                                            if viewModel.likedPosts == [] {
                                                viewModel.likedPosts = viewModel.user?.likedPosts ?? []
                                            }
                                            
                                            if viewModel.description == "" {
                                                viewModel.isReadViewPresented = true
                                            } else {
                                                viewModel.isDescriptionPopupPresented = true
                                                
                                                withAnimation {
                                                    viewModel.isNewPublicationButtonPresented = false
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
                                .padding(.horizontal)
                                
                            } else {
                                VStack(spacing: 20) {
                                    
                                    Image(systemName: "square.and.pencil")
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
                            }
                            
                            if (viewModel.articles != [] && viewModel.postsNeedToLoad.count > 0) || (viewModel.archivePosts != [] && viewModel.postsNeedToLoad.count > 0) {
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
                    .frame(width: UIScreen.main.bounds.width)
                    .padding(.top, 20)
                    .refreshable {
                        if !viewModel.isLoading {
                            viewModel.isLoading = true
                            viewModel.articles = []
                            viewModel.archivePosts = []
                            viewModel.articlesIndexes = []
                            
                            viewModel.user = nil
                            
                            try? await viewModel.loadUser()
                        }
                    }
                    
                    if !viewModel.isLoading && viewModel.isNewPublicationButtonPresented && viewModel.user?.authorName != "" {
                        VStack {
                            Spacer()
                            
                            Text(NSLocalizedString("newPublicationLabel", comment: ""))
                                .frame(width: UIScreen.main.bounds.width - 10, height: 50, alignment: .center)
                                .font(.title3)
                                .fontDesign(.rounded)
                                .background(Color(uiColor: .label))
                                .foregroundStyle(Color(uiColor: .systemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 15))
                                .shadow(radius: 3)
                                .padding(.bottom, 10)
                                .onTapGesture {
                                    viewModel.title = NSLocalizedString("titlePlaceholder", comment: "")
                                    viewModel.description = NSLocalizedString("descriptionPlaceholder", comment: "")
                                    viewModel.image = nil
                                    viewModel.isEditing = false
                                    viewModel.isCreateViewPresented = true
                                }
                        }
                    }
                } else if viewModel.user?.authorName ?? "" == "" || viewModel.isSettingViewPresented == true {
                    VStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: 30)
                                .foregroundStyle(Color(uiColor: .secondarySystemBackground))
                                .frame(width: UIScreen.main.bounds.width - 60, height: 150)
                                .shadow(radius: 2)
                            
                            VStack(spacing: 25) {
                                VStack {
                                    TextField(LocalizedStringKey("nameLabel"), text: $viewModel.authorNameText)
                                        .frame(width: UIScreen.main.bounds.width - 92)
                                        .font(.title2)
                                        .focused($isAuthorNameFocused)
                                        .textInputAutocapitalization(.never)
                                        .onChange(of: viewModel.authorNameText) { _ in
                                            viewModel.isButtonEnable()
                                        }
                                    
                                    RoundedRectangle(cornerRadius: 0)
                                        .frame(width: UIScreen.main.bounds.width - 92, height: 2)
                                        .foregroundStyle(isAuthorNameFocused ? Color(uiColor: .label) : Color.gray)
                                }
                                
                                VStack {
                                    TextField(NSLocalizedString("descriptionLabel", comment: ""), text: $viewModel.descriptionText)
                                        .frame(width: UIScreen.main.bounds.width - 92)
                                        .font(.title2)
                                        .focused($isDescriptionFocused)
                                        .textInputAutocapitalization(.never)
                                        
                                    RoundedRectangle(cornerRadius: 0)
                                        .frame(width: UIScreen.main.bounds.width - 92, height: 2)
                                        .foregroundStyle(isDescriptionFocused ? Color(uiColor: .label) : Color.gray)
                                }
                            }
                            .frame(height: 150)
                            .onAppear {
                                viewModel.isButtonEnable()
                            }
                        }
                        
                        Button {
                            if viewModel.authorNameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                withAnimation {
                                    viewModel.errorText = NSLocalizedString("nameErrorLabel", comment: "")
                                    viewModel.isErrorPopupPresented = true
                                }
                            } else {
                                Task {
                                    do {
                                        try await viewModel.changeAuthorName(to: viewModel.authorNameText, description: viewModel.descriptionText)
                                        
                                        withAnimation {
                                            viewModel.isSettingViewPresented = false
                                            viewModel.user?.authorName = viewModel.authorNameText
                                            viewModel.isLoading = true
                                        }
                                        
                                        viewModel.articles = []
                                        viewModel.articlesIndexes = []
                                        
                                        Task {
                                            do {
                                                try await viewModel.getIndexes()
                                            } catch {
                                                withAnimation {
                                                    viewModel.errorText = error.localizedDescription
                                                    viewModel.isErrorPopupPresented = true
                                                }
                                            }
                                        }
                                    } catch {
                                        withAnimation {
                                            viewModel.errorText = error.localizedDescription
                                            viewModel.isErrorPopupPresented = true
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Text(LocalizedStringKey("nextLabel"))
                                    .foregroundStyle(
                                        viewModel.isButtonEnabled
                                        ? Color(uiColor: .label)
                                        : Color.gray
                                    )
                            }
                            .frame(width: UIScreen.main.bounds.width - 60, height: 50)
                            .background(Color(uiColor: .secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .font(.title2)
                            .shadow(radius: viewModel.isButtonEnabled ? 2 : 0)
                        }
                        .disabled(!viewModel.isButtonEnabled)
                        .padding(.top, 10)
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

#Preview {
    CreatedPostsView()
}
