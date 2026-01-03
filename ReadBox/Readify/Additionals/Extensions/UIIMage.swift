//
//  UIIMage.swift
//  ReadBox
//
//  Created by Тимофей Юдин on 06.12.2025.
//

import UIKit

extension UIImage {
    func resizedForFeed(maxDimension: CGFloat = 1600) -> UIImage {
        let maxSide = max(size.width, size.height)
        guard maxSide > maxDimension else { return self }
        
        let scale = maxDimension / maxSide
        let newSize = CGSize(width: size.width * scale,
                             height: size.height * scale)
        
        UIGraphicsBeginImageContextWithOptions(newSize, true, 1.0)
        defer { UIGraphicsEndImageContext() }
        
        draw(in: CGRect(origin: .zero, size: newSize))
        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
}
