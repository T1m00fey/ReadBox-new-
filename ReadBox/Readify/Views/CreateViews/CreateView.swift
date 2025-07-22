//
//  CreateView.swift
//  Readify
//
//  Created by Тимофей Юдин on 11.02.2025.
//

import SwiftUI
import PhotosUI
import PopupView

struct CreateView: View {
    @Binding var isCreateViewPresented: Bool
    
    let id: String
    let title: String
    let image: UIImage?
    let description: String
    let text: String
    let isEditing: Bool
    let mediaURLs: [URL]
    
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
                        
                        if !viewModel.isDescriptionTESelected {
                            TextEditor(text: $viewModel.titleText)
                                .font(.title3)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 5)
                                .frame(width: UIScreen.main.bounds.width - 32)
                                .frame(minHeight: 150)
                                .frame(maxHeight: 250)
                                .scrollContentBackground(.hidden)
                                .background(Color(uiColor: .secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .shadow(radius: 3)
                                .focused($isTitleTEFocused)
                                .padding(.horizontal)
                                .onChange(of: isTitleTEFocused) {
                                    withAnimation {
                                        viewModel.isTitleTESelected = isTitleTEFocused ? true : false
                                        viewModel.navigationTitle = isTitleTEFocused ? NSLocalizedString("titleLabel", comment: "") : viewModel.getNavigationTitle(isEditing)
                                        
                                        if viewModel.isFirstTapOnTitleTE && !isEditing {
                                            withAnimation {
                                                viewModel.isFirstTapOnTitleTE = false
                                                viewModel.titleText = ""
                                            }
                                        }
                                    }
                                }
                                .tint(Color(uiColor: .label))
                            
                            if !isEditing {
                                VStack(spacing: 10) {
                                    Text(NSLocalizedString("whichFeedUploadingToLabel", comment: ""))
                                        .font(.system(size: 17))
                                        .foregroundStyle(.gray)
                                        .frame(width: UIScreen.main.bounds.width - 36, alignment: .leading)
                                    
                                    CustomSegmentedControl(selectedLanguage: $viewModel.languageSelection)
                                }
                                .padding(.top, 20)
                            }
                        }
                            
                        if !viewModel.isTitleTESelected && !viewModel.isDescriptionTESelected {
                                PhotosPicker(selection: $viewModel.imageItem, matching: .images) {
                                    if viewModel.image == nil {
//                                        Image(systemName: "plus.circle")
//                                            .scaleEffect(3)
//                                            .foregroundStyle(Color.gray)
//                                            .frame(width: UIScreen.main.bounds.width - 32, height: 200)
//                                            .clipShape(RoundedRectangle(cornerRadius: 10))
//                                            .overlay (
//                                                RoundedRectangle(cornerRadius: 10)
//                                                    .stroke(style: StrokeStyle(lineWidth: 4, dash: [15, 10]))
//                                                    .foregroundStyle(Color.gray)
//                                            )
//                                            .padding(.horizontal)
                                        
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 15)
                                                .frame(width: UIScreen.main.bounds.width - 32, height: 50)
                                                .foregroundStyle(Color(uiColor: .secondarySystemBackground))
                                                .shadow(radius: 2)
                                            
                                            HStack {
                                                Text(NSLocalizedString("addPhotoLabel", comment: ""))
                                                    .font(.title2)
                                                    .fontDesign(.rounded)
                                                
                                                Image(systemName: "photo")
                                            }
                                        }
                                        .padding(.top, 30)
                                        
                                        
                                    } else {
                                            
                                        VStack {
                                            Image(uiImage: viewModel.image ?? UIImage())
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: UIScreen.main.bounds.width - 32)
                                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                                .padding(.horizontal)
                                                .padding(.top, 20)
                                            
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 15)
                                                    .frame(width: UIScreen.main.bounds.width - 32, height: 50)
                                                    .foregroundStyle(Color(uiColor: .secondarySystemBackground))
                                                    .shadow(radius: 2)
                                                
                                                HStack {
                                                    Text(NSLocalizedString("removePhotoLabel", comment: ""))
                                                        .font(.title2)
                                                        .fontDesign(.rounded)
                                                    
                                                    Image(systemName: "minus.circle")
                                                }
                                            }
                                            .onTapGesture(perform: {
                                                withAnimation {
                                                    viewModel.image = nil
                                                }
                                            })
                                            .padding(.top, 10)
                                            
                                        }
                                        
                                    }
                                }
//                                .padding(.top, 30)
                                .onChange(of: viewModel.imageItem) {
                                    Task {
                                        do {
                                            guard let imageData = try await viewModel.imageItem?.loadTransferable(type: Data.self) else { return }
                                            guard let inputImage = UIImage(data: imageData) else { return }
                                            
                                            withAnimation {
                                                viewModel.image = inputImage
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
                        
                        
                        if !viewModel.isTitleTESelected {
                            
                            if viewModel.isDescriptionAdded  {
                                TextEditor(text: $viewModel.descriptionText)
                                    .font(.title3)
                                    .fontDesign(.rounded)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 5)
                                    .frame(width: UIScreen.main.bounds.width - 32)
                                    .frame(minHeight: 150)
                                    .frame(maxHeight: 300)
                                    .scrollContentBackground(.hidden)
                                    .background(Color(uiColor: .secondarySystemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                                    .shadow(radius: 3)
                                    .focused($isDescriptionTEFocused)
                                    .onChange(of: isDescriptionTEFocused) {
                                        withAnimation {
                                            viewModel.isDescriptionTESelected = isDescriptionTEFocused ? true : false
                                            viewModel.navigationTitle = isDescriptionTEFocused ? NSLocalizedString("descriptionLabel", comment: "") : viewModel.getNavigationTitle(isEditing)
                                            
                                            if viewModel.isFirstTapOnDescriptionTE && !isEditing {
                                                withAnimation {
                                                    viewModel.isFirstTapOnDescriptionTE = false
                                                    viewModel.descriptionText = ""
                                                }
                                            }
                                        }
                                    }
                                    .tint(Color(uiColor: .label))
                                    .padding(.top, 30)
                                    .padding(.horizontal)
                                    .padding(.bottom, 100)
                            } else {
                                
                                ZStack {
                                    RoundedRectangle(cornerRadius: 15)
                                        .frame(width: UIScreen.main.bounds.width - 32, height: 50)
                                        .foregroundStyle(Color(uiColor: .secondarySystemBackground))
                                        .shadow(radius: 2)
                                    
                                    Text(NSLocalizedString("addDescriptionLabel", comment: ""))
                                        .font(.title2)
                                        .fontDesign(.rounded)
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 100)
                                .onTapGesture {
                                    withAnimation {
                                        viewModel.isDescriptionAdded = true
                                    }
                                }
                                
                            }
                            
                        }
                        
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
                .onTapGesture {
                    isTitleTEFocused = false
                    isDescriptionTEFocused = false
                }
                .navigationDestination(isPresented: $viewModel.isTextCreateViewPresented) {
                    TextCreateView(
                        id: id,
                        title: $viewModel.titleText,
                        image: viewModel.image ?? UIImage(),
                        description: $viewModel.descriptionText,
                        text: text,
                        isEditing: isEditing,
                        uploadingLanguage: viewModel.languageSelection,
                        mediaURLs: $viewModel.mediaURLs,
                        postsCount: $postsCount,
                        posts: $posts,
                        archivePosts: $archivePosts,
                        isCreateViewPresented: $isCreateViewPresented
                    )
                }
                
                VStack {
                    Spacer()
                    
                    Text(NSLocalizedString("nextLabel", comment: ""))
                        .frame(width: UIScreen.main.bounds.width - 10, height: 50, alignment: .center)
                        .font(.title2)
                        .fontDesign(.rounded)
                        .background(Color(uiColor: .label))
                        .foregroundStyle(Color(uiColor: .systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .padding(.bottom, 30)
                        .onTapGesture {
                            if viewModel.titleText.count == 0 || viewModel.titleText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                withAnimation {
                                    viewModel.errorText = NSLocalizedString("titleTEError", comment: "")
                                    viewModel.isErrorPopupPresented = true
                                }
                            } else {
                                if !viewModel.isDescriptionAdded {
                                    viewModel.descriptionText = ""
                                }
                                
                                viewModel.isTextCreateViewPresented = true
                            }
                        }
                    
                }
            }
            .onChange(of: viewModel.isTextCreateViewPresented) {
                viewModel.isFirstAppear = false
            }
            .onAppear {
                withAnimation {
                    viewModel.navigationTitle = viewModel.getNavigationTitle(isEditing)
                }
                
                if viewModel.isFirstAppear {
                    viewModel.titleText = title
                    viewModel.image = image
                    viewModel.descriptionText = description
                }
                
                if isEditing && description != "" {
                    viewModel.isDescriptionAdded = true
                }
                
                if viewModel.isFirstAppear {
                    viewModel.mediaURLs = mediaURLs
                }
                
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        StorageManager.shared.deleteText()
                                                                        
                        if mediaURLs != viewModel.mediaURLs && !isEditing {
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
