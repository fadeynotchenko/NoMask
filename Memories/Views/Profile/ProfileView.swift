//
//  ProfileView.swift
//  Memories
//
//  Created by Fadey Notchenko on 06.11.2022.
//

import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    
    @Binding var dismiss: Bool
    
    @EnvironmentObject private var memoryViewModel: MemoryViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("Background").edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 15) {
                    NavigationLink {
                        EditProfileView()
                    } label: {
                        profileSection
                    }
                    
                    Spacer()
                    
                    logoutButton
                }
            }
            .navigationTitle(Text("profile"))
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
    
    private var profileSection: some View {
        HStack(spacing: 15) {
            if let url = memoryViewModel.userAvatar {
                Avatar(avatarType: .url(url), size: CGSize(width: 60, height: 60))
            } else {
                Avatar(avatarType: .empty, size: CGSize(width: 60, height: 60))
            }
            
            Title(text: memoryViewModel.userNickname.isEmpty ? "nickname" : "\(memoryViewModel.userNickname)", font: .headline)
            
            Spacer()
            
            Chevron()
                .padding(.horizontal)
        }
        .padding()
        .frame(maxWidth: Constants.width)
        .background(.ultraThickMaterial)
        .cornerRadius(15)
        .shadow(radius: 3)
    }
    
    private var logoutButton: some View {
        TextButton(text: "logout", size: 330, color: .red) {
            withAnimation {
                do {
                    try Auth.auth().signOut()
                    
                    UserDefaults.standard.set(false, forKey: "isLoggin")
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
    }
}

