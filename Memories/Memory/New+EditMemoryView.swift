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
    
    @EnvironmentObject private var viewModel: ViewModel
    
    var body: some View {
        GeometryReader { reader in
            let width = reader.size.width
            
            ZStack {
                Color("Background").edgesIgnoringSafeArea(.all)
                
                VStack {
                    header
                    
                    TabView(selection: $selection) {
                        first(width)
                            .tag(0)
                        
                        MediaView(width)
                            .tag(1)
                    }
                    .ignoresSafeArea(.keyboard)
                    .tabViewStyle(.page(indexDisplayMode: .always))
                }
                .ignoresSafeArea(.keyboard)
                .sheet(isPresented: $showPickerView) {
                    ImagePicker(images: $images, videos: $videos, picker: $showPickerView)
                        .edgesIgnoringSafeArea(.bottom)
                }
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
                AlertToast(displayMode: .banner(.pop), type: .error(.red), title: "Ошибка", subTitle: "Требуется доступ к галерее")
            }
            .toast(isPresenting: $downloadError) {
                AlertToast(displayMode: .banner(.pop), type: .error(.red), title: "Ошибка загрузки")
            }
            .onAppear {
                if let memory = viewModel.detailMemory, viewModel.showDetail {
                    name = memory.name
                    date = memory.date
                    if let text = memory.text {
                        self.text = text
                    }
                    
                    images = memory.images.compactMap { $0 }
                }
            }
        }
    }
    
    private var header: some View {
        VStack {
            HStack {
                Title(text: viewModel.showDetail ? "Редактировать" : "Новое Воспоминание")
                
                Spacer()
                
                ImageButton(systemName: "xmark", color: .white) {
                    withAnimation {
                        dismiss = false
                    }
                }
            }
        }
        .padding()
    }
    
    private func first(_ width: CGFloat) -> some View {
        VStack(spacing: 15) {
            Title(text: "Название")
                .frame(maxWidth: .infinity, alignment: .leading)
            
            TextField("Название Вашего воспоминания", text: $name)
                .foregroundColor(.gray)
                .padding()
                .background(.ultraThickMaterial)
                .cornerRadius(15)
            
            Title(text: "Описание")
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if #available(iOS 16, *) {
                TextField("(Необязательно)", text: $text, axis: .vertical)
                    .foregroundColor(.gray)
                    .padding()
                    .background(.ultraThickMaterial)
                    .cornerRadius(15)
                    .lineLimit(1...5)
            } else {
                TextField("(Необязательно)", text: $text)
                    .foregroundColor(.gray)
                    .padding()
                    .background(.ultraThickMaterial)
                    .cornerRadius(15)
            }
            
            DatePicker(selection: $date, displayedComponents: .date) {
                Title(text: "Дата")
            }
            
            Spacer()
            
            TextButton(text: "Далее", size: width - 50, color: name.isEmpty ? .gray : .white) {
                withAnimation {
                    selection = 1
                }
            }
            .padding(.bottom)
            .disabled(name.isEmpty)
        }
        .shadow(radius: 3)
        .padding()
        
    }
    
    @ViewBuilder
    private func MediaView(_ width: CGFloat) -> some View {
        VStack(spacing: 15) {
            Title(text: "Фото")
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: [GridItem(), GridItem()], spacing: 15) {
                    AddMediaButton(width: width / 2.3) { openImagePicker() }
                    
//                    ForEach(0..<videos.count, id: \.self) { i in
//                        viewModel.getThumbnailImageFromVideoUrl(url: videos[i]) { image in
//                            if let image = image {
//                                ImageItem(type: .image(image: image), size: width / 2.3)
//                                    .deleteButtonOverlay {
//                                        withAnimation {
//                                            videos = videos.filter {
//                                                $0 != videos[i]
//                                            }
//                                        }
//                                    }
//                            }
//                        }
//                    }
                    
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
            
            VStack(spacing: 5) {
                Text("Загружайте до 10 фото и видео. Максимальный доступный размер видео 720p")
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)                
                
                Button("Снять ограничения") {
                    
                }
                .foregroundColor(.blue)
            }
            
            TextButton(text: viewModel.showDetail ? "Сохранить" : "Добавить", size: width - 50, color: name.isEmpty || images.isEmpty ? .gray : .white) {
                withAnimation {
                    download = true
                }
                
                uploadToFirebase { ans in
                    withAnimation {
                        download = false
                    }
                    
                    if ans {
                        viewModel.fetchAllMemories()
                        
                        dismiss = false
                        
                        WidgetCenter.shared.reloadAllTimelines()
                    } else {
                        downloadError = true
                    }
                }
            }
            .disabled(name.isEmpty || images.isEmpty)
            .padding(.bottom)
        }
        .padding()
        .shadow(radius: 3)
    }
    
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
        
        print(images)
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
                            viewModel.detailMemory?.images = imageURLs.map { URL(string: $0) }
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
        
        if let data = image.pngData() {
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
        } else {
            comletion(nil)
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
