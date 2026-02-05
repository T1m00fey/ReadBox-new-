//
//  SubscribesView.swift
//  ReadBox
//
//  Created by Тимофей Юдин on 20.01.2026.
//

import SwiftUI
import Shimmer
import SwiftfulLoadingIndicators
import FirebaseFirestore

@MainActor
final class SubscribesViewModel: ObservableObject {
    @Published var isLoading = true
    @Published var channels: [ChannelInfo] = []
    @Published var user: DBUser?

    private let db = Firestore.firestore()
    private let inQueryLimit = 30

    func loadUser() async throws {
        let auth = try AuthenticationManager.shared.getAuthenticatedUser()
        self.user = try await UserManager.shared.getUser(userId: auth.uid)
    }

    func getChannels() async throws {
        let ids = user?.subscribes ?? []
        guard !ids.isEmpty else {
            channels = []
            return
        }

        let chunks: [[String]] = stride(from: 0, to: ids.count, by: inQueryLimit).map { start in
            Array(ids[start..<min(start + inQueryLimit, ids.count)])
        }

        let docs: [QueryDocumentSnapshot] = try await withThrowingTaskGroup(of: [QueryDocumentSnapshot].self) { group in
            for chunk in chunks {
                group.addTask { [db] in
                    let snap = try await db.collection("users")
                        .whereField("id", in: chunk)
                        .getDocuments()
                    return snap.documents
                }
            }

            var all: [QueryDocumentSnapshot] = []
            for try await part in group {
                all.append(contentsOf: part)
            }
            return all
        }

        var channels = docs.compactMap { ChannelInfo(document: $0) }

        let order = Dictionary(uniqueKeysWithValues: ids.enumerated().map { ($0.element, $0.offset) })
        channels.sort { (order[$0.id] ?? .max) < (order[$1.id] ?? .max) }

        withAnimation {
            self.channels = channels
        }
    }
}

struct SubscribesView: View {
    @StateObject private var viewModel = SubscribesViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    
                    headerView
                        .padding(.top, 10)
                    
                    SubscribesHStackView(isLoading: $viewModel.isLoading, channels: $viewModel.channels)
                    
                }
            }
            .onAppear {
                Task {
                    do {
                        try await viewModel.loadUser()
                        
                        if let subscribes = viewModel.user?.subscribes, !subscribes.isEmpty {
                            try await viewModel.getChannels()
                            
                            withAnimation {
                                viewModel.isLoading = false
                            }
                        }
                    } catch {
                        print("error")
                    }
                }
            }
        }
    }
}

private extension SubscribesView {
    var headerView: some View {
        HStack(spacing: 5) {
            Text("Подписки")
                .font(.system(size: 27))
                .fontWeight(.light)
                .fontDesign(.rounded)
            
            if viewModel.isLoading {
                LoadingIndicator(
                    animation: .circleRunner,
                    color: Color(.label),
                    size: .small,
                    speed: .fast
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
    }
}

#Preview {
    SubscribesView()
}
