//
//  ImageProvider.swift
//  ReadBox
//
//  Created by Macbook Pro on 18.07.2025.
//

import SwiftUI
import MarkdownUI
import SDWebImageSwiftUI
import SwiftfulLoadingIndicators
import AVFoundation
import _AVKit_SwiftUI

extension ImageProvider where Self == WebImageProvider {
    static var webImage: Self {
        .init(onImageTap: { _ in })
    }
}

struct WebImageProvider: ImageProvider {
    let onImageTap: (URL) -> Void
    
    @State private var selectedImageURL: URL?
    @State private var isImageFullscreenPresented = false
    
    func makeImage(url: URL?) -> some View {
        if let url {
            if url.pathExtension.lowercased() == "mp4" {
                TappableVideoPreview(url: url, cornerRadius: 20)
            } else {
                WebImage(url: url) { image in
                    image.resizable()
                } placeholder: {
                    LoadingIndicator(
                        animation: .circleRunner,
                        color: Color(.label),
                        size: .small,
                        speed: .fast
                    )
                    .frame(width: UIScreen.main.bounds.width - 32, height: 200)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                .onSuccess { _, _, _ in
                    print("HERE: web image")
                }
                .onFailure(perform: { error in
                    print("HERE: \(error.localizedDescription)")
                })
                .onTapGesture {
                    onImageTap(url)
                }
                .transition(.fade(duration: 0.5))
                .scaledToFit()
                .frame(width: UIScreen.main.bounds.width - 32)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
        } else {
            EmptyView()
        }
    }
}

struct ResizeToFit: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
      guard let view = subviews.first else {
        return .zero
      }

      var size = view.sizeThatFits(.unspecified)

      if let width = proposal.width, size.width > width {
        let aspectRatio = size.width / size.height
        size.width = width
        size.height = width / aspectRatio
      }
      return size
    }

    func placeSubviews(
      in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()
    ) {
      guard let view = subviews.first else { return }
      view.place(at: bounds.origin, proposal: .init(bounds.size))
    }
}
