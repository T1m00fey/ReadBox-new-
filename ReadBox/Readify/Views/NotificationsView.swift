//
//  NotificationsView.swift
//  ReadBox
//
//  Created by Тимофей Юдин on 06.05.2026.
//

import SwiftUI
import PopupView
import Shimmer
import SwiftfulLoadingIndicators

struct NotificationsView: View {
    @ObservedObject var viewModel: NotificationsViewModel

    @EnvironmentObject var sessionManager: SessionManager
    @EnvironmentObject var changedPostsManager: ChangedPostsManager
    @EnvironmentObject var subManager: SubscriptionManager

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                if viewModel.isLoading {
                    ForEach(0..<8, id: \.self) { _ in
                        notificationPlaceholder
                    }
                } else if viewModel.notifications.isEmpty {
                    emptyView
                } else {
                    ForEach(viewModel.notifications) { notification in
                        NotificationRowView(
                            notification: notification,
                            actorInfo: viewModel.actorInfo[notification.actorId ?? ""],
                            articleTitle: viewModel.articleTitles[notification.postId ?? ""],
                            isShortPost: viewModel.postKinds[notification.postId ?? ""],
                            onAuthorTap: {
                                Task {
                                    await viewModel.openAuthorChannel(for: notification)
                                }
                            }
                        )
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            Task {
                                await viewModel.open(notification)
                            }
                        }

                        Divider()
                            .padding(.leading, 72)
                    }
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 8) {
                    Text(LocalizedStringKey("notificationLabel"))

                    if viewModel.isRefreshing {
                        LoadingIndicator(
                            animation: .circleRunner,
                            color: Color(uiColor: .label),
                            size: .small,
                            speed: .fast
                        )
                    }
                }
            }
        }
        .task {
            await viewModel.markNotificationsAsRead()
        }
        .onChange(of: viewModel.unreadCount) {
            guard viewModel.unreadCount > 0 else { return }

            Task {
                await viewModel.markNotificationsAsRead()
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
        .popup(isPresented: $viewModel.isErrorPopupPresented) {
            Text(viewModel.errorText)
                .frame(width: UIScreen.main.bounds.width - 72, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .foregroundStyle(Color.white)
                .background(Color.red)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(.top, 20)
        } customize: {
            $0
                .type(.floater())
                .position(.top)
                .animation(.bouncy)
                .dragToDismiss(true)
                .autohideIn(5)
                .displayMode(.overlay)
        }
        .navigationDestination(isPresented: $viewModel.isReadViewPresented) {
            ReadView(
                id: viewModel.prePost?.id ?? "",
                title: viewModel.prePost?.title ?? NSLocalizedString("notFoundLabel", comment: ""),
                text: viewModel.postToRead?.text ?? NSLocalizedString("notFoundLabel", comment: ""),
                dateCreated: viewModel.postToRead?.dateCreated ?? Date(),
                likesCount: viewModel.prePost?.likesCount ?? 0,
                authorId: viewModel.authorId,
                authorName: viewModel.actorInfo[viewModel.authorId]?.name ?? "",
                isCheckmark: viewModel.actorInfo[viewModel.authorId]?.isCheckmark ?? false,
                isArchive: viewModel.prePost?.isArchive ?? false,
                mediaCount: viewModel.prePost?.mediaCount ?? 0,
                mediaVersion: viewModel.prePost?.mediaVersion ?? 0,
                mediaPosition: viewModel.prePost?.mediaPosition ?? 0,
                lastVersionOfAvatar: viewModel.actorInfo[viewModel.authorId]?.avatarVersion ?? 0,
                articleLanguage: viewModel.prePost?.originalLanguage ?? "",
                isPremiumPost: viewModel.prePost?.isPremiumPost ?? false,
                user: $viewModel.user,
                isChannelViewPresented: $viewModel.isChannelViewPresented,
                isPresented: $viewModel.isReadViewPresented,
                isLocalizedVersion: viewModel.prePost?.isLocalizedVersion ?? false,
                rootId: viewModel.prePost?.rootId ?? ""
            )
            .environmentObject(sessionManager)
            .environmentObject(changedPostsManager)
            .environmentObject(subManager)
        }
        .navigationDestination(isPresented: $viewModel.isChannelViewPresented) {
            ChannelView(
                user: $viewModel.user,
                authorId: viewModel.authorId,
                authorName: viewModel.actorInfo[viewModel.authorId]?.name ?? "",
                isCheckmark: viewModel.actorInfo[viewModel.authorId]?.isCheckmark ?? false,
                lastVersionOfAvatar: viewModel.actorInfo[viewModel.authorId]?.avatarVersion ?? 0,
                isPremiumViewPresented: .constant(false)
            )
            .environmentObject(sessionManager)
            .environmentObject(changedPostsManager)
            .environmentObject(subManager)
        }
    }
}

private extension NotificationsView {
    var notificationPlaceholder: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 140, height: 14)

                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 12)

                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 180, height: 12)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .redacted(reason: .placeholder)
    }

    var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bell")
                .resizable()
                .scaledToFit()
                .frame(width: 90)
                .foregroundStyle(Color.gray)

            Text(LocalizedStringKey("noNotificationsLabel"))
                .font(.title3)
                .fontWeight(.semibold)
                .fontDesign(.rounded)
                .foregroundStyle(Color.gray)
                .multilineTextAlignment(.center)
        }
        .frame(height: UIScreen.main.bounds.height - 260)
    }
}

private struct NotificationRowView: View {
    let notification: PersonalNotificationItem
    let actorInfo: PostAuthorInfo?
    let articleTitle: String?
    let isShortPost: Bool?
    let onAuthorTap: () -> Void

    @State private var avatar: UIImage?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            avatarView
                .contentShape(Circle())
                .onTapGesture {
                    onAuthorTap()
                }

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .center, spacing: 8) {
                    HStack(alignment: .center, spacing: 0) {
                        if let name = actorInfo?.name, !name.isEmpty {
                            Text(name)
                                .font(.system(size: 16))
                                .fontWeight(.semibold)
                                .lineLimit(1)

                            if actorInfo?.isCheckmark == true {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundStyle(Color.blue)
                                    .font(.system(size: 13))
                            }
                        } else {
                            Text("Hello, world")
                                .font(.system(size: 16))
                                .fontWeight(.semibold)
                                .redacted(reason: .placeholder)
                                .shimmering()
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onAuthorTap()
                    }
                    .layoutPriority(1)

                    Spacer(minLength: 8)

                    Text(relativeDateString)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.gray)
                        .lineLimit(1)
                }

                Text(notificationText)
                    .font(.system(size: 15))
                    .foregroundStyle(Color(.label))
                    .multilineTextAlignment(.leading)

                if let articleTitle,
                   !articleTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(articleTitle)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.gray)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }

        }
        .task {
            await loadAvatar()
        }
    }
}

private extension NotificationRowView {
    var notificationText: String {
        switch notification.type {
        case .postLiked:
            return NSLocalizedString(
                isShortPost == true
                ? "notificationLikedPostLabel"
                : "notificationLikedArticleLabel",
                comment: ""
            )
        case .userSubscribed:
            return NSLocalizedString("notificationSubscribedLabel", comment: "")
        case .commentAdded:
            return NSLocalizedString(
                isShortPost == true
                ? "notificationCommentedPostLabel"
                : "notificationCommentedArticleLabel",
                comment: ""
            )
        case .commentReply:
            return NSLocalizedString("notificationCommentReplyLabel", comment: "")
        case .none:
            return ""
        }
    }

    var relativeDateString: String {
        guard let date = notification.dateCreated else { return "" }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    var avatarView: some View {
        Group {
            if let avatar {
                Image(uiImage: avatar)
                    .resizable()
                    .scaledToFill()
            } else {
                Circle()
                    .fill(Color(.secondarySystemBackground))
                    .overlay {
                        Image(systemName: "person.fill")
                            .foregroundStyle(Color.gray)
                    }
            }
        }
        .frame(width: 48, height: 48)
        .clipShape(Circle())
    }

    func loadAvatar() async {
        guard avatar == nil else { return }

        let actorId = notification.actorId ?? ""
        guard !actorId.isEmpty else { return }

        let avatarVersion: Int

        do {
            avatarVersion = try await UserManager.shared.resolveAvatarVersion(
                id: actorId,
                fallback: actorInfo?.avatarVersion
            )
        } catch {
            avatarVersion = actorInfo?.avatarVersion ?? 0
        }

        avatar = await MediaManager.shared.getAvatar(authorId: actorId, lastVersion: avatarVersion)
    }
}
