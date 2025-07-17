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

struct ChannelView: View {
    @StateObject private var viewModel = ChannelViewModel()
    
    @Environment(\.dismiss) var dismiss
    
    @Binding var user: DBUser?
    
    let authorId: String
    let authorName: String
    let isCheckmark: Bool
    
    @Binding var postToView: PrePost?
    @Binding var postToRead: PostToRead?
    
    var body: some View {
        NavigationStack {
            
            ZStack {
                
                Color(uiColor: .systemBackground)
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        if viewModel.isLoadingShowing {
                            Text("HelloWorldHelloWorld HelloWorld HelloWorld HelloWorldHelloWorld HelloWorld HelloWorld")
                                .padding(.vertical, 20)
                                .padding(.horizontal, 16)
                                .frame(width: UIScreen.main.bounds.width, alignment: .leading)
                                .background(Color(uiColor: .secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .padding(.top, 50)
                                .redacted(reason: .placeholder)
                                .shimmering()
                            
                            Text(NSLocalizedString("publicationsLabel", comment: ""))
                                .font(.title)
                                .fontWeight(.light)
                                .fontDesign(.rounded)
                                .frame(width: UIScreen.main.bounds.width - 20, alignment: .leading)
                                .padding(.top, 20)
                                .redacted(reason: .placeholder)
                                .shimmering()
                            
                            ForEach(0..<3) { num in
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
                                .padding(.bottom, num == 6 ? 100 : 0)
                                .shimmering()
                            }
                        } else if !viewModel.posts.isEmpty {
                            
                            if viewModel.authorDescription != "" {
                                Text(viewModel.authorDescription)
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
                                .padding(.bottom, post.id == viewModel.posts[viewModel.posts.count - 1].id ? 100 : 0)
                                .onTapGesture {
                                    viewModel.isLoadingPopupPresented = true
                                    
                                    Task {
                                        do {
                                            let postToread = try await ArticlesManager.shared.getPostToRead(id: post.id)
                                            
                                            if postToread.description == "" {
                                                viewModel.isLoadingPopupPresented = false
                                                
                                                postToView = PrePost(
                                                    id: post.id,
                                                    title: post.title,
                                                    authorId: post.authorId,
                                                    viewsCount: post.viewsCount,
                                                    likesCount: post.likesCount,
                                                    isArchive: post.isArchive
                                                )
                                                
                                                postToRead = PostToRead(
                                                    dateCreated: postToread.dateCreated,
                                                    text: postToread.text,
                                                    description: postToread.description
                                                )
//                                                
                                                dismiss()
                                            } else {
                                                viewModel.description = postToread.description ?? NSLocalizedString("notFoundLabel", comment: "")
                                                
                                                viewModel.isLoadingPopupPresented = false
                                                viewModel.isDescriptionPopupPresented = true
                                            }
                                            
//                                            if (viewModel.user?.createdPosts ?? [id]).contains(id) == false {
//                                                if !viewModel.views.contains(id) {
//                                                    Task {
//                                                        do {
//                                                            try await ArticlesManager.shared.updateViews(at: post.id)
//                                                            
//                                                            viewModel.views.append(id)
//                                                            viewModel.saveViews()
//                                                        }
//                                                    }
//                                                }
//                                            }
                                        } catch {
                                            withAnimation {
                                                viewModel.errorText = error.localizedDescription
                                                viewModel.isErrorPopupPresented = true
                                            }
                                        }
                                    }
                                    
                                    viewModel.isLoadingPopupPresented = false
                                    
                                    let userId = try? AuthenticationManager.shared.getAuthenticatedUser().uid
                                    
                                    if userId != authorId {
                                        if !viewModel.views.contains(post.id) {
                                            Task {
                                                do {
                                                    try await ArticlesManager.shared.updateViews(at: post.id)
                                                    
                                                    viewModel.views.append(post.id)
                                                    viewModel.saveViews()
                                                }
                                            }
                                        }
                                    }
                                    
                                }
                                .onChange(of: viewModel.isReadViewPresented) {
                                    if viewModel.isReadViewPresented {
                                        viewModel.isLoadingPopupPresented = true
                                        
                                        Task {
                                            do {
                                                let postToread = try await ArticlesManager.shared.getPostToRead(id: post.id)
                                                
                                                viewModel.isLoadingPopupPresented = false
                                                
                                                postToView = PrePost(
                                                    id: post.id,
                                                    title: post.title,
                                                    authorId: post.authorId,
                                                    viewsCount: post.viewsCount,
                                                    likesCount: post.likesCount,
                                                    isArchive: post.isArchive
                                                )
                                                
                                                postToRead = PostToRead(
                                                    dateCreated: postToread.dateCreated,
                                                    text: postToread.text,
                                                    description: postToread.description
                                                )

                                                dismiss()
                                            } catch {
                                                withAnimation {
                                                    viewModel.errorText = error.localizedDescription
                                                    viewModel.isErrorPopupPresented = true
                                                }
                                            }
                                        }
                                        
                                        viewModel.isLoadingPopupPresented = false
                                    }
                                }
                                
                            }
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
                        
                        if viewModel.postsNeedToLoad.count > 0 && !viewModel.isLoading {
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
                .popup(isPresented: $viewModel.isLoadingPopupPresented) {
                    LoadingPopup()
                        .shadow(radius: 3)
                } customize: {
                    $0
                        .type(.toast)
                        .appearFrom(.bottomSlide)
                }
                .onAppear(perform: {
                    viewModel.isLoading = false
                    
                    viewModel.isSubscribed = viewModel.isSubscribed(user, on: authorId)
                    
                    viewModel.getViews()
                    
                    Task {
                        viewModel.isLoading = true
                        
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
                            try await viewModel.loadPostsIndexes(id: authorId)
                        } catch {
                            withAnimation {
                                viewModel.errorText = NSLocalizedString("loadDataErrorLabel", comment: "")
                                viewModel.isErrorPopupPresented = true
                            }
                        }
                    }
                })
                .refreshable {
                    withAnimation {
                        viewModel.isLoading = true
                        viewModel.isLoadingShowing = true
                        
                        viewModel.postsNeedToLoad = []
                        viewModel.posts = []
                        
                        Task {
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
                                try await viewModel.loadPostsIndexes(id: authorId)
                            } catch {
                                withAnimation {
                                    viewModel.errorText = NSLocalizedString("loadDataErrorText", comment: "")
                                    viewModel.isErrorPopupPresented = true
                                }
                            }
                        }
                        
                    }
                }
                .toolbar {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .frame(width: UIScreen.main.bounds.width, height: 170)
                            .foregroundStyle(Color(uiColor: .secondarySystemBackground))
                            .padding(.bottom, 40)
                            .shadow(radius: 10)
                        
                        VStack(spacing: -30) {
                            HStack {
                                HStack(spacing: 0) {
                                    Text(authorName)
                                        .font(.largeTitle)
                                        .fontWeight(.light)
                                        .lineLimit(1)
                                    
                                    if isCheckmark {
                                        Image(systemName: "checkmark.seal.fill")
                                            .foregroundStyle(Color.blue)
                                            .font(.footnote)
                                            .padding(.top, 4)
                                    }
                                }
                                
                                if viewModel.isLoading {
                                    LoadingIndicator(animation: .circleRunner, color: Color(uiColor: .label), size: .small, speed: .fast)
                                }
                                
                                Spacer()
                                
                                ShareLink(item: URL(string: "https://readbox-links.online/authors/?index=\(authorId)")!) {
                                    Image(systemName: "square.and.arrow.up")
                                }
                                .padding(.bottom, 1)
                                
                                Button {
                                    dismiss()
                                } label: {
                                    Image(systemName: "xmark")
                                }
                            }
                            
                            if viewModel.isLoading {
                                HStack {
                                    Text("100 000 \(NSLocalizedString("subscribersCountLabel", comment: ""))")
                                    .font(.callout)
                                    .foregroundStyle(Color.gray)
                                    .redacted(reason: .placeholder)
                                    .shimmering()
                                        
                                    Text("•")
                                        .font(.title)
                                        .foregroundStyle(Color.gray)
                                    
                                    Text("100 \(NSLocalizedString("publicationsCountLabel", comment: ""))")
                                    .font(.callout)
                                    .foregroundStyle(Color.gray)
                                    .redacted(reason: .placeholder)
                                    .shimmering()
                                    
                                }
                                .frame(width: UIScreen.main.bounds.width - 32, alignment: .leading)
                                .offset(y: -50)
                            } else {
                                HStack {
                                    Text("\(viewModel.subscribersCount) \(NSLocalizedString("subscribersCountLabel", comment: ""))")
                                    .font(.callout)
                                    .foregroundStyle(Color.gray)
                                        
                                    Text("•")
                                        .font(.title)
                                        .foregroundStyle(Color.gray)
                                    
                                    Text("\(viewModel.postsCount) \(NSLocalizedString("publicationsCountLabel", comment: ""))")
                                    .font(.callout)
                                    .foregroundStyle(Color.gray)
                                    
                                }
                                .frame(width: UIScreen.main.bounds.width - 32, alignment: .leading)
                                .offset(y: -50)
                            }
                            
                        }
                        .padding(.horizontal, 16)
                    }
                }
                
                if let isSubscribed = viewModel.isSubscribed {
                    VStack {
                        Spacer()
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .frame(width: UIScreen.main.bounds.width, height: 120)
                                .foregroundStyle(Color(uiColor: .secondarySystemBackground))
                                .shadow(radius: 3)
                                .offset(y: 40)
                            
                            if isSubscribed && !viewModel.isLoadingShowing {
                                HStack {
                                    Text(NSLocalizedString("youSubscribedLabel", comment: ""))
                                        .font(.title3)
                                    
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color(uiColor: .label))
                                }
                                .frame(width: UIScreen.main.bounds.width - 10, height: 50, alignment: .center)
                                .background(Color(uiColor: .secondarySystemBackground))
                                .foregroundColor(Color(uiColor: .label))
                                .clipShape(RoundedRectangle(cornerRadius: 15))
                                .shadow(radius: 3)
                                .offset(y: 20)
                                .onTapGesture {
                                    Task {
                                        do {
                                            try await viewModel.un_subscribeUser(on: authorId, isNeedToSubscribe: false)
                                            
                                            withAnimation {
                                                user?.subscribes?.removeAll { $0 == authorId }
                                                viewModel.isSubscribed?.toggle()
                                                viewModel.subscribersCount -= 1
                                            }
                                        } catch {
                                            withAnimation {
                                                viewModel.errorText = error.localizedDescription
                                                viewModel.isErrorPopupPresented = true
                                            }
                                        }
                                    }
                                }
                            } else if !isSubscribed && !viewModel.isLoadingShowing {
                                Text(NSLocalizedString("subscribeLabel", comment: ""))
                                    .font(.title3)
                                    .frame(width: UIScreen.main.bounds.width - 10, height: 50, alignment: .center)
                                    .background(Color(uiColor: .label))
                                    .foregroundColor(Color(uiColor: .systemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 15))
                                    .shadow(radius: 3)
                                    .offset(y: 20)
                                    .onTapGesture {
                                        Task {
                                            do {
                                                try await viewModel.un_subscribeUser(on: authorId, isNeedToSubscribe: true)
                                                
                                                withAnimation {
                                                    user?.subscribes?.append(authorId)
                                                    viewModel.isSubscribed?.toggle()
                                                    viewModel.subscribersCount += 1
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
                        }
                    }
                }

            }
        }
    }
}
