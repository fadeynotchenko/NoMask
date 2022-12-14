//
//  LoginViewModel.swift
//  Memories
//
//  Created by Fadey Notchenko on 03.10.2022.
//

import Foundation
import CryptoKit
import AuthenticationServices
import Firebase
import SwiftUI

class LoginViewModel: ObservableObject {
    
    @Published var nonce = ""
    
    func auth(credential: ASAuthorizationAppleIDCredential) {
        guard let token = credential.identityToken else  { return }
        guard let tokenString = String(data: token, encoding: .utf8) else { return }
        
        let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: tokenString, rawNonce: nonce)
        
        Auth.auth().signIn(with: credential) { result, error in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            
            guard let id = Auth.auth().currentUser?.uid else { return}
            
            Firestore.firestore().collection("User Data").document(id).setData(["deleted": false])
            
            withAnimation {
                UserDefaults.standard.set(true, forKey: "LOGIN")
            }
        }
    }
}

func sha256(_ input: String) -> String {
    let inputData = Data(input.utf8)
    let hashedData = SHA256.hash(data: inputData)
    let hashString = hashedData.compactMap {
        String(format: "%02x", $0)
    }.joined()
    
    return hashString
}

func randomNonceString(length: Int = 32) -> String {
    precondition(length > 0)
    let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    var result = ""
    var remainingLength = length
    
    while remainingLength > 0 {
        let randoms: [UInt8] = (0 ..< 16).map { _ in
            var random: UInt8 = 0
            let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            if errorCode != errSecSuccess {
                fatalError(
                    "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
                )
            }
            return random
        }
        
        randoms.forEach { random in
            if remainingLength == 0 {
                return
            }
            
            if random < charset.count {
                result.append(charset[Int(random)])
                remainingLength -= 1
            }
        }
    }
    
    return result
}

   
