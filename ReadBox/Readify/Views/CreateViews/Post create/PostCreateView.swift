//
//  PostCreateView.swift
//  ReadBox
//
//  Created by Тимофей Юдин on 18.08.2025.
//

import SwiftUI
import PhotosUI
import PopupView
@preconcurrency import AVFoundation
import SwiftfulLoadingIndicators
import FirebaseStorage

enum VideoTranscodeError: Error { case exportFailed, cancelled }

final class VideoTranscoder {

    static func transcode720p(inputURL: URL) async throws -> URL {
        let asset = AVURLAsset(url: inputURL)

        guard let export = AVAssetExportSession(asset: asset,
                                               presetName: AVAssetExportPreset1280x720) else {
            throw VideoTranscodeError.exportFailed
        }

        let outURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")

        try? FileManager.default.removeItem(at: outURL)

        export.outputURL = outURL
        export.outputFileType = .mp4
        export.shouldOptimizeForNetworkUse = true

        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            export.exportAsynchronously { cont.resume() }
        }

        if export.status == .completed { return outURL }
        if export.status == .cancelled { throw VideoTranscodeError.cancelled }
        throw export.error ?? VideoTranscodeError.exportFailed
    }

    static func makeThumbnail(url: URL, maxWidth: CGFloat = 720) async -> Data? {
        let asset = AVAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true

        return await withCheckedContinuation { cont in
            DispatchQueue.global(qos: .userInitiated).async {
                guard let cg = try? generator.copyCGImage(at: .zero, actualTime: nil) else {
                    cont.resume(returning: nil); return
                }
                let img = UIImage(cgImage: cg)
                let resized = img.resized(maxWidth: maxWidth)
                let data = resized.jpegData(compressionQuality: 0.8)
                cont.resume(returning: data)
            }
        }
    }
}

private extension UIImage {
    func resized(maxWidth: CGFloat) -> UIImage {
        let w = size.width
        let h = size.height
        guard w > maxWidth else { return self }
        let scale = maxWidth / w
        let newSize = CGSize(width: maxWidth, height: h * scale)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1)
        draw(in: CGRect(origin: .zero, size: newSize))
        let out = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return out ?? self
    }
}


struct PostCreateView: View {
    let postId: String
    let title: String
    let authorId: String
    let authorName: String
    let isCheckmark: Bool
    let isArchived: Bool
    let lastVersionOfAvatar: Int
    let isLocalizing: Bool
    let localizationCount: Int
    let rootId: String
    let rootLang: String
    let rootIsPremium: Bool
    let rootMediaPosition: Int
    let isPremiumAuthor: Bool
    
    @Binding var media: [MediaKind?]
    @Binding var posts: [PrePost]
    @Binding var archivedPosts: [PrePost]
    @Binding var postsCount: Int
    
    @StateObject private var viewModel = PostCreateViewModel()
    
    @FocusState private var isTEFocused: Bool
    
    @EnvironmentObject var hudService: HUDService
    @EnvironmentObject var changedPostsManager: ChangedPostsManager
    @EnvironmentObject var sessionManager: SessionManager
    
    @Environment(\.dismiss) var dismiss

    init(
        postId: String = "",
        title: String = "",
        authorId: String,
        authorName: String,
        isCheckmark: Bool,
        isArchived: Bool,
        lastVersionOfAvatar: Int,
        isLocalizing: Bool,
        localizationCount: Int,
        rootId: String,
        rootLang: String,
        rootIsPremium: Bool,
        rootMediaPosition: Int,
        isPremiumAuthor: Bool,
        media: Binding<[MediaKind?]>,
        posts: Binding<[PrePost]>,
        archivedPosts: Binding<[PrePost]>,
        postsCount: Binding<Int>
    ) {
        self.postId = postId
        self.title = title
        self.authorId = authorId
        self.authorName = authorName
        self.isCheckmark = isCheckmark
        self.isArchived = isArchived
        self.lastVersionOfAvatar = lastVersionOfAvatar
        self.isLocalizing = isLocalizing
        self.localizationCount = localizationCount
        self.rootId = rootId
        self.rootLang = rootLang
        self.rootIsPremium = rootIsPremium
        self.rootMediaPosition = rootMediaPosition
        self.isPremiumAuthor = isPremiumAuthor
        self._media = media
        self._posts = posts
        self._archivedPosts = archivedPosts
        self._postsCount = postsCount
    }
    
    private func uploadPost() {
        viewModel.isArchive = (viewModel.addingMode == 2)
        hudService.showLoading()

        let items = media.compactMap { $0 }

        let isArchive = viewModel.isArchive
        let selectedLanguage = viewModel.selectedLanguage
        let titleText = viewModel.text
        let currentPostId = postId
        let author = authorId
        let oldCount = postsCount
        let wasArchived = isArchived
        let mediaPosition = viewModel.selectedMediaPosition

        dismiss()

        Task.detached {
            do {
                if currentPostId.isEmpty {
                    _ = try await viewModel.uploadPost(
                        title: titleText,
                        isArchive: isArchive,
                        uploadingLanguage: selectedLanguage == 0 ? "en" : "ru",
                        items: items,
                        mediaPosition: mediaPosition,
                        isLocalizing: isLocalizing,
                        localizationCount: localizationCount,
                        rootId: rootId,
                        isPremiumPost: viewModel.isPremiumPost == 0 ? false : true
                    )

                    if !isArchive && !isLocalizing {
                        let newCount = oldCount + 1
                        try await UserManager.shared.updatePostsCount(userId: author, postsCount: newCount)
                    }
                } else {
                    try await viewModel.updatePost(
                        postId: currentPostId,
                        title: titleText,
                        isArchive: isArchive,
                        uploadingLanguage: selectedLanguage == 0 ? "en" : "ru",
                        items: items,
                        mediaPosition: mediaPosition,
                        isPremiumPost: viewModel.isPremiumPost == 0 ? false : true
                    )

                    if isArchive != wasArchived && !isLocalizing {
                        let delta = isArchive ? -1 : +1
                        let newCount = max(0, oldCount + delta)
                        try await UserManager.shared.updatePostsCount(userId: author, postsCount: newCount)
                    }
                    
                    await MainActor.run {
                        changedPostsManager.changedPostsIDs.append(currentPostId)
                    }
                }

                await MainActor.run {
                    hudService.showSuccessPopup()
                    NotificationCenter.default.post(name: .postsDidChange, object: nil)
                }
            } catch {
                await MainActor.run {
                    print("Error: \(error.localizedDescription)")
                    hudService.showErrorPopup(with: error.localizedDescription)
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
                    
                    VStack(spacing: 5) {
                        HStack {
                            if let avatarImage = viewModel.avatarImage {
                                Image(uiImage: avatarImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                Color(.label),
                                                lineWidth: 0.1
                                            )
                                    )
                            }
                            
                            HStack(spacing: 0) {
                                Text(authorName)
                                    .font(.system(size: 19))
                                    .lineLimit(1)
                                    .underline()
                                    
                                if isCheckmark {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundStyle(Color.blue)
                                        .font(.system(size: 14))
                                        .padding(.top, 1)
                                }
                            }
                        }
                        .frame(width: UIScreen.main.bounds.width - 32, alignment: .leading)
                        
                        
                        
//                        VStack(spacing: 10) {
//                            Text(NSLocalizedString("whichFeedUploadingToLabel", comment: ""))
//                                .font(.system(size: 17))
//                                .foregroundStyle(.gray)
//                                .frame(width: UIScreen.main.bounds.width - 36, alignment: .leading)
//                            
//                            CustomSegmentedControl(selectedLanguage: $viewModel.selectedLanguage)
//                        }
//                        .padding(.top, 25)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 20) {
                                ForEach(Array(media.indices), id: \.self) { i in
                                    if i < media.count {
                                        let item = media[i]
                                        
                                        if let image = item?.image {
                                            ZStack(alignment: .topTrailing) {
                                                Image(uiImage: image)
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 200)
                                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                                                
                                                Image(systemName: "xmark")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 12)
                                                    .padding(.all, 8)
                                                    .foregroundStyle(Color(.label))
                                                    .background(Color(.secondarySystemBackground))
                                                    .clipShape(Circle())
                                                    .offset(x: 10, y: -10)
                                                    .onTapGesture {
                                                        guard !viewModel.isCoverLoading else { return }
                                                        let idx = i
                                                        DispatchQueue.main.async {
                                                            if idx < media.count {
                                                                withAnimation {
                                                                    _ = media.remove(at: idx)
                                                                }
                                                            }
                                                        }
                                                    }
                                            }
                                        } else if let _ = item?.videoURL {
                                            ZStack(alignment: .topTrailing) {
                                                ZStack {
                                                    if let videoPreview = item?.videoPreview {
                                                        Image(uiImage: videoPreview)
                                                            .resizable()
                                                            .scaledToFit()
                                                            .frame(width: 100)
                                                            .clipShape(RoundedRectangle(cornerRadius: 20))
                                                        
                                                        Image(systemName: "play.fill")
                                                            .resizable()
                                                            .scaledToFit()
                                                            .frame(width: 30)
                                                            .foregroundStyle(Color(.secondarySystemBackground))
                                                    } else {
                                                        RoundedRectangle(cornerRadius: 20)
                                                            .fill(Color(.secondarySystemBackground))
                                                            .frame(width: 100, height: 100)
                                                            .overlay {
                                                                ProgressView().scaleEffect(0.8)
                                                            }
                                                        
                                                        Image(systemName: "play.fill")
                                                            .resizable()
                                                            .scaledToFit()
                                                            .frame(width: 30)
                                                            .foregroundStyle(Color(.label))
                                                    }
                                                }
                                                
                                                Image(systemName: "xmark")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 12)
                                                    .padding(.all, 8)
                                                    .foregroundStyle(Color(.label))
                                                    .background(Color(.secondarySystemBackground))
                                                    .clipShape(Circle())
                                                    .offset(x: 10, y: -10)
                                                    .onTapGesture {
                                                        guard !viewModel.isCoverLoading else { return }
                                                        let idx = i
                                                        DispatchQueue.main.async {
                                                            if idx < media.count {
                                                                withAnimation {
                                                                    _ = media.remove(at: idx)
                                                                }
                                                            }
                                                        }
                                                    }
                                            }
                                        }
                                    }
                                }
                                
                                if viewModel.isCoverLoading {
                                    ZStack(alignment: .topTrailing) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 20)
                                                .frame(width: 100, height: 100)
                                                .foregroundStyle(Color(.secondarySystemBackground))
                                            
                                            LoadingIndicator(
                                                animation: .circleRunner,
                                                color: Color(.label),
                                                size: .small,
                                                speed: .fast
                                            )
                                        }
                                        
                                        Image(systemName: "xmark")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 12)
                                            .padding(.all, 8)
                                            .foregroundStyle(Color(.label))
                                            .background(Color(.secondarySystemBackground))
                                            .clipShape(Circle())
                                            .offset(x: 10, y: -10)
                                            .onTapGesture {
                                                viewModel.imagePickerTask?.cancel()
                                                viewModel.imagePickerTask = nil
                                                
                                                withAnimation {
                                                    viewModel.isCoverLoading = false
                                                }
                                            }
                                        
                                    }
                                }
                            }
                        }
                        .frame(width: UIScreen.main.bounds.width - 32)
                        .scrollClipDisabled()
                        
                        ZStack {
                            TextEditor(text: $viewModel.text)
                                .focused($isTEFocused)
                                .font(.system(size: 18))
                                .fontDesign(.rounded)
                                .frame(
                                    width: UIScreen.main.bounds.width - 32,
                                    alignment: .topLeading
                                )
                                .frame(minHeight: 300)
                                .padding(.bottom, 5)
                            
                            Text(NSLocalizedString("whatsNewLabel", comment: ""))
                                .font(.system(size: 18))
                                .foregroundStyle(Color.gray)
                                .fontDesign(.rounded)
                                .frame(width: UIScreen.main.bounds.width - 32, height: 300, alignment: .topLeading)
                                .padding(.leading, 10)
                                .padding(.top, 10)
                                .opacity(viewModel.text.isEmpty ? 1 : 0)
                        }
                    }
                    .onAppear {
                        isTEFocused = true
                    }
                    
                }
                .onAppear {
                    viewModel.text = title
                    viewModel.oldMediaCount = media.compactMap { $0 }.count
                    viewModel.selectedMediaPosition = rootMediaPosition
                    
                    if rootLang != "" {
                        viewModel.selectedLanguage = rootLang == "en" ? 1 : 0
                    }
                    
                    viewModel.isPremiumPost = rootIsPremium == true ? 1 : 0
                }
//                .popup(isPresented: $viewModel.isConfirmationPopupPresented) {
//                    ConfirmationView(
//                        addingMode: $viewModel.addingMode,
//                        popupType: .publishType
//                    )
//                    .shadow(radius: 1)
//                } customize: {
//                    $0
//                        .type(.toast)
//                        .appearFrom(.bottomSlide)
//                        .dragToDismiss(true)
//                        .displayMode(.sheet)
//                }
                .sheet(isPresented: $viewModel.isConfirmationPopupPresented, content: {
                    ConfirmationView(
                        addingMode: $viewModel.addingMode,
                        popupType: .publishType
                    )
                    .presentationDetents([.height(250)])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(30)
                })
//                .popup(isPresented: $viewModel.isPostSettingsPopupPresented) {
//                    PostCreateSettingsView(
//                        selectedLanguage: $viewModel.selectedLanguage,
//                        selectedMediaPosition: $viewModel.selectedMediaPosition
//                    )
//                    .shadow(radius: 1)
//                } customize: {
//                    $0
//                        .type(.toast)
//                        .appearFrom(.bottomSlide)
//                        .dragToDismiss(true)
//                        .displayMode(.sheet)
//                }
                .sheet(isPresented: $viewModel.isPostSettingsPopupPresented, content: {
                    PostCreateSettingsView(
                        isLocalizing: isLocalizing,
                        isPremiumAuthor: isPremiumAuthor,
                        localizationCount: localizationCount,
                        selectedLanguage: $viewModel.selectedLanguage,
                        selectedMediaPosition: $viewModel.selectedMediaPosition,
                        premiumSetting: $viewModel.isPremiumPost
                    )
                    .presentationDetents(
                        [
                            .height(
                                viewModel.getHeightOfPopupSettingPopup(
                                    isLocalizing: isLocalizing,
                                    isPremiumAuthor: isPremiumAuthor
                                )
                            )
                        ]
                    )
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(30)
                })
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
                .scrollClipDisabled()
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
//                        Text(NSLocalizedString("cancelButton", comment: ""))
//                            .font(.system(size: 17))
//                            .fontDesign(.rounded)
//                            .onTapGesture {
//                                dismiss()
//                            }
                        Image(systemName: "xmark")
                            .font(.system(size: 20))
                            .fontDesign(.rounded)
                            .onTapGesture {
                                dismiss()
                            }
                    }
                    
                    if isLocalizing {
                        ToolbarItem(placement: .principal) {
                            Text((rootLang == "en" ? "RU" : "EN") + " \(NSLocalizedString("localizationLabel", comment: ""))")
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
                            if #available(iOS 26.0, *) {
                                Button {
                                    VibrationsService.shared.lightImpact()
                                    viewModel.isConfirmationPopupPresented = true
                                } label: {
                                    Image(systemName: "paperplane")
                                        .font(.system(size: 20))
                                        .foregroundStyle(Color(.systemBackground))
                                }
                                .tint(Color(.label))
                                .buttonStyle(.glassProminent)
                            } else {
                                Button {
                                    VibrationsService.shared.lightImpact()
                                    viewModel.isConfirmationPopupPresented = true
                                } label: {
                                    Text(NSLocalizedString("publishLabel", comment: ""))
                                        .foregroundStyle(Color(.systemBackground))
                                        .font(.system(size: 16))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(
                                            viewModel.text.isEmpty || viewModel.isCoverLoading
                                            ? Color.gray
                                            : Color(.label)
                                        )
                                        .clipShape(Capsule())
                                    
                                }
                                .disabled(viewModel.text.isEmpty || viewModel.isCoverLoading)
                                .animation(.default, value: viewModel.text)
                            }
                        }
                    }
                }
                .onChange(of: viewModel.addingMode) {
                    uploadPost()
                }
                
                VStack {
                    Spacer()
                    
                    HStack {
                        if #available(iOS 26, *) {
                            Image(systemName: "gearshape.fill")
                                .foregroundStyle(Color(.label))
                                .font(.system(size: 20))
                                .padding()
                                .glassEffect(.regular)
                                .opacity(isTEFocused ? 1 : 0)
                                .padding(.bottom, 10)
                                .onTapGesture {
                                    viewModel.isPostSettingsPopupPresented = true
                                }
                        } else {
                            Image(systemName: "gearshape.fill")
                                .foregroundStyle(Color(.label))
                                .font(.system(size: 20))
                                .padding()
                                .opacity(isTEFocused ? 1 : 0)
                                .padding(.bottom, 10)
                                .onTapGesture {
                                    viewModel.isPostSettingsPopupPresented = true
                                }
                        }
                        
                        Spacer()
                        
                        PhotosPicker(selection: $viewModel.imageItem, matching: .any(of: [.images, .videos])) {
                            if #available(iOS 26.0, *) {
                                Image(systemName: "photo.badge.plus.fill")
                                    .foregroundStyle(Color(.label))
                                    .font(.system(size: 20))
                                    .padding()
                                    .glassEffect(.regular)
                                    .opacity(isTEFocused ? 1 : 0)
                                    .padding(.bottom, 10)
                            } else {
                                Image(systemName: "photo.badge.plus.fill")
                                    .foregroundStyle(Color(.label))
                                    .font(.system(size: 20))
                                    .padding()
                                    .opacity(isTEFocused ? 1 : 0)
                                    .padding(.bottom, 10)
                            }
                        }
                        .opacity(viewModel.isCoverLoading ? 0 : 1)
                        .onChange(of: viewModel.imageItem) {
                            if media.count < 10 {
                                viewModel.imagePickerTask = Task {
                                    do {
                                        try Task.checkCancellation()
                                        guard let item = viewModel.imageItem else { return }
                                        
                                        withAnimation {
                                            viewModel.isCoverLoading = true
                                        }
                                        
                                        defer {
                                            withAnimation {
                                                viewModel.isCoverLoading = false
                                            }
                                        }
                                        
                                        try Task.checkCancellation()
                                        guard let data = try? await item.loadTransferable(type: Data.self) else {
                                            print("⚠️ Невозможно загрузить данные из файла")
                                            return
                                        }

                                        if let image = UIImage(data: data) {
                                            print("🖼 Обложка — изображение")
                                            withAnimation {
                                                media.append(MediaKind(image: image))
                                            }
                                            return
                                        }

                                        try Task.checkCancellation()
                                        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
                                        try? data.write(to: tempURL)

                                        try Task.checkCancellation()
                                        let asset = AVAsset(url: tempURL)
                                        let duration = try await asset.load(.duration)
                                        let secondsDuration = CMTimeGetSeconds(duration)
                                        
                                        try Task.checkCancellation()
                                        guard secondsDuration <= 120 else {
                                            withAnimation {
                                                viewModel.errorText = NSLocalizedString("durationCoverErrorLabel", comment: "")
                                                viewModel.isErrorPopupPresented = true
                                            }
                                            
                                            return
                                        }
                                        
                                        try Task.checkCancellation()

                                        // 1) Транскодим в 720p (сжатая версия)
                                        let compressedURL = try await VideoTranscoder.transcode720p(inputURL: tempURL)

                                        try Task.checkCancellation()

                                        // 2) Генерим превью уже из сжатого файла (чтобы соответствовало)
                                        let compressedAsset = AVAsset(url: compressedURL)
                                        let generator = AVAssetImageGenerator(asset: compressedAsset)
                                        generator.appliesPreferredTrackTransform = true

                                        let cgImage = try? generator.copyCGImage(at: .zero, actualTime: nil)
                                        let thumbnail = cgImage.map { UIImage(cgImage: $0) }

                                        withAnimation {
                                            viewModel.isCoverLoading = false
                                            media.append(MediaKind(videoURL: compressedURL, videoPreview: thumbnail))
                                        }

                                        try? FileManager.default.removeItem(at: tempURL)
                                    } catch is CancellationError {
                                      print("ЗАДАЧА ОТМЕНЕНА")
                                    } catch {
                                        withAnimation {
                                            viewModel.errorText = error.localizedDescription
                                            viewModel.isErrorPopupPresented = true
                                        }
                                    }
                                }
                            } else {
                                withAnimation {
                                    viewModel.errorText = NSLocalizedString("maxAttachFilesCountLabel", comment: "")
                                    viewModel.isErrorPopupPresented = true
                                }
                            }
                        }
                    }
                    .frame(width: UIScreen.main.bounds.width - 32)
                }
                .task {
                    let ava = await MediaManager.shared.getAvatar(authorId: authorId, lastVersion: lastVersionOfAvatar)
                    
                    withAnimation {
                        viewModel.avatarImage = ava
                    }
                    
                    if isLocalizing {
                        viewModel.selectedLanguage = rootLang == "en" ? 1 : 0
                    }
                }
                
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
