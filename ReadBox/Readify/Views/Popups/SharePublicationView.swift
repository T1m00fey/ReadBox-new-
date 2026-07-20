//
//  SharePublicationView.swift
//  ReadBox
//
//  Created by Тимофей Юдин on 06.07.2026.
//

import Photos
import SwiftUI

struct SharePublicationView: View {
    let articleView: ArticleView
    let url: URL

    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    @Environment(\.colorScheme) private var colorScheme

    @State private var statusText = ""
    @State private var contentSize = CGSize(
        width: UIScreen.main.bounds.width - 10,
        height: UIScreen.main.bounds.height
    )
    @State private var selectedDetent: PresentationDetent = .height(
        UIScreen.main.bounds.height - 100
    )

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 0) {
                Spacer(minLength: 0)

                ZStack(alignment: .topLeading) {
                    getExportContent(isPreview: true)
                        .fixedSize(horizontal: true, vertical: true)
                        .scaleEffect(previewScale, anchor: .topLeading)
                        .allowsHitTesting(false)
                }
                .frame(
                    width: contentSize.width * previewScale,
                    height: previewHeight,
                    alignment: .topLeading
                )

                Spacer(minLength: 0)
            }

            HStack(spacing: 12) {
                actionButton(
                    title: NSLocalizedString("saveLabel", comment: ""),
                    icon: "square.and.arrow.down",
                    action: saveImage
                )

                actionButton(
                    title: NSLocalizedString("copyLinkLabel", comment: ""),
                    icon: "link"
                ) {
                    UIPasteboard.general.url = url
                    withAnimation(.easeInOut(duration: 0.2)) {
                        statusText = NSLocalizedString("linkCopiedLabel", comment: "")
                    }
                    VibrationsService.shared.successFeedback()
                }

                ShareLink(item: url) {
                    actionButtonLabel(
                        title: NSLocalizedString("shareLabel", comment: ""),
                        icon: "arrowshape.turn.up.right"
                    )
                }
                .buttonStyle(.plain)
            }

            if !statusText.isEmpty {
                Text(statusText)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.gray)
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 10)
        .presentationDetents(
            [.height(popupHeight)],
            selection: $selectedDetent
        )
        .onChange(of: popupHeight) {
            selectedDetent = .height(popupHeight)
        }
        .onAppear {
            let renderer = ImageRenderer(content: getExportContent(isPreview: true))
            renderer.scale = 1

            if let image = renderer.uiImage {
                contentSize = image.size
            }
        }
    }
}

private extension SharePublicationView {
    var previewScale: CGFloat {
        min(
            1,
            max(UIScreen.main.bounds.height - 220, 220) / max(contentSize.height, 1)
        )
    }

    var previewHeight: CGFloat {
        max(contentSize.height * previewScale, 120)
    }

    var popupHeight: CGFloat {
        min(
            max(previewHeight + 120 + (statusText.isEmpty ? 0 : 30), 260),
            UIScreen.main.bounds.height - 100
        )
    }
    
    func getExportContent(isPreview: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            if !isPreview {
                ReadBoxTitleView()
            }

            articleView
                .environmentObject(subscriptionManager)
                .background {
                    if !isPreview {
                        RoundedRectangle(cornerRadius: 23)
                            .fill(
                                colorScheme == .dark
                                ? Color(red: 0.08, green: 0.08, blue: 0.085)
                                : Color(red: 0.975, green: 0.975, blue: 0.98)
                            )
                            .shadow(
                                color: Color.black.opacity(0.10),
                                radius: 14,
                                x: 0,
                                y: 7
                            )
                    }
                }
        }
        .padding(.horizontal, isPreview ? 0 : 16)
        .padding(.top, isPreview ? 8 : 24)
        .padding(.bottom, isPreview ? 0 : 28)
        .background {
            if isPreview {
                Color.clear
            } else {
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(
                            color: Color(uiColor: .secondarySystemBackground),
                            location: 0
                        ),
                        .init(
                            color: Color(uiColor: .systemGray6),
                            location: 0.45
                        ),
                        .init(
                            color: Color(uiColor: .tertiarySystemBackground),
                            location: 0.75
                        ),
                        .init(
                            color: Color(uiColor: .secondarySystemBackground),
                            location: 1
                        )
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }

    func actionButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            actionButtonLabel(title: title, icon: icon)
        }
        .buttonStyle(.plain)
    }

    func actionButtonLabel(title: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .frame(width: 60, height: 60)
                .foregroundStyle(Color(uiColor: .systemBackground))
                .background(Color(uiColor: .label))
                .clipShape(Circle())

            Text(title)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(Color(.label))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    @MainActor
    func saveImage() {
        let renderer = ImageRenderer(content: getExportContent())
        renderer.scale = 3

        guard let image = renderer.uiImage else { return }

        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                Task { @MainActor in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        statusText = NSLocalizedString("photoAccessErrorLabel", comment: "")
                    }
                }
                return
            }

            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { success, _ in
                Task { @MainActor in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        statusText = success
                            ? NSLocalizedString("imageSavedLabel", comment: "")
                            : NSLocalizedString("saveImageErrorLabel", comment: "")
                    }

                    if success {
                        VibrationsService.shared.successFeedback()
                    }
                }
            }
        }
    }
}
