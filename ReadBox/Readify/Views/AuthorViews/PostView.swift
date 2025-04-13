//
//  PostView.swift
//  Readify
//
//  Created by Тимофей Юдин on 11.01.2025.
//

import SwiftUI
import FirebaseStorage

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
    
    private func fetchImage() {
        let articleImage = StorageManager.shared.getImage(id: id)
        
        if articleImage != nil {
            withAnimation {
                image = articleImage
            }
        } else {
            DispatchQueue.main.async {
                let storage = Storage.storage()
                let storageRef = storage.reference()
                
                let islandRef = storageRef.child("images/\(id).jpg")
                
                islandRef.getData(maxSize: 1 * 5012 * 50125) { data, error in
                    if let error = error {
                        print(error .localizedDescription)
                    } else {
                        // Data for "images/island.jpg" is returned
                        withAnimation {
                            self.image = UIImage(data: data!)
                            StorageManager.shared.saveImage(id: id, image: image ?? UIImage())
                        }
                    }
                }
            }
        }
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .frame(width: UIScreen.main.bounds.width - 10)
                .foregroundStyle(Color(uiColor: .secondarySystemBackground))
                .shadow(radius: 2)
            
            HStack {
                if let image = image {
                    ZStack {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .padding(.vertical, 10)
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
