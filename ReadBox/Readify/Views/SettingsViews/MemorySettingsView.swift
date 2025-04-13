//
//  MemorySettingsView.swift
//  Readify
//
//  Created by Тимофей Юдин on 04.12.2024.
//

import SwiftUI

struct MemorySettingsView: View {
    func clearCache() {
        let userDefaults = UserDefaults.standard
        let dictionary = userDefaults.dictionaryRepresentation()
        
        for key in dictionary.keys {
            if key != "savedArticles" && key != "language"{
                userDefaults.removeObject(forKey: key)
            }
        }
        
        userDefaults.synchronize()
        
        successText = NSLocalizedString("cacheClearedAlert", comment: "")
        isSuccessPopupPresented = true
    }
    
    let sizeOfData: Double
    
    @Binding var successText: String
    @Binding var isSuccessPopupPresented: Bool
    
    var body: some View {
        VStack {
            Capsule()
                .frame(width: 25, height: 5)
                .foregroundStyle(Color.gray)
                .padding(.top, 5)
            
            Text(LocalizedStringKey("memorySettingsLabel"))
                .font(.title)
                .fontWeight(.light)
                .fontDesign(.rounded)
                .frame(width: UIScreen.main.bounds.width - 32, alignment: .leading)
            
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .foregroundStyle(Color(uiColor: .systemBackground))
                    .shadow(radius: 2)
                
                HStack {
                    Image(systemName: "archivebox")
                        .font(.system(size: 25))
                    
                    Text("\(NSLocalizedString("dataInMemoryLabel", comment: "")): \(Int(sizeOfData)) Mb")
                        .font(.title3)
                        .fontWeight(.light)
                        .fontDesign(.rounded)
                }
                .padding(.vertical, 5)
                .frame(width: UIScreen.main.bounds.width - 64, alignment: .leading)
            }
            .frame(width: UIScreen.main.bounds.width - 32, height: 60)
            
            Button {
                clearCache()
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .foregroundStyle(Color(uiColor: .systemBackground))
                        .shadow(radius: 2)
                    
                    HStack {
                        Image(systemName: "minus.circle")
                            .foregroundStyle(Color.red)
                            .font(.system(size: 25))
                        
                        Text(LocalizedStringKey("clearCacheButton"))
                            .font(.title3)
                            .fontWeight(.light)
                            .fontDesign(.rounded)
                            .foregroundStyle(Color.red)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.title2)
                            .foregroundStyle(Color.gray)
                            .padding(.trailing, 10)
                    }
                    .frame(width: UIScreen.main.bounds.width - 64)
                }
            }
            .frame(width: UIScreen.main.bounds.width - 32, height: 60)
            .padding(.bottom, 150)
            
        }
        .frame(width: UIScreen.main.bounds.width)
        .frame(minHeight: 100)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 30))
    }
}

#Preview {
    MemorySettingsView(sizeOfData: 100, successText: .constant(""), isSuccessPopupPresented: .constant(false))
}
