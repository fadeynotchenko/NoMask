//
//  LoginView.swift
//  Memories
//
//  Created by Fadey Notchenko on 03.10.2022.
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject private var loginViewModel: LoginViewModel
    
    var body: some View {
        GeometryReader { proxy in
            
            let width = proxy.size.width
            
            ZStack {
                Color("Background").edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 15) {
                    Spacer()
                    
                    Title(text: "welcome")
                        .padding()
                    
                    Text("welcometext")
                        .bold()
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    
                    Spacer()
                    
                    SignInWithAppleButton { req in
                        loginViewModel.nonce = randomNonceString()
                        req.requestedScopes = [.fullName]
                        req.nonce = sha256(loginViewModel.nonce)
                        
                    } onCompletion: { res in
                        switch res {
                            
                        case .success(let user):
                            guard let credential = user.credential as? ASAuthorizationAppleIDCredential else { return }
                            
                            loginViewModel.auth(credential: credential)
                        case .failure(let err):
                            print(err.localizedDescription)
                            break
                        }
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(width: width - 100, height: 55)
                    .cornerRadius(15)
                    
                    Text("welcometext2")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                }
                .padding(.bottom)
            }
        }
    }
}

