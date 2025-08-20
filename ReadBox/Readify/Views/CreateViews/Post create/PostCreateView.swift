//
//  PostCreateView.swift
//  ReadBox
//
//  Created by Тимофей Юдин on 18.08.2025.
//

import SwiftUI
import PhotosUI
import PopupView

struct PostCreateView: View {
    let postId: String
    let title: String
    let authorId: String
    let isArchived: Bool
    
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
        posts: Binding<[PrePost]>,
        archivedPosts: Binding<[PrePost]>,
        postsCount: Binding<Int>
    ) {
        self.postId = postId
        self.title = title
        self.authorId = authorId
        self.isArchived = isArchived
        self._posts = posts
        self._archivedPosts = archivedPosts
        self._postsCount = postsCount
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                
                VStack(spacing: 20) {
//                    PhotosPicker(selection: $viewModel.imageItem, matching: .any(of: [.images, .videos])) {
//                        Text("")
//                    }
                    
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
                                height: 300,
                                alignment: .topLeading
                            )
                            .padding(.bottom, 20)
                        
                        Text(NSLocalizedString("whatsNewLabel", comment: ""))
                            .font(.system(size: 20))
                            .foregroundStyle(Color.gray)
                            .fontDesign(.rounded)
                            .frame(width: UIScreen.main.bounds.width - 32, height: 300, alignment: .topLeading)
                            .padding(.leading, 10)
                            .opacity(viewModel.text.isEmpty ? 1 : 0)
                    }
                }
                .onAppear {
                    isTEFocused = true
                }
                
            }
            .onAppear {
                viewModel.text = title
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
            .onChange(of: viewModel.addingMode) {
                viewModel.isArchive = viewModel.addingMode == 2 ? true : false
                
                if postId == "" {
                    Task {
                        do {
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
                            
                            dismiss()
                        } catch {
                            
                        }
                    }
                } else {
                    Task {
                        do {
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
                            
                            dismiss()
                        } catch {
                            
                        }
                    }
                }
            }
            
        }
    }
}
