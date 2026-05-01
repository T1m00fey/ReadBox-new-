//
//  CommentView.swift
//  ReadBox
//
//  Created by Тимофей Юдин on 22.04.2026.
//

import SwiftUI
import UIKit

struct CommentView: View {
    let id: String
    let authorId: String
    let text: String
    let dateCreated: Date?
    let likesCount: Int
    let authorName: String
    let isCheckmark: Bool
    let avatarImage: UIImage?
    let onAuthorTap: (String) -> Void

    init(
        id: String,
        authorId: String,
        text: String,
        dateCreated: Date? = nil,
        likesCount: Int,
        authorName: String = "",
        isCheckmark: Bool = false,
        avatarImage: UIImage? = nil,
        onAuthorTap: @escaping (String) -> Void = { _ in }
    ) {
        self.id = id
        self.authorId = authorId
        self.text = text
        self.dateCreated = dateCreated
        self.likesCount = likesCount
        self.authorName = authorName
        self.isCheckmark = isCheckmark
        self.avatarImage = avatarImage
        self.onAuthorTap = onAuthorTap
    }

    var body: some View {
        VStack {
            HStack {
                avatarView
                    .frame(maxHeight: .infinity, alignment: .top)

                VStack(spacing: 2) {
                    HStack(spacing: 2) {
                        Text(displayedAuthorName)
                            .font(.system(size: 15))
                            .lineLimit(1)
                            .fontWeight(.semibold)

                        if isCheckmark {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(Color.blue)
                                .font(.system(size: 12))
                                .padding(.top, 1)
                        }
                        
                        Text("·")
                            .foregroundStyle(Color.gray)
                            .font(.system(size: 15))
                        
                        Text(relativeDateText)
                            .foregroundStyle(Color.gray)
                            .font(.system(size: 12))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(text)
                        .font(.system(size: 15))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onAuthorTap(authorId)
            }

            HStack {
                HStack(spacing: 2) {
                    Image(systemName: "heart")
                        .foregroundStyle(Color.gray)
                        .font(.system(size: 16))

                    Text("\(likesCount)")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.gray)
                }
                .padding(.leading, 47)

                Spacer()
            }
            .padding(.top, 2)

            Divider()
                .frame(width: UIScreen.main.bounds.width)

        }
        .frame(width: UIScreen.main.bounds.width - 20)
    }
}

private extension CommentView {
    @ViewBuilder
    var avatarView: some View {
        if let avatarImage {
            Image(uiImage: avatarImage)
                .resizable()
                .scaledToFill()
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .stroke(Color(.label), lineWidth: 0.1)
                }
        } else {
            Circle()
                .foregroundStyle(Color(.secondarySystemBackground))
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: "person.fill")
                        .foregroundStyle(Color.gray)
                        .font(.system(size: 16))
                }
        }
    }

    var displayedAuthorName: String {
        authorName.isEmpty ? NSLocalizedString("notFoundLabel", comment: "") : authorName
    }

    var relativeDateText: String {
        guard let dateCreated else { return "" }

        let seconds = max(0, Int(Date().timeIntervalSince(dateCreated)))
        let minute = 60
        let hour = 60 * minute
        let day = 24 * hour
        let month = 31 * day
        let year = 365 * day

        if seconds < minute {
            return NSLocalizedString("justNowLabel", comment: "")
        } else if seconds < hour {
            return relativeDate(value: max(1, seconds / minute), ruForms: ("минуту", "минуты", "минут"), enUnit: "minute")
        } else if seconds < day {
            return relativeDate(value: seconds / hour, ruForms: ("час", "часа", "часов"), enUnit: "hour")
        } else if seconds < month {
            return relativeDate(value: seconds / day, ruForms: ("день", "дня", "дней"), enUnit: "day")
        } else if seconds < year {
            return relativeDate(value: max(1, seconds / month), ruForms: ("месяц", "месяца", "месяцев"), enUnit: "month")
        }

        return relativeDate(value: max(1, seconds / year), ruForms: ("год", "года", "лет"), enUnit: "year")
    }

    var isRussianLanguage: Bool {
        StorageManager.shared.getLanguage() == "ru"
    }

    func relativeDate(value: Int, ruForms: (one: String, few: String, many: String), enUnit: String) -> String {
        if isRussianLanguage {
            return "\(value) \(russianPlural(value, one: ruForms.one, few: ruForms.few, many: ruForms.many)) назад"
        }

        return "\(value) \(enUnit)\(value == 1 ? "" : "s") ago"
    }

    func russianPlural(_ value: Int, one: String, few: String, many: String) -> String {
        let mod100 = value % 100
        let mod10 = value % 10

        if (11...14).contains(mod100) {
            return many
        } else if mod10 == 1 {
            return one
        } else if (2...4).contains(mod10) {
            return few
        } else {
            return many
        }
    }

}

#Preview {
    CommentView(
        id: "",
        authorId: "",
        text: "TestTestTestTestTestTestTestTestTestTestTestTestTestTestTestTestTestTestTestTest",
        dateCreated: Date(),
        likesCount: 100
    )
}
