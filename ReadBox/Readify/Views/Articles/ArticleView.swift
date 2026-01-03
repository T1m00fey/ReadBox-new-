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
        self._user = user
        self._isZoomableViewPresented = isZoomableViewPresented
        self._zoomableImage = zoomableImage
        self._selectedAuthorId = selectedAuthorId
        self._isChannelViewPresented = isChannelViewPresented
    }
    
    private func getAvatar() {
        let cacheKey = "avatar_\(authorId)"
        let storageRef = Storage.storage().reference()

        let currentSessionId = sessionManager.sessionId
        let lastSessionId = StorageManager.shared.getSessionId()
        let isSameSession = (lastSessionId == currentSessionId)

        if let cached = StorageManager.shared.getImage(id: cacheKey) {
            withAnimation {
                avatarImage = cached
            }
        }

        if isSameSession, avatarImage != nil {
            return
        }

        let islandRef = storageRef.child("avatars/\(authorId).jpg")

        islandRef.getData(maxSize: 1 * 5012 * 5012) { data, error in
            guard let data, let image = UIImage(data: data) else { return }

            DispatchQueue.main.async {
                withAnimation {
                    avatarImage = image
                }
                StorageManager.shared.saveImage(id: cacheKey, image: image)

                if !isSameSession {
                    StorageManager.shared.setSessionId(currentSessionId)
                }
            }
        }
    }

    
//    private func fetchImages() {
//        let storageRef = Storage.storage().reference()
//        
//        images = Array(repeating: nil, count: mediaCount)
//        
//        for i in 0..<mediaCount {
//            let cachedImage = StorageManager.shared.getImage(id: "\(id)_\(i)")
//            
//            if let cachedImage {
//                withAnimation {
////                    images.append(MediaKind(image: cachedImage))
//                    images[i] = MediaKind(image: cachedImage)
//                }
//            } else {
//                let islandRef = storageRef.child("images/\(id)_\(i).jpg")
//                
//                islandRef.getData(maxSize: 1 * 5012 * 5012) { data, error in
//                    if let data, let image = UIImage(data: data) {
//                        DispatchQueue.main.async {
//                            withAnimation {
//                                //                            images.append(MediaKind(image: image))
//                                images[i] = MediaKind(image: image)
//                                StorageManager.shared.saveImage(id: "\(id)_\(i)", image: image)
//                            }
//                        }
//                    } else {
//                        let videoRef = storageRef.child("images/\(id)_\(i).mp4")
//                        
//                        videoRef.downloadURL { url, error in
//                            if let url {
//                                DispatchQueue.main.async {
//                                    withAnimation {
////                                        images.append(MediaKind(videoURL: url))
//                                        images[i] = MediaKind(videoURL: url)
//                                    }
//                                }
//                            }
//                        }
//                    }
//                }
//            }
//        }
//        
//        if let image = StorageManager.shared.getImage(id: authorId) {
//            withAnimation {
//                avatarImage = image
//            }
//        } else {
//            DispatchQueue.main.async {
//                let islandRef = storageRef.child("avatars/\(authorId).jpg")
//                
//                islandRef.getData(maxSize: 1 * 5012 * 5012) { data, error in
//                    if let data, let image = UIImage(data: data) {
//                        withAnimation {
//                            avatarImage = image
//                        }
//                        StorageManager.shared.saveImage(id: authorId, image: image)
//                    }
//                }
//            }
//        }
//        
//        if images.isEmpty {
//            fetchImage()
//        }
//    }
    
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
                }
                
                HStack(spacing: 5) {
                    HStack(spacing: 0) {
                        Text(authorName)
                            .font(.system(size: 20))
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
            }
            
            ZStack {
                VStack(spacing: 0) {
                    Text(title)
                        .font(.system(size: 19))
                        .lineLimit(!isExpanded && title.count >= maxTitleLen ? 4 : nil)
                        .fontDesign(.rounded)
                        .frame(width: UIScreen.main.bounds.width - 42, alignment: .leading)
                        .padding(.bottom, isShortPost ? 10 : 20)                    
//                        .padding(.bottom, !isExpanded && title.count >= maxTitleLen && isShortPost ? 10 : 0)
//                        .padding(.bottom, !isExpanded && title.count >= maxTitleLen ? 17 : 0)
                    
                    if isShortPost {
                        HStack(spacing: 12) {
                            Image(systemName: isLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                                .foregroundStyle(Color.gray)
                                .font(.system(size: 20))
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
                                    .font(.system(size: 20))
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
                .shadow(radius: 1)
        )
        .onAppear {
            if let user, let likedPosts = user.likedPosts {
                isLiked = likedPosts.contains(id)
            }
        }
        .onAppear {
            effectiveMediaCount = mediaCount
            getAvatar()
        }
    }
}
