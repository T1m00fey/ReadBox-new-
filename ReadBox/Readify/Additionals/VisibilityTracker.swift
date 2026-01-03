//
//  VisibilityTracker.swift
//  ReadBox
//
//  Created by Тимофей Юдин on 27.11.2025.
//

import SwiftUI

struct VisibilityPreferenceKey: PreferenceKey {
    static var defaultValue: [String: CGFloat] = [:]
    static func reduce(value: inout [String: CGFloat], nextValue: () -> [String: CGFloat]) {
        value.merge(nextValue()) { $1 }
    }
}

struct VisibilityTracker: View {
    let id: String
    var body: some View {
        GeometryReader { proxy in
            let frame = proxy.frame(in: .named("readScroll"))
            Color.clear
                .preference(key: VisibilityPreferenceKey.self,
                            value: [id: frame.minY])
        }
        .frame(height: 0)
    }
}
