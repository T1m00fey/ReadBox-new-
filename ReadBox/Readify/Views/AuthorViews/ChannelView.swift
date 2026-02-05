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
    
    @Environment(\.dismiss) var dismiss
    
    @Binding var user: DBUser?
    
    let authorId: String
    let authorName: String
    let isCheckmark: Bool
    let lastVersionOfAvatar: Int
    
    @EnvironmentObject var sessionManager: SessionManager
    
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
            
                    if viewModel.isLoading {
//                            Text("HelloWorldHelloWorld HelloWorld HelloWorld HelloWorldHelloWorld HelloWorld HelloWorld")
//                                .padding(.vertical, 20)
//                                .padding(.horizontal, 16)
//                                .frame(width: UIScreen.main.bounds.width, alignment: .leading)
//                                .background(Color(uiColor: .secondarySystemBackground))
//                                .clipShape(RoundedRectangle(cornerRadius: 20))
//                                .padding(.top, 50)
//                                .redacted(reason: .placeholder)
//                                .shimmering()
                        
//                        Text(NSLocalizedString("publicationsLabel", comment: ""))
//                            .font(.system(size: 24))
//                            .fontWeight(.light)
//                            .fontDesign(.rounded)
//                            .frame(width: UIScreen.main.bounds.width - 20, alignment: .leading)
//                            .redacted(reason: .placeholder)
//                            .shimmering()
                        
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
                                mediaPosition: 0,
                                lastVersionOfAvatar: 0,
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
                        
//                        VisibilityTracker(id: "publicationsLabel")
////
//                        Text(NSLocalizedString("publicationsLabel", comment: ""))
//                            .font(.system(size: 24))
//                            .fontWeight(.light)
//                            .fontDesign(.rounded)
//                            .frame(width: UIScreen.main.bounds.width - 20, alignment: .leading)
                        
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
                                mediaPosition: post.mediaPosition ?? 0,
                                lastVersionOfAvatar: lastVersionOfAvatar,
                                user: $user,
                                isZoomableViewPresented: $viewModel.isZoomableImageViewPresented,
                                zoomableImage: $viewModel.zoomableImage,
                                selectedAuthorId: .constant(""),
                                isChannelViewPresented: .constant(true)
                            )
//                            .padding(.top, post.id == viewModel.posts[0].id ? 10 : 0)
                            .padding(.bottom, post.id == viewModel.posts[viewModel.posts.count - 1].id ? 100 : 0)
                            .padding(.top, 10)
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
                                            mediaVersion: post.mediaVersion,
                                            mediaPosition: post.mediaPosition ?? 0
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
                    user: $user,
                    isChannelViewPresented: .constant(false),
                    isPresented: $viewModel.isReadViewPresented
                )
            })
            .onAppear(perform: {
                if !viewModel.isDataLoaded {
                    viewModel.isLoading = false
                    viewModel.authorId = authorId
                    
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
                    if !viewModel.isPublicationsLabelVisible {
                        if #available(iOS 26, *) {
//                            HStack(spacing: 0) {
//                                Text(authorName)
//                                
//                                if isCheckmark {
//                                    Image(systemName: "checkmark.seal.fill")
//                                        .foregroundStyle(Color.blue)
//                                        .font(.system(size: 12))
//                                }
//                            }
//                            .padding()
//                            .glassEffect(.regular)
                            
                            Text(NSLocalizedString("publicationsLabel", comment: ""))
                                .padding()
                                .glassEffect(.regular)
                        } else {
//                            HStack(spacing: 0) {
//                                Text(authorName)
//                                
//                                if isCheckmark {
//                                    Image(systemName: "checkmark.seal.fill")
//                                        .foregroundStyle(Color.blue)
//                                        .font(.system(size: 12))
//                                }
//                            }
                            
                            Text(NSLocalizedString("publicationsLabel", comment: ""))
                        }
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: URL(string: "https://readbox-links.online/authors/?index=\(authorId)")!) {
                        Image(systemName: "arrowshape.turn.up.right")
                    }
                }
            }
            .refreshable {
                withAnimation {
                    viewModel.isLoading = true
                    viewModel.isLoadingShowing = true
                    
                    viewModel.posts = []
                    
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
                                .padding(.bottom, 10)
                            } else {
                                Button {
                                    un_subscribe(isSubscribed: isSubscribed)
                                } label: {
                                    viewModel.buildSubscribeButtonView(isSubscribed)
                                }
                                .tint(Color(.label))
                                .buttonStyle(.borderedProminent)
                                .padding(.horizontal, 22.5)
                                .padding(.bottom, 10)
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
            
            if !viewModel.isLoading && viewModel.authorDescription != "" {
                Text(viewModel.authorDescription)
                    .font(.system(size: 18))
                    .fontDesign(.rounded)
                    .frame(width: UIScreen.main.bounds.width - 20, alignment: .leading)
                    .padding(.top, 15)
            }
            
            VisibilityTracker(id: "publicationsLabel")
            
            Capsule()
                .foregroundStyle(.gray)
                .frame(width: UIScreen.main.bounds.width - 20, height: 1)
                .padding(.top, 20)
        }
        .padding(.vertical, 15)
//        .background(
//            RoundedRectangle(cornerRadius: 25)
//                .foregroundStyle(Color(.secondarySystemBackground))
////                .shadow(radius: 1)
//                .frame(width: UIScreen.main.bounds.width)
//        )
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
