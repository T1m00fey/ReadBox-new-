//
//  TopArticleView.swift
//  Readify
//
//  Created by Тимофей Юдин on 06.11.2024.
//

import SwiftUI
import FirebaseStorage

struct TopArticleView: View {
    let id: String
    let title: String?
    let isArchive: Bool?
    
    @State private var image: UIImage? = nil
    @State private var videoURL: URL? = nil
    
    private func fetchImage() {
        let articleImage = StorageManager.shared.getImage(id: id)
        
        if articleImage != nil {
            withAnimation {
                image = articleImage
            }
        } else {
            getMedia(byPath: "images/\(id)")
        }
        
        if image == nil && videoURL == nil {
            getMedia(byPath: "images/\(id)_0")
        }
    }
    
    private func getMedia(byPath path: String) {
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let islandRef = storageRef.child("\(path).jpg")
        
        islandRef.getData(maxSize: 1 * 5012 * 5012) { data, error in
            if let data  {
                withAnimation {
                    self.image = UIImage(data: data)
                    StorageManager.shared.saveImage(id: id, image: image ?? UIImage())
                }
            } else {
                let videoRef = storageRef.child("\(path).mp4")
                videoRef.downloadURL { url, error in
                    if let url {
                        DispatchQueue.main.async {
                            withAnimation {
                                self.videoURL = url
                            }
                        }
                    }
                }
            }
        }
    }
    
    var body: some View {
        ZStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .frame(width: UIScreen.main.bounds.width - 10)
                    .shadow(radius: 2)
            } else if let videoURL {
                TappableVideoPreview(
                    url: videoURL,
                    cornerRadius: 20,
                    width: UIScreen.main.bounds.width - 10,
                    height: 260
                )
                    .frame(width: UIScreen.main.bounds.width - 10)
                    .shadow(radius: 2)
            } else {
                RoundedRectangle(cornerRadius: 20)
                    .frame(width: UIScreen.main.bounds.width - 10, height: 250)
                    .foregroundStyle(Color(uiColor: .secondarySystemBackground))
            }
            
            VStack {
                Spacer()
                
                if let title = title {
                    Text(title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .fontDesign(.rounded)
                        .foregroundStyle(Color.white)
                        .shadow(color: Color.black, radius: 5)
                        .frame(width: UIScreen.main.bounds.width - 42, alignment: .bottomLeading)
                }
            }
            .frame(height: 200)
        }
        .onAppear {
            if image == nil && !(isArchive ?? true) {
                fetchImage()
            }
        }
    }
}

#Preview {
    TopArticleView(id: "", title: "", isArchive: false)
}
