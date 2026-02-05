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
    
    @Binding var user: DBUser?
    @Binding var isZoomableViewPresented: Bool
    @Binding var zoomableImage: UIImage?
    @Binding var selectedAuthorId: String
    @Binding var isChannelViewPresented: Bool
    
    @State private var videoURL: URL? = nil
    @State private var avatarImage: UIImage? = nil
    @State private var isExpanded = false
    @State private var isLiked = false
    @State private var currentIndex = 0
    @State private var effectiveMediaCount = 0
    
    @State private var images: [MediaKind?] = []
    
    @EnvironmentObject var sessionManager: SessionManager
    
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
        user: Binding<DBUser?>,
        isZoomableViewPresented: Binding<Bool>,
        zoomableImage: Binding<UIImage?>,
        selectedAuthorId: Binding<String>,
        isChannelViewPresented: Binding<Bool>,
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
        self._user = user
        self._isZoomableViewPresented = isZoomableViewPresented
        self._zoomableImage = zoomableImage
        self._selectedAuthorId = selectedAuthorId
        self._isChannelViewPresented = isChannelViewPresented
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
                    
                    if !isShortPost {
                        Text(NSLocalizedString("articleLabel", comment: ""))
                            .font(.system(size: 12))
                            .foregroundStyle(Color(.systemGray6))
                            .padding(.all, 5)
                            .background(Color(.systemGray4))
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                    }
                }
            }
            .frame(width: UIScreen.main.bounds.width - 42, height: 40, alignment: .leading)
            .padding(.top, 7)
            .padding(.vertical, 5)
            
            if mediaPosition == 1 && isShortPost {
                titleView
            }
            
            if mediaCount > 0 {
                MediaViews(
                    id: id,
                    authorId: authorId,
                    mediaCount: effectiveMediaCount,
                    mediaVersion: mediaVersion,
                    isArchive: isArchive,
                    zoomableImage: $zoomableImage,
                    isZoomableViewPresented: $isZoomableViewPresented,
                    currentIndex: $currentIndex
                )
                .id("\(id)-\(effectiveMediaCount)")
//                .padding(.top, isChannelViewPresented ? 9 : 0)
                .padding(.bottom, title == "" || (mediaPosition == 1 && isShortPost) ? 10 : 0)
                
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
                    
                    if mediaPosition == 0 || !isShortPost {
                        titleView
                            .padding(.bottom, isShortPost ? 10 : 20)
                            .padding(.top, mediaCount > 0 ? 3 : 0)
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
            let ava = await MediaManager.shared.getAvatar(authorId: authorId, lastVersion: lastVersionOfAvatar)
            
            withAnimation {
                avatarImage = ava
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
}
