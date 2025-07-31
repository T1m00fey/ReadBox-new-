//
//  AuthorFileAttachTip.swift
//  ReadBox
//
//  Created by Macbook Pro on 31.07.2025.
//

import TipKit

struct AuthorFileAttachTip: Tip {
    var title: Text {
        Text(NSLocalizedString("attachingFilesTitleTip", comment: ""))
    }
    
    var message: Text? {
        Text(NSLocalizedString("attachingFilesMessageTip", comment: ""))
    }
    
    var asset: Image? {
        Image(systemName: "photo.on.rectangle.angled")
    }
}
