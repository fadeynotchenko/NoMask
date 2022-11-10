//
//  NicknameView.swift
//  No Mask
//
//  Created by Fadey Notchenko on 07.11.2022.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct NicknameView: View {
    
    @Binding var dismiss: Bool
    @Binding var showNewMemoryView: Bool
    @EnvironmentObject private var memoryViewModel: MemoryViewModel
    
    @State private var nickname = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("Background").edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    Title(text: "nicknametext", font: .title2)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                    
                    NicknameTF(nickname: $nickname)
                    
                    Spacer()
                    
                    TextButton(text: "save", size: 330, color: nickname.isEmpty ? .gray : .white) {
                        guard let id = Auth.auth().currentUser?.uid else { return }
                        
                        Firestore.firestore().collection("User Data").document(id).setData(["nickname": nickname])
                        
                        dismiss.toggle()
                        
                        showNewMemoryView = true
                    }
                    .disabled(nickname.isEmpty)
                }
                .ignoresSafeArea(.keyboard, edges: .all)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem {
                    Button {
                        dismiss.toggle()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
}

