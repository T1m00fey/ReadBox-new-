//
//  SubscribesView.swift
//  ReadBox
//
//  Created by Macbook Pro on 30.07.2025.
//

import SwiftUI
import Shimmer
import SwiftfulLoadingIndicators
import PopupView

struct SubscribesView: View {
    @Binding var user: DBUser?
    
    @StateObject private var viewModel = SubscribesViewModel()
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                ZStack {
                    ScrollView {
                        VStack(spacing: 20) {
                            if viewModel.isLoading && viewModel.channels.isEmpty {
                                ForEach(0..<5) { _ in
                                    ChannelListItem(
                                        channel: Channel(
                                            authorId: "",
                                            authorName: "TESTESTESTEST",
                                            isCheckmark: true
                                        ),
                                        isShimmering: true
                                    )
                                    .redacted(reason: .placeholder)
                                    .shimmering()
                                }
                            } else {
                                ForEach(0..<viewModel.channels.count, id: \.self) { index in
                                    let channel = viewModel.channels[index]
                                    
                                    ChannelListItem(
                                        channel: channel,
                                        isShimmering: false
                                    )
                                    .onTapGesture {
                                        viewModel.isChannelViewPresented = true
                                        viewModel.selectedChannel = channel
                                    }
                                }
                            }
                        }
                    }
                    .scrollClipDisabled()
                    .padding(.top, 70)
                    
                    VStack {
                        HStack {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 23))
                                .foregroundStyle(Color(.label))
                                .onTapGesture {
                                    dismiss()
                                }
                                .padding(.leading, 16)
                            
                            Text(NSLocalizedString("subscribesLabel", comment: ""))
                                .font(.system(size: 26))
                                .fontWeight(.light)
                            
                            if viewModel.isLoading {
                                LoadingIndicator(
                                    animation: .circleRunner,
                                    color: Color(.label),
                                    size: .small,
                                    speed: .fast
                                )
                            }
                        }
                        .frame(
                            width: UIScreen.main.bounds.width,
                            height: 60,
                            alignment: .leading
                        )
                        .background(Color(.systemBackground))
                        .padding(.top, -10)
                        
                        Spacer()
                    }

                }
                .onAppear {
                    if viewModel.channels.isEmpty {
                        Task {
                            do {
                                if let user {
                                    try await viewModel.getChannels(user.subscribes ?? [])
                                }
                            } catch {
//                                withAnimation {
//                                    viewModel.errorText = error.localizedDescription
//                                    viewModel.isErrorPopupPresented = true
//                                }
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
                        .padding(.top, 20)
                } customize: {
                    $0
                        .type(.floater())
                        .position(.top)
                        .animation(.bouncy)
                        .dragToDismiss(true)
                        .autohideIn(5)
                }               
                .fullScreenCover(isPresented: $viewModel.isChannelViewPresented) {
                    let channel = viewModel.selectedChannel
                    
                    ChannelView(
                        user: $user,
                        authorId: channel?.authorId ?? "",
                        authorName: channel?.authorName ?? NSLocalizedString("notFoundLabel", comment: ""),
                        isCheckmark: channel?.isCheckmark ?? false
                    )
                }
            }
        }
        .navigationBarBackButtonHidden()
    }
}

import FirebaseStorage

struct ChannelListItem: View {
    let channel: Channel
    let isShimmering: Bool
    
    @State private var avatarImage: UIImage? = nil
    
    func getAvatar() {
        let authorId = channel.authorId
        
        let storage = Storage.storage()
        let storageRef = storage.reference()
        
        if let image = StorageManager.shared.getImage(id: authorId) {
            withAnimation {
                self.avatarImage = image
            }
        } else {
            let islandRef = storageRef.child("avatars/\(authorId).jpg")
            
            islandRef.getData(maxSize: 1 * 5012 * 5012) { data, error in
                if let data, let image = UIImage(data: data) {
                    withAnimation {
                        self.avatarImage = image
                    }
                    StorageManager.shared.saveImage(id: authorId, image: image)
                }
            }
        }
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .frame(width: UIScreen.main.bounds.width - 32)
                .foregroundStyle(Color(.secondarySystemBackground))
                .shadow(radius: 2)
            
            HStack {
                if isShimmering {
                    Circle()
                        .stroke(
                            Color(.label),
                            lineWidth: 0.1
                        )
                        .frame(width: 50, height: 50)
                        .foregroundStyle(Color(.systemBackground))
                } else if let avatarImage {
                    Image(uiImage: avatarImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                        .overlay {
                            Circle()
                                .stroke(
                                    Color(.label),
                                    lineWidth: 0.1
                                )
                        }
                }
                
                HStack(spacing: 0) {
                    Text(channel.authorName)
                        .font(.system(size: 21))
                        .fontWeight(.light)
                        .lineLimit(1)
                        .padding(.vertical, 20)
                    
                    if channel.isCheckmark {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(Color.blue)
                            .font(.footnote)
                            .padding(.top, 1)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 25))
                    .foregroundStyle(Color.gray)
            }
            .frame(width: UIScreen.main.bounds.width - 64, alignment: .leading)
        }
        .onAppear {
            getAvatar()
        }
        .overlay(EnableSwipeBack().frame(width: 0, height: 0))
    }
}
