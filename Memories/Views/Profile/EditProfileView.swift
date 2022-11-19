//
//  EditProfileView.swift
//  NoMask
//
//  Created by Fadey Notchenko on 06.11.2022.
//

import SwiftUI
import PhotosUI
import FirebaseStorage
import FirebaseFirestore
import FirebaseAuth

struct EditProfileView: View {
    
    var isEntry: Bool
    
    @State private var nickname = ""
    @State private var photo: UIImage?
    
    @State private var error = false
    
    @State private var download = false
    
    @State private var showPickerView = false
    
    @EnvironmentObject private var memoryViewModel: ViewModel
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color("Background").edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 15) {
                if isEntry {
                    textView
                }
                
                Button {
                    showPickerView = true
                } label: {
                     if let photo = photo {
                         Avatar(avatarType: .image(photo), size: CGSize(width: 150, height: 150), downloadImage: false)
                    } else {
                        if let url = memoryViewModel.userAvatar {
                            Avatar(avatarType: .url(url), size: CGSize(width: 150, height: 150), downloadImage: true)
                        } else {
                            Avatar(avatarType: .empty, size: CGSize(width: 150, height: 150), downloadImage: false)
                        }
                    }
                }
                
                NicknameTF(nickname: $nickname)
                
                Spacer()
                
                saveButton
            }
            .ignoresSafeArea(.keyboard, edges: .all)
            .onAppear {
                nickname = memoryViewModel.userNickname
                
                checkStatus()
            }
        }
        .navigationTitle(Text("editprofile"))
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if error {
                Permission(text: "photopermission")
            }
            
            if download {
                Download()
            }
        }
        .sheet(isPresented: $showPickerView) {
            ImagePicker(image: $photo, dismiss: $showPickerView)
        }
    }
    
    private var textView: some View {
        VStack(alignment: .center, spacing: 10) {
            Title(text: "profile", font: .headline)
            
            Text("profilenext")
                .bold()
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal)
    }
    
    private var saveButton: some View {
        TextButton(text: "save", size: 330, color: nickname.isEmpty || (photo == nil && memoryViewModel.userAvatar == nil) ? .gray : .blue) {
            guard let id = Auth.auth().currentUser?.uid else { return }
            
            withAnimation {
                download = true
                
                if let image = photo {
                    memoryViewModel.uploadImage(image: image) { url in
                        download = false
                        
                        if let url = url {
                            
                            if let oldImage = memoryViewModel.userAvatar {
                                Storage.storage().reference(forURL: oldImage.absoluteString).delete { _ in }
                            }
                            
//                            if nickname != memoryViewModel.userNickname {
//                                Firestore.firestore().document(memoryViewModel.userNickname).delete { _ in }
//                            }
                            
                            Firestore.firestore().collection("User Data").document(id).setData(["nickname": nickname, "image": url])
                            
                            memoryViewModel.fetchGlobalMemories()
                            
                            if isEntry {
                                withAnimation {
                                    UserDefaults.standard.set(true, forKey: "isProfile")
                                }
                            } else {
                                dismiss()
                            }
                        }
                    }
                } else {
//                    if nickname != memoryViewModel.userNickname {
//                        Firestore.firestore().document(memoryViewModel.userNickname).delete { _ in }
//                    }
                    
                    Firestore.firestore().collection("User Data").document(id).setData(["nickname": nickname])
                    
                    memoryViewModel.fetchGlobalMemories()
                    
                    if isEntry {
                        withAnimation {
                            UserDefaults.standard.set(true, forKey: "isProfile")
                        }
                    } else {
                        dismiss()
                    }
                }
            }
        }
        .disabled(nickname.isEmpty || (photo == nil && memoryViewModel.userAvatar == nil))
    }
}

extension EditProfileView {
    private func checkStatus() {
        let status = PHPhotoLibrary.authorizationStatus()
        
        switch status {
            
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { status in
                switch status {
                case .authorized, .limited:
                    error = false
                case .denied, .restricted:
                    error = true
                case .notDetermined:
                    break
                @unknown default:
                    break
                }
            }
            
        case .denied, .restricted:
            error = true
        case .authorized, .limited:
            error = false
        @unknown default:
            break
        }
    }
}
