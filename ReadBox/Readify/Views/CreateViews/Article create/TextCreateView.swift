//
//  TextCreateView.swift
//  Readify
//
//  Created by Тимофей Юдин on 13.02.2025.
//

import SwiftUI
import MarkdownUI
import PopupView
import SwiftfulLoadingIndicators
import _PhotosUI_SwiftUI
import PopupView
import FirebaseStorage
import TipKit

struct TextCreateView: View {
    let id: String
    @Binding var title: String
    let text: String
    let isEditing: Bool
    let uploadingLanguage: String
    let oldMediaCount: Int
    @Binding var media: [MediaKind?]
    @Binding var mediaURLs: [URL]
    @Binding var postsCount: Int
    @Binding var posts: [PrePost]
    @Binding var archivePosts: [PrePost]
    
    @Binding var isCreateViewPresented: Bool
    
    @StateObject private var viewModel = TextCreateViewModel()
    @FocusState var isTEFocused: Bool
    
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var hudService: HUDService
    @EnvironmentObject var changedPostsManager: ChangedPostsManager
    
    private func applyPostsCountDelta(forNewPost newIsArchive: Bool, createdNewPostId: String? = nil) async throws {
        var delta = 0
        
        if isEditing == false {
            if newIsArchive == false { delta = 1 }
        } else {
            let wasArchived = archivePosts.contains { $0.id == id }
            let wasPublished = posts.contains { $0.id == id }
            
            if wasArchived && newIsArchive == false { delta = 1 }
            if wasPublished && newIsArchive == true { delta = -1 }
        }
        
        guard delta != 0 else { return }
        postsCount += delta
                
        let userId = try AuthenticationManager.shared.getAuthenticatedUser().uid
        
        try await UserManager.shared.updatePostsCount(userId: userId, postsCount: postsCount)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemBackground)
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    
                    VStack {
                        if viewModel.isPreviewShowed {
                            Markdown(
                                viewModel.text
                                    .replacingOccurrences(of: "\n", with: "  \n").normalizeEmptyLines()
                                    .replacingOccurrences(of: "readbox-links.online", with: "firebasestorage.googleapis.com")
                                    .replacingOccurrences(of: "cont", with: "contentImages")
                            )
                            .markdownImageProvider(
                                WebImageProvider(onImageTap: { url in
                                    viewModel.selectedImageURL = url
                                    viewModel.isImageFullScreenPresented = true
                                })
                            )
                            .padding(.vertical, 16)
                            .frame(width: UIScreen.main.bounds.width - 32, alignment: .topLeading)
                            .padding(.horizontal)
                            
                        } else {
                            MarkdownTextView(text: $viewModel.text, selectedRange: $viewModel.selectedRange)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                                .frame(width: UIScreen.main.bounds.width - 10, height: viewModel.heightOfTE)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color(uiColor: .label), lineWidth: 1)
                                )
                                .focused($isTEFocused)
                                .padding(.horizontal)
                                .onAppear {
                                    viewModel.text = viewModel.text.replacingOccurrences(of: "firebasestorage.googleapis.com", with: "readbox-links.online")
                                    viewModel.text = viewModel.text.replacingOccurrences(of: "contentImages", with: "cont")
                                }
                        }
                        
                    }
                    
                }
                .background(Color(.systemBackground))
                .onChange(of: isTEFocused) {
                    withAnimation {
                        viewModel.heightOfTE = isTEFocused ? 300 : UIScreen.main.bounds.height - 300
                    }
                }
                .onTapGesture {
                    isTEFocused = false
                }
                .popup(isPresented: $viewModel.isMediaControlViewPresented) {
                    MediaControlView(
                        postId: id,
                        mediaURLs: $mediaURLs,
                        text: $viewModel.text,
                        errorText: $viewModel.errorText,
                        isErrorPopupPresented: $viewModel.isErrorPopupPresented,
                        isErrorPopup: $viewModel.isErrorPopup
                    )
                        .shadow(radius: 2)
                } customize: {
                    $0
                        .type(.toast)
                        .appearFrom(.bottomSlide)
                        .dragToDismiss(true)
                        .displayMode(.sheet)
                }

                
                if !viewModel.isPreviewShowed {
                    VStack {
                        Spacer()
                        
                        HStack {
                            
                            if #available(iOS 26.0, *) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 22))
                                    .foregroundStyle(Color(.label))
                                    .padding(.all, 10)
                                    .glassEffect(.regular, in: .rect(cornerRadius: 12))
                                    .onTapGesture {
                                        viewModel.isMediaControlViewPresented.toggle()
                                    }
                                    .popoverTip(AuthorMediaListTip())
                            } else {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 22))
                                    .foregroundStyle(Color(.label))
                                    .background(Color(.secondarySystemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .shadow(radius: 1)
                                    .onTapGesture {
                                        viewModel.isMediaControlViewPresented.toggle()
                                    }
                                    .popoverTip(AuthorMediaListTip())
                            }
                            
                            ZStack {
                                RoundedRectangle(cornerRadius: 20)
                                    .foregroundStyle(Color(uiColor: .secondarySystemBackground))
                                    .shadow(radius: 1)
                                    .frame(height: 60)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        PhotosPicker(selection: $viewModel.imageItem, matching: .any(of: [.images, .videos])) {
                                            Image(systemName: "photo.badge.plus")
                                                .font(.system(size: 20))
                                                .foregroundStyle(Color(.label))
                                                .frame(width: 40, height: 40)
                                                .background(Color(.systemBackground))
                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                                .shadow(radius: 1)
                                        }
                                        .disabled(viewModel.isImageUploading)
//                                        .popoverTip(AuthorFileAttachTip())
                                        
                                        Menu(NSLocalizedString("titleLabel", comment: "")) {
                                            ForEach(1..<7) { num in
                                                Button {
                                                    viewModel.toggleMarkdown(type: .header(level: num))
                                                } label: {
                                                    Text("h\(num)")
                                                }
                                            }
                                        }
                                        .font(.title2)
                                        .fontDesign(.rounded)
                                        .frame(height: 40)
                                        .padding(.horizontal)
                                        .background(Color(uiColor: .systemBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .shadow(radius: 2)
                                        
                                        ForEach(0..<viewModel.markdownButtons.count, id: \.self) { index in
                                            viewModel.configureMarkdownButton(
                                                type: viewModel.markdownButtons[index]
                                            )
                                        }
                                        
                                    }
                                    .padding(.vertical, 2)
                                    .padding(.leading, 1)
                                    
                                }
                                .background(Color(uiColor: .secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .padding(.horizontal, 10)
                            }
                            
//                            if #available(iOS 26.0, *) {
//                                Image(systemName: "arrow.right")
//                                    .font(.system(size: 22))
//                                    .foregroundStyle(Color(uiColor: .systemBackground))
//                                    .padding(.all, 10)
//                                    .glassEffect(.regular, in: .rect(cornerRadius: 12))
//                                    .tint(Color(.label))
//                                    .onTapGesture {
//                                        guard !viewModel.isLoading else { return }
//                                        guard !viewModel.isImageUploading else { return }
//                                        
//                                        isTEFocused = false
//                                        viewModel.isConfirmationViewPresented = true
//                                    }
//                            } else {
//                                Button {
//                                    guard !viewModel.isLoading else { return }
//                                    
//                                    isTEFocused = false
//                                    viewModel.isConfirmationViewPresented = true
//                                } label: {
//                                    Image(systemName: "arrow.right")
//                                        .font(.system(size: 22))
//                                        .foregroundStyle(Color(uiColor: .systemBackground))
//                                        .frame(width: 50, height: 50)
//                                        .background(Color(uiColor: .label))
//                                        .clipShape(RoundedRectangle(cornerRadius: 12))
//                                        .shadow(radius: 2)
//                                }
//                                .disabled(viewModel.isImageUploading)
//                            }
                            
                            Button {
                                guard !viewModel.isLoading else { return }
                                
                                isTEFocused = false
                                viewModel.isConfirmationViewPresented = true
                            } label: {
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 22))
                                    .foregroundStyle(Color(uiColor: .systemBackground))
                                    .frame(width: 50, height: 50)
                                    .background(Color(uiColor: .label))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .shadow(radius: 2)
                            }
                            .disabled(viewModel.isImageUploading)
                        }
                        .frame(width: UIScreen.main.bounds.width - 32)
                        .padding(.bottom, 20)
                        
                    }
                    .onChange(of: viewModel.imageItem) {
                        Task {
                            do {
                                let url = try await viewModel.insertMedia(with: UUID().uuidString + id)
                                
                                if url != "" {
                                    withAnimation {
                                        mediaURLs.append(URL(string: url)!)
                                    }
                                }
                            } catch {
                                withAnimation {
                                    viewModel.errorText = error.localizedDescription
                                    viewModel.isErrorPopupPresented = true
                                    viewModel.isErrorPopup = true
                                }
                            }
                        }
                    }
                    
                }
            }
            .fullScreenCover(isPresented: $viewModel.isImageFullScreenPresented) {
                if let url = viewModel.selectedImageURL {
                    ZoomableImageView(imageURL: url)
                }
            }
//            .popup(isPresented: $viewModel.isConfirmationViewPresented) {
//                ConfirmationView(addingMode: $viewModel.addingMode)
//                .shadow(radius: 3)
//            } customize: {
//                $0
//                    .type(.toast)
//                    .appearFrom(.bottomSlide)
//                    .dragToDismiss(true)
//                    .displayMode(.sheet)
//            }
            .sheet(isPresented: $viewModel.isConfirmationViewPresented, content: {
                ConfirmationView(addingMode: $viewModel.addingMode)
                    .presentationDetents([.height(250)])
                    .presentationCornerRadius(30)
                    .presentationDragIndicator(.visible)
            })
            .onChange(of: viewModel.addingMode) {
                hudService.showLoading()
                isCreateViewPresented = false
                let newIsArchive = (viewModel.addingMode == 2)
                let items = media.compactMap { $0 }
 
                if viewModel.addingMode > 0 {
                    if isEditing {
                        Task {
                            do {
                                try await viewModel.updatePost(
                                    id: id,
                                    title: title,
                                    text: viewModel.text,
                                    isArchive: newIsArchive,
                                    mediaURLs: mediaURLs,
                                    uploadingLanguage: uploadingLanguage,
                                    items: items,
                                    oldMediaCount: oldMediaCount
                                )

                                try await applyPostsCountDelta(forNewPost: newIsArchive)

                                changedPostsManager.changedPostsIDs.append(id)
                                hudService.showSuccessPopup(type: .post)
                                
                                NotificationCenter.default.post(name: .postsDidChange, object: nil)
                            } catch {
                                hudService.showErrorPopup(with: error.localizedDescription)
                            }
                        }
                    } else {
                        Task {
                            do {
                                let _ = try await viewModel.addNewPost(
                                    title: title,
                                    text: viewModel.text,
                                    isArchive: newIsArchive,
                                    uploadingLanguage: uploadingLanguage,
                                    mediaURLs: mediaURLs,
                                    items: items
                                )

                                try await applyPostsCountDelta(forNewPost: newIsArchive)

                                StorageManager.shared.deleteText()
                                hudService.showSuccessPopup(type: .post)
                                
                                NotificationCenter.default.post(name: .postsDidChange, object: nil)
                            } catch {
                                hudService.showErrorPopup(with: error.localizedDescription)
                            }
                        }
                    }
                }

                viewModel.addingMode = 0
            }

            .popup(isPresented: $viewModel.isErrorPopupPresented) {
                Text(viewModel.errorText)
                    .frame(width: UIScreen.main.bounds.width - 72, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .foregroundStyle(viewModel.isErrorPopup ? Color.white : Color(.label))
                    .background(viewModel.isErrorPopup ? Color.red : Color(.secondarySystemBackground))
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
            .task {
                try? Tips.configure()
            }
            .onAppear {
                withAnimation {
                    viewModel.navigationTitle = viewModel.getNavigationTitle(isEditing)
                }
                
                let savedText = StorageManager.shared.getText()
                viewModel.text = savedText == "" ? text : savedText
                
                isTEFocused = false
            }
            .onDisappear {
                if viewModel.isPreviewShowed {
                    StorageManager.shared.save(text: viewModel.text)
                }
                
                isTEFocused = false
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        StorageManager.shared.save(text: viewModel.text)
                        dismiss()
                    } label: {
                        Image(systemName: "arrow.left")
                    }
                    .disabled(viewModel.isImageUploading)
                }
                
                ToolbarItem(placement: .principal) {
                    if viewModel.isImageUploading {
                        HStack(spacing: 5) {
                            Text(NSLocalizedString("uploadingLabel", comment: ""))
                                .font(.system(size: 17))
                                .fontWeight(.semibold)
                            
                            LoadingIndicator(
                                animation: .circleRunner,
                                color: Color(.label),
                                size: .small,
                                speed: .fast
                            )
                            .scaleEffect(0.7)
                        }
                    } else {
                        Text(viewModel.getNavigationTitle(isEditing))
                            .font(.system(size: 17))
                            .fontWeight(.semibold)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation {
                            viewModel.isPreviewShowed.toggle()
                            viewModel.navigationTitle = viewModel.isPreviewShowed ? NSLocalizedString("previewLabel", comment: "") : viewModel.getNavigationTitle(isEditing)
                        }
                    } label: {
                        if viewModel.isLoading {
                            LoadingIndicator(
                                animation: .circleRunner,
                                size: .small,
                                speed: .fast
                            )
                        } else {
                            viewModel.isPreviewShowed ? Image(systemName: "pencil.and.scribble") : Image(systemName: "eye")
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .overlay(EnableSwipeBack().frame(width: 0, height: 0))
        }
    }
}

//struct MarkdownPreview: UIViewRepresentable {
//    let markdownText: String
//
//    func makeUIView(context: Context) -> UITextView {
//        let textView = UITextView()
//        textView.isEditable = false
//        textView.backgroundColor = UIColor.clear
//        textView.font = UIFont.systemFont(ofSize: 16)
//        return textView
//    }
//
//    func updateUIView(_ uiView: UITextView, context: Context) {
//        let md = SwiftyMarkdown(string: markdownText)
//        uiView.attributedText = md.attributedString()
//    }
//}
