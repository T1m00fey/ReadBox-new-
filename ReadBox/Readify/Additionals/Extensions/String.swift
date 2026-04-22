//
//  String.swift
//  ReadBox
//
//  Created by Тимофей Юдин on 28.06.2025.
//

import Foundation

extension String {
    var markdownAttributedStringPreservingLineBreaks: AttributedString {
        (try? AttributedString(
            markdown: self,
            options: AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .inlineOnlyPreservingWhitespace
            )
        )) ?? AttributedString(self)
    }

    func normalizeEmptyLines() -> String {
        let lines = self.components(separatedBy: "\n")
        return lines.map { line in
            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                return "\n![]()\n"
            } else {
                return line
            }
        }.joined(separator: "\n")
    }

    var normalizedPublicationPlainText: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
