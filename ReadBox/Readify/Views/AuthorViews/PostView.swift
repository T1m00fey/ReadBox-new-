//
//  PostView.swift
//  Readify
//
//  Created by Тимофей Юдин on 11.01.2025.
//

import SwiftUI
import FirebaseStorage
import AVFoundation

struct PostView: View {
    let id: String
    let title: String
    let likesCount: Int
    let viewsCount: Int
    let isArchive: Bool
    let isAuthorView: Bool
    
    @Binding var postOption: PostOptions
    @Binding var selectedId: String
    
    @State private var image: UIImage? = nil
    @State private var isVideo = false
    
    private func fetchImage() {
        let articleImage = StorageManager.shared.getImage(id: id)
        
        if articleImage != nil {
            withAnimation {
                image = articleImage
            }
        } else {
            let imageRef = Storage.storage().reference().child("images/\(id).jpg")
            
            imageRef.getData(maxSize: 1 * 5012 * 5012) { data, error in
                if let data {
                    withAnimation {
                        image = UIImage(data: data) ?? UIImage()
                        if let image {
                            StorageManager.shared.saveImage(id: id, image: image)
                            return
                        }
                    }
                }
            }
        }
        
        let videoRef = Storage.storage().reference().child("images/\(id).mp4")
        videoRef.downloadURL { url, error in
            guard let url else {
                print("❌ Нет видео-обложки: \(error?.localizedDescription ?? "неизвестно")")
                return
            }
            
            // ✅ Асинхронная генерация превью
            Task.detached {
                let asset = AVAsset(url: url)
                
                do {
                    let _ = try await asset.loadTracks(withMediaType: .video)
                    
                    let generator = AVAssetImageGenerator(asset: asset)
                    generator.appliesPreferredTrackTransform = true
                    let cgImage = try generator.copyCGImage(at: .zero, actualTime: nil)
                    let preview = UIImage(cgImage: cgImage)
                    
                    await MainActor.run {
                        withAnimation {
                            self.image = preview
                            self.isVideo = true
                        }
                    }
                } catch {
                    print("❌ Не удалось создать превью: \(error)")
                }
            }
        }
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .frame(width: UIScreen.main.bounds.width - 10)
                .foregroundStyle(Color(uiColor: .secondarySystemBackground))
                .shadow(radius: 1)
            
            HStack {
                if let image = image {
                    ZStack {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .padding(.vertical, 10)
                        
                        if isVideo {
                            Image(systemName: "play.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30)
                                .foregroundStyle(Color(.secondarySystemBackground))
                        }
                    }
                }
                
                VStack {
                    HStack {
                        Text(title)
                            .font(.title3)
                            .fontDesign(.rounded)
                            .lineLimit(3)
                        
                        Spacer()
                    }
                    
                    Spacer()
                    
                    HStack {
                        Image(systemName: "eye")
                            .scaleEffect(0.8)
                        
                        Text("\(viewsCount)")
                            .padding(.leading, -5)
                            .padding(.trailing, 5)
                        
                        Image(systemName: "hand.thumbsup")
                            .scaleEffect(0.8)
                        
                        Text("\(likesCount)")
                            .padding(.leading, -5)
                        
                        Spacer()
                    }
                    .frame(alignment: .leading)
                }
                .padding(.vertical, 20)
                .padding(.leading, 10)
                
                if isAuthorView {
                    Menu {
                        
                        Button {
                            postOption = .editing
                            selectedId = id
                        } label: {
                            Label(NSLocalizedString("editingLabel", comment: ""), systemImage: "pencil")
                        }
                        
                        Button {
                            selectedId = id
                            
                            if isArchive {
                                postOption = .publish
                            } else {
                                postOption = .toArchive
                            }
                            
                        } label: {
                            if isArchive {
                                Label(NSLocalizedString("publishLabel", comment: ""), systemImage: "paperplane")
                            } else {
                                Label(NSLocalizedString("saveToArchiveLabel", comment: ""), systemImage: "archivebox")
                            }
                        }
                    
                        Button {
                            postOption = .delete
                            selectedId = id
                            
                            print("HERE: \(id)")
                            
                            StorageManager.shared.deleteImage(id: id)
                        } label: {
                            Label(NSLocalizedString("deleteLabel", comment: ""), systemImage: "xmark.circle")
                        }
                        
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.title2)
                            .foregroundStyle(Color.gray)
                            .frame(width: 30, height: 30)
                            .padding(.trailing, 10)
                    }

                }
            }
            .frame(width: UIScreen.main.bounds.width - 30)
        }
        .onAppear {
            if image == nil {
                fetchImage()
            }
        }
    }
}

#Preview {
    PostView(id: "", title: "", likesCount: 0, viewsCount: 0, isArchive: false, isAuthorView: true, postOption: .constant(PostOptions.nothing), selectedId: .constant("7"))
}
