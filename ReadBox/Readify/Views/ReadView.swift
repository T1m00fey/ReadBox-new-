//
//  TestReadView.swift
//  Readify
//
//  Created by Тимофей Юдин on 17.12.2024.
//

import SwiftUI
import MarkdownUI
import FirebaseStorage

final class ReadViewModel: ObservableObject {
    @Published var isPostLiked = false
    @Published var errorText = ""
    @Published var isErrorPopupPresented = false
    @Published var likesCount = 0
    @Published var fontSize = 0
    @Published var isFontSettingPopupPresented = false
    @Published var contentHeight: CGFloat = 0
    @Published var markdownText = """
                                    """
    @Published var image = UIImage()
    
//    func plusReadArticle(userId: String, articlesRead: Int) async throws {
//        try await UserManager.shared.plusReadArticle(userId: userId, articlesRead: articlesRead)
//    }
    
    func addLikedPost(userId: String, articleId: String) async throws {
        try await UserManager.shared.addLikedPost(id: userId, likedPost: articleId)
    }
    
    func removeLikedPost(userId: String, articleId: String) async throws {
        try await UserManager.shared.removeLikedPost(id: userId, likedPost: articleId)
    }
    
    func updateLikes(at article: String, likesCount: Int) async throws {
        try await ArticlesManager.shared.updateLikes(at: article, likesCount: likesCount)
    }
    
//    func getMarkdownText(_ text: String) -> NSAttributedString {
//        let preMarkdown = text.replacingOccurrences(of: "/n", with: "\n")
//        
//        let markdownString = SwiftyMarkdown(string: preMarkdown)
//        markdownString.bold.fontSize = CGFloat(fontSize)
//        markdownString.body.fontSize = CGFloat(fontSize)
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
//        return markdownString.attributedString()
//    }
    
    func getDateCreated(regDate: Date) -> String {
        let timeInterval = Int(Date().timeIntervalSince(regDate)) / 60 / 60 / 24
        var date = ""
        
        if StorageManager.shared.getLanguage() == "ru" {
            if timeInterval > 30 && timeInterval < 365 {
                if timeInterval / 30 == 1 {
                    date = "\(timeInterval / 30) месяц назад"
                } else if (2...4).contains(timeInterval / 30) {
                    date = "\(timeInterval / 30) месяца назад"
                } else {
                    date = "\(timeInterval / 30) месяцев назад"
                }
            } else if timeInterval >= 365 {
                if (11...14).contains(timeInterval / 365) {
                    date = "\(timeInterval / 365) лет назад"
                } else if timeInterval / 365 % 10 == 1 {
                    date = "\(timeInterval / 365) год назад"
                } else if timeInterval / 365 % 10 == 2 || timeInterval / 365 % 10 == 4 || timeInterval / 365 % 10 == 3 {
                    date = "\(timeInterval) года назад"
                } else {
                    date = "\(timeInterval) лет назад"
                }
            } else {
                if timeInterval == 11 || timeInterval == 12 || timeInterval == 13 || timeInterval == 14 {
                    date = "\(timeInterval) дней назад"
                } else if timeInterval % 10 == 1 {
                    date = "\(timeInterval) день назад"
                } else if timeInterval % 10 == 2 || timeInterval % 10 == 4 || timeInterval % 10 == 3 {
                    date = "\(timeInterval) дня назад"
                } else if timeInterval == 0 {
                    date = "Сегодня"
                } else {
                    date = "\(timeInterval) дней назад"
                }
            }
            
        } else {
            if timeInterval > 30 && timeInterval < 365 {
                if timeInterval / 30 == 1 {
                    date = "\(timeInterval / 30) month ago"
                } else {
                    date = "\(timeInterval / 30) months ago"
                }
            } else if timeInterval >= 365 {
                if timeInterval / 365 == 1 {
                    date = "\(timeInterval / 365) year ago"
                } else {
                    date = "\(timeInterval / 365) years ago"
                }
            } else {
                if timeInterval == 1 {
                    date = "\(timeInterval) day ago"
                } else if timeInterval == 0 {
                    date = "Today"
                } else {
                    date = "\(timeInterval) days ago"
                }
            }
        }
        
        return date
    }
}

struct ReadView: View {
    let id: String
    let userId: String
    let title: String
    let text: String
    let dateCreated: Date
    let likesCount: Int
    let authorName: String
    let isCheckmark: Bool
    
    @Binding var likedPosts: [String]
    @Binding var isChannelViewPresented: Bool
    
    @StateObject var viewModel = ReadViewModel()

    @Environment(\.dismiss) var dismiss
    
    private func fetchImage() {
        let articleImage = StorageManager.shared.getImage(id: id)
        
        if articleImage != nil {
            withAnimation {
                viewModel.image = articleImage ?? UIImage()
            }
        } else {
            DispatchQueue.main.async {
                let storage = Storage.storage()
                let storageRef = storage.reference()
                
                let islandRef = storageRef.child("images/\(id).jpg")
                
                islandRef.getData(maxSize: 1 * 5012 * 50125) { data, error in
                    if let error = error {
                        print(error .localizedDescription)
                    } else {
                        // Data for "images/island.jpg" is returned
                        withAnimation {
                            self.viewModel.image = UIImage(data: data!)!
                            StorageManager.shared.saveImage(id: id, image: viewModel.image)
                        }
                    }
                }
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .secondarySystemBackground)
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    
                    VStack {
                        
                        Text(title)
                            .fontWeight(.light)
                            .fontDesign(.rounded)
                            .font(.largeTitle)
                            .frame(width: UIScreen.main.bounds.width - 32, alignment: .leading)
                        
                        RoundedRectangle(cornerRadius: 0)
                            .frame(width: UIScreen.main.bounds.width, height: 1)
                            .foregroundStyle(Color.gray)
                        
                        HStack {
                            Text("by")
                                .font(.title3)
                                .fontDesign(.rounded)
                                .foregroundStyle(Color.gray)
                            
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
                                        .font(.title2)
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
                        }
                    
                        HStack {
                            Text(viewModel.getDateCreated(regDate: dateCreated))
                                .font(.title2)
                                .fontWeight(.light)
                                .fontDesign(.rounded)
                                .foregroundStyle(Color.gray)
                            
                            Spacer()
                            
                            Button {
                                if viewModel.isPostLiked {
                                    withAnimation {
                                        viewModel.isPostLiked.toggle()
                                    }
                                    
                                    likedPosts.removeAll {
                                        id == $0
                                    
                                    }
                                    
                                    viewModel.likesCount -= 1
                                    
                                    Task {
                                        do {
                                            try await viewModel.removeLikedPost(userId: userId, articleId: id)
                                            
                                            if id != "" {
                                                try await viewModel.updateLikes(at: id, likesCount: viewModel.likesCount)
                                            }
                                            
                                            return
                                        } catch {
                                            withAnimation {
                                                viewModel.errorText = error.localizedDescription
                                            }
                                        }
                                        
                                        viewModel.isErrorPopupPresented = true
                                    }
                                } else {
                                    if id != "" {
                                        withAnimation {
                                            viewModel.isPostLiked.toggle()
                                        }
                                        
                                        viewModel.likesCount += 1
                                        
                                        likedPosts.append(id)
                                        
                                        Task {
                                            do {
                                                try await viewModel.addLikedPost(userId: userId, articleId: id)
                                                try await viewModel.updateLikes(at: id, likesCount: viewModel.likesCount)
                                                
                                                return
                                            } catch {
                                                withAnimation {
                                                    viewModel.errorText = error.localizedDescription
                                                }
                                            }
                                            
                                            viewModel.isErrorPopupPresented = true
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
                        }
                        .frame(width: UIScreen.main.bounds.width - 32)
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                        
                        Markdown(text.replacingOccurrences(of: "<br>#", with: "\n#").replacingOccurrences(of: "#<br>", with: "\n"))
                            .markdownTextStyle(\.text) {
                                FontSize(CGFloat(viewModel.fontSize))
                            }
                            .markdownTheme(.gitHub)
                            .frame(width: UIScreen.main.bounds.width - 32, alignment: .topLeading)
                            .padding(.bottom, 50)
    
                    }
                    
                }
                .onAppear {
                    withAnimation {
                        viewModel.isPostLiked = likedPosts.contains(id)
                        fetchImage()
                    }
                    
                    viewModel.likesCount = likesCount
                    
                    viewModel.fontSize = StorageManager.shared.getFontSize()
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
                .onChange(of: viewModel.isFontSettingPopupPresented) { newValue in
                    withAnimation {
                        if !newValue {
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
                            
                            ShareLink(item: URL(string: "readbox://posts/\(id)")!) {
                                Image(systemName: "square.and.arrow.up")
                            }
                            
                        }
                        
                    }
                }
                .background(Color(uiColor: .secondarySystemBackground))
                
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


#Preview {
    ReadView(id: "10", userId: "", title: "", text: "ksdkdnksndkskdnnsksdfd", dateCreated: Date(), likesCount: 0, authorName: "test", isCheckmark: false, likedPosts: .constant([]), isChannelViewPresented: .constant(false))
}


