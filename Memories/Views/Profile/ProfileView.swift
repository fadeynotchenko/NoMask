//
//  ProfileView.swift
//  Memories
//
//  Created by Fadey Notchenko on 06.11.2022.
//

import SwiftUI
import FirebaseAuth
import AlertToast
import Kingfisher

struct ProfileView: View {
    
    @Binding var dismiss: Bool
    
    //dialogs
    @State private var showLogoutDialog = false
    @State private var showDeleteAccDialog = false
    
    @EnvironmentObject private var memoryViewModel: MemoryViewModel
    
    var body: some View {
        GeometryReader { reader in
            NavigationView {
                ZStack {
                    Color("Background").edgesIgnoringSafeArea(.all)
                    
//                    ScrollView {
//                        TopView(reader: reader)
//                            .edgesIgnoringSafeArea(.all)
//
//                        VStack(spacing: 15) {
//                            Title(text: "Публикации")
//
//                            ZStack {
//                                if memoryViewModel.loadMyMemoriesStatus == .start {
//                                    ProgressView()
//                                        .shadow(radius: 3)
//                                } else if memoryViewModel.personalMemories.isEmpty {
//                                    Text("empry")
//                                        .foregroundColor(.gray)
//                                }
//
//                                ScrollView(.horizontal, showsIndicators: false) {
//                                    LazyHStack(spacing: 20) {
//                                        ForEach(memoryViewModel.personalMemories) { memory in
//                                            MemoryCardView(showReportDialog: .constant(false), showDeleteDialog: .constant(false), currentMemory: .constant(nil), memory: memory)
//                                        }
//                                    }
//                                }
//                                .onAppear {
//                                    memoryViewModel.fetchPersonalMemories()
                    //                                }
                    //                            }
                    //                        }
                    //                    }
                    
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
                .confirmationDialog("", isPresented: $showLogoutDialog) {
                    Button(role: .destructive) {
                        withAnimation {
                            do {
                                try Auth.auth().signOut()
                                
                                UserDefaults.standard.set(false, forKey: "isLoggin")
                            } catch {
                                print(error.localizedDescription)
                            }
                        }
                    } label: {
                        Text("logout_yes")
                    }
                } message: {
                    Text("logout_dialog")
                }
                .confirmationDialog("", isPresented: $showDeleteAccDialog) {
                    Button(role: .destructive) {
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
                    } label: {
                        Text("delete_yes")
                    }
                } message: {
                    Text("delete_dialog")
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
                .overlay(alignment: .topTrailing) {
                    NavigationLink {
                        EditProfileView()
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .resizable()
                            .scaledToFit()
                            .padding(10)
                            .frame(width: 35, height: 35)
                            .foregroundColor(.white)
                            .background(.ultraThickMaterial)
                            .clipShape(Circle())
                            .shadow(radius: 3)
                    }
                }
                .overlay(alignment: .topLeading) {
                    ImageButton(systemName: "xmark", color: .white) {
                        dismiss.toggle()
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func TopView(reader: GeometryProxy) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            TopImage(imageType: .url(memoryViewModel.userAvatar!), reader: reader)
            
            Title(text: "\(memoryViewModel.userNickname)")
                .padding(.horizontal)
        }
    }
    
    @ViewBuilder
    private func TopImage(imageType: AvatarImageType, reader: GeometryProxy) -> some View {
        switch imageType {
        case .url(let url):
            KFImage(url)
                .loadDiskFileSynchronously(true)
                .resizable()
                .placeholder {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: reader.size.height / 2)
                        .background(Color("Background"))
                        .shadow(radius: 3)
                }
                .frame(maxWidth: .infinity, maxHeight: reader.size.height / 2)
                .scaledToFill()
                .background(Color("Background"))
                .shadow(radius: 3)
                
        case .image(_):
            EmptyView()
            
        case .empty:
            EmptyView()
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
            showLogoutDialog = true
        }
    }
    
    private var deleteButton: some View {
        TextButton(text: "deleteacc", size: 330, color: .red) {
            showDeleteAccDialog = true
        }
    }
}

