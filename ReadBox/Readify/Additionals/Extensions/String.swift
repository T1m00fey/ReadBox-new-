//
//  String.swift
//  ReadBox
//
//  Created by Тимофей Юдин on 28.06.2025.
//

import Foundation

extension String {
    func normalizeEmptyLines() -> String {
        let lines = self.components(separatedBy: "\n")
        return lines.map { line in
            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                return "&nbsp;\n"
            } else {
                return line
            }
        }.joined(separator: "\n")
    }
}
