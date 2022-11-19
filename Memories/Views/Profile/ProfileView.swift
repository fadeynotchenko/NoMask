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
    
    //dialogs
    @State private var showLogoutDialog = false
    @State private var showDeleteAccDialog = false
    
    @EnvironmentObject private var viewModel: ViewModel
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            GeometryReader { reader in
                ZStack {
                    Color("Background").edgesIgnoringSafeArea(.all)
                    
                    ScrollView {
                        VStack(spacing: 15) {
                            TopView(reader: reader)
                            
                            NavigationLink {
                                EditProfileView(isEntry: false)
                            } label: {
                                editSection
                            }
                            
                            //                            NavigationLink {
                            //                                SettingsView()
                            //                            } label: {
                            //                                settingSection
                            //                            }
                            
                                                    PersonalMemoriesView()
                            
                            //                            logoutButton
                            //                                .padding(.top, reader.size.width / 3.5)
                            //
                            //                            deleteButton
                        }
                    }
                }
                .navigationBarHidden(true)
                .onAppear {
                    viewModel.fetchSelfData()
                    
                    viewModel.fetchAdmins()
                }
                .navigationBarHidden(true)
                .confirmationDialog("", isPresented: $showLogoutDialog) {
                    Button(role: .destructive) {
                        withAnimation {
                            do {
                                try Auth.auth().signOut()
                                
                                UserDefaults.standard.set(false, forKey: "isLoggin")
                                UserDefaults.standard.set(false, forKey: "isProfile")
                                
                                dismiss()
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
                                    UserDefaults.standard.set(false, forKey: "isProfile")
                                    
                                    dismiss()
                                }
                            }
                        }
                    } label: {
                        Text("delete_yes")
                    }
                } message: {
                    Text("delete_dialog")
                }
                .overlay(alignment: .topTrailing) {
                    Menu {
                        Button(role: .destructive) {
                            showLogoutDialog = true
                        } label: {
                            Text("logout")
                        }
                        
                        Button(role: .destructive) {
                            showDeleteAccDialog = true
                        } label: {
                            Text("deleteacc")
                        }
                    } label: {
                        ImageButton(systemName: "ellipsis", color: .white) { }
                            .padding()
                    }
                }
                .overlay(alignment: .topLeading) {
                    ImageButton(systemName: "xmark", color: .white) {
                        withAnimation {
                            dismiss()
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    @ViewBuilder
    private func TopView(reader: GeometryProxy) -> some View {
        GeometryReader { proxy in
            let minY = proxy.frame(in: .named("SCROLL")).minY
            let size = proxy.size
            let height = (size.height + minY)
            
            if let imageURL = viewModel.userAvatar {
                KFImage(imageURL)
                    .resizable()
                    .placeholder {
                        ProgressView()
                    }
                    .scaledToFill()
                    .background(.ultraThickMaterial)
                    .frame(width: size.width, height: max(height, 0), alignment: .top)
                    .overlay {
                        ZStack(alignment: .bottom) {
                            LinearGradient(colors: [.clear, .black.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                        }
                        
                        Title(text: "\(viewModel.userNickname)")
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                            .padding()
                    }
                    .cornerRadius(15)
                    .offset(y: -minY)
            }
        }
        .frame(height: reader.size.height / 2)
    }
    
    private var editSection: some View {
        HStack(spacing: 10) {
            Image(systemName: "square.and.pencil")
                .font(.title2)
                .foregroundColor(.white)
            
            Title(text: "edit", font: .headline)
            
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
}

