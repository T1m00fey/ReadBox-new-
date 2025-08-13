//
//  ArtcleView.swift
//  Readify
//
//  Created by Тимофей Юдин on 05.11.2024.
//

import SwiftUI
import FirebaseStorage

struct ArticleView: View {
    let id: String
    let title: String
    let authorId: String
    let authorName: String
    let isCheckmark: Bool
    let isArchive: Bool
    let isShortPost: Bool
    
    @Binding var user: DBUser?
    
    @State private var image: UIImage? = nil
    @State private var videoURL: URL? = nil
    @State private var avatarImage: UIImage? = nil
    @State private var isExpanded = false
    @State private var isLiked = false
    
    private let maxTitleLen = 150
    
    private func fetchImage() {
        let articleImage = StorageManager.shared.getImage(id: id)
        let storage = Storage.storage()
        let storageRef = storage.reference()
        
        if articleImage != nil {
            withAnimation {
                image = articleImage
            }
        } else {
            let islandRef = storageRef.child("images/\(id).jpg")
            
            islandRef.getData(maxSize: 1 * 5012 * 5012) { data, error in
                if let data  {
                    withAnimation {
                        self.image = UIImage(data: data)
                        StorageManager.shared.saveImage(id: id, image: image ?? UIImage())
                    }
                } else {
                    let videoRef = storageRef.child("images/\(id).mp4")
                    videoRef.downloadURL { url, error in
                        if let url {
                            DispatchQueue.main.async {
                                withAnimation {
                                    self.videoURL = url
                                }
                            }
                        }
                    }
                }
            }
        }
        
        DispatchQueue.main.async {
            let islandRef = storageRef.child("avatars/\(authorId).jpg")
            
            islandRef.getData(maxSize: 1 * 5012 * 5012) { data, error in
                if let error = error {
                    print(error.localizedDescription)
                } else {
                    withAnimation {
                        self.avatarImage = UIImage(data: data!)
                    }
                }
            }
        }
    }
    
    private func updateLike() async throws {
        let likesCount = try await ArticlesManager.shared.getLikesCount(byPostId: id)
                        
        if isLiked {
            try await UserManager.shared.removeLikedPost(id: user?.userId ?? "", likedPost: id)
            try await ArticlesManager.shared.updateLikes(at: id, likesCount: likesCount - 1)
            
            withAnimation {
                user?.likedPosts?.removeAll {
                    $0 == id
                }
            }
        } else {
            try await UserManager.shared.addLikedPost(id: user?.userId ?? "", likedPost: id)
            try await ArticlesManager.shared.updateLikes(at: id, likesCount: likesCount + 1)
            
            withAnimation {
                user?.likedPosts?.append(id)
            }
        }
        
        withAnimation {
            isLiked.toggle()
            
            if isLiked {
                VibrationsService.shared.softImpact()
            } else {
                VibrationsService.shared.lightImpact()
            }
        }
    }
    
    var body: some View {
        
        VStack(spacing: -45) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .frame(width: UIScreen.main.bounds.width - 10)
                    .foregroundStyle(Color(uiColor: .secondarySystemBackground))
                    .shadow(radius: 2)
                
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
                    }
                    
                    HStack(spacing: 0) {
                        Text(authorName)
                            .font(.system(size: 21))
                            .fontDesign(.rounded)
                            .padding(.vertical, 20)
                            .lineLimit(1)
                        
                        if isCheckmark {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(Color.blue)
                                .font(.footnote)
                                .padding(.top, 1)
                        }
                        
                        Spacer()
                    }
                }
                .frame(width: UIScreen.main.bounds.width - 42, height: 90, alignment: .topLeading)
                .padding(.bottom, 16)
            }
            
            if let image = image {
                ZStack {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: UIScreen.main.bounds.width - 10)
                        .clipShape(RoundedRectangle(cornerRadius: 30))
                        .shadow(radius: 2)
                }
            } else if let videoURL {
                TappableVideoPreview(url: videoURL, cornerRadius: 30, width: UIScreen.main.bounds.width - 10)
                    .frame(width: UIScreen.main.bounds.width - 10)
                    .shadow(radius: 2)
            }
            
            ZStack {
                RoundedRectangle(cornerRadius: 25)
                    .foregroundStyle(Color(uiColor: .secondarySystemBackground))
                    .frame(width: UIScreen.main.bounds.width - 10)
                    .shadow(radius: 2)
                
                VStack(spacing: 0) {
                    Text(title)
                        .font(.system(size: 19))
                        .fontDesign(.rounded)
                        .lineLimit(!isExpanded && title.count >= maxTitleLen ? 3 : nil)
                        .frame(width: UIScreen.main.bounds.width - 42, alignment: .leading)
                        .padding(.top, 20)
                        .padding(.bottom, !isExpanded && title.count >= maxTitleLen && isShortPost ? 10 : 0)
                        .padding(.bottom, isShortPost ? 10 : 20)
                        .padding(.bottom, !isExpanded && title.count >= maxTitleLen ? 17 : 0)
                    
                    if ((title.count >= maxTitleLen && isExpanded) || title.count < maxTitleLen) && isShortPost {
                        HStack(spacing: 12) {
                            ShareLink(item: URL(string: "https://readbox-links.online/posts/?index=\(id)")!) {
                                Image(systemName: "arrowshape.turn.up.right")
                                    .font(.system(size: 22))
                            }
                            
                            Image(systemName: isLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                                .font(.system(size: 22))
                                .onTapGesture {
                                    Task {
                                        do {
                                          try? await updateLike()
                                        }
                                    }
                                }
                        }
                        .padding(.bottom, 15)
                        .frame(width: UIScreen.main.bounds.width - 50, alignment: .trailing)
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
                            .offset(y: 25)
                    }
                }
                .offset(y: 15)
            }
            
        }
        .onAppear{
            if image == nil && !isArchive {
                fetchImage()
            }
            
            if let user, let likedPosts = user.likedPosts {
                isLiked = likedPosts.contains(id)
            }
        }
        
    }
}
