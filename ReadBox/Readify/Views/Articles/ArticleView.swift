//
//  ArtcleView.swift
//  Readify
//
//  Created by Тимофей Юдин on 05.11.2024.
//

import SwiftUI
import FirebaseStorage

struct ArticleView: View {
    let id: String
    let title: String
    let authorName: String
    let isCheckmark: Bool
    let isArchive: Bool
    
    @State private var image: UIImage? = nil
    @State private var isExpanded = false
    
    private let maxTitleLen = 150
    
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
        
        VStack(spacing: -45) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .frame(width: UIScreen.main.bounds.width - 10)
                    .foregroundStyle(Color(uiColor: .secondarySystemBackground))
                    .shadow(radius: 2)
                
                HStack(spacing: 0) {
                    Text(authorName)
                        .font(.system(size: 21))
                        .fontDesign(.rounded)
                        .padding(.vertical, 20)
                        .lineLimit(1)
                    
                    if isCheckmark {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(Color.blue)
                            .font(.footnote)
                            .padding(.top, 4)
                    }
                    
                    Spacer()
                }
                .frame(width: UIScreen.main.bounds.width - 42, height: 90, alignment: .topLeading)
                .padding(.bottom, 16)
            }
            
            if let image = image {
                ZStack {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: UIScreen.main.bounds.width - 10)
                        .clipShape(RoundedRectangle(cornerRadius: 30))
                        .shadow(radius: 2)
                }
            }
            
            ZStack {
                RoundedRectangle(cornerRadius: 30)
                    .foregroundStyle(Color(uiColor: .secondarySystemBackground))
                    .frame(width: UIScreen.main.bounds.width - 10)
                    .shadow(radius: 2)
                
                VStack(spacing: 0) {
                    Text(title)
                        .font(.system(size: 19))
                        .fontDesign(.rounded)
                        .lineLimit(!isExpanded && title.count >= maxTitleLen ? 3 : nil)
                        .frame(width: UIScreen.main.bounds.width - 42, alignment: .leading)
                        .padding(.vertical, 20)
                        .padding(.bottom, !isExpanded && title.count >= maxTitleLen ? 17 : 0)
                    
                }
                
                ZStack {
                    if !isExpanded && title.count >= maxTitleLen {
                        RoundedRectangle(cornerRadius: 30)
                            .fill(
                                LinearGradient(
                                    gradient:
                                        Gradient(
                                            colors: [Color.clear, Color(.secondarySystemBackground)]
                                        ),
                                    startPoint: UnitPoint.top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: UIScreen.main.bounds.width - 42, height: 50)
                    }
                    
                    if !isExpanded && title.count >= maxTitleLen {
                        Text(NSLocalizedString("expandButtonLabel", comment: ""))
                            .font(.system(size: 16))
                            .fontDesign(.rounded)
                            .foregroundStyle(.gray)
                            .frame(width: UIScreen.main.bounds.width - 42, alignment: .trailing)
                            .padding(.horizontal, 20)
                            .onTapGesture {
                                withAnimation {
                                    isExpanded = true
                                }
                            }
                            .offset(y: 25)
                    }
                }
                .offset(y: 15)

            }
            
        }
        .onAppear{
            if image == nil && !isArchive {
                fetchImage()
            }
        }
        
    }
}

#Preview {
    ArticleView(id: "1", title: "TETSTETSTETSTETSTETSTETSTETSTETSTETSTETSTETSTETSTETSTETSTETSTETSTETSTETSTETSTETSTETSTETSTETSTETSTETSTETSTETSTETSTETSTETSTETSTETS", authorName: "Test", isCheckmark: false, isArchive: false)
}
