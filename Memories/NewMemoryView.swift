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

struct NewMemoryView: View {
    
    @Binding var dismiss: Bool
    
    @State private var name = ""
    @State private var text = ""
    @State private var date = Date()
    @State private var images = [UIImage]()
    @State private var videos = [URL]()
    
    @State private var showPickerView = false
    @State private var error = false
    
    @State private var download = false
    
    var body: some View {
        GeometryReader { reader in
            let width = reader.size.width
            
            VStack(spacing: 15) {
                header
                
                Group {
                    nameSection
                    
                    textSection
                    
                    dateDection
                    
                    mediaSection
                    
                    addButtonSection(width)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .background(Color("Background").edgesIgnoringSafeArea(.all))
            .overlay {
                if showPickerView {
                    ImagePicker(images: $images, videos: $videos, picker: $showPickerView)
                        .edgesIgnoringSafeArea(.all)
                }
            }
            .overlay {
                if download {
                    ProgressView()
                        .frame(width: 70, height: 70)
                        .background(.ultraThinMaterial)
                        .cornerRadius(15)
                }
            }
        }
    }
    
    private var header: some View {
        VStack {
            HStack {
                Title(text: "Новое Воспоминание")
                
                Spacer()
                
                ImageButton(systemName: "xmark", color: .white) {
                    withAnimation {
                        dismiss = false
                    }
                }
            }
            .shadow(radius: 3)
        }
        .padding()
    }
    
    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Title(text: "Название")
            
            TextField("Например: Геледжик 2010", text: $name)
                .foregroundColor(.gray)
        }
    }
    
    private var textSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Title(text: "Описание")
            
            TextField("(Необязательно)", text: $text)
                .foregroundColor(.gray)
        }
    }
    
    private var dateDection: some View {
        DatePicker(selection: $date, displayedComponents: [.date]) {
            Title(text: "Дата")
        }
        .padding(.vertical)
    }
    
    private var mediaSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Title(text: "Фото и Видео")
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 15) {
                    
                    //addButton
                    AddMediaButton {
                        openImagePicker()
                    }
                    
                    //videos
                    ForEach(videos, id: \.self) { url in
                        VideoItem(url: url)
                            .deleteButtonOverlay {
                                videos = videos.filter {
                                    $0 != url
                                }
                            }
                    }
                    
                    ForEach(images, id: \.self) { img in
                        ImageItem(type: .image(image: img))
                            .deleteButtonOverlay {
                                images = images.filter {
                                    $0 != img
                                }
                            }
                    }
                }
            }
            .frame(height: 150)
        }
    }
    
    private func addButtonSection(_ width: CGFloat) -> some View {
        TextButton(text: "Добавить", size: width - 50, color: .white) {
            withAnimation {
                download = true
            }
            
            Task {
                await uploadToFirebase { ans in
                    if ans {
                        download = false
                    }
                }
            }
        }
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
    
    private func uploadToFirebase(_ completion: @escaping (Bool) -> Void) async {
        guard let id = Auth.auth().currentUser?.uid else { return }
        
        let storage = Storage.storage().reference()
        let db = Firestore.firestore().collection(id).document()
        
        do {
            try await db.setData(["name": name, "date": date])
            
            if !text.isEmpty {
                try await db.setData(["name": name, "date": date])
            }
        } catch {
            completion(false)
            
            return
        }
        
        //upload images
        images.enumerated().forEach { i, image in
            if let data = image.jpegData(compressionQuality: 0.5) {
                let ref = storage.child("\(id)/images/\(UUID().uuidString)")
                
                ref.putData(data) { meta, error in
                    if error != nil {
                        completion(false)
                        return
                    }
                    
                    ref.downloadURL { url, error in
                        if error != nil {
                            completion(false)
                            return
                        }
                        
                        if let url = url {
                            db.collection("images").document().setData(["url": url.absoluteString, "id": i])
                            
                            completion(true)
                        }
                    }
                }
            }
        }
        
        //upload videos
        videos.enumerated().forEach { i, url in
            do {
                let data = try Data(contentsOf: url)
                let ref = storage.child("\(id)/videos/\(UUID().uuidString)")
                
                ref.putData(data) { meta, error in
                    if error != nil {
                        completion(false)
                        return
                    }
                    
                    ref.downloadURL { url, error in
                        if error != nil {
                            completion(false)
                            return
                        }
                        
                        if let url = url {
                            db.collection("videos").document().setData(["url": url.absoluteString, "id": i])
                        }
                    }
                }
            } catch {
                completion(false)
                
                return
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
