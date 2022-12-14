//
//  LoginView.swift
//  Memories
//
//  Created by Fadey Notchenko on 03.10.2022.
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    
    @EnvironmentObject private var memoryViewModel: ViewModel
    @EnvironmentObject private var loginViewModel: LoginViewModel
    
    var body: some View {
        ZStack {
            Color("Background").edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 15) {
                Spacer()
                
                Title(text: "welcome1")
                    .padding()
                
                Text("welcome2")
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
                .frame(width: Constants.width - 80, height: 55)
                .cornerRadius(15)
                
                Text("appleid")
                    .multilineTextAlignment(.leading)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                Link("privacy", destination: URL(string: "https://appnomask.com/Privasy.html")!)
                    .font(.system(size: 13))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading)
                
                Link("eula", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                    .font(.system(size: 13))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading)
            }
            .padding(.bottom)
        }
    }
}

