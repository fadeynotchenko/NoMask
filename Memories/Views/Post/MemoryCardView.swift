//
//  MemoryCardView.swift
//  Memories
//
//  Created by Fadey Notchenko on 26.10.2022.
//

import SwiftUI
import AlertToast
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore

struct MemoryCardView: View {
    
    @Binding var showReportDialog: Bool
    @Binding var showDeleteDialog: Bool
    @Binding var showBanUserDialog: Bool
    @Binding var currentMemory: Post?
    @State var memory: Post
    var isPersonal: Bool
    
    @State private var selection = 0
    
    @State private var isGet = false
    
    @EnvironmentObject private var memoryViewModel: ViewModel
    
    private var userID: String? {
        Auth.auth().currentUser?.uid
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if isPersonal {
                personalTopView
            } else {
                topView
            }
            
            TabView(selection: $selection) {
                ForEach(0..<memory.images.count, id: \.self) { i in
                    if let url = memory.images[i] {
                        VStack(spacing: 0) {
                            ImageItem(url: url, size: CGSize(width: Constants.width, height: Constants.height), loadDisk: memory.userID == userID)
                                .onTapGesture {
                                    withAnimation {
                                        selection = selection == 0 ? 1 : 0
                                    }
                                }
                        }
                        .background(.ultraThickMaterial)
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: memory.images.count == 1 ? .never : .always))
            .frame(width: Constants.width, height: Constants.height)
            .onAppear {
                memoryViewModel.fetchUserData(userID: memory.userID) { url, nickname in
                    withAnimation {
                        memory.userImage = url
                        memory.userNickname = nickname
                    }
                }
            }
        }
        .background(.ultraThickMaterial)
        .cornerRadius(15)
        .shadow(radius: 3)
    }
    
    @ViewBuilder
    private var menuButton: some View {
        Menu {
            Button {
                downloadImageToPhoto()
            } label: {
                Label("savephoto", systemImage: "square.and.arrow.down")
            }
            
            if memory.userID != Auth.auth().currentUser?.uid {
                Button(role: .destructive) {
                    showReportDialog = true
                    
                    currentMemory = memory
                } label: {
                    Label("report", systemImage: "exclamationmark.triangle")
                }
                .accentColor(.red)
                
                Button(role: .destructive) {
                    showBanUserDialog = true
                    
                    currentMemory = memory
                } label: {
                    Label("ban", systemImage: "person.badge.minus")
                }
                .accentColor(.red)
            } else {
                Button(role: .destructive) {
                    showDeleteDialog = true
                    
                    currentMemory = memory
                } label: {
                    Label("delete", systemImage: "trash")
                }
            }
            
            if let id = Auth.auth().currentUser?.uid, memoryViewModel.admins.contains(id) {
                Text("For Admin")
                
                Button(role: .destructive) {
                    deletePost()
                } label: {
                    Label("Удалить пост", systemImage: "trash")
                }
                
                //                Button(role: .destructive) {
                //
                //                } label: {
                //                    Label("Удалить все посты", systemImage: "trash")
                //                }
                
                Button(role: .destructive) {
                    banUser()
                } label: {
                    Label("Заблокировать", systemImage: "person.badge.minus")
                        .accentColor(.red)
                }
            }
        } label: {
            Image(systemName: "ellipsis")
                .foregroundColor(.white)
                .padding()
        }
    }
    
    @ViewBuilder
    private var topView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                if let url = memory.userImage, !url.absoluteString.isEmpty {
                    Avatar(avatarType: .url(url), size: CGSize(width: 40, height: 40), downloadImage: true)
                        .padding(.leading)
                } else {
                    Avatar(avatarType: .empty, size: CGSize(width: 40, height: 40), downloadImage: false)
                        .padding(.leading)
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    if let nickname = memory.userNickname {
                        HStack(spacing: 5) {
                            Title(text: "\(nickname)", font: .system(size: 15))
                            
                            if memoryViewModel.admins.contains(memory.userID) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.linearGradient(colors: [.orange, .purple], startPoint: .topTrailing, endPoint: .bottomLeading))
                            }
                        }
                            
                    }
                    
                    Text(memory.date.timeAgoDisplay())
                        .bold()
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                        .padding(.trailing)
                }
                
                Spacer()
                
                menuButton
            }
            
            if let desc = memory.descText {
                Text(desc)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.gray)
                    .font(.system(size: 14))
                    .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .frame(maxWidth: Constants.width)
        .background(.ultraThickMaterial)
        .cornerRadius(15, corners: [.topLeft, .topRight])
    }
    
    @ViewBuilder
    private var personalTopView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                if let url = memoryViewModel.userAvatar {
                    Avatar(avatarType: .url(url), size: CGSize(width: 40, height: 40), downloadImage: true)
                        .padding(.leading)
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 5) {
                        Title(text: "\(memoryViewModel.userNickname)", font: .system(size: 15))
                        
                        if memoryViewModel.admins.contains(memory.userID) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(.linearGradient(colors: [.orange, .purple], startPoint: .topTrailing, endPoint: .bottomLeading))
                        }
                    }
                    
                    Text(memory.date.timeAgoDisplay())
                        .bold()
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                        .padding(.trailing)
                }
                
                Spacer()
                
                menuButton
            }
            
            if let desc = memory.descText {
                Text(desc)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.gray)
                    .font(.system(size: 14))
                    .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .frame(maxWidth: Constants.width)
        .background(.ultraThickMaterial)
        .cornerRadius(15, corners: [.topLeft, .topRight])
    }
}

extension MemoryCardView {
    private func downloadImageToPhoto() {
        memory.images.forEach { image in
            Storage.storage().reference(forURL: image.absoluteString).getData(maxSize: 10 * 1024 * 1024) { data, error in
                if let data = data, error == nil, let image = UIImage(data: data) {
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                }
            }
        }
    }
    
    private func deletePost() {
        Firestore.firestore().collection("Global Memories").document(memory.memoryID).delete { _ in }
    }
    
    private func banUser() {
        Firestore.firestore().collection("User Data").document(memory.userID).updateData(["banned": true])
    }
}

