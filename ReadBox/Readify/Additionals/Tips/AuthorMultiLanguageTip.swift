//
//  AuthorMultiLanguageTip.swift
//  ReadBox
//
//  Created by Macbook Pro on 11.07.2025.
//

import TipKit

struct AuthorMultiLanguageTip: Tip {
    var title: Text {
        Text(NSLocalizedString("authorMultiLanguageTipTitle", comment: ""))
    }
    
    var message: Text? {
        Text(NSLocalizedString("authorMultiLanguageTipMessage", comment: ""))
    }
    
    var asset: Image? {
        Image(systemName: "globe")
    }
}
