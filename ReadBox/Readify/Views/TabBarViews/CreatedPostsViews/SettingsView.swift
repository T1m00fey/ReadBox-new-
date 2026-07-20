//
//  SettingsView.swift
//  ReadBox
//
//  Created by Тимофей Юдин on 16.01.2026.
//

import SwiftUI
import FirebaseStorage
import PopupView
import SDWebImage
import SwiftUIMailView

final class SettingsViewModel: ObservableObject {
    @Published var avatarImage: UIImage?
    @Published var name = ""
    @Published var description = ""

    @Published var sizeOfData: Double = 0

    @Published var isSettingsLabelVisible = true

    @Published var isErrorPopupPresented = false
    @Published var errorText = ""

    @Published var isSuccessPopupPresented = false
    @Published var successText = ""

    @Published var isSignOutDialogPresented = false
//    @Published var isDeleteAccDialogPresented = false

    @Published var isNewPasswordViewPresented = false
    @Published var isFontSettingPopupPresented = false
    @Published var isMemoryPopupPresented = false
    @Published var isMailViewPresented = false

    @Published var isLoading = false
    @Published var fontSize = StorageManager.shared.getFontSize()

    @Published var mailData = ComposeMailData(
        subject: "To the developer",
         recipients: ["support@ireadbox.ru"],
         message: """
                    App: ReadBox
                    iOS: \(UIDevice.current.systemVersion)
                    _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _

                    Your question...
                """,
         attachments: []
    )

    @Published var privacyURL = URL(string: "https://readbox-links.online/privacy.html")
    @Published var termsURL = URL(string: "https://readbox-links.online/terms.html")

    var settingsTitles: [String] = [
        NSLocalizedString("passwordTFPlaceholder", comment: ""),
        NSLocalizedString("fontLabel", comment: ""),
        NSLocalizedString("memorySettingsLabel", comment: ""),
        NSLocalizedString("writeToDeveloperLabel", comment: ""),
        NSLocalizedString("privacyPolicy", comment: ""),
        NSLocalizedString("termsOfUse", comment: "")
    ]

    var settingsImages: [String] = [
        "lock",
        "book.pages",
        "brain.fill",
        "envelope",
        "document",
        "document"
    ]

    var settingsColors: [Color] = [
        .blue,
        .mint,
        .green,
        .orange,
        .gray,
        .gray
    ]

    func getTotalCacheSize() {
        var totalSize = 0

        let dictionary = UserDefaults.standard.dictionaryRepresentation()
        for (_, value) in dictionary {
            if let data = try? NSKeyedArchiver.archivedData(withRootObject: value, requiringSecureCoding: false) {
                totalSize += data.count
            }
        }

        SDImageCache.shared.calculateSize { _, sdSize in
            totalSize += Int(sdSize)

            let tmp = FileManager.default.temporaryDirectory
            let fileURLs = (try? FileManager.default.contentsOfDirectory(at: tmp, includingPropertiesForKeys: [.fileSizeKey])) ?? []

            for url in fileURLs where url.pathExtension == "mp4" {
                if let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    totalSize += size
                }
            }

            DispatchQueue.main.async {
                self.sizeOfData = Double(totalSize) / (1024 * 1024)
            }
        }
    }

    func changeAuthorName(withId authorId: String, to name: String, description: String) async throws {
        try await UserManager.shared.changeAuthorName(userId: authorId, to: name, description: description)
    }

    func removeCheckmarkStatus(toId id:String) async throws {
        try await UserManager.shared.removeCheckmarkStatus(userId: id)
    }

    func signOut(userId: String) async throws {
        try? await UserManager.shared.deleteFcmToken(from: userId)
        try AuthenticationManager.shared.signOut()

        let userDefaults = UserDefaults.standard
        let dictionary = userDefaults.dictionaryRepresentation()

        for key in dictionary.keys {
            if key != "language"
                && key != "fontSize"
                && key != "isNotificationsApproved"
                && key != "isNotificationsPopupPresented"
                && key != "fcmToken" {
                userDefaults.removeObject(forKey: key)
            }
        }

        await SDImageCache.shared.clear(with: .all)

        let tmp = FileManager.default.temporaryDirectory
        let fileURLs = try? FileManager.default.contentsOfDirectory(at: tmp, includingPropertiesForKeys: nil)
        fileURLs?.forEach { url in
            if url.pathExtension == "mp4" {
                try? FileManager.default.removeItem(at: url)
            }
        }

        userDefaults.synchronize()
    }

}

struct SettingsView: View {
    let authorId: String
    let email: String
    @Binding var lastVersionOfAvatar: Int
    @Binding var avatar: UIImage?
    @Binding var nameText: String
    @Binding var descriptionText: String
    @Binding var isScreenPresented: Bool
    @Binding var isWelcomeViewPresented: Bool

    @StateObject private var viewModel = SettingsViewModel()

    @Environment(\.openURL) var openURL

    func settingsListAction(_ id: Int) {
        switch id {
        case 0: viewModel.isNewPasswordViewPresented = true
        case 1: viewModel.isFontSettingPopupPresented = true
        case 2: viewModel.getTotalCacheSize(); viewModel.isMemoryPopupPresented = true
        case 3: viewModel.isMailViewPresented = true
        case 4: if let url = viewModel.privacyURL { openURL(url) }
        case 5: if let url = viewModel.termsURL { openURL(url) }
        default: break
        }
    }

    func update(withId userId: String) async throws {
        if viewModel.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            withAnimation {
                viewModel.errorText = NSLocalizedString("nameErrorLabel", comment: "")
                viewModel.isErrorPopupPresented = true
            }
        } else {
            withAnimation {
                viewModel.isLoading = true
            }

            VibrationsService.shared.lightImpact()

            let cacheKey = "avatar_\(userId)_\(lastVersionOfAvatar+1)"
            let lastCacheKey = "avatar_\(userId)_\(lastVersionOfAvatar)"

            if let ava = viewModel.avatarImage, avatar != viewModel.avatarImage {
                let resized = ava.resizedForAvatar(maxDimension: 512)
                guard let data = resized.jpegData(compressionQuality: 0.7) else { return }

                let ref = Storage.storage().reference().child("avatars/\(userId).jpg")
                _ = try await ref.putDataAsync(data)

                StorageManager.shared.saveImage(id: cacheKey, image: resized)
                StorageManager.shared.deleteImage(id: lastCacheKey)

                try await UserManager.shared.setAvatarVersion(id: userId, lastVersion: lastVersionOfAvatar)
                lastVersionOfAvatar += 1

                await MainActor.run {
                    avatar = resized
                }
            } else if viewModel.avatarImage == nil {
                let ref = Storage.storage().reference().child("avatars/\(userId).jpg")
                do {
                    try await ref.delete()
                    try await UserManager.shared.setAvatarVersion(id: userId, lastVersion: lastVersionOfAvatar)
                    lastVersionOfAvatar += 1
                    StorageManager.shared.deleteImage(id: lastCacheKey)
                } catch {
                    print("Ошибка при удалении аватара: \(error.localizedDescription)")
                }

                avatar = nil
            }

            let isNameChanged = nameText != viewModel.name
            let isDescriptionChanged = descriptionText != viewModel.description

            if isNameChanged || isDescriptionChanged {
                if isNameChanged {
                    try await viewModel.removeCheckmarkStatus(toId: authorId)
                }
                try await viewModel.changeAuthorName(
                    withId: authorId,
                    to: viewModel.name,
                    description: viewModel.description
                )

                nameText = viewModel.name
                descriptionText = viewModel.description
            }

            withAnimation {
                viewModel.isLoading = false
                isScreenPresented = false
            }
        }
    }

    func updateUser() {
        Task {
            do {
                try await update(withId: authorId)
            } catch {
                withAnimation {
                    viewModel.isErrorPopupPresented = true
                    viewModel.errorText = error.localizedDescription
                }
            }
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                Text(NSLocalizedString("settingsLabel", comment: ""))
                    .font(.system(size: 27))
                    .fontWeight(.light)
                    .fontDesign(.rounded)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)

                VisibilityTracker(id: "settingsLabel")

                AvatarControlView(authorId: authorId, avatarImage: $viewModel.avatarImage)

                SettingsTextFieldView(tfPlaceholder: NSLocalizedString("nameLabel", comment: ""), text: $viewModel.name)

                SettingsTextFieldView(tfPlaceholder: NSLocalizedString("descriptionLabel", comment: ""), text: $viewModel.description)
                    .padding(.top, 10)

                List {
                    ForEach(0..<viewModel.settingsTitles.count, id: \.self) { id in
                        Button {
                            settingsListAction(id)
                        } label: {
                            HStack {
                                Image(systemName: viewModel.settingsImages[id])
                                    .frame(width: 30, height: 30)
                                    .padding(.all, 5)
                                    .foregroundStyle(Color.white)
                                    .background(viewModel.settingsColors[id])
                                    .clipShape(Circle())

                                Text(viewModel.settingsTitles[id])
                                    .font(.system(size: 18))
                                    .padding(.leading, 10)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 18))
                                    .foregroundStyle(Color.gray)
                            }
                        }
                        .padding(.vertical, -5)
                        .listRowBackground(Color(.secondarySystemBackground))
                    }
                }
                .frame(minHeight: 500)
                .scrollContentBackground(.hidden)
            }
        }
        .onPreferenceChange(VisibilityPreferenceKey.self) { values in
            if let minY = values["settingsLabel"] {
                let isVisible = minY > 100

                if viewModel.isSettingsLabelVisible != isVisible {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.isSettingsLabelVisible = isVisible
                    }
                }
            }
        }
        .task {
            let ava = await MediaManager.shared.getAvatar(authorId: authorId, lastVersion: lastVersionOfAvatar)

            withAnimation {
                avatar = ava
            }
        }
        .onAppear {
            viewModel.avatarImage = avatar
            viewModel.name = nameText
            viewModel.description = descriptionText
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    isScreenPresented = false
                } label: {
                    Image(systemName: "arrow.left")
                }
            }

            ToolbarItem(placement: .topBarLeading) {
                Button {
                    viewModel.isSignOutDialogPresented = true
                } label: {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .foregroundStyle(Color.red)
                }
            }

            ToolbarItem(placement: .principal) {
                if !viewModel.isSettingsLabelVisible {
                    if #available(iOS 26, *) {
                        Text(NSLocalizedString("settingsLabel", comment: ""))
                            .padding()
                            .glassEffect(.regular)
                    } else {
                        Text(NSLocalizedString("settingsLabel", comment: ""))
                    }
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                if !viewModel.isLoading {
                    if #available(iOS 26, *) {
                        Button {
                            updateUser()
                        } label: {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color(.systemBackground))
                        }
                        .tint(Color(.label))
                        .buttonStyle(.glassProminent)
                    } else {
                        Button {
                            updateUser()
                        } label: {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color(.label))
                        }
                    }
                } else {
                    ProgressView()
                }
            }
        }
        .alert(
            LocalizedStringKey("signOutAlertTitle"),
            isPresented: $viewModel.isSignOutDialogPresented
        ) {
            Button(LocalizedStringKey("cancelButton"), role: .cancel) {}

            Button(LocalizedStringKey("signOutLabel"), role: .destructive) {
                Task {
                    do {
                        try await viewModel.signOut(userId: authorId)
                        isScreenPresented = false
                        isWelcomeViewPresented = true
                    } catch {
                        withAnimation {
                            viewModel.errorText = error.localizedDescription
                            viewModel.isErrorPopupPresented = true
                        }
                    }
                }
            }
        } message: {
            Text(LocalizedStringKey("signOutAlertMessage"))
        }
//        .confirmationDialog("", isPresented: $viewModel.isDeleteAccDialogPresented) {
//            Button(LocalizedStringKey("deleteLabel"), role: .destructive) {
//                Task {
//                    do {
//                        let user = DBUser(
//                            userId: authorId,
//                            name: nameText,
//                            email: email,
//                            authorDescription: descriptionText,
//                            avatarVersion: lastVersionOfAvatar
//                        )
//
//                        try await viewModel.deleteAccount(user: user)
//                        isScreenPresented = false
//                        isWelcomeViewPresented = true
//                    } catch {
//                        withAnimation {
//                            viewModel.errorText = error.localizedDescription
//                            viewModel.isErrorPopupPresented = true
//                        }
//                    }
//                }
//            }
//
//            Button(LocalizedStringKey("cancelButton"), role: .cancel) {}
//        } message: {
//            Text(LocalizedStringKey("youSureToDeleteAcc"))
//        }
        .navigationBarBackButtonHidden()
        .overlay(
            EnableSwipeBack().frame(width: 0, height: 0)
        )
        .popup(isPresented: $viewModel.isErrorPopupPresented) {
            Text(viewModel.errorText)
                .frame(width: UIScreen.main.bounds.width - 72, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .foregroundStyle(Color.white)
                .background(Color.red)
                .clipShape(RoundedRectangle(cornerRadius: 20))
        } customize: {
            $0
                .type(.floater())
                .position(.top)
                .animation(.bouncy)
                .dragToDismiss(true)
                .autohideIn(5)
                .displayMode(.overlay)
        }
        .popup(isPresented: $viewModel.isSuccessPopupPresented) {
            Text(viewModel.successText)
                .frame(width: UIScreen.main.bounds.width - 72, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .foregroundStyle(Color(.label))
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .foregroundStyle(Color(.systemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            Color.green, lineWidth: 1
                        )
                )
        } customize: {
            $0
                .type(.floater())
                .position(.top)
                .animation(.bouncy)
                .dragToDismiss(true)
                .autohideIn(5)
                .displayMode(.overlay)
        }
        .sheet(isPresented: $viewModel.isFontSettingPopupPresented, content: {
            FontSettingView(
                isPopupPresented: $viewModel.isFontSettingPopupPresented,
                selectedFontSize: $viewModel.fontSize,
                successText: $viewModel.successText,
                isSuccessPopupPresented: $viewModel.isSuccessPopupPresented
            )
            .presentationDetents([.height(300)])
            .presentationCornerRadius(30)
            .presentationDragIndicator(.visible)
        })
        .sheet(isPresented: $viewModel.isMemoryPopupPresented, content: {
            MemorySettingsView(
                sizeOfData: viewModel.sizeOfData,
                successText: $viewModel.successText,
                isSuccessPopupPresented: $viewModel.isSuccessPopupPresented
            )
            .presentationDetents([.height(300)])
            .presentationCornerRadius(30)
            .presentationDragIndicator(.visible)
        })
        .sheet(isPresented: $viewModel.isMailViewPresented, content: {
            MailView(data: $viewModel.mailData) { _ in }
        })
        .navigationDestination(isPresented: $viewModel.isNewPasswordViewPresented) {
            NewPasswordView(
                isSuccessPopupPresented: $viewModel.isSuccessPopupPresented,
                successText: $viewModel.successText,
                email: email
            )
        }
    }
}

fileprivate struct SettingsTextFieldView: View {
    let tfPlaceholder: String
    @Binding var text: String

    @FocusState var isTFFocused: Bool

    var body: some View {
        VStack {
            TextField(tfPlaceholder, text: $text)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .font(.system(size: 18))
                .focused($isTFFocused)
                .textInputAutocapitalization(.never)
                .tint(Color(.label))

            Capsule()
                .frame(maxWidth: .infinity)
                .frame(height: 3)
                .padding(.horizontal, 20)
                .foregroundStyle(isTFFocused ? Color(.label) : Color.gray)
        }
    }
}

//VStack {
//    ZStack {
//        RoundedRectangle(cornerRadius: 30)
//            .foregroundStyle(Color(uiColor: .secondarySystemBackground))
//            .frame(width: UIScreen.main.bounds.width - 60, height: 270)
//            .shadow(radius: 1)
//
//        VStack(spacing: 25) {
//            AvatarControlView(
//                authorId: viewModel.user?.userId ?? "",
//                avatarImage: $viewModel.avatarImage
//            )
//
//            VStack {
//                TextField(LocalizedStringKey("nameLabel"), text: $viewModel.name)
//                    .frame(width: UIScreen.main.bounds.width - 92)
//                    .font(.system(size: 20))
//                    .focused($isAuthorNameFocused)
//                    .textInputAutocapitalization(.never)
//                    .onChange(of: viewModel.name) {
//                        viewModel.isButtonEnable()
//                    }
//                    .tint(Color(uiColor: .label))
//
//                RoundedRectangle(cornerRadius: 0)
//                    .frame(width: UIScreen.main.bounds.width - 92, height: 2)
//                    .foregroundStyle(isAuthorNameFocused ? Color(uiColor: .label) : Color.gray)
//            }
//
//            VStack {
//                TextField(NSLocalizedString("descriptionLabel", comment: ""), text: $viewModel.description)
//                    .frame(width: UIScreen.main.bounds.width - 92)
//                    .font(.system(size: 20))
//                    .focused($isDescriptionFocused)
//                    .textInputAutocapitalization(.never)
//                    .tint(Color(uiColor: .label))
//
//                RoundedRectangle(cornerRadius: 0)
//                    .frame(width: UIScreen.main.bounds.width - 92, height: 2)
//                    .foregroundStyle(isDescriptionFocused ? Color(uiColor: .label) : Color.gray)
//            }
//        }
//        .padding(.vertical, 5)
//        .onAppear {
//            viewModel.isButtonEnable()
//        }
//    }
//
//    Button {
//        if viewModel.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
//            withAnimation {
//                viewModel.errorText = NSLocalizedString("nameErrorLabel", comment: "")
//                viewModel.isErrorPopupPresented = true
//            }
//        } else {
//            Task {
//                do {
//                    withAnimation {
//                        viewModel.isLoading = true
//                        viewModel.isButtonEnabled = false
//                    }
//
//                    viewModel.vibrationsService.softImpact()
//
//                    if let avatar = viewModel.avatarImage,
//                       let userId = viewModel.user?.userId {
//
//                        let resized = avatar.resizedForAvatar(maxDimension: 512)
//                        guard let data = resized.jpegData(compressionQuality: 0.7) else { return }
//
//                        let ref = Storage.storage().reference().child("avatars/\(userId).jpg")
//                        _ = try await ref.putDataAsync(data)
//
//                        StorageManager.shared.saveImage(id: userId, image: resized)
//                        await MainActor.run { viewModel.avatarImage = resized }
//                    } else {
//                        if let userId = viewModel.user?.userId {
//                            let ref = Storage.storage().reference().child("avatars/\(userId).jpg")
//                            do {
//                                try await ref.delete()
//                                StorageManager.shared.deleteImage(id: userId)
//                            } catch {
//                                print("Ошибка при удалении аватара: \(error.localizedDescription)")
//                            }
//                        }
//                    }
//
//                    if viewModel.user?.name != viewModel.name {
//                        try await viewModel.removeCheckmarkStatus()
//                    }
//                    try await viewModel.changeAuthorName(to: viewModel.name, description: viewModel.description)
//
//                    withAnimation {
//                        viewModel.isLoading = false
//                        viewModel.isSettingViewPresented = false
//                        viewModel.user?.name = viewModel.name
//                        viewModel.user?.authorDescription = viewModel.description
//                    }
//
//                    withAnimation {
//                        viewModel.isButtonEnabled = false
//                    }
//                } catch {
//                    withAnimation {
//                        viewModel.errorText = error.localizedDescription
//                        viewModel.isErrorPopupPresented = true
//                        viewModel.isLoading = false
//                        viewModel.isButtonEnabled = false
//                    }
//                }
//            }
//        }
//    } label: {
//        HStack {
//            Text(
//                viewModel.isLoading
//                ? LocalizedStringKey("shortNextLabel")
//                : LocalizedStringKey("nextLabel")
//            )
//                .foregroundStyle(
//                    viewModel.isButtonEnabled
//                    ? Color(uiColor: .label)
//                    : Color.gray
//                )
//
//            if viewModel.isLoading {
//                LoadingIndicator(
//                    animation: .circleRunner,
//                    color: Color(.label),
//                    size: .small,
//                    speed: .fast
//                )
//            }
//        }
//        .frame(width: UIScreen.main.bounds.width - 60, height: 50)
//        .background(Color(uiColor: .secondarySystemBackground))
//        .clipShape(RoundedRectangle(cornerRadius: 20))
//        .font(.system(size: 20))
//        .shadow(radius: viewModel.isButtonEnabled ? 1 : 0)
//    }
//    .disabled(!viewModel.isButtonEnabled)
//    .padding(.top, 10)
//}
