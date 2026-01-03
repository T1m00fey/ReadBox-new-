//
//  PostCreateView.swift
//  ReadBox
//
//  Created by Тимофей Юдин on 18.08.2025.
//

import SwiftUI
import PhotosUI
import PopupView
import AVFoundation
import SwiftfulLoadingIndicators

struct PostCreateView: View {
    let postId: String
    let title: String
    let authorId: String
    let isArchived: Bool
    
    @Binding var media: [MediaKind?]
    @Binding var posts: [PrePost]
    @Binding var archivedPosts: [PrePost]
    @Binding var postsCount: Int
    
    @StateObject private var viewModel = PostCreateViewModel()
    
    @FocusState private var isTEFocused: Bool
    
    @EnvironmentObject var hudService: HUDService
    @EnvironmentObject var changedPostsManager: ChangedPostsManager
    
    @Environment(\.dismiss) var dismiss

    init(
        postId: String = "",
        title: String = "",
        authorId: String,
        isArchived: Bool,
        media: Binding<[MediaKind?]>,
        posts: Binding<[PrePost]>,
        archivedPosts: Binding<[PrePost]>,
        postsCount: Binding<Int>
    ) {
        self.postId = postId
        self.title = title
        self.authorId = authorId
        self.isArchived = isArchived
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

        dismiss()

        Task.detached {
            do {
                if currentPostId.isEmpty {
                    _ = try await viewModel.uploadPost(
                        title: titleText,
                        isArchive: isArchive,
                        uploadingLanguage: selectedLanguage,
                        items: items
                    )

                    if !isArchive {
                        let newCount = oldCount + 1
                        try await UserManager.shared.updatePostsCount(userId: author, postsCount: newCount)
                    }
                } else {
                    try await viewModel.updatePost(
                        postId: currentPostId,
                        title: titleText,
                        isArchive: isArchive,
                        uploadingLanguage: selectedLanguage,
                        items: items
                    )

                    if isArchive != wasArchived {
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
                    
                    VStack(spacing: 20) {
                        VStack(spacing: 10) {
                            Text(NSLocalizedString("whichFeedUploadingToLabel", comment: ""))
                                .font(.system(size: 17))
                                .foregroundStyle(.gray)
                                .frame(width: UIScreen.main.bounds.width - 36, alignment: .leading)
                            
                            CustomSegmentedControl(selectedLanguage: $viewModel.selectedLanguage)
                        }
                        .padding(.top, 25)
                        
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
                                                    .frame(width: 100)
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
                                .font(.system(size: 20))
                                .fontDesign(.rounded)
                                .frame(
                                    width: UIScreen.main.bounds.width - 32,
                                    alignment: .topLeading
                                )
                                .frame(minHeight: 300)
                                .padding(.bottom, 5)
                            
                            Text(NSLocalizedString("whatsNewLabel", comment: ""))
                                .font(.system(size: 20))
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
                        .displayMode(.sheet)
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
                                        let generator = AVAssetImageGenerator(asset: asset)
                                        generator.appliesPreferredTrackTransform = true
                                        
                                        try Task.checkCancellation()
                                        let cgImage = try? generator.copyCGImage(at: .zero, actualTime: nil)
                                        let thumbnail = cgImage.map { UIImage(cgImage: $0) }

                                        withAnimation {
                                            viewModel.isCoverLoading = false
                                            media.append(MediaKind(videoURL: tempURL, videoPreview: thumbnail))
                                        }
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
                
            }
        }
    }
}
