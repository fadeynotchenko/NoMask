//
//  LoginView.swift
//  Memories
//
//  Created by Fadey Notchenko on 03.10.2022.
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    
    @EnvironmentObject private var memoryViewModel: MemoryViewModel
    @EnvironmentObject private var loginViewModel: LoginViewModel
    
    var body: some View {
        GeometryReader { proxy in
            
            let width = proxy.size.width
            
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
                    .frame(width: width - 100, height: 55)
                    .cornerRadius(15)
                    
                    Text("appleid")
                        .multilineTextAlignment(.leading)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    Link("privacy", destination: URL(string: "https://mymemoriesapp.com/Privacy/Privacy.html")!)
                        .font(.system(size: 13))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading)
                    
                    Link("eula", destination: URL(string: "https://mymemoriesapp.com/Privacy/Privacy.html")!)
                        .font(.system(size: 13))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading)
                }
                .padding(.bottom)
            }
        }
    }
}

