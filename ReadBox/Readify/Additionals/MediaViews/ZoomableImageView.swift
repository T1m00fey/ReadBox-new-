//
//  ZoomableImageView.swift
//  ReadBox
//
//  Created by Macbook Pro on 27.07.2025.
//

import SwiftUI
import SDWebImageSwiftUI

struct ZoomableImageView: View {
    let imageURL: URL
    @Environment(\.dismiss) private var dismiss

    @State private var scale: CGFloat = 1
    @GestureState private var gestureScale: CGFloat = 1

    @State private var offset: CGSize = .zero
    @GestureState private var gestureOffset: CGSize = .zero

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let containerSize = geo.size

                ZStack {
                    Color(.systemBackground)
                        .ignoresSafeArea()

                    WebImage(url: imageURL)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(effectiveScale)
                        .offset(x: limitedOffsetX(in: containerSize),
                                y: limitedOffsetY(in: containerSize))
                        .gesture(
                            MagnificationGesture()
                                .updating($gestureScale) { value, state, _ in
                                    state = value
                                }
                                .onEnded { value in
                                    scale = max(1.0, scale * value)
                                }
                        )
                        .simultaneousGesture(
                            DragGesture()
                                .updating($gestureOffset) { value, state, _ in
                                    if effectiveScale > 1 {
                                        state = value.translation
                                    }
                                }
                                .onEnded { value in
                                    if effectiveScale > 1 {
                                        offset.width += value.translation.width
                                        offset.height += value.translation.height
                                    } else {
                                        offset = .zero
                                    }
                                }
                        )
                        .onTapGesture(count: 2) {
                            withAnimation {
                                if scale > 1 {
                                    scale = 1
                                    offset = .zero
                                } else {
                                    scale = 2.5
                                }
                            }
                        }                        
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Image(systemName: "xmark")
                        .foregroundStyle(Color(.label))
                        .onTapGesture {
                            dismiss()
                        }
                }
            }
        }
    }

    private var effectiveScale: CGFloat {
        scale * gestureScale
    }

    private func limitedOffsetX(in container: CGSize) -> CGFloat {
        let scaledWidth = container.width * effectiveScale
        let maxOffsetX = max((scaledWidth - container.width) / 2, 0)

        let combinedX = offset.width + gestureOffset.width
        return clamp(combinedX, -maxOffsetX, maxOffsetX)
    }

    private func limitedOffsetY(in container: CGSize) -> CGFloat {
        let scaledHeight = container.height * effectiveScale
        let maxOffsetY = max((scaledHeight - container.height) / 2, 0)

        let combinedY = offset.height + gestureOffset.height
        return clamp(combinedY, -maxOffsetY, maxOffsetY)
    }

    private func clamp(_ value: CGFloat, _ min: CGFloat, _ max: CGFloat) -> CGFloat {
        Swift.max(min, Swift.min(value, max))
    }
}

struct SizeReader: ViewModifier {
    @Binding var size: CGSize

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .preference(key: SizePreferenceKey.self, value: proxy.size)
                }
            )
            .onPreferenceChange(SizePreferenceKey.self) { size = $0 }
    }

    private struct SizePreferenceKey: PreferenceKey {
        static var defaultValue: CGSize = .zero
        static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
            value = nextValue()
        }
    }
}
