//
//  UISegmentedControl.swift
//  ReadBox
//
//  Created by Macbook Pro on 11.07.2025.
//

import UIKit

extension UISegmentedControl {
    override open func didMoveToSuperview() {
        super.didMoveToSuperview()
        self.setContentHuggingPriority(.defaultLow, for: .vertical)
    }
}
