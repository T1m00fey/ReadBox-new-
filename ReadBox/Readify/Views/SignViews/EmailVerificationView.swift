//
//  EmailVerificationView.swift
//  ReadBox
//
//  Created by Macbook Pro on 30.09.2025.
//

import SwiftUI

final class EmailVerificationViewModel: ObservableObject {
    @Published var verificationCodeText = ""
    
    func char(at i: Int, in str: String) -> String {
        guard i >= 0 && i < str.count else { return "" }
        let id = str.index(str.startIndex, offsetBy: i)
        return String(str[id])
    }
}

struct EmailVerificationView: View {
    @StateObject private var viewModel = EmailVerificationViewModel()
    
    @FocusState private var isCodeTFFocused: Bool
    
    var body: some View {
        ZStack {            
            TextField("", text: $viewModel.verificationCodeText)
                .focused($isCodeTFFocused)
                .frame(width: 1, height: 1)
                .tint(Color(.systemBackground))
                .keyboardType(.numberPad)
            
            VStack {
                Text("Введите код 📩")
                    .font(.system(size: 27))
                    .fontDesign(.rounded)
                    .fontWeight(.light)
                    .frame(
                        width: UIScreen.main.bounds.width,
                        alignment: .center
                    )
                
                HStack(spacing: 10) {
                    ForEach(0..<6, id: \.self) { i in
                        makeCodeInputCell(index: i)
                            .onTapGesture {
                                isCodeTFFocused = true
                            }
                            .animation(.bouncy, value: viewModel.verificationCodeText)
                    }
                }
                
                Text("Отправить код заново")
                    .font(.system(size: 18))
                    .fontDesign(.rounded)
                    .foregroundStyle(Color.gray)
                    .padding(.top, 10)
            }
        }
        .onAppear {
            isCodeTFFocused = true
        }
        .ignoresSafeArea(.keyboard)
    }
}

private extension EmailVerificationView {
    @ViewBuilder
    func makeCodeInputCell(index: Int) -> some View {
        let text = viewModel.char(at: index, in: viewModel.verificationCodeText)
        
        Text(text)
            .font(.system(size: 23))
            .fontDesign(.rounded)
            .frame(width: 40, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        text.isEmpty ? Color.gray : Color(.label),
                        lineWidth: 1.5
                    )
            )
    }
}

#Preview {
    EmailVerificationView()
}
