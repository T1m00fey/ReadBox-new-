//
//  TopArticleView.swift
//  Readify
//
//  Created by Тимофей Юдин on 06.11.2024.
//

import SwiftUI
import FirebaseStorage
import UIKit

struct TopArticleView: View {
    let id: String
    let title: String?
    let isArchive: Bool?
    let isPremiumPost: Bool
    let isAccessToPremiumDenied: Bool
    
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
            Group {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .frame(width: UIScreen.main.bounds.width - 10)
                        .shadow(radius: 1)
                } else if let videoURL {
                    TappableVideoPreview(
                        url: videoURL,
                        cornerRadius: 20,
                        width: UIScreen.main.bounds.width - 10
                    )
                        .frame(width: UIScreen.main.bounds.width - 10)
                        .shadow(radius: 1)
                } else {
                    RoundedRectangle(cornerRadius: 20)
                        .frame(width: UIScreen.main.bounds.width - 10, height: 250)
                        .foregroundStyle(Color(uiColor: .secondarySystemBackground))
                }
            }
            .compositingGroup()
            .blur(radius: isAccessToPremiumDenied ? 10 : 0)
            .disabled(isAccessToPremiumDenied)
            
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

            if isAccessToPremiumDenied {
                subscriptionAlertView
                    .padding(.all, 12)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
        }
        .hiddenTopArticleOnScreenshots(isPremiumPost)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .onAppear {
            if image == nil && !(isArchive ?? true) {
                fetchImage()
            }
        }
    }
}

private extension View {
    @ViewBuilder
    func hiddenTopArticleOnScreenshots(_ isHidden: Bool) -> some View {
        if isHidden {
            mask {
                TopArticleScreenShotPreventerMask()
            }
        } else {
            self
        }
    }
}

private struct TopArticleScreenShotPreventerMask: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UITextField()
        view.isSecureTextEntry = true
        view.text = ""
        view.isUserInteractionEnabled = false

        if let autoHideLayer = findAutoHideLayer(view: view) {
            autoHideLayer.backgroundColor = UIColor.white.cgColor
        } else {
            view.layer.sublayers?.last?.backgroundColor = UIColor.white.cgColor
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let autoHideLayer = findAutoHideLayer(view: uiView) {
            autoHideLayer.backgroundColor = UIColor.white.cgColor
        } else {
            uiView.layer.sublayers?.last?.backgroundColor = UIColor.white.cgColor
        }
    }

    private func findAutoHideLayer(view: UIView) -> CALayer? {
        guard let layers = view.layer.sublayers else { return nil }

        return layers.first { layer in
            String(describing: layer.delegate).contains("UITextLayoutCanvasView")
        }
    }
}

private extension TopArticleView {
    var subscriptionAlertView: some View {
        VStack(spacing: 1) {
            Text(LocalizedStringKey("availableOnlyWithLabel"))
                .font(.system(size: 16))
                .fontDesign(.rounded)
                .foregroundStyle(Color(.gray))

            Text("Read+")
                .font(.custom("Borel-Regular", size: 28))
                .foregroundStyle(Color(.gray))
                .padding(.bottom, -20)
        }
    }
}

#Preview {
    TopArticleView(
        id: "",
        title: "",
        isArchive: false,
        isPremiumPost: false,
        isAccessToPremiumDenied: false
    )
}
