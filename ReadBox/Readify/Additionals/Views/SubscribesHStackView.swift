//
//  SubscribesHStackView.swift
//  ReadBox
//
//  Created by Тимофей Юдин on 20.01.2026.
//

import SwiftUI
import Shimmer

struct SubscribesHStackView: View {
    @Binding var isLoading: Bool
    @Binding var channels: [ChannelInfo]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                if isLoading {
                    ForEach(0..<11) { _ in
                        SubscribeRow(channelInfo: nil, isLoading: true)
                    }
                } else {
                    ForEach(0..<channels.count, id: \.self) { id in
                        SubscribeRow(channelInfo: channels[id], isLoading: false)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
        }
    }
}

struct SubscribeRow: View {
    let channelInfo: ChannelInfo?
    let isLoading: Bool
    
    @State private var ava: UIImage? = nil
    
    var body: some View {
        VStack {
            if isLoading {
                Circle()
                    .frame(width: 70, height: 70)
                    .foregroundStyle(Color(.systemGray6))
                
                Text("HelloWorld")
                    .font(.system(size: 13))
                    .redacted(reason: .placeholder)
                    .shimmering()
            } else {
                if let ava {
                    Image(uiImage: ava)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 70, height: 70)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(
                                    Color(.label),
                                    lineWidth: 0.1
                                )
                        )
                } else {
                    Image(systemName: "person.fill")
                        .resizable()
                        .scaledToFit()
                        .padding()
                        .frame(width: 70, height: 70)
                        .foregroundStyle(Color(.systemGray6))
                        .background(
                            Circle()
                                .foregroundStyle(Color(.systemGray5))
                        )
                }
                
                Text(channelInfo?.name ?? NSLocalizedString("notFoundLabel", comment: ""))
                    .font(.system(size: 13))
                    .multilineTextAlignment(.center)
                    .onAppear {
                        if let channelInfo {
                            Task {
                                let avatar = await MediaManager.shared.getAvatar(
                                    authorId: channelInfo.id,
                                    lastVersion: channelInfo.avatarVersion ?? 0
                                )
                                
                                withAnimation {
                                    ava = avatar
                                }
                            }
                        }
                    }
            }
        }
        .frame(width: 80, height: 150, alignment: .top)
    }
}
