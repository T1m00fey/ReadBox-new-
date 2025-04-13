//
//  ChannelView.swift
//  Readify
//
//  Created by Тимофей Юдин on 31.03.2025.
//

import SwiftUI
import PopupView
import SwiftfulLoadingIndicators

@MainActor
final class ChannelViewModel: ObservableObject {
    @Published var user: DBUser? = nil
    @Published var postsNeedToLoad: [String] = []
    @Published var isLoading = true
    @Published var posts: [Article] = []
    @Published var errorText = ""
    @Published var isErrorPopupPresented = false
    @Published var postOption = PostOptions.nothing
    @Published var id = ""
    @Published var isDescriptionPopupPresented = false
    @Published var isReadViewPresented = false
    @Published var subscribersCount = 0
    @Published var postsCount = 0
    
    var description = ""
    
    func loadPostsIndexes(id: String) async throws {
        let indexes = try await UserManager.shared.getAuthorsCreatedPosts(id: id) ?? []
        postsNeedToLoad = indexes.reversed()
        
        if postsNeedToLoad != [] {
            try await loadPosts()
        }
    }
    
    func getSubscribersCount(authorId: String) async throws {
        subscribersCount = try await UserManager.shared.getSubscribersCount(authorId: authorId)
    }
    
    func getPostsCount(authorId: String) async throws {
        postsCount = try await UserManager.shared.getPostsCount(authorId: authorId)
    }
    
    func loadPosts() async throws {
        var posts: [Article] = []
        var count = 0
        
        print("HERE")
        
        for index in postsNeedToLoad {
            if count < 20 && postsNeedToLoad != [] {
                do {
                    let post = try await ArticlesManager.shared.getArticle(id: index)
                    
                    if !(post.isArchive ?? true) {
                        posts.append(post)
                        count += 1
                    }
                    
                    postsNeedToLoad.removeAll { $0 == index }
                } catch {
                    withAnimation {
                        errorText = NSLocalizedString("someArticlesNotFoundLabel", comment: "")
                        isErrorPopupPresented = true
                    }
                }
            }
        }
        
        withAnimation {
            isLoading = false
        }
        
        withAnimation {
            for post in posts {
                self.posts.append(post)
            }
        }
    }
}

struct ChannelView: View {
    @StateObject private var viewModel = ChannelViewModel()
    
    @Environment(\.dismiss) var dismiss
    
    let authorId: String
    let authorName: String
    let isCheckmark: Bool
    
    @Binding var postToView: Article?
    
    var body: some View {
        NavigationStack {
            
            ScrollView(showsIndicators: false) {
                
                VStack(spacing: 20) {
                    if viewModel.isLoading {
                        HStack {
                            VStack {
                                Text("10 000")
                                    .font(.title)
                                    .frame(width: UIScreen.main.bounds.width / 2 - 47)
                                    .fontDesign(.rounded)
                                    .padding(.top, 20)
                                
                                Text("публикации")
                                    .font(.title3)
                                    .foregroundStyle(Color.gray)
                                    .fontDesign(.rounded)
                                    .padding(.bottom, 10)
                            }
                            .frame(width: UIScreen.main.bounds.width / 2 - 15)
                            .background(Color(uiColor: .secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(radius: 2)
                            
                            Spacer()
                            
                            VStack {
                                Text("100 000")
                                    .font(.title)
                                    .frame(width: UIScreen.main.bounds.width / 2 - 47)
                                    .fontDesign(.rounded)
                                    .padding(.top, 20)
                                
                                Text("подписчики")
                                    .font(.title3)
                                    .fontDesign(.rounded)
                                    .foregroundStyle(Color.gray)
                                    .padding(.bottom, 10)
                            }
                            .frame(width: UIScreen.main.bounds.width / 2 - 15)
                            .background(Color(uiColor: .secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(radius: 2)
                        }
                        .frame(width: UIScreen.main.bounds.width - 15)
                        .padding(.top, 20)
                        .redacted(reason: .placeholder)
                        
                        ForEach(0..<7) { num in
                            PostView(
                                id: "-1",
                                title: "Hello, World!",
                                likesCount: 10,
                                viewsCount: 10,
                                isArchive: false,
                                isAuthorView: false,
                                postOption: $viewModel.postOption,
                                selectedId: $viewModel.id
                            )
                            .redacted(reason: .placeholder)
                            .padding(.top, num == 0 ? 10 : 0)
                        }
                    } else if !viewModel.posts.isEmpty {
                        
                        HStack {
                            VStack {
                                Text("\(viewModel.postsCount)")
                                    .font(.title2)
                                    .frame(width: UIScreen.main.bounds.width / 2 - 47)
                                    .fontDesign(.rounded)
                                    .padding(.top, 20)
                                
                                Text("публикации")
                                    .font(.title3)
                                    .foregroundStyle(Color.gray)
                                    .fontDesign(.rounded)
                                    .padding(.bottom, 10)
                            }
                            .frame(width: UIScreen.main.bounds.width / 2 - 15)
                            .background(Color(uiColor: .secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(radius: 2)
                            
                            Spacer()
                            
                            VStack {
                                Text("\(viewModel.subscribersCount)")
                                    .font(.title2)
                                    .frame(width: UIScreen.main.bounds.width / 2 - 47)
                                    .fontDesign(.rounded)
                                    .padding(.top, 20)
                                
                                Text("подписчики")
                                    .font(.title3)
                                    .fontDesign(.rounded)
                                    .foregroundStyle(Color.gray)
                                    .padding(.bottom, 10)
                            }
                            .frame(width: UIScreen.main.bounds.width / 2 - 15)
                            .background(Color(uiColor: .secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(radius: 2)
                        }
                        .frame(width: UIScreen.main.bounds.width - 15)
                        .padding(.top, 20)
                        
                        ForEach(viewModel.posts) { post in
                            PostView(
                                id: post.id,
                                title: post.title ?? NSLocalizedString("notFoundLabel", comment: ""),
                                likesCount: post.likesCount ?? 0,
                                viewsCount: post.viewsCount ?? 0,
                                isArchive: post.isArchive ?? false,
                                isAuthorView: false,
                                postOption: $viewModel.postOption,
                                selectedId: $viewModel.id
                            )
                            .padding(.top, post.id == viewModel.posts[0].id ? 10 : 0)
                            .onTapGesture {
                                if (post.description ?? "abc") != "" {
                                    viewModel.description = post.description ?? ""
                                    viewModel.isDescriptionPopupPresented = true
                                } else {
                                    postToView = Article(
                                        id: post.id,
                                        dateCreated: post.dateCreated,
                                        title: post.title,
                                        text: post.text,
                                        description: post.description,
                                        likesCount: post.likesCount,
                                        isArchive: post.isArchive,
                                        authorId: post.authorId,
                                        viewsCount: post.viewsCount,
                                        originalLanguage: post.originalLanguage
                                    )
                                    
                                    dismiss()
                                }
            
                            }
            
                        }
                    }
                    
                    if viewModel.postsNeedToLoad.count > 0 {
                        Button {
                            Task {
                                do {
                                    try await viewModel.loadPosts()
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
//                    else {
//                        VStack(spacing: 20) {
//                            
//                            Image(systemName: "square.and.pencil")
//                                .resizable()
//                                .frame(width: 100, height: 100)
//                                .foregroundStyle(Color.gray)
//                            
//                            Text(LocalizedStringKey("noArticlesAddedLabel"))
//                                .font(.title)
//                                .bold()
//                                .fontDesign(.rounded)
//                                .foregroundStyle(Color.gray)
//                                .multilineTextAlignment(.center)
//                        }
//                        .frame(height: UIScreen.main.bounds.height - 200, alignment: .center)
//                    }
                    
                }
                .padding(.horizontal)
                
            }
            .padding(.top, 20)
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
            .onAppear(perform: {
                Task {
                    do {
                        try await viewModel.loadPostsIndexes(id: authorId)
                    } catch {
                        withAnimation {
                            viewModel.errorText = NSLocalizedString("loadDataErrorLabel", comment: "")
                            viewModel.isErrorPopupPresented = true
                        }
                    }
                }
                
                Task {
                    do {
                        try await viewModel.getPostsCount(authorId: authorId)
                        try await viewModel.getSubscribersCount(authorId: authorId)
                    } catch {
                        withAnimation {
                            viewModel.errorText = error.localizedDescription
                            viewModel.isErrorPopupPresented = true
                        }
                    }
                }
            })
            .refreshable {
                withAnimation {
                    viewModel.isLoading = true
                    
                    viewModel.postsNeedToLoad = []
                    viewModel.posts = []
                    
                    Task {
                        do {
                            try await viewModel.loadPostsIndexes(id: authorId)
                        } catch {
                            withAnimation {
                                viewModel.errorText = NSLocalizedString("loadDataErrorText", comment: "")
                                viewModel.isErrorPopupPresented = true
                            }
                        }
                    }
                    
                    Task {
                        do {
                            try await viewModel.getPostsCount(authorId: authorId)
                            try await viewModel.getSubscribersCount(authorId: authorId)
                        } catch {
                            withAnimation {
                                viewModel.errorText = error.localizedDescription
                                viewModel.isErrorPopupPresented = true
                            }
                        }
                    }
                }
            }
            .toolbar {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .frame(width: UIScreen.main.bounds.width, height: 130)
                        .foregroundStyle(Color(uiColor: .secondarySystemBackground))
                        .padding(.bottom, 40)
                        .shadow(radius: 10)
                    
                    HStack {
                        HStack(spacing: 0) {
                            Text(authorName)
                                .font(.largeTitle)
                                .fontWeight(.light)
//                                .fontDesign(.rounded)
                            
                            if isCheckmark {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundStyle(Color.blue)
                                    .font(.footnote)
                                    .padding(.top, 4)
                            }
                        }
                        
                        if viewModel.isLoading {
                            LoadingIndicator(animation: .circleRunner, color: Color(uiColor: .label), size: .small, speed: .fast)
                        } else {
                        }
                        
                        Spacer()
                        
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                        }
                    }
                    .padding(.horizontal, 10)
                }
            }
    
        }
    }
}

#Preview {
    ChannelView(authorId: "", authorName: "", isCheckmark: false, postToView: .constant(nil))
}
