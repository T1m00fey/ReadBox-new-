//
//  ArtcleView.swift
//  Readify
//
//  Created by Тимофей Юдин on 05.11.2024.
//

import SwiftUI
import FirebaseStorage
import AVFoundation

struct ArticleView: View {
    let id: String
    let title: String
    let authorId: String
    let authorName: String
    let isCheckmark: Bool
    let isArchive: Bool
    let isShortPost: Bool
    let mediaCount: Int
    
    @Binding var user: DBUser?
    @Binding var isZoomableViewPresented: Bool
    @Binding var zoomableImage: UIImage?
    
    @State private var videoURL: URL? = nil
    @State private var avatarImage: UIImage? = nil
    @State private var isExpanded = false
    @State private var isLiked = false
    @State private var currentIndex = 0
    
    @State private var images: [MediaKind] = []
    
    private let maxTitleLen = 200
    
    init(
        id: String,
        title: String,
        authorId: String,
        authorName: String,
        isCheckmark: Bool,
        isArchive: Bool,
        isShortPost: Bool,
        mediaCount: Int,
        user: Binding<DBUser?>,
        isZoomableViewPresented: Binding<Bool>,
        zoomableImage: Binding<UIImage?>
    ) {
        self.id = id
        self.title = title
        self.authorId = authorId
        self.authorName = authorName
        self.isCheckmark = isCheckmark
        self.isArchive = isArchive
        self.isShortPost = isShortPost
        self.mediaCount = mediaCount
        self._user = user
        self._isZoomableViewPresented = isZoomableViewPresented
        self._zoomableImage = zoomableImage
    }
    
    private func fetchImages() {
        let storageRef = Storage.storage().reference()
        
        for i in 0..<mediaCount {
            let cachedImage = StorageManager.shared.getImage(id: "\(id)_\(i)")
            
            if let cachedImage {
                withAnimation {
                    images.append(MediaKind(image: cachedImage))
                }
            } else {
                let islandRef = storageRef.child("images/\(id)_\(i).jpg")
                
                islandRef.getData(maxSize: 1 * 5012 * 5012) { data, error in
                    if let data, let image = UIImage(data: data) {
                        withAnimation {
                            images.append(MediaKind(image: image))
                            StorageManager.shared.saveImage(id: "\(id)_\(i)", image: image)
                        }
                    } else {
                        let videoRef = storageRef.child("images/\(id)_\(i).mp4")
                        
                        videoRef.downloadURL { url, error in
                            if let url {
                                DispatchQueue.main.async {
                                    withAnimation {
                                        images.append(MediaKind(videoURL: url))
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        if let image = StorageManager.shared.getImage(id: authorId) {
            withAnimation {
                avatarImage = image
            }
        } else {
            DispatchQueue.main.async {
                let islandRef = storageRef.child("avatars/\(authorId).jpg")
                
                islandRef.getData(maxSize: 1 * 5012 * 5012) { data, error in
                    if let data, let image = UIImage(data: data) {
                        withAnimation {
                            avatarImage = image
                        }
                        StorageManager.shared.saveImage(id: authorId, image: image)
                    }
                }
            }
        }
        
        if images.isEmpty {
            fetchImage()
        }
    }
    
    private func fetchImage() {
        let articleImage = StorageManager.shared.getImage(id: id)
        let storage = Storage.storage()
        let storageRef = storage.reference()
        
        if let articleImage {
            withAnimation {
                images.append(MediaKind(image: articleImage))
            }
        } else {
            let islandRef = storageRef.child("images/\(id).jpg")
            
            islandRef.getData(maxSize: 1 * 5012 * 5012) { data, error in
                if let data, let image = UIImage(data: data)  {
                    withAnimation {
                        images.append(MediaKind(image: image))
                        StorageManager.shared.saveImage(id: id, image: image)
                    }
                } else {
                    let videoRef = storageRef.child("images/\(id).mp4")
                    videoRef.downloadURL { url, error in
                        if let url {
                            DispatchQueue.main.async {
                                withAnimation {
                                    images.append(MediaKind(videoURL: url))
                                }
                            }
                        }
                    }
                }
            }
        }
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
            VibrationsService.shared.softImpact()
            
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
                            .font(.system(size: 21))
                            .fontDesign(.rounded)
                            .lineLimit(1)
                        
                        if isCheckmark {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(Color.blue)
                                .font(.footnote)
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
            
            if images.count > 0 && mediaCount > 0 {
                if mediaCount == 1, let image = images[0].image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: UIScreen.main.bounds.width - 25)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .padding(.bottom, 10)
                        .onTapGesture {
                            withAnimation {
                                zoomableImage = image
                                isZoomableViewPresented = true
                            }
                        }
                } else if mediaCount == 1, let videoURL = images[0].videoURL {
                    TappableVideoPreview(url: videoURL, cornerRadius: 20, width: UIScreen.main.bounds.width - 25)
                        .frame(width: UIScreen.main.bounds.width - 25)
                        .padding(.bottom, 10)
                } else {
                    VStack(spacing: 5) {
                        if mediaCount > 1 {
                            Text("\(currentIndex + 1)/\(mediaCount)")
                                .font(.system(size: 18))
                                .fontDesign(.rounded)
                                .foregroundStyle(Color.gray)
                                .frame(width: UIScreen.main.bounds.width - 32, alignment: .trailing)
                                .padding(.top, -10)
                        }
                        
                        TabView(selection: $currentIndex) {
                            ForEach(0..<mediaCount, id: \.self) { i in
                                ZStack {
                                    if images.count > i {
                                        if let image = images[i].image {
                                            Image(uiImage: image)
                                                .resizable()
                                                .scaledToFit()
                                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                                .frame(width: UIScreen.main.bounds.width - 25)
                                                .padding(.bottom, 10)
                                                .onTapGesture {
                                                    withAnimation {
                                                        zoomableImage = image
                                                        isZoomableViewPresented = true
                                                    }
                                                }
                                        } else if let videoURL = images[i].videoURL {
                                            TappableVideoPreview(url: videoURL, cornerRadius: 20, width: UIScreen.main.bounds.width - 25)
                                                .frame(width: UIScreen.main.bounds.width - 25)
                                                .padding(.bottom, 10)
                                        }
                                    }
                                }
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .frame(
                            width: UIScreen.main.bounds.width - 25,
                            height: 350
                        )
                    }
                }
            }
            
            ZStack {
                VStack(spacing: 0) {
                    Text(title)
                        .font(.system(size: 19))
                        .lineLimit(!isExpanded && title.count >= maxTitleLen ? 4 : nil)
                        .fontDesign(.rounded)
                        .frame(width: UIScreen.main.bounds.width - 42, alignment: .leading)
                        .padding(.bottom, !isExpanded && title.count >= maxTitleLen && isShortPost ? 10 : 0)
                        .padding(.bottom, isShortPost ? 10 : 20)
                        .padding(.bottom, !isExpanded && title.count >= maxTitleLen ? 17 : 0)
                    
                    if ((title.count >= maxTitleLen && isExpanded) || title.count < maxTitleLen) && isShortPost {
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
                        .padding(.bottom, 15)
                        .frame(width: UIScreen.main.bounds.width - 50, alignment: .leading)
                    }
                }
                
                ZStack {
                    if !isExpanded && title.count >= maxTitleLen {
                        RoundedRectangle(cornerRadius: 30)
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
                            .frame(width: UIScreen.main.bounds.width - 42, height: 50)
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
                            .offset(y: 30)
                    }
                }
                .offset(y: 10)
            }
            
        }
        .frame(width: UIScreen.main.bounds.width - 10)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .foregroundStyle(Color(.secondarySystemBackground))
                .shadow(radius: 1)
        )
        .onAppear{
            if images.count == 0 && mediaCount != 0 && !isArchive {
                fetchImages()
            }
            
            if let user, let likedPosts = user.likedPosts {
                isLiked = likedPosts.contains(id)
            }
        }
    }
}
