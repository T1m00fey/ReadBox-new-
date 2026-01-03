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

struct CreateView: View {
    @Binding var isCreateViewPresented: Bool
    
    let id: String
    let title: String
    let image: UIImage?
    let text: String
    let isEditing: Bool
    let mediaURLs: [URL]
    
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
                        
                        TextEditor(text: $viewModel.titleText)
                            .font(.title3)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 5)
                            .frame(width: UIScreen.main.bounds.width - 32, height: 200)
//                            .frame(height: viewModel.titleTEHeight)
                            .scrollContentBackground(.hidden)
                            .background(Color(uiColor: .secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(radius: 1)
                            .focused($isTitleTEFocused)
                            .padding(.horizontal)
                            .onChange(of: isTitleTEFocused) {
                                withAnimation {
                                    viewModel.isTitleTESelected = isTitleTEFocused ? true : false
//                                    viewModel.titleTEHeight = isTitleTEFocused ? 200 : 300
                                    
                                    if viewModel.isFirstTapOnTitleTE && !isEditing {
                                        withAnimation {
                                            viewModel.isFirstTapOnTitleTE = false
                                            viewModel.titleText = ""
                                        }
                                    }
                                }
                            }
                            .tint(Color(uiColor: .label))
                        
                        if !viewModel.isTitleTESelected {
                            VStack(spacing: 10) {
                                Text(NSLocalizedString("whichFeedUploadingToLabel", comment: ""))
                                    .font(.system(size: 17))
                                    .foregroundStyle(.gray)
                                    .frame(width: UIScreen.main.bounds.width - 36, alignment: .leading)
                                
                                CustomSegmentedControl(selectedLanguage: $viewModel.languageSelection)
                            }
                            .padding(.top, 20)
                        }
                            
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 20) {
                                ForEach(0..<media.count, id: \.self) { i in
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
                                                            withAnimation { _ = media.remove(at: idx) }
                                                        }
                                                    }
                                                }
                                        }
                                    } else if let _ = item?.videoURL {
                                        ZStack(alignment: .topTrailing) {
                                            ZStack {
                                                if let videoPreview = item?.videoPreview {
                                                    Image(uiImage: videoPreview)
                                                        .resizable().scaledToFit()
                                                        .frame(width: 100)
                                                        .clipShape(RoundedRectangle(cornerRadius: 20))
                                                    Image(systemName: "play.fill")
                                                        .resizable().scaledToFit().frame(width: 30)
                                                        .foregroundStyle(Color(.secondarySystemBackground))
                                                } else {
                                                    RoundedRectangle(cornerRadius: 20)
                                                        .fill(Color(.secondarySystemBackground))
                                                        .frame(width: 100, height: 100)
                                                        .overlay { ProgressView().scaleEffect(0.8) }
                                                    Image(systemName: "play.fill")
                                                        .resizable().scaledToFit().frame(width: 30)
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
                                                            withAnimation { _ = media.remove(at: idx) }
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
                        .padding(.top, 10)
                        
                        //                            PhotosPicker(selection: $viewModel.imageItem, matching: .any(of: [.videos, .images])) {
                        //                                ZStack {
                        //                                    RoundedRectangle(cornerRadius: 20)
                        //                                        .frame(width: UIScreen.main.bounds.width - 32, height: 50)
                        //                                        .foregroundStyle(Color(uiColor: .secondarySystemBackground))
                        //                                        .shadow(radius: 1)
                        //
                        //                                    HStack {
                        //                                        Text(NSLocalizedString("addPhotoLabel", comment: ""))
                        //                                            .font(.system(size: 24))
                        //                                            .fontDesign(.rounded)
                        //
                        //                                        Image(systemName: "photo")
                        //                                    }
                        //                                }
                        //                                .padding(.top, 30)
                        //                            }
                        //                            .opacity(viewModel.isCoverLoading ? 0 : 1)

                        
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
                    TextCreateView(
                        id: id,
                        title: $viewModel.titleText,
                        text: text,
                        isEditing: isEditing,
                        uploadingLanguage: viewModel.languageSelection,
                        oldMediaCount: viewModel.oldMediaCount,
                        media: $media,
                        mediaURLs: $viewModel.mediaURLs,
                        postsCount: $postsCount,
                        posts: $posts,
                        archivePosts: $archivePosts,
                        isCreateViewPresented: $isCreateViewPresented
                    )
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
                        .onChange(of: viewModel.imageItem) {
                            if media.count < 10 {
                                viewModel.imagePickerTask =  Task {
                                    do {
                                        guard let item = viewModel.imageItem else { return }
                                        
                                        withAnimation {
                                            viewModel.isCoverLoading = true
                                        }
                                        
                                        try Task.checkCancellation()
                                        // Загружаем Data
                                        guard let data = try? await item.loadTransferable(type: Data.self) else {
                                            print("⚠️ Невозможно загрузить данные из файла")
                                            return
                                        }
                                        
                                        try Task.checkCancellation()
                                        // Пробуем как изображение
                                        if let image = UIImage(data: data) {
                                            print("🖼 Обложка — изображение")
                                            withAnimation {
                                                media.append(MediaKind(image: image))
                                                viewModel.isCoverLoading = false
                                            }
                                            return
                                        }
                                        
                                        // Иначе — это видео
                                        print("🎞 Обложка — видео (по Data)")
                                        try Task.checkCancellation()
                                        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
                                        try? data.write(to: tempURL)
                                        
                                        try Task.checkCancellation()
                                        // Генерируем превью
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
                            } else {
                                withAnimation {
                                    viewModel.errorText = NSLocalizedString("maxAttachFilesCountLabel", comment: "")
                                    viewModel.isErrorPopupPresented = true
                                }
                            }
                        }
                    }
                    
                    if #available(iOS 26.0, *) {
                        Button {
                            if (viewModel.titleText.count == 0 || viewModel.titleText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isFirstTapOnTitleTE) && !isEditing && !viewModel.isCoverLoading {
                                withAnimation {
                                    viewModel.errorText = NSLocalizedString("titleTEError", comment: "")
                                    viewModel.isErrorPopupPresented = true
                                }
                            } else {
                                viewModel.isTextCreateViewPresented = true
                            }
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
                                if (viewModel.titleText.count == 0 || viewModel.titleText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isFirstTapOnTitleTE) && !isEditing {
                                    withAnimation {
                                        viewModel.errorText = NSLocalizedString("titleTEError", comment: "")
                                        viewModel.isErrorPopupPresented = true
                                    }
                                } else {
                                    viewModel.isTextCreateViewPresented = true
                                }
                            }
                            .animation(.default, value: viewModel.titleText)
                    }
                    
                }
            }
            .onChange(of: viewModel.isTextCreateViewPresented) {
                viewModel.isFirstAppear = false
            }
            .onAppear {
                withAnimation { viewModel.navigationTitle = viewModel.getNavigationTitle(isEditing) }

                if viewModel.isFirstAppear {
                    viewModel.titleText = title
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
                        StorageManager.shared.deleteText()
                                                                        
                        if mediaURLs != viewModel.mediaURLs {
                            if mediaURLs.count < viewModel.mediaURLs.count {
                                for url in viewModel.mediaURLs {
                                    if !mediaURLs.contains(url) {
                                        Task {
                                            try? await ArticlesManager.shared.deleteImage(url: url)
                                        }
                                    }
                                }
                            }
                        }
                        
                        dismiss()
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
