//
//  LanguageSwitchTip.swift
//  ReadBox
//
//  Created by Macbook Pro on 11.07.2025.
//

import TipKit

struct LanguageSwitchTip: Tip {
    var title: Text {
        Text(NSLocalizedString("languageSwitchTipTitle", comment: ""))
    }
    
    var message: Text? {
        Text(NSLocalizedString("languageSwitchTipMessage", comment: ""))
    }
    
    var asset: Image? {
        Image(systemName: "magnifyingglass")
    }
}
