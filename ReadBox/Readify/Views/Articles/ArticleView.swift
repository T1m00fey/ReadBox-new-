//
//  ArtcleView.swift
//  Readify
//
//  Created by Тимофей Юдин on 05.11.2024.
//

import SwiftUI
import FirebaseStorage
import AVFoundation
import SwiftfulLoadingIndicators

struct ArticleView: View {
    let id: String
    let title: String
    let authorId: String
    let authorName: String
    let isCheckmark: Bool
    let isArchive: Bool
    let isShortPost: Bool
    let mediaCount: Int
    let mediaVersion: Int
    let mediaPosition: Int
    let lastVersionOfAvatar: Int
    let locCount: Int
    let isCreatedView: Bool
    let isLocalizedVersion: Bool
    let isPremiumPost: Bool
    
    @Binding var user: DBUser?
    @Binding var isZoomableViewPresented: Bool
    @Binding var zoomableImage: UIImage?
    @Binding var selectedAuthorId: String
    @Binding var isChannelViewPresented: Bool
    @Binding var postOption: PostOptions
    @Binding var selectedId: String

    @State private var videoURL: URL? = nil
    @State private var avatarImage: UIImage? = nil
    @State private var isExpanded = false
    @State private var isLiked = false
    @State private var currentIndex = 0
    @State private var effectiveMediaCount = 0
    
    @State private var images: [MediaKind?] = []
    
    @EnvironmentObject var sessionManager: SessionManager
    @EnvironmentObject var subscriptionMnaager: SubscriptionManager
    
    private let maxTitleLen = 250
    
    init(
        id: String,
        title: String,
        authorId: String,
        authorName: String,
        isCheckmark: Bool,
        isArchive: Bool,
        isShortPost: Bool,
        mediaCount: Int,
        mediaVersion: Int,
        mediaPosition: Int,
        lastVersionOfAvatar: Int,
        locCount: Int,
        isCreatedView: Bool = false,
        isLocalizedVersion: Bool,
        isPremiumPost: Bool,
        user: Binding<DBUser?>,
        isZoomableViewPresented: Binding<Bool>,
        zoomableImage: Binding<UIImage?>,
        selectedAuthorId: Binding<String>,
        isChannelViewPresented: Binding<Bool>,
        postOption: Binding<PostOptions> = .constant(.nothing),
        selectedId: Binding<String> = .constant("")
    ) {
        self.id = id
        self.title = title
        self.authorId = authorId
        self.authorName = authorName
        self.isCheckmark = isCheckmark
        self.isArchive = isArchive
        self.isShortPost = isShortPost
        self.mediaCount = mediaCount
        self.mediaVersion = mediaVersion
        self.mediaPosition = mediaPosition
        self.lastVersionOfAvatar = lastVersionOfAvatar
        self.locCount = locCount
        self.isCreatedView = isCreatedView
        self.isLocalizedVersion = isLocalizedVersion
        self.isPremiumPost = isPremiumPost
        self._user = user
        self._isZoomableViewPresented = isZoomableViewPresented
        self._zoomableImage = zoomableImage
        self._selectedAuthorId = selectedAuthorId
        self._isChannelViewPresented = isChannelViewPresented
        self._postOption = postOption
        self._selectedId = selectedId
    }
    
    private func isAccessToPremiumDenied() -> Bool {
        isPremiumPost && !subscriptionMnaager.hasPremium && authorId != user?.userId
    }
    
    private func updateLike() async throws {
        let likesCount = try await ArticlesManager.shared.getLikesCount(byPostId: id)
                        
        if isLiked {
            withAnimation {
                isLiked.toggle()
            }
            VibrationsService.shared.lightImpact()
            
            try await UserManager.shared.removeLikedPost(id: user?.userId ?? "", likedPost: id)
            try await ArticlesManager.shared.updateLikes(at: id, likesCount: likesCount - 1)
            
            withAnimation {
                user?.likedPosts?.removeAll {
                    $0 == id
                }
            }
        } else {
            withAnimation {
                isLiked.toggle()
            }
            VibrationsService.shared.lightImpact()
            
            try await UserManager.shared.addLikedPost(id: user?.userId ?? "", likedPost: id)
            try await ArticlesManager.shared.updateLikes(at: id, likesCount: likesCount + 1)
            
            withAnimation {
                user?.likedPosts?.append(id)
            }
        }
    }
    
    var body: some View {
        
        VStack {
            HStack {
                if let avatarImage {
                    Image(uiImage: avatarImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(
                                    Color(.label),
                                    lineWidth: 0.1
                                )
                        )
                        .onTapGesture {
                            withAnimation {
                                zoomableImage = avatarImage
                                isZoomableViewPresented = true
                            }
                        }
                        .id("\(id)")
                }
                
                HStack(spacing: 5) {
                    HStack(spacing: 0) {
                        Text(authorName)
                            .font(.system(size: 18))
                            .lineLimit(1)
                            .underline()
                            .onTapGesture {
                                selectedAuthorId = authorId
                                isChannelViewPresented = true
                            }
                        
                        if isCheckmark {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(Color.blue)
                                .font(.system(size: 14))
                                .padding(.top, 1)
                        }
                    }
                    
                    Spacer()
                    
                    if isLocalizedVersion {
                        Image("translateIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 15)
                            .foregroundStyle(Color(.systemGray6))
                            .padding(.all, 5)
                            .background(Color(.systemGray4))
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                    }
                    
                    if !isShortPost {
                        Text(NSLocalizedString("articleLabel", comment: ""))
                            .font(.system(size: 12))
                            .foregroundStyle(Color(.systemGray6))
                            .padding(.all, 5)
                            .background(Color(.systemGray4))
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                    }
                    
                    if isPremiumPost {
//                        Image(systemName: "plus")
//                            .resizable()
//                            .scaledToFit()
//                            .frame(width: 15)
//                            .foregroundStyle(Color(.label))
//                            .padding(.all, 5)
//                            .background(Color(.systemGray4))
//                            .clipShape(RoundedRectangle(cornerRadius: 5))
                        Text("R+")
                            .font(.custom("PlaywriteIE-Regular", size: 15))
                            .foregroundStyle(Color(.gray))
                            .padding(.trailing, -5)
                    }
                    
                    if isCreatedView {
                        Menu {
                            Button {
                                postOption = .editing
                                selectedId = id
                            } label: {
                                Label(NSLocalizedString("editingLabel", comment: ""), systemImage: "pencil")
                            }
                            
                            Button {
                                selectedId = id
                                
                                if isArchive {
                                    postOption = .publish
                                } else {
                                    postOption = .toArchive
                                }
                                
                            } label: {
                                if isArchive {
                                    Label(NSLocalizedString("publishLabel", comment: ""), systemImage: "paperplane")
                                } else {
                                    Label(NSLocalizedString("saveToArchiveLabel", comment: ""), systemImage: "archivebox")
                                }
                            }
                            
                            if locCount == 0 && !isLocalizedVersion {
                                Button {
                                    postOption = .localize
                                    selectedId = id
                                } label: {
                                    Label(NSLocalizedString("toLocalizeMenuActionLabel", comment: ""), systemImage: "globe")
                                }
                            }
                        
                            Button {
                                postOption = .delete
                                selectedId = id
                        
                                
                                StorageManager.shared.deleteImage(id: id)
                            } label: {
                                Label(NSLocalizedString("deleteLabel", comment: ""), systemImage: "xmark.circle")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 15, height: 15)
                                .foregroundStyle(Color(.gray))
                                .padding(.all, 5)
                                .background(Color(.systemGray4))
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                        }
        
                    }
                    
                }
            }
            .frame(width: UIScreen.main.bounds.width - 42, height: 40, alignment: .leading)
            .padding(.top, 7)
            .padding(.vertical, 5)
            
            if mediaPosition == 1 && isShortPost && !isAccessToPremiumDenied() {
                titleView
            }
            
            if mediaCount > 0 {
                ZStack {
                    MediaViews(
                        id: id,
                        authorId: authorId,
                        mediaCount: effectiveMediaCount,
                        mediaVersion: mediaVersion,
                        zoomableImage: $zoomableImage,
                        isZoomableViewPresented: $isZoomableViewPresented,
                        currentIndex: $currentIndex
                    )
                    .id("\(id)-\(effectiveMediaCount)")
                    .padding(.bottom, mediaPosition == 1 && isShortPost && title != "" ? 10 : 0)
                    .padding(.bottom, title == "" ? -25: 0)
                    .blur(radius: isAccessToPremiumDenied() ? 10 : 0)
                    .disabled(isAccessToPremiumDenied())
                    
                    if isAccessToPremiumDenied() {
                        subscriptionAlertView
                            .padding(.all, 10)
                            .background(.thinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                }
            } else if isAccessToPremiumDenied() {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .frame(width: UIScreen.main.bounds.width - 32, height: 200)
                        .foregroundStyle(Color("availableInRead+"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    Color(.systemGray5),
                                    lineWidth: 2
                                )
                        )
                    
                    subscriptionAlertView
                }
                .padding(.bottom, 5)
            }
            
            ZStack {
                VStack(spacing: 0) {
//                    Text(title)
//                        .font(.system(size: 18))
//                        .lineLimit(!isExpanded && title.count >= maxTitleLen ? 4 : nil)
//                        .fontDesign(.rounded)
//                        .frame(width: UIScreen.main.bounds.width - 42, alignment: .leading)
//                        .padding(.bottom, isShortPost ? 10 : 20)
//                        .padding(.top, mediaCount == 0 && isChannelViewPresented ? 16 : 0)
//                        .padding(.bottom, !isExpanded && title.count >= maxTitleLen && isShortPost ? 10 : 0)
//                        .padding(.bottom, !isExpanded && title.count >= maxTitleLen ? 17 : 0)
                    
                    if (mediaPosition == 0 || !isShortPost) && !(isShortPost && isAccessToPremiumDenied() && isPremiumPost) {
                        titleView
                            .padding(.top, mediaCount > 0 ? 5 : 0)
                            .padding(.bottom, isShortPost ? 10 : 20)
                    }
                    
                    if isShortPost {
                        HStack(spacing: 12) {
                            Image(systemName: isLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                                .foregroundStyle(Color.gray)
                                .font(.system(size: 21))
                                .onTapGesture {
                                    Task {
                                        do {
                                          try? await updateLike()
                                        }
                                    }
                                }
                            
                            ShareLink(item: URL(string: "https://readbox-links.online/posts/?index=\(id)")!) {
                                Image(systemName: "arrowshape.turn.up.right")
                                    .foregroundStyle(Color.gray)
                                    .font(.system(size: 21))
                            }
                        }
                        .padding(.top, title.count > maxTitleLen && !isExpanded ? 12 : 0)
                        .padding(.bottom, 15)
                        .frame(width: UIScreen.main.bounds.width - 50, alignment: .leading)
                    }
                }
                
                ZStack {
                    if !isExpanded && title.count >= maxTitleLen {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    gradient:
                                        Gradient(
                                            colors: [Color.clear, Color(.secondarySystemBackground)]
                                        ),
                                    startPoint: UnitPoint.top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: UIScreen.main.bounds.width - 38, height: 50)
                    }
                    
                    if !isExpanded && title.count >= maxTitleLen {
                        Text(NSLocalizedString("expandButtonLabel", comment: ""))
                            .font(.system(size: 16))
                            .fontDesign(.rounded)
                            .foregroundStyle(.gray)
                            .frame(width: UIScreen.main.bounds.width - 42, alignment: .trailing)
                            .padding(.horizontal, 20)
                            .onTapGesture {
                                withAnimation {
                                    isExpanded = true
                                }
                            }
                            .offset(y: 25)
                    }
                }
                .offset(y: 10)
            }
            
        }
        .onReceive(NotificationCenter.default.publisher(for: .postMediaDidUpdate)) { note in
            guard let pid = note.userInfo?["postId"] as? String, pid == id else { return }
            if let newCount = note.userInfo?["mediaCount"] as? Int {
                effectiveMediaCount = newCount
            }
        }
        .frame(width: UIScreen.main.bounds.width - 10)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .foregroundStyle(Color(.secondarySystemBackground))
//                .shadow(radius: 1)
        )
        .onAppear {
            if let user, let likedPosts = user.likedPosts {
                isLiked = likedPosts.contains(id)
            }
        }
        .onAppear {
            effectiveMediaCount = mediaCount
        }
        .task {
            if avatarImage == nil {
                let ava = await MediaManager.shared.getAvatar(authorId: authorId, lastVersion: lastVersionOfAvatar)
                
                withAnimation {
                    avatarImage = ava
                }
            }
        }
    }
}

private extension ArticleView {
    var titleView: some View {
        Text(title)
            .font(.system(size: 18))
            .lineLimit(!isExpanded && title.count >= maxTitleLen ? 4 : nil)
            .fontDesign(.rounded)
            .frame(width: UIScreen.main.bounds.width - 42, alignment: .leading)
    }
    
    var subscriptionAlertView: some View {
        VStack(spacing: 1) {
            Text("доступно только с")
                .font(.system(size: 16))
                .fontDesign(.rounded)
                .foregroundStyle(Color(.gray))
                
            
            Text("Read+")
    //                                .font(.custom("PlaywriteIE-Regular", size: 28))
                .font(.custom("Borel-Regular", size: 28))
                .foregroundStyle(Color(.gray))
                .padding(.bottom, -20)
        }
    }
}
