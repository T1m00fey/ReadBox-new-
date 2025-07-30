//
//  SubscribesViewModel.swift
//  ReadBox
//
//  Created by Macbook Pro on 30.07.2025.
//

import SwiftUI
import FirebaseStorage

struct Channel {
    let authorId: String
    let authorName: String
    let isCheckmark: Bool
}

@MainActor
final class SubscribesViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var channels: [Channel] = []
    
    @Published var isChannelViewPresented = false
    @Published var isReadViewPresented = false
    
    @Published var errorText = ""
    @Published var isErrorPopupPresented = false
    
    @Published var postToView: PrePost? = nil
    @Published var postToRead: PostToRead? = nil
    
    @Published var selectedChannel: Channel? = nil
    
    func getChannels(_ authorIds: [String]) async throws {
        withAnimation {
            isLoading = true
        }
        defer {
            withAnimation {
                isLoading = false
            }
        }
        
        for id in authorIds {
            let authorName = try await UserManager.shared.getAuthorName(id: id)
            let isCheckmark = try await UserManager.shared.getIsCheckmarkStatus(id: id)
            
            if let authorName, let isCheckmark {
                withAnimation {
                    self.channels.append(
                        Channel(
                            authorId: id,
                            authorName: authorName,
                            isCheckmark: isCheckmark
                        )
                    )
                }
            }
        }
    }
}
