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
import FirebaseStorage

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
    let mediaPosition: Int
    let lastVersionOfAvatar: Int
    let isLocalizedVersion: Bool
    let rootId: String
    let originalPrePost: PrePost?
    
    @Binding var user: DBUser?
    @Binding var isChannelViewPresented: Bool
    @Binding var isPresented: Bool
    
    @State private var isSubscribed = false
    @State private var currentPrePost: PrePost? = nil
    @State private var currentPostToRead: PostToRead? = nil
    
    @StateObject var viewModel = ReadViewModel()
    
    @Namespace var namespace
    
    @EnvironmentObject var sessionManager: SessionManager
    
    init(
        id: String,
        title: String,
        text: String,
        dateCreated: Date,
        likesCount: Int,
        authorId: String,
        authorName: String,
        isCheckmark: Bool,
        isArchive: Bool,
        mediaCount: Int,
        mediaVersion: Int,
        mediaPosition: Int,
        lastVersionOfAvatar: Int,
        user: Binding<DBUser?>,
        isChannelViewPresented: Binding<Bool>,
        isPresented: Binding<Bool>,
        isLocalizedVersion: Bool = false,
        rootId: String = "",
        originalPrePost: PrePost? = nil
    ) {
        self.id = id
        self.title = title
        self.text = text
        self.dateCreated = dateCreated
        self.likesCount = likesCount
        self.authorId = authorId
        self.authorName = authorName
        self.isCheckmark = isCheckmark
        self.isArchive = isArchive
        self.mediaCount = mediaCount
        self.mediaVersion = mediaVersion
        self.mediaPosition = mediaPosition
        self.lastVersionOfAvatar = lastVersionOfAvatar
        self._user = user
        self._isChannelViewPresented = isChannelViewPresented
        self._isPresented = isPresented
        self.isLocalizedVersion = isLocalizedVersion
        self.rootId = rootId
        self.originalPrePost = originalPrePost
    }
    
    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack {
                                                                    
                    if !currentText.isEmpty {
                        Text(currentTitle)
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
//                            Text("by")
//                                .font(.system(size: 20))
//                                .fontDesign(.rounded)
//                                .foregroundStyle(Color.gray)
                            
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
                                            
                                            isPresented = false
                                        }
                                    }
                                } label: {
                                    Text(authorName == "" ? NSLocalizedString("notFoundLabel", comment: "") : authorName)
                                        .font(.system(size: 19))
                                        .multilineTextAlignment(.leading)
                                        .lineLimit(2)
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
                        .padding(.bottom, 5)
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
                    
                    if currentMediaPosition == 0 && currentMediaCount > 0 {
                        mediaViews
                    } else if currentMediaPosition == 1 && !currentTitle.isEmpty {
                        titleView
                            .padding(.top, 10)
//                            .padding(.bottom, -20)
                    }
                
                    HStack {
                        Text(viewModel.getDateCreated(regDate: currentDateCreated))
                            .font(.system(size: 21))
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
                                    currentId == $0
                                
                                }
                                
                                viewModel.likesCount -= 1
                                
                                Task {
                                    do {
                                        viewModel.vibrationsService.lightImpact()
                                        try await viewModel.removeLikedPost(userId: user?.userId ?? "", articleId: currentId)
                                    } catch {
                                        withAnimation {
                                            viewModel.errorText = error.localizedDescription
                                            viewModel.isErrorPopupPresented = true
                                        }
                                    }
                                    
                                    try? await viewModel.updateLikes(at: currentId, likesCount: viewModel.likesCount)
                                }
                            } else {
                                if currentId != "" {
                                    withAnimation {
                                        viewModel.isPostLiked.toggle()
                                    }
                                    
                                    viewModel.likesCount += 1
                                    
                                    user?.likedPosts?.append(currentId)
                                    
                                    Task {
                                        do {
                                            viewModel.vibrationsService.lightImpact()
                                            try await viewModel.addLikedPost(userId: user?.userId ?? "", articleId: currentId)
                                        } catch {
                                            withAnimation {
                                                viewModel.errorText = error.localizedDescription
                                                viewModel.isErrorPopupPresented = true
                                            }
                                        }
                                        
                                        try? await viewModel.updateLikes(at: currentId, likesCount: viewModel.likesCount)
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
                    
                    if !currentText.isEmpty {
                        Markdown(
                            currentText.replacingOccurrences(of: "\n", with: "  \n").normalizeEmptyLines()
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
                    } else if currentMediaPosition == 0 && currentTitle != "" {
                        titleView
                            .padding(.bottom, 50)
                            .padding(.top, -15)
                    } else if currentMediaPosition == 1 {
                        mediaViews
                            .padding(.top, -15)
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
            
                    viewModel.isPostLiked = (user?.likedPosts ?? []).contains(currentId)
                }
                
                viewModel.likesCount = currentLikesCount
                
                viewModel.fontSize = StorageManager.shared.getFontSize()
            }
            .task {
                let ava = await MediaManager.shared.getAvatar(authorId: authorId, lastVersion: lastVersionOfAvatar)
                withAnimation {
                    viewModel.avatarImage = ava
                }
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
            .sheet(isPresented: $viewModel.isFontSettingPopupPresented, content: {
                FontSettingView(
                    isPopupPresented: $viewModel.isFontSettingPopupPresented,
                    successText: .constant(""),
                    isSuccessPopupPresented: .constant(false)
                )
                .presentationDetents([.height(300)])
                .presentationCornerRadius(30)
                .presentationDragIndicator(.visible)
            })
            .onChange(of: viewModel.isFontSettingPopupPresented) {
                withAnimation {
                    if !viewModel.isFontSettingPopupPresented {
                        viewModel.fontSize = StorageManager.shared.getFontSize()
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "arrow.left")
                    }
                    
                }
                
                ToolbarItem(placement: .principal) {
                    if !viewModel.isAuthorBlockVisible {
                        if #available(iOS 26, *) {
                            principalToolView
                                .padding(.all, 10)
                                .glassEffect(.regular)
                        } else {
                            principalToolView
                        }
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    if hasExtraToolbarActions {
                        Menu {
                            if currentText != "" {
                                Button {
                                    viewModel.isFontSettingPopupPresented.toggle()
                                } label: {
                                    Label(
                                        StorageManager.shared.getLanguage() == "ru" ? "Шрифт" : "Font",
                                        systemImage: "book.pages"
                                    )
                                }
                            }
                            
                            if currentIsLocalizedVersion && !currentRootId.isEmpty {
                                originalArticleMenuButton
                            }
                            
                            if !currentIsArchive {
                                ShareLink(item: URL(string: "https://readbox-links.online/posts/?index=\(currentId)")!) {
                                    Label(
                                        StorageManager.shared.getLanguage() == "ru" ? "Поделиться" : "Share",
                                        systemImage: "arrowshape.turn.up.right"
                                    )
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    } else if !currentIsArchive {
                        ShareLink(item: URL(string: "https://readbox-links.online/posts/?index=\(currentId)")!) {
                            Image(systemName: "arrowshape.turn.up.right")
                        }
                    }
                }
            }
            .background(Color(uiColor: .systemBackground))
            
        }
        .navigationBarBackButtonHidden()
        .overlay(
            EnableSwipeBack()
                .frame(width: 0, height: 0)
        )
    }
}

private extension ReadView {
    var mediaViews: some View {
        MediaViews(
            id: currentId,
            authorId: authorId,
            mediaCount: currentMediaCount,
            mediaVersion: currentMediaVersion,
            zoomableImage: $viewModel.zoomableImage,
            isZoomableViewPresented: $viewModel.isZoomableViewPresented,
            currentIndex: $viewModel.currentIndex
        )
        .id(currentId)
    }
    
    var titleView: some View {
        Text(currentTitle)
            .font(.system(size: 18))
            .fontDesign(.rounded)
            .frame(width: UIScreen.main.bounds.width - 32, alignment: .leading)
    }
    
    var currentId: String {
        currentPrePost?.id ?? id
    }
    
    var currentTitle: String {
        currentPrePost?.title ?? title
    }
    
    var currentText: String {
        currentPostToRead?.text ?? text
    }
    
    var currentDateCreated: Date {
        currentPostToRead?.dateCreated ?? dateCreated
    }
    
    var currentLikesCount: Int {
        currentPrePost?.likesCount ?? likesCount
    }
    
    var currentIsArchive: Bool {
        currentPrePost?.isArchive ?? isArchive
    }
    
    var currentMediaCount: Int {
        currentPrePost?.mediaCount ?? mediaCount
    }
    
    var currentMediaVersion: Int {
        currentPrePost?.mediaVersion ?? mediaVersion
    }
    
    var currentMediaPosition: Int {
        currentPrePost?.mediaPosition ?? mediaPosition
    }
    
    var currentIsLocalizedVersion: Bool {
        currentPrePost?.isLocalizedVersion ?? isLocalizedVersion
    }
    
    var currentRootId: String {
        currentPrePost?.rootId ?? rootId
    }
    
    var canSwitchArticleLanguage: Bool {
        isLocalizedVersion && !rootId.isEmpty
    }
    
    var isShowingOriginalArticle: Bool {
        currentPrePost != nil
    }
    
    var hasExtraToolbarActions: Bool {
        currentText != "" || canSwitchArticleLanguage
    }
    
    @ViewBuilder
    var originalArticleButton: some View {
        if viewModel.isOriginalArticleLoading {
            LoadingIndicator(
                animation: .circleRunner,
                color: Color(uiColor: .label),
                size: .small,
                speed: .fast
            )
        } else {
            Button {
                toggleArticleLanguage()
            } label: {
                Image("switchLanguageIcon")
            }
        }
    }
    
    @ViewBuilder
    var originalArticleMenuButton: some View {
        if viewModel.isOriginalArticleLoading {
            HStack {
                Image("switchLanguageIcon")
                Text(StorageManager.shared.getLanguage() == "ru" ? "Загрузка..." : "Loading...")
            }
        } else {
            Button {
                toggleArticleLanguage()
            } label: {
                HStack {
                    Image("switchLanguageIcon")
                    Text(languageSwitchButtonTitle)
                }
            }
        }
    }
    
    var languageSwitchButtonTitle: String {
        if StorageManager.shared.getLanguage() == "ru" {
            return isShowingOriginalArticle ? "Перевод" : "Оригинал"
        }
        
        return isShowingOriginalArticle ? "Translation" : "Original"
    }
    
    func toggleArticleLanguage() {
        if isShowingOriginalArticle {
            withAnimation {
                currentPrePost = nil
                currentPostToRead = nil
                viewModel.likesCount = likesCount
                viewModel.isPostLiked = (user?.likedPosts ?? []).contains(id)
                viewModel.currentIndex = 0
                viewModel.selectedImageURL = nil
            }
            return
        }
        
        showOriginalArticle()
    }
    
    func showOriginalArticle() {
        guard !currentRootId.isEmpty, !viewModel.isOriginalArticleLoading else { return }
        
        Task {
            do {
                await MainActor.run {
                    withAnimation {
                        viewModel.isOriginalArticleLoading = true
                    }
                }
                
                let loadedOriginalPrePost: PrePost
                
                if let originalPrePostFromChannel = self.originalPrePost {
                    loadedOriginalPrePost = originalPrePostFromChannel
                } else {
                    loadedOriginalPrePost = try await ArticlesManager.shared.getPrePost(id: currentRootId)
                }
                
                let originalPostToRead = try await ArticlesManager.shared.getPostToRead(id: currentRootId)
                
                await MainActor.run {
                    withAnimation {
                        currentPrePost = loadedOriginalPrePost
                        currentPostToRead = originalPostToRead
                        viewModel.likesCount = loadedOriginalPrePost.likesCount ?? 0
                        viewModel.isPostLiked = (user?.likedPosts ?? []).contains(loadedOriginalPrePost.id)
                        viewModel.currentIndex = 0
                        viewModel.selectedImageURL = nil
                        viewModel.isOriginalArticleLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    withAnimation {
                        viewModel.isOriginalArticleLoading = false
                        viewModel.errorText = error.localizedDescription
                        viewModel.isErrorPopupPresented = true
                    }
                }
            }
        }
    }
}

private extension ReadView {
    var principalToolView: some View {
        HStack(spacing: 0) {
            if let avatar = viewModel.avatarImage {
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
                    .padding(.trailing, authorName == "" ? 0 : 2)
            }
            
            if authorName != "" {
                Text(authorName)
                    .font(.system(size: 17))
            }
            
            
            if isCheckmark {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(Color.blue)
                    .font(.system(size: 10))
            }
        }
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
