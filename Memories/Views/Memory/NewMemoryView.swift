//
//  NewMemoryView.swift
//  Memories
//
//  Created by Fadey Notchenko on 06.11.2022.
//

import SwiftUI
import AVKit
import Firebase
import FirebaseStorage
import FirebaseFirestore

struct NewMemoryView: View {
    
    @EnvironmentObject private var memoryViewModel: MemoryViewModel
    @StateObject private var cameraViewModel = CameraViewModel()
    
    @State private var images = [UIImage]()
    
    @State private var disabled = false
    @State private var download = false
    
    @State private var uploadedCount = 0
    
    var body: some View {
        NavigationView {
            GeometryReader { reader in
                let width = reader.size.width
                
                ZStack {
                    Color("Background").edgesIgnoringSafeArea(.all)
                    
                    VStack {
                        CameraPreview(camera: cameraViewModel, width: width - 20)
                            .frame(width: width - 20, height: width - 20)
                            .cornerRadius(15)
                            .shadow(radius: 3)
                        
                        takePhotoAndRotationButtons
                        
                        imagesLazyHStack
                        
                        Spacer()
                        
                        uploadButton
                    }
                }
                .navigationTitle(Text("Новое воспоминание"))
                .navigationBarTitleDisplayMode(.inline)
                .onAppear {
                    cameraViewModel.checkPermission()
                }
                .onChange(of: cameraViewModel.previewURL) { url in
                    DispatchQueue.main.async {
                        if let url = url, let image = UIImage(contentsOfFile: url.path) {
                            withAnimation {
                                images.append(image)
                            }
                        }
                        
                        cameraViewModel.retakePic()
                    }
                }
                .overlay {
                    if download {
                        VStack(spacing: 10) {
                            ProgressView()
                            
                            Text("\(uploadedCount) / \(images.count)")
                                .bold()
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(.ultraThickMaterial)
                        .cornerRadius(15)
                    }
                }
            }
        }
    }
    
    private var takePhotoAndRotationButtons: some View {
        Button {
            cameraViewModel.takePic()
            
            disabled = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                disabled = false
            }
        } label: {
            ZStack {
                Circle()
                    .fill(disabled ? .gray : .white)
                    .frame(width: 65, height: 65)
                
                Circle()
                    .stroke(disabled ? .gray : .white, lineWidth: 2)
                    .frame(width: 75, height: 75)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .shadow(radius: 3)
        .disabled(disabled)
        .overlay(alignment: .trailing) {
            Button {
                if cameraViewModel.position == .back {
                    cameraViewModel.position = .front
                } else {
                    cameraViewModel.position = .back
                }
                
                cameraViewModel.setUp()
            } label: {
                Image(systemName: "arrow.triangle.2.circlepath.camera")
                    .foregroundColor(.white)
            }
            .padding(.horizontal)
        }
    }
    
    private var imagesLazyHStack: some View {
        VStack(alignment: .leading, spacing: 15) {
            Title(text: "photo", font: .title3)
                .padding(.leading)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 5) {
                    ForEach(images, id: \.self) { image in
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 150, height: 150)
                            .cornerRadius(15)
                            .shadow(radius: 3)
                            .padding(.leading)
                            .overlay(alignment: .topTrailing) {
                                Button {
                                    withAnimation {
                                        images = images.filter { $0 != image }
                                    }
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.system(size: 15))
                                        .foregroundColor(.red)
                                        .padding(5)
                                        .background(.ultraThickMaterial)
                                        .clipShape(Circle())
                                        .padding(5)
                                }
                            }
                    }
                }
            }
            .frame(height: 150)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var uploadButton: some View {
        TextButton(text: "add", size: 330, color: images.isEmpty ? .gray : .blue) {
            withAnimation {
                download = true
                
                uploadToFirebase { ans in
                    download = false
                    
                    if ans {
                        memoryViewModel.showNewMemoryView = false
                    }
                }
            }
        }
    }
}

extension NewMemoryView {
    private func uploadToFirebase(_ completion: @escaping (Bool) -> Void) {
        guard let id = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore().collection("Global Memories").document()
        
        var imageURLs = [String](repeating: "", count: images.count)
        
        uploadedCount = 0
        
        images.enumerated().forEach { i, image in
            uploadImage(image: image) { url in
                if let url = url {
                    imageURLs[i] = url
                    uploadedCount += 1
                    
                    if uploadedCount == images.count {
                        db.setData(["date": Date(), "images": imageURLs, "userID": id, "userName": memoryViewModel.userName])
                        
                        completion(true)
                    }
                } else {
                    completion(false)
                    
                    return
                }
            }
        }
    }
    
    private func uploadImage(image: UIImage, _ comletion: @escaping (String?) -> Void) {
        guard let id = Auth.auth().currentUser?.uid else { return }
        
        let storage = Storage.storage().reference().child(id).child("images").child("\(UUID().uuidString).jpg")
        var data: Data?
        
        data = image.jpegData(compressionQuality: 0.7)
        
        if let data = data {
            let _ = storage.putData(data) { _, error in
                if error != nil {
                    comletion(nil)
                }
                
                storage.downloadURL { url, error in
                    if error != nil {
                        comletion(nil)
                    }
                    
                    if let url = url {
                        comletion(url.absoluteString)
                    }
                }
            }
        }
    }
}


struct CameraPreview: UIViewRepresentable {
    @ObservedObject var camera: CameraViewModel
    let width: CGFloat
    
    public func makeUIView(context: Context) -> UIView {
        let frame = CGRect(x: 0, y: 0, width: width, height: width)
        let view = UIView(frame: frame)
        
        camera.preview = AVCaptureVideoPreviewLayer(session: camera.session)
        camera.preview.frame = view.frame
        
        camera.preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(camera.preview)
        
        camera.session.startRunning()
        
        return view
    }
    
    public func updateUIView(_ uiView: UIView, context: Context) {
        
    }
}
