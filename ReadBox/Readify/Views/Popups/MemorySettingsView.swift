//
//  MemorySettingsView.swift
//  Readify
//
//  Created by Тимофей Юдин on 04.12.2024.
//

import SwiftUI
import SDWebImageSwiftUI

struct MemorySettingsView: View {
    let sizeOfData: Double
    
    @Binding var successText: String
    @Binding var isSuccessPopupPresented: Bool
    
    private func clearCache() {
        let userDefaults = UserDefaults.standard
        let dictionary = userDefaults.dictionaryRepresentation()
        
        for key in dictionary.keys {
            if key != "views"
                && key != "language"
                && key != "fontSize"
                && key != "isNotificationsApproved"
                && key != "isNotificationsPopupPresented" {
                userDefaults.removeObject(forKey: key)
            }
        }
        
        SDImageCache.shared.clear(with: .all)
        
        VideoCacheManager.shared.clear()
            
        let tmp = FileManager.default.temporaryDirectory
        let fileURLs = try? FileManager.default.contentsOfDirectory(at: tmp, includingPropertiesForKeys: nil)
        fileURLs?.forEach { url in
            if url.pathExtension == "mp4" {
                try? FileManager.default.removeItem(at: url)
            }
        }

        userDefaults.synchronize()
        
        successText = NSLocalizedString("cacheClearedAlert", comment: "")
        isSuccessPopupPresented = true
    }
    
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
