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
    
    @State private var name = ""
    @State private var text = ""
    @State private var date = Date()
    
    @State private var images = [Any]()
    @State private var videos = [URL]()
    
    @State private var error = false
    
    @State private var download = false
    @State private var downloadError = false
    
    @State private var selection = 0
    
    @State private var downloadCount = 0
    
    @EnvironmentObject private var memoryViewModel: MemoryViewModel
    
    var body: some View {
        NavigationView {
            GeometryReader { reader in
                let width = reader.size.width
                
                ZStack {
                    Color("Background").edgesIgnoringSafeArea(.all)
                    
                    VStack(spacing: 10) {
                        NavigationLink {
                            InformationView(width)
                        } label: {
                            informatonSection
                        }
                        
                        photoSection(width)
                        
                        Spacer()
                    }
                }
                .navigationTitle(Text(memoryViewModel.showDetail ? "edit" : "new"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem {
                        Button("close") {
                            memoryViewModel.showNewMemoryView = false
                        }
                    }
                }
                .sheet(isPresented: $memoryViewModel.showPickerView) {
                    ImagePicker(images: $images, videos: $videos)
                        .edgesIgnoringSafeArea(.bottom)
                }
                .overlay {
                    if download {
                        VStack(spacing: 5) {
                            ProgressView()
                            
                            Text("\(downloadCount) / \(images.count)")
                                .foregroundColor(.gray)
                                .bold()
                                .font(.system(size: 12))
                        }
                        .padding()
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
                    if let memory = memoryViewModel.detailMemory, memoryViewModel.showDetail {
                        name = memory.name
                        date = memory.date
                        text = memory.text
                        
                        images = memory.images
                    }
                }
            }
        }
    }
    
    private var informatonSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text("Основная информация")
                    .foregroundColor(.gray)
                
                if name.isEmpty {
                    Title(text: "Название воспоминания", font: .title3)
                } else {
                    Title(text: "\(name)", font: .title3)
                }
                
                Text(date, format: .dateTime.year().month().day())
                    .foregroundColor(.gray)
                    .bold()
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
    
    private func photoSection(_ width: CGFloat) -> some View {
        VStack(spacing: 15) {
            Title(text: "photo", font: .title3)
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
            
            TextButton(text: memoryViewModel.showDetail ? "save" : "add", size: width - 50, color: name.isEmpty || images.isEmpty ? .gray : .white) {
                withAnimation {
                    download = true
                    
                    uploadToFirebase { ans in
                        withAnimation {
                            download = false
                        }
                        
                        if ans {
                            memoryViewModel.showNewMemoryView = false
                            
                            WidgetCenter.shared.reloadAllTimelines()
                        } else {
                            downloadError = true
                        }
                    }
                }
            }
            .disabled(name.isEmpty || images.isEmpty)
        }
        .padding()
        .shadow(radius: 3)
    }
    
    private func InformationView(_ width: CGFloat) -> some View {
        VStack(spacing: 15) {
            VStack(spacing: 10) {
                Title(text: "name", font: .title3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                TextField("name2", text: $name)
                    .foregroundColor(.gray)
                    .padding()
                    .background(.ultraThickMaterial)
                    .cornerRadius(15)
            }
            
            VStack(spacing: 10) {
                Title(text: "desc", font: .title3)
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
            }
            
            DatePicker(selection: $date, displayedComponents: .date) {
                Title(text: "date", font: .title3)
            }
            
            Spacer()
        }
        .navigationTitle(Text("Основная информация"))
        .navigationBarTitleDisplayMode(.inline)
        .shadow(radius: 3)
        .padding()
        
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
                        memoryViewModel.showPickerView = true
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
                memoryViewModel.showPickerView = true
            }
        @unknown default:
            break
        }
    }
    
    private func uploadToFirebase(_ completion: @escaping (Bool) -> Void) {
        guard let id = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore().collection("Self Memories").document(id).collection("Memories")
        
        var imageURLs = [String](repeating: "", count: images.count)
        
        downloadCount = 0
        
        images.enumerated().forEach { i, image in
            if let image = image as? UIImage {
                uploadImage(id, image: image) { url in
                    if let url = url {
                        imageURLs[i] = url
                        downloadCount += 1
                        
                        if downloadCount == images.count {
                            if let memory = memoryViewModel.detailMemory, memoryViewModel.showDetail {
                                db.document(memory.id).setData(["name": name, "date": date, "text": text, "images": imageURLs])
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
                downloadCount += 1
                
                if downloadCount == images.count {
                    if let memory = memoryViewModel.detailMemory, memoryViewModel.showDetail {
                        db.document(memory.id).setData(["name": name, "date": date, "text": text, "images": imageURLs])
                        
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
