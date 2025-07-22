//
//  MediaControlView.swift
//  ReadBox
//
//  Created by Macbook Pro on 22.07.2025.
//

import SwiftUI
import SDWebImageSwiftUI
import SwiftfulLoadingIndicators

struct MediaControlView: View {
    let postId: String
    
    @Binding var mediaURLs: [URL]
    
    @Binding var text: String
    @Binding var errorText: String
    @Binding var isErrorPopupPresented: Bool
    @Binding var isErrorPopup: Bool
    
    var body: some View {
        VStack {
            Capsule()
                .frame(width: 25, height: 5)
                .foregroundStyle(Color.gray)
                .padding(.top, 5)
            
            Text(NSLocalizedString("attachedFilesLabel", comment: ""))
                .font(.system(size: 26))
                .fontWeight(.light)
                .fontDesign(.rounded)
                .frame(width: UIScreen.main.bounds.width - 32, alignment: .leading)
                .padding(.top, 10)
            
            ScrollView {
                VStack {
                    if mediaURLs.count > 0 {
                        ForEach(mediaURLs, id: \.self) { url in
                            ZStack {
                                RoundedRectangle(cornerRadius: 20)
                                    .frame(width: UIScreen.main.bounds.width - 10)
                                    .foregroundStyle(Color(.systemBackground))
                                    .shadow(radius: 2)
                                
                                HStack {
                                    WebImage(url: url) { image in
                                        image
                                            .resizable()
                                    } placeholder: {
                                        LoadingIndicator(
                                            animation: .circleRunner,
                                            color: Color(.label),
                                            size: .small,
                                            speed: .fast
                                        )
                                        .frame(width: 100, height: 100)
                                        .background(Color(.secondarySystemBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                    }
                                    .onSuccess { _, _, _ in
                                        print("HERE: web image")
                                    }
                                    .onFailure(perform: { error in
                                        print("HERE: \(error.localizedDescription)")
                                    })
                                    .transition(.fade(duration: 0.5))
                                    .scaledToFit()
                                    .frame(width: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .padding(.vertical, 10)
                                    
                                    Text(url.absoluteString)
                                        .font(.system(size: 18))
                                        .fontDesign(.rounded)
                                        .fontWeight(.light)
                                        .lineLimit(5)
                                        .multilineTextAlignment(.leading)
                                    
                                    Spacer()
                                    
                                    HStack(spacing: 12) {
                                        Button {
                                            UIPasteboard.general.string = "![](\(url))"
                                            
                                            withAnimation {
                                                errorText = NSLocalizedString("linkIsCopiedLabel", comment: "")
                                                isErrorPopupPresented = true
                                                isErrorPopup = false
                                            }
                                        } label: {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 12)
                                                    .frame(width: 50, height: 50)
                                                    .foregroundStyle(Color(.secondarySystemBackground))
                                                    .shadow(radius: 2)
                                                
                                                Image(systemName: "document.on.document")
                                                    .font(.system(size: 23))
                                                    .foregroundStyle(Color.gray)
                                            }
                                        }
                                        
                                        Button {
                                            Task {
                                                do {
                                                    try await ArticlesManager.shared.removeMedia(url: url.absoluteString, from: postId)
                                                    try await ArticlesManager.shared.deleteImage(url: url)
                                                    
                                                    withAnimation {
                                                        text = text.replacingOccurrences(of: "![](\(url))", with: "")
                                                        mediaURLs.removeAll { $0 == url }
                                                        print("DELETE: \(mediaURLs)")
                                                        
                                                        errorText = NSLocalizedString("fileDeletedFromTextCreateView", comment: "")
                                                        isErrorPopupPresented = true
                                                        isErrorPopup = false
                                                    }
                                                } catch {
                                                    withAnimation {
                                                        errorText = error.localizedDescription
                                                        isErrorPopupPresented = true
                                                        isErrorPopup = true
                                                    }
                                                }
                                            }
                                        } label: {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 12)
                                                    .frame(width: 50, height: 50)
                                                    .foregroundStyle(Color(.secondarySystemBackground))
                                                    .shadow(radius: 2)
                                                
                                                Image(systemName: "minus.circle")
                                                    .font(.system(size: 23))
                                                    .foregroundStyle(Color.red)
                                            }
                                        }
                                    }
                                }
                                .frame(width: UIScreen.main.bounds.width - 30)
                            }
                        }
                    } else {
                        VStack {
                            Image(systemName: "photo.on.rectangle.angled")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 150)
                                .foregroundStyle(Color.gray)
                            
                            Text(NSLocalizedString("noMediaFilesAddedLabel", comment: ""))
                                .font(.system(size: 25))
                                .bold()
                                .fontDesign(.rounded)
                                .foregroundStyle(Color.gray)
                                .multilineTextAlignment(.center)
                        }
                        .offset(y: 50)
                    }
                }
                .padding()
            }
        }
        .frame(width: UIScreen.main.bounds.width)
        .frame(height: 700)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 30))
    }
}
