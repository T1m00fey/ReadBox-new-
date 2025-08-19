//
//  WelcomeView.swift
//  ReadBox
//
//  Created by Macbook Pro on 19.08.2025.
//

import SwiftUI

struct WelcomeView: View {
    @Binding var isSignInViewPreseted: Bool
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                
                VStack(spacing: 1) {
                    Text("ReadBox")
                        .font(.system(size: 32))
                        .fontWeight(.light)
                        .fontDesign(.rounded)
                        .frame(width: UIScreen.main.bounds.width - 40, alignment: .leading)
                    
                    Text(NSLocalizedString("welcomeLabel", comment: ""))
                        .font(.system(size: 28))
                        .fontWeight(.light)
                        .fontDesign(.rounded)
                        .frame(width: UIScreen.main.bounds.width - 40, alignment: .leading)
                }
                
                Spacer()
                
                VStack(spacing: 15) {
                    NavigationLink {
                        SignInView(isWelcomeViewPresented: $isSignInViewPreseted)
                    } label: {
                        Text(NSLocalizedString("signInLabel", comment: ""))
                            .font(.system(size: 24))
                            .fontWeight(.light)
                            .fontDesign(.rounded)
                            .frame(width: UIScreen.main.bounds.width - 40)
                            .padding(.vertical, 10)
                            .foregroundStyle(Color(.systemBackground))
                            .background(
                                Capsule()
                                    .foregroundStyle(Color(.label))
                                    .shadow(radius: 1)
                            )
                    }

                    
                    NavigationLink {
                        SignUpView(isWelcomeViewPresented: $isSignInViewPreseted)
                    } label: {
                        Text(NSLocalizedString("signUpLabel", comment: ""))
                            .font(.system(size: 24))
                            .fontWeight(.light)
                            .fontDesign(.rounded)
                            .frame(width: UIScreen.main.bounds.width - 40)
                            .padding(.vertical, 10)
                            .foregroundStyle(Color(.label))
                            .background(
                                Capsule()
                                    .foregroundStyle(Color(.secondarySystemBackground))
                                    .shadow(radius: 1)
                            )
                    }
                }
                .padding(.bottom, 50)
            }
            .navigationBarBackButtonHidden()
        }
    }
}
