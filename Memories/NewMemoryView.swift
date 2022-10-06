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
import FirebaseDynamicLinks

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
    @State private var downloadError = false
    
    @EnvironmentObject private var viewModel: ViewModel
    
    var body: some View {
        GeometryReader { reader in
            let width = reader.size.width
            
            VStack(spacing: 15) {
                header
                
                nameSection
                    .padding(.horizontal)
                
                textSection
                    .padding(.horizontal)
                
                dateDection
                    .padding(.horizontal)
                
                mediaSection
                    .padding(.horizontal)
                
                addButtonSection(width)
                
                
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
            .toast(isPresenting: $downloadError) {
                AlertToast(displayMode: .banner(.pop), type: .error(.red), title: "Ошибка загрузки!")
            }
            .toast(isPresenting: $error) {
                AlertToast(displayMode: .banner(.pop), type: .error(.red), title: "Ошибка!", subTitle: "Требуется доступ к галерее")
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
        VStack(alignment: .leading, spacing: 15) {
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
                        ImageItem(type: .image(image: img), size: 150)
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
        
        let db = Firestore.firestore().collection(id).document()
        
        do {
            if text.isEmpty {
                try await db.setData(["name": name, "date": date])
            } else {
                try await db.setData(["name": name, "date": date, "text": text])
            }
        } catch {
            completion(false)
            
            return
        }
        
        createDynamicLink()
        
        //upload images
        var count = 0
        var videoCount = 0
        uploadImages(images: images, userId: id) { bool, str in
            if let url = str, bool {
                
                db.collection("images").document().setData(["url": url, "id": count])
                count += 1
                
                if count == images.count {
                    
                    if videos.isEmpty {
                        
                        withAnimation {
                            download.toggle()
                            dismiss.toggle()
                            
                            viewModel.fetchData()
                        }
                    } else {
                        uploadVideos(videos: videos, userId: id) { bool, url in
                            if let url = url, bool {
                                
                                db.collection("videos").document().setData(["url": url, "id": videoCount])
                                videoCount += 1
                                
                                if videoCount == videos.count {
                                    
                                    withAnimation {
                                        download.toggle()
                                        dismiss.toggle()
                                        
                                        viewModel.fetchData()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func uploadImages(images: [UIImage], userId: String, completion: @escaping (_ status: Bool,_ response: String?) -> Void) {
        images.enumerated().forEach { (index, image) in
            guard let data = image.jpegData(compressionQuality: 0.5) else{
                completion(false, nil)
                return
            }
            
            let riversRef = Storage.storage().reference().child("\(userId)/images/\(UUID().uuidString)")
            // Upload the file to the path "images/rivers.jpg"
            let _ = riversRef.putData(data, metadata: nil) { (metadata, error) in
                guard let _ = metadata else {
                    
                    completion(false,error!.localizedDescription)
                    return
                }
                
                riversRef.downloadURL { (url, error) in
                    guard let downloadURL = url else{
                        completion(false,error!.localizedDescription)
                        return
                    }
                    completion(true, downloadURL.absoluteString)
                }
            }
        }
    }
    
    private func uploadVideos(videos: [URL], userId: String, completion: @escaping (_ status: Bool, _ response: String?) -> Void) {
        videos.enumerated().forEach { (index, url1) in
            do {
                let data = try Data(contentsOf: url1)
                
                let riversRef = Storage.storage().reference().child("\(userId)/videos/\(UUID().uuidString).mp4")
                let imgsRef = Storage.storage().reference().child("\(userId)/images/\(UUID().uuidString)")
                
                let _ = riversRef.putData(data, metadata: nil) { (metadata, error) in
                    guard let _ = metadata else {
                        
                        completion(false, nil)
                        return
                    }
                    
                    riversRef.downloadURL { (url, error) in
                        if let url = url {
                            completion(true, url.absoluteString)
                        }
                    }
                }
            } catch {
                completion(false, nil)
            }
        }
    }
    
    private func generateThumbnail(asset: AVAsset, completion: @escaping (UIImage?) -> Void) {
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        do {
            let thumbnailCGImage = try imageGenerator.copyCGImage(at: CMTimeMake(value: 1, timescale: 60), actualTime: nil)
            completion(UIImage(cgImage: thumbnailCGImage))
        } catch {
            completion(nil)
        }
    }
    
    private func createDynamicLink() {
        guard let id = Auth.auth().currentUser?.uid else { return }
        
        var components = URLComponents()
        components.scheme = "https"
        components.host = "mymemoriesapp.page.link"
        components.path = "/memory"
        
        let query = URLQueryItem(name: "id", value: id)
        components.queryItems = [query]
        
        guard let parametr = components.url else { return }
        print("LINK \(parametr.absoluteString)")
        
        guard let shareLink = DynamicLinkComponents(link: parametr, domainURIPrefix: "https://mymemoriesapp.page.link") else { return }
        
        if let bundle = Bundle.main.bundleIdentifier {
            shareLink.iOSParameters = DynamicLinkIOSParameters(bundleID: bundle)
        }
        
        shareLink.iOSParameters?.appStoreID = "1642544455"
        
        shareLink.socialMetaTagParameters = DynamicLinkSocialMetaTagParameters()
        shareLink.socialMetaTagParameters?.title = name
        
        if !text.isEmpty {
            shareLink.socialMetaTagParameters?.descriptionText = text
        }
        
        print(shareLink.link)
        
        shareLink.shorten { url, _, _ in
            if let url = url {
                print(url)
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
