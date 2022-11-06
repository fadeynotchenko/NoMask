//
//  ProfileView.swift
//  Memories
//
//  Created by Fadey Notchenko on 30.10.2022.
//

import SwiftUI
import Firebase
import FirebaseFirestore

struct ProfileView: View {
    
    @EnvironmentObject private var memoryViewModel: MemoryViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("Background").edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 15) {
                    
                    NavigationLink {
                        EditName()
                    } label: {
                        nameSection
                    }
                    
                    Spacer()
                    
                    quitButton
                        .padding(.bottom)
                }
            }
            .navigationTitle(Text("profile"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem {
                    Button("close") {
                        memoryViewModel.showProfileView = false
                    }
                }
            }
        }
    }
    
    private var nameSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text("personname")
                    .foregroundColor(.gray)
                
                if memoryViewModel.userName.isEmpty {
                    Title(text: "Unwknow User", font: .title3)
                } else {
                    Title(text: "\(memoryViewModel.userName)", font: .title3)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .frame(width: 15, height: 15)
                .foregroundColor(.gray)
                .shadow(radius: 3)
        }
        .padding()
        .background(.ultraThickMaterial)
        .cornerRadius(15)
        .shadow(radius: 3)
        .padding()
    }
    
    private var quitButton: some View {
        TextButton(text: "quit", size: 330, color: .red) {
            withAnimation {
                do {
                    try Auth.auth().signOut()
                    
                    UserDefaults.standard.set(false, forKey: "isLoggin")
                } catch {
                    //error
                }
            }
        }
    }
}

struct EditName: View {
    
    @State private var newName = ""
    
    @EnvironmentObject private var memoryViewModel: MemoryViewModel
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color("Background").edgesIgnoringSafeArea(.all)
            
            VStack(alignment: .leading, spacing: 10) {
                Title(text: "personname")
                
                TextField("newname", text: $newName)
                    .padding()
                    .background(.ultraThickMaterial)
                    .cornerRadius(15)
                    .shadow(radius: 3)
                
                Spacer()
                
                saveButton
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(Text("editprofile"))
        .onAppear {
            newName = memoryViewModel.userName
        }
    }
    
    private var saveButton: some View {
        TextButton(text: "save", size: 330, color: newName.isEmpty || memoryViewModel.userName == newName ? .gray : .blue) {
            guard let id = Auth.auth().currentUser?.uid else { return }
            
            Firestore.firestore().collection("User Data").document(id).setData(["name": newName])
            
            dismiss()
        }
        .disabled(newName.isEmpty || memoryViewModel.userName == newName)
        .frame(maxWidth: .infinity, alignment: .center)
    }
}
