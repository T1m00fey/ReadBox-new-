//
//  PostCreateView.swift
//  ReadBox
//
//  Created by Тимофей Юдин on 18.08.2025.
//

import SwiftUI
import PhotosUI
import PopupView
import AVFoundation
import SwiftfulLoadingIndicators

struct PostCreateView: View {
    let postId: String
    let title: String
    let authorId: String
    let isArchived: Bool
    let cover: UIImage?
    let isVideoCover: Bool
    
    @Binding var posts: [PrePost]
    @Binding var archivedPosts: [PrePost]
    @Binding var postsCount: Int
    
    @StateObject private var viewModel = PostCreateViewModel()
    
    @FocusState private var isTEFocused: Bool
    
    @Environment(\.dismiss) var dismiss
    
    init(
        postId: String = "",
        title: String = "",
        authorId: String,
        isArchived: Bool,
        cover: UIImage? = nil,
        isVideoCover: Bool = false,
        posts: Binding<[PrePost]>,
        archivedPosts: Binding<[PrePost]>,
        postsCount: Binding<Int>
    ) {
        self.postId = postId
        self.title = title
        self.authorId = authorId
        self.isArchived = isArchived
        self.cover = cover
        self.isVideoCover = isVideoCover
        self._posts = posts
        self._archivedPosts = archivedPosts
        self._postsCount = postsCount
    }
    
    private func uploadPost() {
        viewModel.isArchive = viewModel.addingMode == 2 ? true : false
        
        if postId == "" {
            Task {
                do {
                    withAnimation {
                        viewModel.isLoading = true
                    }
                    
                    let id = try await viewModel.uploadPost(
                        title: viewModel.text,
                        isArchive: viewModel.isArchive,
                        uploadingLanguage: viewModel.selectedLanguage
                    )
                    
                    let post = PrePost(
                        id: id,
                        title: viewModel.text,
                        authorId: authorId,
                        viewsCount: 0,
                        likesCount: 0,
                        isArchive: viewModel.isArchive,
                        isShortPost: true
                    )
                    
                    withAnimation {
                        if viewModel.isArchive {
                            archivedPosts.insert(
                                post,
                                at: 0
                            )
                        } else {
                            posts.insert(
                                post,
                                at: 0
                            )
                            
                            postsCount += 1
                            Task {
                                try await UserManager.shared.updatePostsCount(userId: authorId, postsCount: postsCount)
                            }
                        }
                    }
                    
                    withAnimation {
                        viewModel.isLoading = false
                    }
                    
                    dismiss()
                } catch {
                    withAnimation {
                        viewModel.errorText = error.localizedDescription
                        viewModel.isErrorPopupPresented = true
                        
                        viewModel.isLoading = false
                    }
                }
            }
        } else {
            Task {
                do {
                    withAnimation {
                        viewModel.isLoading = true
                    }
                    
                    try await viewModel.updatePost(
                        postId: postId,
                        title: viewModel.text,
                        isArchive: viewModel.isArchive,
                        uploadingLanguage: viewModel.selectedLanguage
                    )
                    
                    let viewsCount = try await ArticlesManager.shared.getViews(at: postId)
                    let likesCount = try await ArticlesManager.shared.getLikesCount(byPostId: postId)
                                                        
                    let post = PrePost(
                        id: postId,
                        title: viewModel.text,
                        authorId: authorId,
                        viewsCount: viewsCount,
                        likesCount: likesCount,
                        isArchive: viewModel.isArchive,
                        isShortPost: true
                    )
                    
                    var index = 0
                                                        
                    if viewModel.isArchive {
                        if viewModel.isArchive != isArchived {
                            posts.removeAll { $0.id == postId }
                            postsCount -= 1
                            try await UserManager.shared.updatePostsCount(userId: authorId, postsCount: postsCount)
                            
                            index = posts.firstIndex { $0.id == postId } ?? 0
                        } else {
                            index = archivedPosts.firstIndex { $0.id == postId } ?? 0
                        }
                        
                        archivedPosts.removeAll { $0.id == postId }
                        archivedPosts.insert(post, at: index)
                    } else {
                        if viewModel.isArchive != isArchived {
                            archivedPosts.removeAll { $0.id == postId }
                            postsCount += 1
                            try await UserManager.shared.updatePostsCount(userId: authorId, postsCount: postsCount)
                            
                            index = archivedPosts.firstIndex { $0.id == postId } ?? 0
                        } else {
                            index = posts.firstIndex { $0.id == postId } ?? 0
                        }
                        
                        posts.removeAll { $0.id == postId }
                        posts.insert(post, at: index)
                    }
                    
                    withAnimation {
                        viewModel.isLoading = false
                    }
                    
                    dismiss()
                } catch {
                    withAnimation {
                        viewModel.errorText = error.localizedDescription
                        viewModel.isErrorPopupPresented = true
                        
                        viewModel.isLoading = false
                    }
                }
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                    .onTapGesture { isTEFocused = false }
                
                ScrollView(showsIndicators: false) {
                    
                    VStack(spacing: 20) {
                        VStack(spacing: 10) {
                            Text(NSLocalizedString("whichFeedUploadingToLabel", comment: ""))
                                .font(.system(size: 17))
                                .foregroundStyle(.gray)
                                .frame(width: UIScreen.main.bounds.width - 36, alignment: .leading)
                            
                            CustomSegmentedControl(selectedLanguage: $viewModel.selectedLanguage)
                        }
                        .padding(.top, 25)
                        
                        ZStack {
                            TextEditor(text: $viewModel.text)
                                .focused($isTEFocused)
                                .font(.system(size: 20))
                                .fontDesign(.rounded)
                                .frame(
                                    width: UIScreen.main.bounds.width - 32,
                                    height: 200,
                                    alignment: .topLeading
                                )
                                .padding(.bottom, 15)
                            
                            Text(NSLocalizedString("whatsNewLabel", comment: ""))
                                .font(.system(size: 20))
                                .foregroundStyle(Color.gray)
                                .fontDesign(.rounded)
                                .frame(width: UIScreen.main.bounds.width - 32, height: 200, alignment: .topLeading)
                                .padding(.leading, 10)
                                .opacity(viewModel.text.isEmpty ? 1 : 0)
                        }
                        
                        if let image = viewModel.image {
                            VStack {
                                ZStack {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: UIScreen.main.bounds.width - 32)
                                        .clipShape(RoundedRectangle(cornerRadius: 20))
                                    
                                    if viewModel.isVideoCover {
                                        Image(systemName: "play.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 50)
                                            .foregroundStyle(Color(.secondarySystemBackground))
                                    }
                                }
                                
                                HStack {
                                    Text(NSLocalizedString("removePhotoLabel", comment: ""))
                                        .font(.system(size: 24))
                                        .fontDesign(.rounded)
                                    
                                    Image(systemName: "minus.circle")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20)
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 10)
                                .frame(width: UIScreen.main.bounds.width - 32)
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .foregroundStyle(Color(.secondarySystemBackground))
                                        .shadow(radius: 1)
                                        
                                )
                                .padding(.bottom, 30)
                                .onTapGesture {
                                    withAnimation {
                                        viewModel.image = nil
                                        viewModel.isVideoCover = false
                                        viewModel.imageItem = nil
                                    }
                                }
                            }
                        }
                    }
                    .onAppear {
                        isTEFocused = true
                    }
                    
                }
                .onAppear {
                    viewModel.text = title
                    if !postId.isEmpty {
                        withAnimation {
                            viewModel.setCover(image: cover, isVideo: isVideoCover)
                        }
                    }
                }
                .popup(isPresented: $viewModel.isConfirmationPopupPresented) {
                    ConfirmationView(
                        addingMode: $viewModel.addingMode,
                        popupType: .publishType
                    )
                    .shadow(radius: 3)
                } customize: {
                    $0
                        .type(.toast)
                        .appearFrom(.bottomSlide)
                        .dragToDismiss(true)
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
                .scrollClipDisabled()
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Text(NSLocalizedString("cancelButton", comment: ""))
                            .font(.system(size: 17))
                            .fontDesign(.rounded)
                            .onTapGesture {
                                dismiss()
                            }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        if viewModel.isLoading {
                            LoadingIndicator(
                                animation: .circleRunner,
                                color: Color(.label),
                                size: .small,
                                speed: .fast
                            )
                        } else {
                            Button {
                                VibrationsService.shared.lightImpact()
                                viewModel.isConfirmationPopupPresented = true
                            } label: {
                                Text(NSLocalizedString("publishLabel", comment: ""))
                                    .foregroundStyle(Color(.systemBackground))
                                    .font(.system(size: 16))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5).background(Color(.label))
                                    .clipShape(Capsule())
                            }
                            .disabled(viewModel.text.isEmpty)
                        }
                    }
                }
                .onChange(of: viewModel.addingMode) {
                    uploadPost()
                }
                
                VStack {
                    Spacer()
                    
                    HStack {
                        PhotosPicker(selection: $viewModel.imageItem, matching: .any(of: [.images, .videos])) {
                            Image(systemName: "photo.badge.plus.fill")
                                .foregroundStyle(Color(.label))
                                .font(.system(size: 20))
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .foregroundStyle(Color(.secondarySystemBackground))
                                        .shadow(radius: 1)
                                )
                                .opacity(isTEFocused ? 1 : 0)
                                .padding(.bottom, 10)
                        }
                        .onChange(of: viewModel.imageItem) {
                            Task {
                                viewModel.didChangeCover = true
                                guard let item = viewModel.imageItem else { return }

                                guard let data = try? await item.loadTransferable(type: Data.self) else {
                                    print("⚠️ Невозможно загрузить данные из файла")
                                    return
                                }

                                if let image = UIImage(data: data) {
                                    print("🖼 Обложка — изображение")
                                    withAnimation {
                                        viewModel.image = image
                                        viewModel.isVideoCover = false
                                    }
                                    return
                                }

                                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
                                try? data.write(to: tempURL)
                                viewModel.videoURL = tempURL

                                let asset = AVAsset(url: tempURL)
                                let duration = try await asset.load(.duration)
                                let secondsDuration = CMTimeGetSeconds(duration)
                                
                                guard secondsDuration <= 60 else {
                                    withAnimation {
                                        viewModel.errorText = NSLocalizedString("durationCoverErrorLabel", comment: "")
                                        viewModel.isErrorPopupPresented = true
                                        viewModel.image = nil
                                        viewModel.isVideoCover = false
                                    }
                                    
                                    return
                                }
                                
                                let generator = AVAssetImageGenerator(asset: asset)
                                generator.appliesPreferredTrackTransform = true
                                let cgImage = try? generator.copyCGImage(at: .zero, actualTime: nil)
                                let thumbnail = cgImage.map { UIImage(cgImage: $0) }

                                withAnimation {
                                    viewModel.image = thumbnail
                                    viewModel.isVideoCover = true
                                }
                            }
                        }
                        
                        Spacer()
                    }
                    .frame(width: UIScreen.main.bounds.width - 32)
                }
                
            }
        }
    }
}
