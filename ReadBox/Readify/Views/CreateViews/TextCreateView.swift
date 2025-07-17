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

struct TextCreateView: View {
    let id: String
    @Binding var title: String
    let image: UIImage
    @Binding var description: String
    let text: String
    let isEditing: Bool
    let uploadingLanguage: String
    @Binding var postsCount: Int
    @Binding var posts: [PrePost]
    @Binding var archivePosts: [PrePost]
    
    @Binding var isCreateViewPresented: Bool
    
    @StateObject private var viewModel = TextCreateViewModel()
    @FocusState var isTEFocused: Bool
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemBackground)
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    
                    VStack {
                        
                        if viewModel.isPreviewShowed {
                            
                            Markdown(
                                viewModel.text.normalizeEmptyLines()
                            )
                            .markdownTheme(.gitHub)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            .frame(width: UIScreen.main.bounds.width - 10, alignment: .topLeading)
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
                            
                        }
                        
                    }
                    
                }
                .onChange(of: isTEFocused) {
                    withAnimation {
                        viewModel.heightOfTE = isTEFocused ? 300 : UIScreen.main.bounds.height - 300
                    }
                }
                .onTapGesture {
                    isTEFocused = false
                }
                
                if !viewModel.isPreviewShowed {
                    VStack {
                        Spacer()
                        
                        HStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: 20)
                                    .foregroundStyle(Color(uiColor: .secondarySystemBackground))
                                    .shadow(radius: 3)
                                    .frame(height: 60)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
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
                                        
                                        Button("B") {
                                            viewModel.toggleMarkdown(type: .bold)
                                        }
                                        .font(.title2)
                                        .fontDesign(.rounded)
                                        .bold()
                                        .frame(height: 40)
                                        .padding(.horizontal)
                                        .background(Color(uiColor: .systemBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .shadow(radius: 2)
                                        
                                        
                                        Button("I") {
                                            viewModel.toggleMarkdown(type: .italic)
                                        }
                                        .font(.title2)
                                        .fontDesign(.rounded)
                                        .italic()
                                        .frame(height: 40)
                                        .padding(.horizontal)
                                        .background(Color(uiColor: .systemBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .shadow(radius: 2)
                                        
                                        Button(NSLocalizedString("quoteLabel", comment: "")) {
                                            viewModel.toggleMarkdown(type: .blockquote)
                                        }
                                        .font(.title2)
                                        .fontDesign(.rounded)
                                        .frame(height: 40)
                                        .padding(.horizontal)
                                        .background(Color(uiColor: .systemBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .shadow(radius: 2)
                                        
                                        Button(NSLocalizedString("strikeThroughLabel", comment: "")) {
                                            viewModel.toggleMarkdown(type: .strikethrough)
                                        }
                                        .font(.title2)
                                        .fontDesign(.rounded)
                                        .frame(height: 40)
                                        .padding(.horizontal)
                                        .background(Color(uiColor: .systemBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .shadow(radius: 2)
                                        
                                        Button(NSLocalizedString("codeLabel", comment: "")) {
                                            viewModel.toggleMarkdown(type: .code)
                                        }
                                        .font(.title2)
                                        .fontDesign(.rounded)
                                        .frame(height: 40)
                                        .padding(.horizontal)
                                        .background(Color(uiColor: .systemBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .shadow(radius: 2)
                                        
                                        Button(NSLocalizedString("linkLabel", comment: "")) {
                                            viewModel.toggleMarkdown(type: .link)
                                        }
                                        .font(.title2)
                                        .fontDesign(.rounded)
                                        .frame(height: 40)
                                        .padding(.horizontal)
                                        .background(Color(uiColor: .systemBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .shadow(radius: 2)
                                        
                                    }
                                    .padding(.vertical, 2)
                                    .padding(.leading, 1)
                                    
                                }
                                .background(Color(uiColor: .secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .padding(.horizontal, 10)
                            }
                            
                            Button {
                                guard !viewModel.isLoading else { return }
                                
                                isTEFocused = false
                                viewModel.isConfirmationViewPresented = true
                            } label: {
                                Image(systemName: "arrow.right")
                                    .font(.title2)
                                    .foregroundStyle(Color(uiColor: .systemBackground))
                                    .frame(width: 50, height: 50)
                                    .background(Color(uiColor: .label))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .shadow(radius: 2)
                            }
                        }
                        .frame(width: UIScreen.main.bounds.width - 32)
                        .padding(.bottom, 20)
                        
                    }
                }
            }
            .popup(isPresented: $viewModel.isConfirmationViewPresented) {
                ConfirmationView(addingMode: $viewModel.addingMode)
                .shadow(radius: 3)
            } customize: {
                $0
                    .type(.toast)
                    .appearFrom(.bottomSlide)
                    .dragToDismiss(true)
            }
            .onChange(of: viewModel.addingMode) {
                Task {
                    viewModel.isLoading = true
                }
                
                var isArchive = false
                
                if viewModel.addingMode == 2 {
                    isArchive = true
                }
                
                if viewModel.addingMode > 0 {
                    if isEditing {
                        
                        Task {
                            do {
                                let isArchived = try await ArticlesManager.shared.getIsArchive(of: id)
                                let userId = try AuthenticationManager.shared.getAuthenticatedUser().uid
                                
                                try await viewModel.updatePost(
                                    id: id,
                                    title: title,
                                    image: image,
                                    description: description,
                                    text: viewModel.text,
                                    isArchive: isArchive
                                )
                                
                                if isArchived != isArchive {
                                    postsCount += isArchive ? -1 : 1
                                    
                                    try await UserManager.shared.updatePostsCount(userId: userId, postsCount: postsCount)
                                    
                                    if isArchived {
                                        let post = archivePosts.first { $0.id == id }
                                        archivePosts.removeAll { $0.id == id }
                                        
                                        posts.insert(
                                            PrePost(
                                                id: id,
                                                title: title,
                                                authorId: userId,
                                                viewsCount: post?.viewsCount,
                                                likesCount: post?.likesCount,
                                                isArchive: false
                                            ),
                                            at: 0
                                        )
                                    } else {
                                        let post = posts.first { $0.id == id }
                                        posts.removeAll { $0.id == id }
                                        
                                        archivePosts.insert(
                                            PrePost(
                                                id: id,
                                                title: title,
                                                authorId: userId,
                                                viewsCount: post?.viewsCount,
                                                likesCount: post?.likesCount,
                                                isArchive: false
                                            ),
                                            at: 0
                                        )
                                    }
                                } else {
                                    if isArchive {
                                        let post = archivePosts.first { $0.id == id }
                                        
                                        if let index = archivePosts.firstIndex(where: { $0.id == id }) {
                                            archivePosts[index] = PrePost(
                                                id: id,
                                                title: title,
                                                authorId: userId,
                                                viewsCount: post?.viewsCount,
                                                likesCount: post?.likesCount,
                                                isArchive: true
                                            )
                                        }
                                    } else {
                                        let post = posts.first { $0.id == id }
                                        
                                        if let index = posts.firstIndex(where: { $0.id == id }) {
                                            posts[index] = PrePost(
                                                id: id,
                                                title: title,
                                                authorId: userId,
                                                viewsCount: post?.viewsCount,
                                                likesCount: post?.likesCount,
                                                isArchive: false
                                            )
                                        }
                                    }
                                }
                                
                                StorageManager.shared.deleteText()
                                
                            } catch {
                                withAnimation {
                                    viewModel.isLoading = false
                                    viewModel.errorText = error.localizedDescription
                                    viewModel.isErrorPopupPresented = true
                                    
                                    return
                                }
                            }
                            
                            isCreateViewPresented = false
                        }
                        
                        StorageManager.shared.deleteImage(id: id)
                        
                    } else {
                        Task {
                            do {
                                let userId = try AuthenticationManager.shared.getAuthenticatedUser().uid
                                
                                try await viewModel.addNewPost(
                                    title: title,
                                    description: description,
                                    text: viewModel.text,
                                    image: image,
                                    isArchive: isArchive,
                                    uploadingLanguage: uploadingLanguage
                                )
                                
                                if !isArchive {
                                    postsCount += 1
                                    
                                    try await UserManager.shared.updatePostsCount(userId: userId, postsCount: postsCount)
                                    let maxIndex = try await ArticlesManager.shared.getMaxIndex()
                                    
                                    posts.insert(
                                        PrePost(
                                            id: maxIndex ?? "",
                                            title: title,
                                            authorId: userId,
                                            viewsCount: 0,
                                            likesCount: 0,
                                            isArchive: false
                                        ),
                                        at: 0
                                    )
                                } else {
                                    let maxIndex = try await ArticlesManager.shared.getMaxIndex()
                                    archivePosts.insert(
                                        PrePost(
                                            id: maxIndex ?? "",
                                            title: title,
                                            authorId: userId,
                                            viewsCount: 0,
                                            likesCount: 0,
                                            isArchive: true
                                        ),
                                        at: 0
                                    )
                                }
                                                                
                                StorageManager.shared.saveImage(id: id, image: image)
                                StorageManager.shared.deleteText()
                            } catch {
                                withAnimation {
                                    viewModel.isLoading = true
                                    viewModel.errorText = error.localizedDescription
                                    viewModel.isErrorPopupPresented = true
                                }
                                
                                return
                            }
                            
                            isCreateViewPresented = false
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
            .onAppear {
                withAnimation {
                    viewModel.navigationTitle = viewModel.getNavigationTitle(isEditing)
                }
                
                if isEditing {
                    viewModel.text = text
                } else {
                    viewModel.text = StorageManager.shared.getText()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                        StorageManager.shared.save(text: viewModel.text)
                    } label: {
                        Image(systemName: "arrow.left")
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
            .navigationTitle(viewModel.navigationTitle)
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


