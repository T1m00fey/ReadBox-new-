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
    let mediaCount: Int
    let mediaVersion: Int
    
    @Binding var user: DBUser?
    @Binding var isChannelViewPresented: Bool
    
    @State private var isSubscribed = false
    
    @StateObject var viewModel = ReadViewModel()
    
    @Environment(\.dismiss) var dismiss
    
    @Namespace var namespace
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemBackground)
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack {
                                                                        
                        if !text.isEmpty {
                            Text(title)
                                .fontWeight(.light)
                                .fontDesign(.rounded)
                                .font(.system(size: 24))
                                .frame(width: UIScreen.main.bounds.width - 32, alignment: .leading)
                            
                            RoundedRectangle(cornerRadius: 0)
                                .frame(width: UIScreen.main.bounds.width, height: 1)
                                .foregroundStyle(Color.gray)
                        }
                        
                        ZStack {
                            VisibilityTracker(id: "authorBlock")
                            
                            HStack {
                                Text("by")
                                    .font(.system(size: 20))
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
                                            .font(.system(size: 14))
                                            .padding(.top, 1)
                                    }
                                }
                            }
                            .frame(width: UIScreen.main.bounds.width - 32, alignment: .leading)
                            .padding(.bottom, 20)
                            .padding(.top, viewModel.images.count == 0 ? 10 : 0)
                        }
                       
//                        if viewModel.image != UIImage() {
//                            Image(uiImage: viewModel.image)
//                                .resizable()
//                                .scaledToFit()
//                                .frame(width: UIScreen.main.bounds.width - 20)
//                                .clipShape(RoundedRectangle(cornerRadius: 20))
//                                .padding(.horizontal)
//                                .onTapGesture {
//                                    viewModel.isImageFullscreenPresented = true
//                                }
//                        } else if let videoURL = viewModel.videoURL {
//                            TappableVideoPreview(url: videoURL, cornerRadius: 20, width: UIScreen.main.bounds.width - 20)
//                                .frame(width: UIScreen.main.bounds.width - 20)
//                        }
                        
                        if mediaCount > 0 {
                            MediaViews(
                                id: id,
                                authorId: authorId,
                                mediaCount: mediaCount,
                                mediaVersion: mediaVersion,
                                isArchive: isArchive,
                                zoomableImage: $viewModel.zoomableImage,
                                isZoomableViewPresented: $viewModel.isZoomableViewPresented,
                                currentIndex: $viewModel.currentIndex
                            )
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
                                            viewModel.vibrationsService.softImpact()
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
                                                viewModel.vibrationsService.softImpact()
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
                                if #available(iOS 26.0, *) {
                                    Image(systemName: viewModel.isPostLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                                        .scaleEffect(1.2)
                                        .frame(width: 50, height: 50)
                                        .glassEffect(.regular, in: .rect(cornerRadius: 20))
                                } else {
                                    Image(systemName: viewModel.isPostLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                                        .scaleEffect(1.2)
                                        .frame(width: 50, height: 50)
                                        .background(Color(uiColor: .secondarySystemBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .shadow(radius: 1)
                                }
                            }
                            
                            if authorId != "" && authorId != user?.userId {
                                ZStack {
                                    if #available(iOS 26.0, *) {
                                        if viewModel.isSubscribeLoading {
                                            LoadingIndicator(
                                                animation: .circleRunner,
                                                color: Color(.label),
                                                size: .small,
                                                speed: .fast
                                            )
                                            .padding(.vertical, 10)
                                            .frame(width: 130)
                                            .glassEffect(.regular, in: .rect(cornerRadius: 20))
                                        } else {
                                            Text(
                                                isSubscribed
                                                ? NSLocalizedString("youSubscribedLabel", comment: "")
                                                : NSLocalizedString("subscribeLabel", comment: "")
                                            )
                                            .font(.system(size: 14))
                                            .fontDesign(.rounded)
                                            .padding()
                                            .glassEffect(.regular, in: .rect(cornerRadius: 20))
                                        }
                                    } else {
                                        RoundedRectangle(cornerRadius: 10)
                                            .foregroundStyle(
                                                isSubscribed
                                                ? Color(uiColor: .secondarySystemBackground)
                                                : Color(uiColor: .label)
                                            )
                                            .shadow(radius: isSubscribed ? 1 : 0)
                                            .frame(width: 120)
                                        
                                        if viewModel.isSubscribeLoading {
                                            LoadingIndicator(
                                                animation: .circleRunner,
                                                color:  isSubscribed
                                                ? Color(uiColor: .label)
                                                : Color(uiColor: .systemBackground),
                                                size: .small,
                                                speed: .fast
                                            )
                                        } else {
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
                                    }
                                }
                                .onTapGesture {
                                    if !viewModel.isSubscribeLoading {
                                        Task {
                                            do {
                                                withAnimation {
                                                    viewModel.isSubscribeLoading = true
                                                }
                                                
                                                try await viewModel.un_subcribeUser(
                                                    on: authorId,
                                                    isNeedToSubscribe: !isSubscribed
                                                )
                                                
                                                withAnimation {
                                                    if isSubscribed {
                                                        user?.subscribes?.removeAll { $0 == authorId }
                                                        viewModel.vibrationsService.lightImpact()
                                                    } else {
                                                        user?.subscribes?.append(authorId)
                                                        viewModel.vibrationsService.successFeedback()
                                                    }
                                                                                                    
                                                    viewModel.isSubscribeLoading = false
                                                    isSubscribed.toggle()
                                                }
                                            } catch {
                                                withAnimation {
                                                    viewModel.isSubscribeLoading = false
                                                    viewModel.errorText = error.localizedDescription
                                                    viewModel.isErrorPopupPresented = true
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .frame(width: UIScreen.main.bounds.width - 32)
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                        
                        if text.isEmpty {
                            Text(title)
                                .fontDesign(.rounded)
                                .font(.system(size: 20))
                                .frame(width: UIScreen.main.bounds.width - 32, alignment: .leading)
                                .padding(.bottom, 50)
                        } else {
                            Markdown(
                                text.replacingOccurrences(of: "\n", with: "  \n").normalizeEmptyLines()
                            )
                            .markdownImageProvider(
                                WebImageProvider(onImageTap: { url in
                                    viewModel.selectedImageURL = url
                                    viewModel.isZoomableViewPresented = true
                                })
                            )
                            .markdownTextStyle(\.text) {
                                FontSize(CGFloat(viewModel.fontSize))
                            }
                            .markdownTheme(.gitHub)
                            .frame(width: UIScreen.main.bounds.width - 32, alignment: .topLeading)
                            .padding(.bottom, 50)                            
                        }
                    }
                    
                }
                .coordinateSpace(name: "readScroll")
                .fullScreenCover(isPresented: $viewModel.isZoomableViewPresented) {
                    if let image = viewModel.zoomableImage {
                        ZoomableImageView(image: image)
                    } else if let url = viewModel.selectedImageURL {
                        ZoomableImageView(imageURL: url)
                    }
                }
                .onPreferenceChange(VisibilityPreferenceKey.self) { values in
                    if let minY = values["authorBlock"] {
                        let isVisible = minY > -20

                        if viewModel.isAuthorBlockVisible != isVisible {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.isAuthorBlockVisible = isVisible
                            }
                        }
                    }
                }
                .onAppear {
                    withAnimation {
                        if let subscribes = user?.subscribes {
                            isSubscribed = subscribes.contains(authorId)
                        }
                
                        viewModel.isPostLiked = (user?.likedPosts ?? []).contains(id)
                    }
                    
                    viewModel.getAvatar(authorId)
                    
                    viewModel.likesCount = likesCount
                    
                    viewModel.fontSize = StorageManager.shared.getFontSize()
                }
                .onChange(of: viewModel.isZoomableViewPresented) {
                    if !viewModel.isZoomableViewPresented {
                        viewModel.selectedImageURL = nil
                    }
                }
                .popup(isPresented: $viewModel.isErrorPopupPresented) {
                    Text(viewModel.errorText)
                        .frame(width: UIScreen.main.bounds.width - 72, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .foregroundStyle(Color.white)
                        .background(Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                } customize: {
                    $0
                        .type(.floater())
                        .position(.top)
                        .animation(.bouncy)
                        .dragToDismiss(true)
                        .autohideIn(5)
                        .displayMode(.overlay)
                }
                .popup(isPresented: $viewModel.isFontSettingPopupPresented) {
                    FontSettingView(
                        isPopupPresented: $viewModel.isFontSettingPopupPresented,
                        successText: .constant(""),
                        isSuccessPopupPresented: .constant(false)
                    )
                    .shadow(radius: 2)
                } customize: {
                    $0
                        .type(.toast)
                        .appearFrom(.bottomSlide)
                        .dragToDismiss(true)
                        .displayMode(.sheet)
                }
                .onChange(of: viewModel.isFontSettingPopupPresented) {
                    withAnimation {
                        if !viewModel.isFontSettingPopupPresented {
                            viewModel.fontSize = StorageManager.shared.getFontSize()
                        }
                    }
                }
                .overlay(
                    EnableSwipeBack()
                        .frame(width: 0, height: 0)
                )
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "arrow.left")
                        }
                        
                    }
                    
                    ToolbarItem(placement: .principal) {
                        if let avatar = viewModel.avatarImage, !viewModel.isAuthorBlockVisible {
                            HStack(spacing: 0) {
                                Image(uiImage: avatar)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 35, height: 35)
                                    .clipShape(Circle())
                                    .overlay {
                                        Circle()
                                            .stroke(
                                                Color(.label),
                                                lineWidth: 0.1
                                            )
                                    }
                                
                                if isCheckmark {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundStyle(Color.blue)
                                        .font(.system(size: 10))
                                }
                            }
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        
                        if #available(iOS 26.0, *) {
                            HStack(spacing: 10) {
                                if text != "" {
                                    Button {
                                        viewModel.isFontSettingPopupPresented.toggle()
                                    } label: {
                                        Image(systemName: "book.pages")
                                    }
                                }
                                
                                if !isArchive {
                                    ShareLink(item: URL(string: "https://readbox-links.online/posts/?index=\(id)")!) {
                                        Image(systemName: "arrowshape.turn.up.right")
                                    }
                                }
                                
                            }
                        } else {
                            HStack {
                                if text != "" {
                                    Button {
                                        viewModel.isFontSettingPopupPresented.toggle()
                                    } label: {
                                        Image(systemName: "book.pages")
                                    }
                                }
                                
                                if !isArchive {
                                    ShareLink(item: URL(string: "https://readbox-links.online/posts/?index=\(id)")!) {
                                        Image(systemName: "arrowshape.turn.up.right")
                                    }
                                }
                                
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




