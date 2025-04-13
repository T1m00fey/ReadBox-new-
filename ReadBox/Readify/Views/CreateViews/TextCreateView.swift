//
//  TextCreateView.swift
//  Readify
//
//  Created by Тимофей Юдин on 13.02.2025.
//

import SwiftUI
import MarkdownUI

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
    case header(level: Int)  // Заголовок с указанием уровня (1–6)
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
    @Published var heightOfTE: CGFloat = UIScreen.main.bounds.height - 300
    
    let fonts: [String: [String]] = [
        NSLocalizedString("titleLabel", comment: ""): ["1", "2", ""]
    ]
    
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
    
    func addNewPost(title: String, description: String, text: String, image: UIImage, isArchive: Bool) async throws {
        try await ArticlesManager.shared.addNewPost(
            title: title,
            description: description,
            text: text,
            image: image,
            isArchive: isArchive
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


struct TextCreateView: View {
    let id: String
    @Binding var title: String
    let image: UIImage
    @Binding var description: String
    let text: String
    let isEditing: Bool
    
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
                                viewModel.text
                                    .replacingOccurrences(of: "\n", with: "<br>")
                                    .replacingOccurrences(of: "<br>#", with: "\n#")
                                    .replacingOccurrences(of: "#<br>", with: "\n")
                            )
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
                .onChange(of: isTEFocused) { newValue in
                    withAnimation {
                        viewModel.heightOfTE = newValue ? 300 : UIScreen.main.bounds.height - 300
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
            .onChange(of: viewModel.addingMode) { newValue in
                var isArchive = false
                
                if viewModel.addingMode == 2 {
                    isArchive = true
                }
                
                if viewModel.addingMode > 0 {
                    if isEditing {
                        Task {
                            do {
                                try await viewModel.updatePost(
                                    id: id,
                                    title: title,
                                    image: image,
                                    description: description,
                                    text: viewModel.text.replacingOccurrences(of: "\n", with: "<br>"),
                                    isArchive: isArchive
                                )
                                
                                StorageManager.shared.deleteText()
                            } catch {
                                withAnimation {
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
                                try await viewModel.addNewPost(
                                    title: title,
                                    description: description,
                                    text: viewModel.text.replacingOccurrences(of: "\n", with: "<br>"),
                                    image: image,
                                    isArchive: isArchive
                                )
                                
                                StorageManager.shared.saveImage(id: id, image: image)
                                StorageManager.shared.deleteText()
                            } catch {
                                withAnimation {
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
                    viewModel.text = text.replacingOccurrences(of: "<br>", with: "\n")
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
                        viewModel.isPreviewShowed ? Image(systemName: "pencil.and.scribble") : Image(systemName: "eye")
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

#Preview {
    TextCreateView(id: "", title: .constant(""), image: UIImage(systemName: "")!, description: .constant(""), text: "", isEditing: false, isCreateViewPresented: .constant(true))
}
