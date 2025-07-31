//
//  AuthorMediaListTip.swift
//  ReadBox
//
//  Created by Macbook Pro on 31.07.2025.
//

import TipKit

struct AuthorMediaListTip: Tip {
    var title: Text {
        Text(NSLocalizedString("mediaFilesListTipTitle", comment: ""))
    }
    
    var message: Text? {
        Text(NSLocalizedString("mediaFilesListTipMessage", comment: ""))
    }
    
    var asset: Image? {
        Image(systemName: "globe")
    }
}
