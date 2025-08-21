//
//  ScreenVisibility.swift
//  ReadBox
//
//  Created by Macbook Pro on 21.08.2025.
//

import SwiftUI

private struct ScreenVisibilityKey: PreferenceKey {
    static var defaultValue: [UUID: CGRect] = [:]
    static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

private struct ScreenVisibilityModifier: ViewModifier {
    let id = UUID()
    let threshold: CGFloat
    let onChange: (Bool) -> Void
    @State private var lastVisible: Bool = true

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .preference(key: ScreenVisibilityKey.self,
                                    value: [id: proxy.frame(in: .global)])
                }
            )
            .onPreferenceChange(ScreenVisibilityKey.self) { map in
                guard let rect = map[id], rect.height > 0, rect.width > 0 else { return }
                let screen = UIScreen.main.bounds
                let inter = screen.intersection(rect)
                let visibleArea = max(0, inter.width) * max(0, inter.height)
                let totalArea = rect.width * rect.height
                let ratio = visibleArea / max(1, totalArea)
                let isVisible = ratio > threshold
                if isVisible != lastVisible {
                    lastVisible = isVisible
                    onChange(isVisible)
                }
            }
    }
}

extension View {
    func onScreenVisibility(threshold: CGFloat = 0.25,
                            _ onChange: @escaping (Bool) -> Void) -> some View {
        modifier(ScreenVisibilityModifier(threshold: threshold, onChange: onChange))
    }
}
