//
//  CreateView.swift
//  Readify
//
//  Created by Тимофей Юдин on 11.02.2025.
//

import SwiftUI
import PhotosUI
import PopupView
import SwiftfulLoadingIndicators
@preconcurrency import AVFoundation

struct CreateView: View {
    @Binding var isCreateViewPresented: Bool

    let id: String
    let title: String
    let image: UIImage?
    let text: String
    let isEditing: Bool
    let mediaURLs: [URL]
    let isArchived: Bool
    let isLocalizing: Bool
    let localizationCount: Int
    let isLocalizedVersion: Bool
    let rootId: String
    let rootLang: String
    let rootIsPremium: Bool
    let isPremiumAuthor: Bool

    @Binding var media: [MediaKind?]
    @Binding var postsCount: Int
    @Binding var posts: [PrePost]
    @Binding var archivePosts: [PrePost]

    @Environment(\.dismiss) var dismiss

    @StateObject private var viewModel = CreateViewModel()

    @FocusState var isTitleTEFocused: Bool
    @FocusState var isDescriptionTEFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemBackground)
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack {
                        titleEditorSection
                        mediaStripSection
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
                .onTapGesture {
                    isTitleTEFocused = false
                    isDescriptionTEFocused = false
                }
                .navigationDestination(isPresented: $viewModel.isTextCreateViewPresented) {
                    textCreateDestination
                }

                bottomControlsSection
            }
            .onChange(of: viewModel.isTextCreateViewPresented) {
                viewModel.isFirstAppear = false
            }
            .onChange(of: viewModel.imageItem) {
                handleImageItemChange()
            }
            .onAppear {
                if isLocalizing {
                    viewModel.languageSelection = rootLang == "en" ? 1 : 0
                } else if isEditing {
                    viewModel.languageSelection = rootLang == "en" ? 0 : 1
                    viewModel.isPremiumPostSetting = rootIsPremium == true ? 1 : 0
                }

                withAnimation {
                    viewModel.navigationTitle = viewModel.getNavigationTitle(
                        isEditing,
                        isLocalizing: isLocalizing,
                        rootLang: rootLang
                    )
                }

                if viewModel.isFirstAppear {
                    let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
                    let placeholder = NSLocalizedString("titlePlaceholder", comment: "")
                    let isPlaceholderTitle = trimmedTitle == placeholder.trimmingCharacters(in: .whitespacesAndNewlines)

                    if !trimmedTitle.isEmpty && !isPlaceholderTitle {
                        viewModel.titleText = title
                        viewModel.isFirstTapOnTitleTE = false
                    } else {
                        viewModel.titleText = placeholder
                        viewModel.isFirstTapOnTitleTE = true
                    }

                    viewModel.oldMediaCount = media.compactMap { $0 }.count
                    viewModel.mediaURLs = mediaURLs
                }

                isTitleTEFocused = false
            }
            .onDisappear {
                isTitleTEFocused = false
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        handleClose()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private extension CreateView {
    var titleEditorSection: some View {
        VStack {
            TextEditor(text: $viewModel.titleText)
                .font(.system(size: 20))
                .padding(.horizontal, 16)
                .padding(.vertical, 5)
                .frame(width: UIScreen.main.bounds.width - 32, height: 200)
                .scrollContentBackground(.hidden)
                .background(Color(uiColor: .secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(radius: 1)
                .focused($isTitleTEFocused)
                .padding(.horizontal)
                .onChange(of: isTitleTEFocused) {
                    handleTitleFocusChange()
                }
                .tint(Color(uiColor: .label))

            if !viewModel.isTitleTESelected {
                PhotosPicker(selection: $viewModel.imageItem, matching: .any(of: [.images, .videos])) {
                    HStack {
                        Text(NSLocalizedString("addPhotoLabel", comment: ""))
                            .font(.system(size: 20))
                            .fontDesign(.rounded)

                        Image(systemName: "photo")
                            .font(.system(size: 20))
                    }
                    .foregroundStyle(Color(.label))
                    .frame(width: UIScreen.main.bounds.width - 40, height: 40)
                    .background(
                        Capsule()
                            .foregroundStyle(Color(.secondarySystemBackground))
                    )
                }
                .padding(.top, 5)
            }

            if !viewModel.isTitleTESelected {
                VStack(spacing: 10) {
                    if !isLanguageSettingHidden {
                        CustomSegmentedControl(selected: $viewModel.languageSelection, type: .language)
                    }

                    if isPremiumAuthor {
                        CustomSegmentedControl(selected: $viewModel.isPremiumPostSetting, type: .premiumSetting)
                    }
                }
                .padding(.top, 20)
            }
        }
    }

    var isLanguageSettingHidden: Bool {
        isLocalizing || isLocalizedVersion || localizationCount > 0
    }

    var articleUploadingLanguage: String {
        if isLocalizing {
            return rootLang == "en" ? "ru" : "en"
        }

        return viewModel.languageSelection == 0 ? "en" : "ru"
    }

    var mediaStripSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(Array(media.indices), id: \.self) { index in
                    mediaPreviewItem(at: index)
                }

                if viewModel.isCoverLoading {
                    loadingMediaPreview
                }
            }
        }
        .frame(width: UIScreen.main.bounds.width - 32)
        .scrollClipDisabled()
        .padding(.top, 10)
    }

    @ViewBuilder
    func mediaPreviewItem(at index: Int) -> some View {
        let item = media[index]

        if let image = item?.image {
            ZStack(alignment: .topTrailing) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                removeMediaButton {
                    removeMedia(at: index)
                }
            }
        } else if item?.videoURL != nil {
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
                            .overlay { ProgressView().scaleEffect(0.8) }
                        Image(systemName: "play.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30)
                            .foregroundStyle(Color(.label))
                    }
                }

                removeMediaButton {
                    removeMedia(at: index)
                }
            }
        }
    }

    var loadingMediaPreview: some View {
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

            removeMediaButton {
                cancelMediaPicking()
            }
        }
    }

    func removeMediaButton(action: @escaping () -> Void) -> some View {
        Image(systemName: "xmark")
            .resizable()
            .scaledToFit()
            .frame(width: 12)
            .padding(.all, 8)
            .foregroundStyle(Color(.label))
            .background(Color(.secondarySystemBackground))
            .clipShape(Circle())
            .offset(x: 10, y: -10)
            .onTapGesture(perform: action)
    }

    var textCreateDestination: some View {
        TextCreateView(
            id: id,
            title: $viewModel.titleText,
            text: text,
            isEditing: isEditing,
            wasArchivedBeforeEditing: isArchived,
            uploadingLanguage: articleUploadingLanguage,
            oldMediaCount: viewModel.oldMediaCount,
            isLocalizing: isLocalizing,
            localizationCount: localizationCount,
            rootId: rootId,
            isPremiumPost: viewModel.isPremiumPostSetting == 0 ? false : true,
            shouldSavePublicationLanguage: !isLocalizing && !isLocalizedVersion,
            media: $media,
            mediaURLs: $viewModel.mediaURLs,
            postsCount: $postsCount,
            posts: $posts,
            archivePosts: $archivePosts,
            isCreateViewPresented: $isCreateViewPresented
        )
    }

    var bottomControlsSection: some View {
        VStack {
            Spacer()

            HStack {
                Spacer()
                mediaPickerButton
            }

            nextButtonSection
        }
    }

    var mediaPickerButton: some View {
        PhotosPicker(selection: $viewModel.imageItem, matching: .any(of: [.images, .videos])) {
            if #available(iOS 26.0, *) {
                Image(systemName: "photo.badge.plus.fill")
                    .foregroundStyle(Color(.label))
                    .font(.system(size: 20))
                    .padding()
                    .glassEffect(.regular)
                    .padding(.bottom, 10)
                    .padding(.trailing, 10)
                    .opacity(isTitleTEFocused && !viewModel.isCoverLoading ? 1 : 0)
            } else {
                Image(systemName: "photo.badge.plus.fill")
                    .foregroundStyle(Color(.label))
                    .font(.system(size: 20))
                    .padding()
                    .opacity(isTitleTEFocused ? 1 : 0)
                    .padding(.bottom, 10)
            }
        }
    }

    @ViewBuilder
    var nextButtonSection: some View {
        if #available(iOS 26.0, *) {
            Button {
                openTextCreateStep(requiresIdleCoverLoading: true)
            } label: {
                Text(NSLocalizedString("nextLabel", comment: ""))
                    .font(.system(size: 20))
                    .foregroundStyle(Color(.systemBackground))
                    .fontDesign(.rounded)
                    .padding(.vertical, 7)
                    .frame(maxWidth: .infinity)
            }
            .tint(Color(.label))
            .buttonStyle(.glassProminent)
            .padding(.horizontal, 22.5)
            .padding(.bottom, 20)
        } else {
            Text(NSLocalizedString("nextLabel", comment: ""))
                .frame(width: UIScreen.main.bounds.width - 10, height: 50, alignment: .center)
                .font(.title2)
                .fontDesign(.rounded)
                .background(
                    viewModel.titleText.isEmpty || viewModel.isCoverLoading
                    ? Color.gray
                    : Color(uiColor: .label)
                )
                .foregroundStyle(Color(uiColor: .systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .padding(.bottom, 30)
                .onTapGesture {
                    openTextCreateStep(requiresIdleCoverLoading: false)
                }
                .animation(.default, value: viewModel.titleText)
        }
    }

    func handleTitleFocusChange() {
        withAnimation {
            viewModel.isTitleTESelected = isTitleTEFocused

            if viewModel.isFirstTapOnTitleTE && !isEditing {
                withAnimation {
                    viewModel.isFirstTapOnTitleTE = false
                    viewModel.titleText = ""
                }
            }
        }
    }

    func removeMedia(at index: Int) {
        guard !viewModel.isCoverLoading else { return }

        DispatchQueue.main.async {
            if index < media.count {
                withAnimation {
                    _ = media.remove(at: index)
                }
            }
        }
    }

    func cancelMediaPicking() {
        viewModel.imagePickerTask?.cancel()
        viewModel.imagePickerTask = nil

        withAnimation {
            viewModel.isCoverLoading = false
        }
    }

    func handleImageItemChange() {
        guard media.count < 10 else {
            withAnimation {
                viewModel.errorText = NSLocalizedString("maxAttachFilesCountLabel", comment: "")
                viewModel.isErrorPopupPresented = true
            }
            return
        }

        viewModel.imagePickerTask = Task {
            do {
                guard let item = viewModel.imageItem else { return }

                withAnimation {
                    viewModel.isCoverLoading = true
                }

                try Task.checkCancellation()
                guard let data = try? await item.loadTransferable(type: Data.self) else {
                    print("⚠️ Невозможно загрузить данные из файла")
                    return
                }

                try Task.checkCancellation()
                if let image = UIImage(data: data) {
                    withAnimation {
                        media.append(MediaKind(image: image))
                        viewModel.isCoverLoading = false
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
                        viewModel.isCoverLoading = false
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
                    media.append(MediaKind(videoURL: tempURL, videoPreview: thumbnail))
                    viewModel.isCoverLoading = false
                }
            } catch is CancellationError {
                print("Task was determined")
            } catch {
                withAnimation {
                    viewModel.errorText = NSLocalizedString("maxAttachFilesCountLabel", comment: "")
                    viewModel.isErrorPopupPresented = true
                    viewModel.isCoverLoading = false
                }
            }
        }
    }

    func openTextCreateStep(requiresIdleCoverLoading: Bool) {
        let isTitleEmpty = viewModel.titleText.isEmpty
            || viewModel.titleText.normalizedPublicationPlainText.isEmpty
            || viewModel.isFirstTapOnTitleTE

        let shouldShowError = isTitleEmpty
            && !isEditing
            && (!requiresIdleCoverLoading || !viewModel.isCoverLoading)

        if shouldShowError {
            withAnimation {
                viewModel.errorText = NSLocalizedString("titleTEError", comment: "")
                viewModel.isErrorPopupPresented = true
            }
        } else {
            viewModel.titleText = viewModel.titleText.normalizedPublicationPlainText
            viewModel.isTextCreateViewPresented = true
        }
    }

    func handleClose() {
        StorageManager.shared.deleteText()

        if mediaURLs != viewModel.mediaURLs, mediaURLs.count < viewModel.mediaURLs.count {
            for url in viewModel.mediaURLs where !mediaURLs.contains(url) {
                Task {
                    try? await ArticlesManager.shared.deleteImage(url: url)
                }
            }
        }

        dismiss()
    }
}
