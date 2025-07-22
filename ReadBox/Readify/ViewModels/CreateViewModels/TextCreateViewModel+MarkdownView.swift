//
//  TextCreateViewModel.swift
//  ReadBox
//
//  Created by Тимофей Юдин on 24.05.2025.
//

import SwiftUI
import _PhotosUI_SwiftUI

@MainActor
struct MarkdownTextView: UIViewRepresentable {
    @Binding var text: String
    @Binding var selectedRange: NSRange

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.delegate = context.coordinator
        textView.isEditable = true
        textView.isScrollEnabled = true
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        // Обновляем текст, если он изменился
        if uiView.text != text {
            uiView.text = text
        }
        // Обновляем выделение курсора асинхронно, чтобы избежать ошибки "Modifying state during view update"
        DispatchQueue.main.async {
            if uiView.selectedRange != self.selectedRange {
                uiView.selectedRange = self.selectedRange
            }
        }
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: MarkdownTextView

        init(_ parent: MarkdownTextView) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            DispatchQueue.main.async {
                self.parent.text = textView.text
            }
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            DispatchQueue.main.async {
                self.parent.selectedRange = textView.selectedRange
            }
        }
    }
}

// MARK: - Типы markdown-форматирования

enum MarkdownType {
    case bold
    case italic
    case header(level: Int)
    case code
    case strikethrough
    case blockquote
    case unorderedList
    case orderedList
    case link
}


final class TextCreateViewModel: ObservableObject {
    @Published var text = ""
    @Published var isPreviewShowed = false
    @Published var selectedRange: NSRange = NSRange(location: 0, length: 0)
    @Published var isPreviewPresented = false
    @Published var isConfirmationViewPresented = false
    @Published var navigationTitle = ""
    @Published var addingMode = 0
    @Published var isErrorPopupPresented = false
    @Published var errorText = ""
    @Published var isErrorPopup = false
    @Published var heightOfTE: CGFloat = UIScreen.main.bounds.height - 300
    @Published var isLoading = false
    @Published var imageItem: PhotosPickerItem? = nil
    @Published var isImageUploading = false
    @Published var isMediaControlViewPresented = false
    @Published var mediaURLs: [URL] = []
    
    @Published var markdownButtons: [(title: String, type: MarkdownType)] = [
        ("B", .bold),
        ("I", .italic),
        (NSLocalizedString("quoteLabel", comment: ""), .blockquote),
        (NSLocalizedString("strikeThroughLabel", comment: ""), .strikethrough),
        (NSLocalizedString("codeLabel", comment: ""), .code),
        (NSLocalizedString("linkLabel", comment: ""), .link)
    ]
    
    func configureMarkdownButton(title: String, type: MarkdownType) -> some View {
        Button(title) {
            self.toggleMarkdown(type: type)
        }
        .font(.system(size: 22))
        .fontDesign(.rounded)
        .bold()
        .frame(height: 40)
        .padding(.horizontal)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(radius: 2)
    }
    
    func toggleMarkdown(type: MarkdownType) {
        guard let swiftRange = Range(selectedRange, in: text) else { return }
        
        switch type {
        // Жирный: оборачиваем текст в "**"
        case .bold:
            let prefix = "**", suffix = "**"
            if selectedRange.length == 0 {
                text.replaceSubrange(swiftRange, with: prefix + suffix)
                let newCursor = selectedRange.location + prefix.count
                selectedRange = NSRange(location: newCursor, length: 0)
            } else {
                let selectedText = text[swiftRange]
                if selectedText.hasPrefix(prefix) && selectedText.hasSuffix(suffix) && selectedText.count >= prefix.count + suffix.count {
                    let unformatted = String(selectedText.dropFirst(prefix.count).dropLast(suffix.count))
                    text.replaceSubrange(swiftRange, with: unformatted)
                    selectedRange = NSRange(location: selectedRange.location, length: selectedRange.length - prefix.count - suffix.count)
                } else {
                    let wrapped = prefix + selectedText + suffix
                    text.replaceSubrange(swiftRange, with: wrapped)
                    selectedRange = NSRange(location: selectedRange.location, length: selectedRange.length + prefix.count + suffix.count)
                }
            }
            
        // Курсив: оборачиваем текст в "_"
        case .italic:
            let prefix = "*", suffix = "*"
            if selectedRange.length == 0 {
                text.replaceSubrange(swiftRange, with: prefix + suffix)
                let newCursor = selectedRange.location + prefix.count
                selectedRange = NSRange(location: newCursor, length: 0)
            } else {
                let selectedText = text[swiftRange]
                if selectedText.hasPrefix(prefix) && selectedText.hasSuffix(suffix) && selectedText.count >= prefix.count + suffix.count {
                    let unformatted = String(selectedText.dropFirst(prefix.count).dropLast(suffix.count))
                    text.replaceSubrange(swiftRange, with: unformatted)
                    selectedRange = NSRange(location: selectedRange.location, length: selectedRange.length - prefix.count - suffix.count)
                } else {
                    let wrapped = prefix + selectedText + suffix
                    text.replaceSubrange(swiftRange, with: wrapped)
                    selectedRange = NSRange(location: selectedRange.location, length: selectedRange.length + prefix.count + suffix.count)
                }
            }
            
        // Заголовки: действуют на всю строку, добавляя или удаляя префикс вида "# ", "## ", ... в зависимости от уровня
        case .header(let level):
            let prefix = String(repeating: "#", count: level) + " "
            let suffix = " #"
            
            if selectedRange.length == 0 {
                text.replaceSubrange(swiftRange, with: prefix + suffix)
                let newCursor = selectedRange.location + prefix.count
                selectedRange = NSRange(location: newCursor, length: 0)
            } else {
                let selectedText = text[swiftRange]
                if selectedText.hasPrefix(prefix) && selectedText.hasSuffix(suffix) && selectedText.count >= prefix.count + suffix.count {
                    let unformatted = String(selectedText.dropFirst(prefix.count).dropLast(suffix.count))
                    text.replaceSubrange(swiftRange, with: unformatted)
                    selectedRange = NSRange(location: selectedRange.location, length: selectedRange.length - prefix.count - suffix.count)
                } else {
                    let wrapped = prefix + selectedText + suffix
                    text.replaceSubrange(swiftRange, with: wrapped)
                    selectedRange = NSRange(location: selectedRange.location, length: selectedRange.length + prefix.count + suffix.count)
                }
            }

            
        // Inline код: оборачиваем текст в "`"
        case .code:
            let prefix = "`", suffix = "`"
            if selectedRange.length == 0 {
                text.replaceSubrange(swiftRange, with: prefix + suffix)
                let newCursor = selectedRange.location + prefix.count
                selectedRange = NSRange(location: newCursor, length: 0)
            } else {
                let selectedText = text[swiftRange]
                if selectedText.hasPrefix(prefix) && selectedText.hasSuffix(suffix) && selectedText.count >= prefix.count + suffix.count {
                    let unformatted = String(selectedText.dropFirst(prefix.count).dropLast(suffix.count))
                    text.replaceSubrange(swiftRange, with: unformatted)
                    selectedRange = NSRange(location: selectedRange.location, length: selectedRange.length - prefix.count - suffix.count)
                } else {
                    let wrapped = prefix + selectedText + suffix
                    text.replaceSubrange(swiftRange, with: wrapped)
                    selectedRange = NSRange(location: selectedRange.location, length: selectedRange.length + prefix.count + suffix.count)
                }
            }
            
        // Зачёркивание: оборачиваем текст в "~~"
        case .strikethrough:
            let prefix = "~~", suffix = "~~"
            if selectedRange.length == 0 {
                text.replaceSubrange(swiftRange, with: prefix + suffix)
                let newCursor = selectedRange.location + prefix.count
                selectedRange = NSRange(location: newCursor, length: 0)
            } else {
                let selectedText = text[swiftRange]
                if selectedText.hasPrefix(prefix) && selectedText.hasSuffix(suffix) && selectedText.count >= prefix.count + suffix.count {
                    let unformatted = String(selectedText.dropFirst(prefix.count).dropLast(suffix.count))
                    text.replaceSubrange(swiftRange, with: unformatted)
                    selectedRange = NSRange(location: selectedRange.location, length: selectedRange.length - prefix.count - suffix.count)
                } else {
                    let wrapped = prefix + selectedText + suffix
                    text.replaceSubrange(swiftRange, with: wrapped)
                    selectedRange = NSRange(location: selectedRange.location, length: selectedRange.length + prefix.count + suffix.count)
                }
            }
            
        // Цитата: применяется ко всей строке, добавляя или удаляя префикс "> "
        case .blockquote:
            let nsText = text as NSString
            let lineRange = nsText.lineRange(for: selectedRange)
            guard let lineStart = text.index(text.startIndex, offsetBy: lineRange.location, limitedBy: text.endIndex) else { return }
            let lineEnd = text.index(lineStart, offsetBy: lineRange.length)
            let lineText = String(text[lineStart..<lineEnd])
            let quotePrefix = "> "
            if lineText.hasPrefix(quotePrefix) {
                let unformattedLine = String(lineText.dropFirst(quotePrefix.count))
                text.replaceSubrange(lineStart..<lineEnd, with: unformattedLine)
                let newLocation = max(selectedRange.location - quotePrefix.count, lineRange.location)
                selectedRange = NSRange(location: newLocation, length: max(selectedRange.length - quotePrefix.count, 0))
            } else {
                text.insert(contentsOf: quotePrefix, at: lineStart)
                let newLocation = selectedRange.location + quotePrefix.count
                selectedRange = NSRange(location: newLocation, length: selectedRange.length)
            }
            
        // Маркированный список: применяется ко всей строке, с префиксом "- "
        case .unorderedList:
            let nsText = text as NSString
            let lineRange = nsText.lineRange(for: selectedRange)
            guard let lineStart = text.index(text.startIndex, offsetBy: lineRange.location, limitedBy: text.endIndex) else { return }
            let lineEnd = text.index(lineStart, offsetBy: lineRange.length)
            let lineText = String(text[lineStart..<lineEnd])
            let listPrefix = "- "
            if lineText.hasPrefix(listPrefix) {
                let unformattedLine = String(lineText.dropFirst(listPrefix.count))
                text.replaceSubrange(lineStart..<lineEnd, with: unformattedLine)
                let newLocation = max(selectedRange.location - listPrefix.count, lineRange.location)
                selectedRange = NSRange(location: newLocation, length: max(selectedRange.length - listPrefix.count, 0))
            } else {
                text.insert(contentsOf: listPrefix, at: lineStart)
                let newLocation = selectedRange.location + listPrefix.count
                selectedRange = NSRange(location: newLocation, length: selectedRange.length)
            }
            
        // Нумерованный список: применяется ко всей строке, с префиксом "1. "
        case .orderedList:
            let nsText = text as NSString
            let lineRange = nsText.lineRange(for: selectedRange)
            guard let lineStart = text.index(text.startIndex, offsetBy: lineRange.location, limitedBy: text.endIndex) else { return }
            let lineEnd = text.index(lineStart, offsetBy: lineRange.length)
            let lineText = String(text[lineStart..<lineEnd])
            let listPrefix = "1. "
            if lineText.hasPrefix(listPrefix) {
                let unformattedLine = String(lineText.dropFirst(listPrefix.count))
                text.replaceSubrange(lineStart..<lineEnd, with: unformattedLine)
                let newLocation = max(selectedRange.location - listPrefix.count, lineRange.location)
                selectedRange = NSRange(location: newLocation, length: max(selectedRange.length - listPrefix.count, 0))
            } else {
                text.insert(contentsOf: listPrefix, at: lineStart)
                let newLocation = selectedRange.location + listPrefix.count
                selectedRange = NSRange(location: newLocation, length: selectedRange.length)
            }
            
        // Ссылка: если текст не выделен — вставляется шаблон "[](url)", иначе оборачивается выделенный текст в квадратные скобки с "(url)"
        case .link:
            let linkPlaceholder = "url"
            if selectedRange.length == 0 {
                let insertion = "[](\(linkPlaceholder))"
                text.replaceSubrange(swiftRange, with: insertion)
                // Ставим курсор между квадратными скобками
                let newCursor = selectedRange.location + 1
                selectedRange = NSRange(location: newCursor, length: 0)
            } else {
                let selectedText = text[swiftRange]
                if selectedText.hasPrefix("[") && selectedText.hasSuffix("](\(linkPlaceholder))") {
                    let unformatted = String(selectedText.dropFirst().dropLast("](\(linkPlaceholder))".count))
                    text.replaceSubrange(swiftRange, with: unformatted)
                    selectedRange = NSRange(location: selectedRange.location, length: selectedRange.length - 1 - "](\(linkPlaceholder))".count)
                } else {
                    let wrapped = "[" + selectedText + "](\(linkPlaceholder))"
                    text.replaceSubrange(swiftRange, with: wrapped)
                    selectedRange = NSRange(location: selectedRange.location, length: selectedRange.length + 1 + "](\(linkPlaceholder))".count)
                }
            }
        }
    }
    
    @MainActor
    func insertPhoto(postId: String) async throws {
        guard !isImageUploading else { return }
        guard let item = imageItem else { return }
        
        withAnimation {
            isImageUploading = true
        }
        
        guard let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) else { return }
        
        let id = UUID().uuidString + postId
        let url = try await ArticlesManager.shared.uploadImage(id: id, image: image, folder: "contentImages")
        
        let markdown = "\n\n![](\(url))\n\n"
        
        try await ArticlesManager.shared.uploadMedia(url: String(url), to: postId)
        mediaURLs.append(URL(string: url)!)
        
        if let range = Range(selectedRange, in: text) {
            withAnimation {
                text.replaceSubrange(range, with: markdown)
            }
        }
        
        withAnimation {
            isImageUploading = false
        }
    }
    
    func addNewPost(
        title: String,
        description: String,
        text: String,
        image: UIImage,
        isArchive: Bool,
        uploadingLanguage: String
    ) async throws -> String {
        try await ArticlesManager.shared.addNewPost(
            title: title,
            description: description,
            text: text,
            image: image,
            isArchive: isArchive,
            uploadingLanguage: uploadingLanguage
        )
    }
    
    func updatePost(id: String, title: String, image: UIImage, description: String, text: String, isArchive: Bool) async throws {
        try await ArticlesManager.shared.updatePost(
            id: id,
            title: title,
            image: image,
            description: description,
            text: text,
            isArchive: isArchive
        )
    }
    
    func getNavigationTitle(_ isEditing: Bool) -> String {
        isEditing ? NSLocalizedString("editingLabel", comment: "") : NSLocalizedString("creationLabel", comment: "")
    }
}
