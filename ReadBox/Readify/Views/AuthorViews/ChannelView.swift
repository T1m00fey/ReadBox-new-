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
        NavigationStack {
            
            ZStack {
                
                Color(uiColor: .systemBackground)
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 20) {
                        Color.clear.frame(height: 40)
                        
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
                                    user: .constant(nil),
                                    isZoomableViewPresented: .constant(false),
                                    zoomableImage: .constant(nil),
                                    selectedAuthorId: .constant(""),
                                    isChannelViewPresented: .constant(false)
                                )
                                .redacted(reason: .placeholder)
                                .padding(.top, num == 0 ? 10 : 0)
                                .padding(.bottom, num == 6 ? 100 : 0)
                                .shimmering()
                            }
                        } else if !viewModel.posts.isEmpty {
                            if viewModel.authorDescription != "" {
                                Text(viewModel.authorDescription)
                                    .font(.system(size: 20))
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
                                .padding(.top, viewModel.authorDescription == "" ? 50 : 20)
                            
                            ForEach(viewModel.posts) { post in
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
                                    user: $user,
                                    isZoomableViewPresented: $viewModel.isZoomableImageViewPresented,
                                    zoomableImage: $viewModel.zoomableImage,
                                    selectedAuthorId: .constant(""),
                                    isChannelViewPresented: .constant(false)
                                )
                                .padding(.top, post.id == viewModel.posts[0].id ? 10 : 0)
                                .padding(.bottom, post.id == viewModel.posts[viewModel.posts.count - 1].id ? 100 : 0)
                                .onAppear {
                                    if post == viewModel.posts.last, viewModel.posts.count >= 20 {
                                        Task {
                                            try? await viewModel.loadPosts(by: authorId)
                                        }
                                    }
                                }
                                .onTapGesture {
                                    viewModel.isLoadingPopupPresented = true
                                    
                                    Task {
                                        do {
                                            let postToread = try await ArticlesManager.shared.getPostToRead(id: post.id)
                                            
                                            viewModel.isLoadingPopupPresented = false
                                            
                                            viewModel.postToView = PrePost(
                                                id: post.id,
                                                title: post.title,
                                                authorId: post.authorId,
                                                viewsCount: post.viewsCount,
                                                likesCount: post.likesCount,
                                                isArchive: post.isArchive,
                                                isShortPost: post.isShortPost,
                                                mediaCount: post.mediaCount,
                                                mediaVersion: post.mediaVersion
                                            )
                                            
                                            viewModel.postToRead = PostToRead(
                                                dateCreated: postToread.dateCreated,
                                                text: postToread.text,
                                                mediaURLs: postToread.mediaURLs
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
                                
                            }
                        } else {
                            
                            if viewModel.authorDescription != "" {
                                Text(viewModel.authorDescription)
                                    .font(.system(size: 20))
                                    .padding(.vertical, 20)
                                    .padding(.horizontal, 16)
                                    .frame(width: UIScreen.main.bounds.width, alignment: .leading)
                                    .background(Color(uiColor: .secondarySystemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                                    .padding(.top, 50)
                            }
                            
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
                .popup(isPresented: $viewModel.isLoadingPopupPresented) {
                    LoadingPopup()
                } customize: {
                    $0
                        .type(.toast)
                        .appearFrom(.bottomSlide)
                        .displayMode(.sheet)
                }
                .popup(isPresented: $viewModel.isNotificationPopupPresented) {
                    NotificationPermissionView(
                        isPopupPresented: $viewModel.isNotificationPopupPresented,
                        route: viewModel.pushRoute ?? .goToSettings
                    )
                    .shadow(radius: 2)
                } customize: {
                    $0
                        .type(.toast)
                        .appearFrom(.bottomSlide)
                        .dragToDismiss(true)
                        .displayMode(.sheet)
                }
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
                        user: $user,
                        isChannelViewPresented: .constant(false)
                    )
                })
                .onAppear(perform: {
                    if !viewModel.isDataLoaded {
                        viewModel.isLoading = false
                        viewModel.authorId = authorId
                        
                        viewModel.isSubscribed = viewModel.isSubscribed(user, on: authorId)
                        
                        viewModel.getViews()
                        viewModel.getAvatar()
                        
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
                .refreshable {
                    withAnimation {
                        viewModel.isLoading = true
                        viewModel.isLoadingShowing = true
                        
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
                                try await viewModel.loadPosts(by: authorId)
                                viewModel.getAvatar()
                            } catch {
                                withAnimation {
                                    viewModel.errorText = NSLocalizedString("loadDataErrorText", comment: "")
                                    viewModel.isErrorPopupPresented = true
                                }
                            }
                        }
                        
                    }
                }
                
                if let isSubscribed = viewModel.isSubscribed {
                    VStack {
                        Spacer()
                        
                        if #available(iOS 26.0, *) {
                            if !viewModel.isLoading {
                                if isSubscribed {
                                    Button {
                                        un_subscribe(isSubscribed: isSubscribed)
                                    } label: {
                                        viewModel.buildSubscribeButtonView(isSubscribed)
                                    }
                                    .buttonStyle(.glass)
                                    .padding(.horizontal, 22.5)
                                    .offset(y: 10)
                                } else {
                                    Button {
                                        un_subscribe(isSubscribed: isSubscribed)
                                    } label: {
                                        viewModel.buildSubscribeButtonView(isSubscribed)
                                    }
                                    .tint(Color(.label))
                                    .buttonStyle(.borderedProminent)
                                    .padding(.horizontal, 22.5)
                                    .offset(y: 10)
                                }
                            }
                        } else {
                            ZStack {
                                RoundedRectangle(cornerRadius: 20)
                                    .frame(width: UIScreen.main.bounds.width, height: 120)
                                //                                .foregroundStyle(Color(uiColor: .secondarySystemBackground))
                                    .foregroundStyle(.thinMaterial)
                                    .shadow(radius: 1)
                                    .offset(y: 40)
                                
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
                                            .font(.system(size: 20))
                                            .foregroundColor(
                                                isSubscribed
                                                ? Color(.label)
                                                : Color(uiColor: .systemBackground)
                                            )
                                        }
                                    }
                                    .frame(width: UIScreen.main.bounds.width - 10, height: 50, alignment: .center)
                                    .background(
                                        RoundedRectangle(cornerRadius: 15)
                                            .foregroundStyle(
                                                isSubscribed
                                                ? Color(.systemBackground)
                                                : Color(uiColor: .label)
                                            )
                                            .shadow(radius: 1)
                                    )
                                    .offset(y: 20)
                                    .onTapGesture {
                                        un_subscribe(isSubscribed: isSubscribed)
                                    }
                                }
                            }
                        }
                    }
                }
                
                VStack {
                    headerView
                    
                    Spacer()
                }.ignoresSafeArea()
                
            }
        }
    }
}


private extension ChannelView {
    var headerView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15)
                .frame(width: UIScreen.main.bounds.width, height: 140)
//                .foregroundStyle(Color(uiColor: .secondarySystemBackground))
                .foregroundStyle(.thinMaterial)
                .shadow(radius: 5)
            
            VStack(spacing: -3) {
                HStack {
                    if let avatar = viewModel.avatarImage {
                        Image(uiImage: avatar)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 50, height: 50)
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
                    
                    HStack(spacing: 0) {
                        Text(authorName)
                            .font(.system(size: 25))
                            .fontWeight(.light)
                            .lineLimit(1)
                        
                        if isCheckmark {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(Color.blue)
                                .font(.system(size: 14))
                                .padding(.top, 1)
                        }
                    }
                    
                    if viewModel.isLoading {
                        LoadingIndicator(animation: .circleRunner, color: Color(uiColor: .label), size: .small, speed: .fast)
                    }
                    
                    Spacer()
                    
                    ShareLink(item: URL(string: "https://readbox-links.online/authors/?index=\(authorId)")!) {
                        Image(systemName: "arrowshape.turn.up.right")
                            .font(.system(size: 22))
                    }
                    .padding(.trailing, 2)
                    
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 22))
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
                }
                
            }
            .padding(.top, 50)
            .padding(.horizontal, 16)
        }
    }
}
