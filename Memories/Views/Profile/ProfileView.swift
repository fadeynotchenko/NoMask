//
//  ProfileView.swift
//  Memories
//
//  Created by Fadey Notchenko on 06.11.2022.
//

import SwiftUI
import FirebaseAuth
import AlertToast

struct ProfileView: View {
    
    @Binding var dismiss: Bool
    
    @State private var imageDownloaded = false
    
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
                    
                    NavigationLink {
                        PersonalMemoriesView()
                    } label: {
                        personalSection
                    }
                    
                    NavigationLink {
                        SettingsView()
                    } label: {
                        settingSection
                    }
                    
                    Spacer()
                    
                    logoutButton
                    
                    deleteButton
                }
            }
            .navigationTitle(Text("profile"))
            .navigationBarTitleDisplayMode(.inline)
            .toast(isPresenting: $imageDownloaded) {
                AlertToast(displayMode: .banner(.pop), type: .complete(.green), title: NSLocalizedString("imageDownloaded", comment: ""))
            }
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
                Avatar(avatarType: .url(url), size: CGSize(width: 60, height: 60), downloadImage: true)
            } else {
                Avatar(avatarType: .empty, size: CGSize(width: 60, height: 60), downloadImage: false)
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
    
    private var personalSection: some View {
        HStack(spacing: 10) {
            Image(systemName: "rectangle.stack.fill")
                .font(.title2)
                .foregroundColor(.white)
            
            Title(text: "my", font: .headline)
            
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
    
    private var settingSection: some View {
        HStack(spacing: 10) {
            Image(systemName: "gearshape.fill")
                .font(.title2)
                .foregroundColor(.white)
            
            Title(text: "settings", font: .headline)
            
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
    
    private var deleteButton: some View {
        TextButton(text: "deleteacc", size: 330, color: .red) {
            withAnimation {
                let user = Auth.auth().currentUser

                user?.delete { error in
                  if let error = error {
                      print(error.localizedDescription)
                  } else {
                      UserDefaults.standard.set(false, forKey: "isLoggin")
                  }
                }
            }
        }
    }
}

