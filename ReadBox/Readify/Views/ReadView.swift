//
//  TestReadView.swift
//  Readify
//
//  Created by Тимофей Юдин on 17.12.2024.
//

import SwiftUI
import PopupView
import MarkdownUI
import SwiftfulLoadingIndicators
import SDWebImageSwiftUI

struct ReadView: View {
    
    let id: String
    let title: String
    let text: String
    let dateCreated: Date
    let likesCount: Int
    let authorId: String
    let authorName: String
    let isCheckmark: Bool
    let isArchive: Bool
    
    @Binding var user: DBUser?
    @Binding var isChannelViewPresented: Bool
    
    @State private var isSubscribed = false
    
    @StateObject var viewModel = ReadViewModel()
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemBackground)
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    
                    VStack {
                        
                        Text(title)
                            .fontWeight(.light)
                            .fontDesign(.rounded)
                            .font(.system(size: 26))
                            .frame(width: UIScreen.main.bounds.width - 32, alignment: .leading)
                        
                        RoundedRectangle(cornerRadius: 0)
                            .frame(width: UIScreen.main.bounds.width, height: 1)
                            .foregroundStyle(Color.gray)
                        
                        HStack {
                            Text("by")
                                .font(.system(size: 21))
                                .fontDesign(.rounded)
                                .foregroundStyle(Color.gray)
                            
                            if let avatar = viewModel.avatarImage {
                                Image(uiImage: avatar)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                                    .overlay {
                                        Circle()
                                            .stroke(
                                                Color(.label),
                                                lineWidth: 0.1
                                            )
                                    }
                            }
                            
                            HStack(spacing: 0) {
                                Button {
                                    withAnimation {
                                        if authorName != "" {
                                            isChannelViewPresented = true
                                            
                                            dismiss()
                                        }
                                    }
                                } label: {
                                    Text(authorName == "" ? NSLocalizedString("notFoundLabel", comment: "") : authorName)
                                        .font(.system(size: 21))
                                        .multilineTextAlignment(.leading)
                                        .lineLimit(2)
                                        .fontDesign(.rounded)
                                        .underline()
                                }
                                
                                if isCheckmark {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundStyle(Color.blue)
                                        .font(.subheadline)
                                        .padding(.top, 4)
                                }
                            }
                        }
                        .frame(width: UIScreen.main.bounds.width - 32, alignment: .leading)
                        .padding(.vertical, viewModel.image != UIImage() ? 20 : 0)
                        .padding(.top, viewModel.image == UIImage() ? 10 : 0)
                        
                        if viewModel.image != UIImage() {
                            Image(uiImage: viewModel.image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: UIScreen.main.bounds.width - 20)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .padding(.horizontal)
                        } else if let videoURL = viewModel.videoURL {
                            TappableVideoPreview(url: videoURL, cornerRadius: 10, width: UIScreen.main.bounds.width - 20)
                                .frame(width: UIScreen.main.bounds.width - 20)
                        }
                    
                        HStack {
                            Text(viewModel.getDateCreated(regDate: dateCreated))
                                .font(.system(size: 22))
                                .fontWeight(.light)
                                .fontDesign(.rounded)
                                .foregroundStyle(Color.gray)
                            
                            Spacer()
                            
                            Button {
                                if viewModel.isPostLiked {
                                    withAnimation {
                                        viewModel.isPostLiked.toggle()
                                    }
                                    
                                    user?.likedPosts?.removeAll {
                                        id == $0
                                    
                                    }
                                    
                                    viewModel.likesCount -= 1
                                    
                                    Task {
                                        do {
                                            try await viewModel.removeLikedPost(userId: user?.userId ?? "", articleId: id)
                                        } catch {
                                            withAnimation {
                                                viewModel.errorText = error.localizedDescription
                                                viewModel.isErrorPopupPresented = true
                                            }
                                        }
                                        
                                        try? await viewModel.updateLikes(at: id, likesCount: viewModel.likesCount)
                                    }
                                } else {
                                    if id != "" {
                                        withAnimation {
                                            viewModel.isPostLiked.toggle()
                                        }
                                        
                                        viewModel.likesCount += 1
                                        
                                        user?.likedPosts?.append(id)
                                        
                                        Task {
                                            do {
                                                try await viewModel.addLikedPost(userId: user?.userId ?? "", articleId: id)
                                            } catch {
                                                withAnimation {
                                                    viewModel.errorText = error.localizedDescription
                                                    viewModel.isErrorPopupPresented = true
                                                }
                                            }
                                            
                                            try? await viewModel.updateLikes(at: id, likesCount: viewModel.likesCount)
                                        }
                                    } else {
                                        withAnimation {
                                            viewModel.errorText = NSLocalizedString("addPostToFavoritesLabel", comment: "")
                                            viewModel.isErrorPopupPresented = true
                                        }
                                    }
                                }
                            } label: {
                                Image(systemName: viewModel.isPostLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                                    .scaleEffect(1.2)
                                    .frame(width: 50, height: 50)
                                    .background(Color(uiColor: .systemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .shadow(radius: 2)
                            }
                            
                            if authorId != "" && authorId != user?.userId {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .foregroundStyle(
                                            isSubscribed
                                            ? Color(uiColor: .systemBackground)
                                            : Color(uiColor: .label)
                                        )
                                        .shadow(radius: isSubscribed ? 2 : 0)
                                        .frame(width: 120)
                                    
                                    Text(
                                        isSubscribed
                                        ? NSLocalizedString("youSubscribedLabel", comment: "")
                                        : NSLocalizedString("subscribeLabel", comment: "")
                                    )
                                    .font(.system(size: 14))
                                    .fontDesign(.rounded)
                                    .foregroundStyle(
                                        isSubscribed
                                        ? Color(uiColor: .label)
                                        : Color(uiColor: .systemBackground)
                                    )
                                }
                                .onTapGesture {
                                    Task {
                                        do {
                                            try await viewModel.un_subcribeUser(
                                                on: authorId,
                                                isNeedToSubscribe: !isSubscribed
                                            )
                                            
                                            withAnimation {
                                                if isSubscribed {
                                                    user?.subscribes?.removeAll { $0 == authorId }
                                                } else {
                                                    user?.subscribes?.append(authorId)
                                                }
                                                
                                                isSubscribed.toggle()
                                            }
                                        } catch {
                                            withAnimation {
                                                viewModel.errorText = error.localizedDescription
                                                viewModel.isErrorPopupPresented = true
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .frame(width: UIScreen.main.bounds.width - 32)
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                        
                        Markdown(
                            text.replacingOccurrences(of: "\n", with: "  \n").normalizeEmptyLines()
                        )
                        .markdownImageProvider(
                            WebImageProvider(onImageTap: { url in
                                viewModel.selectedImageURL = url
                                viewModel.isImageFullscreenPresented = true
                            })
                        )
                        .markdownTextStyle(\.text) {
                            FontSize(CGFloat(viewModel.fontSize))
                        }
                        .markdownTheme(.gitHub)
                        .frame(width: UIScreen.main.bounds.width - 32, alignment: .topLeading)
                        .padding(.bottom, 50)
                        .onDisappear {
                            NotificationCenter.default.post(name: .stopAllVideoPlayback, object: nil)
                        }
                    }
                    
                }
                .onAppear {
                    withAnimation {
                        if let subscribes = user?.subscribes {
                            isSubscribed = subscribes.contains(authorId)
                        }
                
                        viewModel.isPostLiked = (user?.likedPosts ?? []).contains(id)
                        viewModel.fetchImage(byId: id)
                    }
                    
                    viewModel.getAvatar(authorId)
                    
                    viewModel.likesCount = likesCount
                    
                    viewModel.fontSize = StorageManager.shared.getFontSize()
                }
                .fullScreenCover(isPresented: $viewModel.isImageFullscreenPresented) {
                    if let url = viewModel.selectedImageURL {
                        ZoomableImageView(imageURL: url)
                    }
                }
                .popup(isPresented: $viewModel.isErrorPopupPresented) {
                    Text(viewModel.errorText)
                        .frame(width: UIScreen.main.bounds.width - 72, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .foregroundStyle(Color.white)
                        .background(Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } customize: {
                    $0
                        .type(.floater())
                        .position(.top)
                        .animation(.bouncy)
                        .dragToDismiss(true)
                        .autohideIn(5)
                }
                .popup(isPresented: $viewModel.isFontSettingPopupPresented) {
                    FontSettingView(
                        isPopupPresented: $viewModel.isFontSettingPopupPresented,
                        successText: .constant(""),
                        isSuccessPopupPresented: .constant(false)
                    )
                    .shadow(radius: 3)
                } customize: {
                    $0
                        .type(.toast)
                        .appearFrom(.bottomSlide)
                        .dragToDismiss(true)
                }
                .onChange(of: viewModel.isFontSettingPopupPresented) {
                    withAnimation {
                        if !viewModel.isFontSettingPopupPresented {
                            viewModel.fontSize = StorageManager.shared.getFontSize()
                        }
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                        }
                        
                    }
                    
                    ToolbarItem(placement: .topBarLeading) {
                        
                        HStack {
                            Button {
                                viewModel.isFontSettingPopupPresented.toggle()
                            } label: {
                                Image(systemName: "book.pages")
                            }
                            
                            if !isArchive {
                                ShareLink(item: URL(string: "https://readbox-links.online/posts/?index=\(id)")!) {
                                    Image(systemName: "square.and.arrow.up")
                                }
                                .padding(.bottom, 1)
                            }
                            
                        }
                        
                    }
                }
                .background(Color(uiColor: .systemBackground))
                
            }
        }
        .navigationBarBackButtonHidden()
    }
}

//class TextViewDelegate: NSObject, UITextViewDelegate {
//    var didChangeHeight: ((CGFloat) -> Void)?
//
//    func textViewDidChange(_ textView: UITextView) {
//        // Отправляем высоту контента
//        let height = textView.contentSize.height
//        didChangeHeight?(height)
//    }
//}
//
//
//struct MarkdownText: UIViewRepresentable {
//    @Binding var contentHeight: CGFloat
//    @Binding var fontSize: Int
//    let markdownText: String
//
//    // Создаем UITextView для отображения Markdown текста
//    func makeUIView(context: Context) -> UITextView {
//        let textView = UITextView()
//        textView.isEditable = false
//        textView.isSelectable = false
//        textView.backgroundColor = .clear
//        textView.delegate = context.coordinator // Связываем делегата
//        textView.isScrollEnabled = true
//        textView.textContainer.lineBreakMode = .byWordWrapping // Разрывы строк по словам
//        textView.textContainerInset = .zero // Убираем отступы
//        textView.layoutManager.allowsNonContiguousLayout = false
//        textView.translatesAutoresizingMaskIntoConstraints = false
//        textView.font = .systemFont(ofSize: CGFloat(fontSize))
//        return textView
//    }
//
//    // Обновляем UI с атрибутированным текстом
//    func updateUIView(_ uiView: UITextView, context: Context) {
//        let markdownString = SwiftyMarkdown(string: markdownText)
//        
//        markdownString.bold.fontSize = CGFloat(fontSize)
//        markdownString.body.fontSize = CGFloat(fontSize)
//        markdownString.body.fontStyle = .bold
//        markdownString.blockquotes.fontSize = CGFloat(fontSize)
//        markdownString.italic.fontSize = CGFloat(fontSize)
//        markdownString.code.fontSize = CGFloat(fontSize)
//        markdownString.strikethrough.fontSize = CGFloat(fontSize)
//        markdownString.link.fontSize = CGFloat(fontSize)
//        markdownString.h1.fontSize = CGFloat(fontSize)
//        markdownString.h2.fontSize = CGFloat(fontSize)
//        markdownString.h3.fontSize = CGFloat(fontSize)
//        markdownString.h4.fontSize = CGFloat(fontSize)
//        markdownString.h5.fontSize = CGFloat(fontSize)
//        markdownString.h6.fontSize = CGFloat(fontSize)
//        
//        
//        UIView.transition(with: uiView, duration: 0.3, options: .curveEaseIn, animations: {
//            uiView.attributedText = markdownString.attributedString()
//        }, completion: nil)
//        
//        uiView.sizeToFit()
//        
//        DispatchQueue.main.async {
//            self.contentHeight = uiView.contentSize.height // Обновляем высоту
//        }
//    }
//    
//    func makeCoordinator() -> TextViewDelegate {
//        let coordinator = TextViewDelegate()
//        coordinator.didChangeHeight = { height in
//            self.contentHeight = height // Обновляем высоту
//        }
//        
//        return coordinator
//    }
//}




