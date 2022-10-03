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
                    
                    Title(text: "Добро пожаловать!")
                        .padding()
                    
                    Text("'Мои Воспоминания' - место, куда Вы можете сохранять свои лучшие моменты жизни")
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
                        case .failure(_):
                            break
                        }
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(width: width - 100, height: 55)
                    .cornerRadius(15)
                    
                    Text("Для доступа в приложение требуется авторизация через Apple ID")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                }
                .padding(.bottom)
            }
        }
    }
}

