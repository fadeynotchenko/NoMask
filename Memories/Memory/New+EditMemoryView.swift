//
//  NewMemoryView.swift
//  Memories
//
//  Created by Fadey Notchenko on 03.10.2022.
//

import SwiftUI
import PhotosUI
import FirebaseStorage
import FirebaseFirestore
import Firebase
import AlertToast
import WidgetKit

struct NewMemoryView: View {
    
    @Binding var dismiss: Bool
    
    @State private var name = ""
    @State private var text = ""
    @State private var date = Date()
    
    @State private var images = [Any]()
    @State private var videos = [URL]()
    
    @State private var deletedImages = [URL]()
    
    @State private var showPickerView = false
    @State private var error = false
    
    @State private var download = false
    @State private var downloadError = false
    
    @State private var selection = 0
    
    @EnvironmentObject private var viewModel: MemoryViewModel
    @EnvironmentObject private var storeViewModel: StoreViewModel
    
    var body: some View {
        GeometryReader { reader in
            let width = reader.size.width
            
            ZStack {
                Color("Background").edgesIgnoringSafeArea(.all)
                
                VStack {
                    Header(text: viewModel.showDetail ? "edit" : "new") {
                        ImageButton(systemName: "xmark", color: .white) {
                            withAnimation {
                                dismiss = false
                            }
                        }
                    }
                    
                    TabView(selection: $selection) {
                        InformationView(width)
                            .tag(0)
                        
                        MediaView(width)
                            .tag(1)
                    }
                    .ignoresSafeArea(.keyboard)
                    .edgesIgnoringSafeArea(.bottom)
                    .tabViewStyle(.page(indexDisplayMode: .always))
                }
                .ignoresSafeArea(.keyboard)
            }
            .sheet(isPresented: $showPickerView) {
                ImagePicker(images: $images, videos: $videos, picker: $showPickerView)
                    .edgesIgnoringSafeArea(.bottom)
            }
            .sheet(isPresented: $viewModel.showProVersionView) {
                ProVersionView()
            }
            .overlay {
                if download {
                    ProgressView()
                        .frame(width: 50, height: 50)
                        .background(.ultraThickMaterial)
                        .cornerRadius(15)
                        .shadow(radius: 3)
                }
            }
            .toast(isPresenting: $error) {
                AlertToast(displayMode: .banner(.pop), type: .error(.red), title: Constants.language == "ru" ? "Ошибка" : "Error", subTitle: Constants.language == "ru" ? "Требуется доступ к галерее" : "Gallery access required")
            }
            .toast(isPresenting: $downloadError) {
                AlertToast(displayMode: .banner(.pop), type: .error(.red), title: Constants.language == "ru" ? "Ошибка загрузки" : "Loading error")
            }
            .onAppear {
                if let memory = viewModel.detailMemory, viewModel.showDetail {
                    name = memory.name
                    date = memory.date
                    text = memory.text
                    
                    images = memory.images.compactMap { $0 }
                }
            }
        }
    }
    
    private func InformationView(_ width: CGFloat) -> some View {
        VStack(spacing: 15) {
            Title(text: "name")
                .frame(maxWidth: .infinity, alignment: .leading)
            
            TextField("name2", text: $name)
                .foregroundColor(.gray)
                .padding()
                .background(.ultraThickMaterial)
                .cornerRadius(15)
            
            Title(text: "desc")
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if #available(iOS 16, *) {
                TextField("optional", text: $text, axis: .vertical)
                    .foregroundColor(.gray)
                    .padding()
                    .background(.ultraThickMaterial)
                    .cornerRadius(15)
                    .lineLimit(3...5)
            } else {
                TextField("optional", text: $text)
                    .foregroundColor(.gray)
                    .padding()
                    .background(.ultraThickMaterial)
                    .cornerRadius(15)
            }
            
            DatePicker(selection: $date, displayedComponents: .date) {
                Title(text: "date")
            }
            
            Spacer()
            
            TextButton(text: "next", size: width - 50, color: name.isEmpty ? .gray : .white) {
                withAnimation {
                    selection = 1
                }
            }
            .padding(.bottom, 25)
            .disabled(name.isEmpty)
        }
        .shadow(radius: 3)
        .padding()
        
    }
    
    private func MediaView(_ width: CGFloat) -> some View {
        VStack(spacing: 15) {
            Title(text: "photo")
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: [GridItem(), GridItem()], spacing: 15) {
                    AddMediaButton(width: width / 2.3) {
                        openImagePicker()
                        
                    }
                    
                    ForEach(0..<images.count, id: \.self) { i in
                        if let image = images[i] as? UIImage {
                            ImageItem(type: .image(image: image), size: width / 2.3)
                                .deleteButtonOverlay {
                                    withAnimation {
                                        images = images.filter {
                                            $0 as? UIImage != image
                                        }
                                    }
                                }
                        } else if let url = images[i] as? URL {
                            ImageItem(type: .url(url: url), size: width / 2.3)
                                .deleteButtonOverlay {
                                    deletedImages.append(url)
                                    
                                    withAnimation {
                                        images = images.filter {
                                            $0 as? URL != url
                                        }
                                    }
                                }
                        }
                    }
                }
            }
            
            if storeViewModel.isSubscription == false {
                VStack(spacing: 5) {
                    Text("limit")
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)

                    Button("pro") {
                        viewModel.showProVersionView = true
                    }
                    .foregroundColor(.blue)
                }
            }
            
            TextButton(text: viewModel.showDetail ? "save" : "add", size: width - 50, color: name.isEmpty || images.isEmpty ? .gray : .white) {
                withAnimation {
                    download = true
                }
                
                uploadToFirebase { ans in
                    withAnimation {
                        download = false
                    }
                    
                    if ans {
                        dismiss = false
                        
                        WidgetCenter.shared.reloadAllTimelines()
                    } else {
                        downloadError = true
                    }
                }
            }
            .disabled(name.isEmpty || images.isEmpty)
            .padding(.bottom, 25)
        }
        .padding()
        .shadow(radius: 3)
    }
}

extension NewMemoryView {
    private func openImagePicker() {
        let status = PHPhotoLibrary.authorizationStatus()
        
        switch status {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { status in
                switch status {
                case .authorized, .limited:
                    withAnimation {
                        showPickerView = true
                    }
                case .denied, .restricted:
                    withAnimation {
                        error = true
                    }
                case .notDetermined:
                    break
                @unknown default:
                    break
                }
            }
        case .denied, .restricted:
            withAnimation {
                error = true
            }
        case .authorized, .limited:
            withAnimation {
                showPickerView = true
            }
        @unknown default:
            break
        }
    }
    
    private func uploadToFirebase(_ completion: @escaping (Bool) -> Void) {
        guard let id = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore().collection(id)
        
        var imageURLs = [String](repeating: "", count: images.count)
        
        var cnt = 0
        
        images.enumerated().forEach { i, image in
            if let image = image as? UIImage {
                uploadImage(id, image: image) { url in
                    if let url = url {
                        imageURLs[i] = url
                        cnt += 1
                        
                        if cnt == images.count {
                            if let memory = viewModel.detailMemory, viewModel.showDetail {
                                db.document(memory.id).setData(["name": name, "date": date, "text": text, "images": imageURLs])
                                
                                DispatchQueue.main.async {
                                    viewModel.detailMemory?.name = name
                                    viewModel.detailMemory?.date = date
                                    viewModel.detailMemory?.text = text
                                    viewModel.detailMemory?.images = imageURLs.compactMap { URL(string: $0) }
                                }
                                
                            } else {
                                db.document().setData(["name": name, "date": date, "text": text, "images": imageURLs])
                            }
                            
                            completion(true)
                        }
                    } else {
                        completion(false)
                        
                        return
                    }
                }
            } else {
                let url = image as? URL
                imageURLs[i] = url!.absoluteString
                cnt += 1
                
                if cnt == images.count {
                    if let memory = viewModel.detailMemory, viewModel.showDetail {
                        db.document(memory.id).setData(["name": name, "date": date, "text": text, "images": imageURLs])
                        
                        DispatchQueue.main.async {
                            viewModel.detailMemory?.name = name
                            viewModel.detailMemory?.date = date
                            viewModel.detailMemory?.text = text
                            viewModel.detailMemory?.images = imageURLs.map { URL(string: $0)! }
                        }
                        
                    } else {
                        db.document().setData(["name": name, "date": date, "text": text, "images": imageURLs])
                    }
                    
                    completion(true)
                }
            }
        }
    }
    
    private func uploadImage(_ id: String, image: UIImage, _ comletion: @escaping (String?) -> Void) {
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

extension View {
    func deleteButtonOverlay(_ action: @escaping () -> ()) -> some View {
        self
            .overlay(alignment: .topTrailing) {
                Button {
                    withAnimation {
                        action()
                    }
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(.red)
                        .font(.system(size: 15))
                        .shadow(radius: 3)
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .padding(5)
                    
                }
            }
    }
}
