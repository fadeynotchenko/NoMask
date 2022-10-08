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
    @State private var images = [UIImage?](repeating: nil, count: 20)
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
            .onAppear {
                if let memory = viewModel.detailMemory, viewModel.showDetail {
                    memory.images.enumerated().forEach { i, url in
                        if let url = url {
                            getData(from: url) { data, _, _ in
                                if let data = data, let image = UIImage(data: data) {
                                    images[i] = image
                                }
                            }
                        }
                    }
                    
                    name = memory.name
                    date = memory.date
                    
                    if let text = memory.text {
                        self.text = text
                    }
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
            .shadow(radius: 3)
        }
        .padding()
    }
    
    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Title(text: "Название")
            
            TextField("Например: Геледжик 2010", text: $name)
                .foregroundColor(.gray)
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(15)
        }
    }
    
    private var textSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Title(text: "Описание")
            
            TextField("(Необязательно)", text: $text)
                .foregroundColor(.gray)
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(15)
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
                    
                    ForEach(images.compactMap { $0 }, id: \.self) { img in
                        if let img = img {
                            ImageItem(type: .image(image: img), size: 150)
                                .deleteButtonOverlay {
                                    images = images.filter {
                                        $0 != img
                                    }
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
            
            uploadToFirebase { result in
                if result {
                    withAnimation {
                        download = false
                        
                        dismiss = false
                        
                        viewModel.fetchData()
                    }
                } else {
                    withAnimation {
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
    
    private func uploadToFirebase(_ completion: @escaping (Bool) -> Void) {
        guard let id = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore().collection(id).document()
        
        var imageURLs = [String](repeating: "", count: images.count)
        
        var cnt = 0
        images.enumerated().forEach { i, image in
            if let image = image {
                uploadImages(id, image: image) { url in
                    if let url = url {
                        imageURLs[i] = url
                        cnt += 1
                    } else {
                        completion(false)
                        
                        return
                    }
                    
                    if cnt == images.count {
                        createDynamicLink { link in
                            if let link = link {
                                db.setData(["name": name, "date": date, "text": text, "images": imageURLs, "link": link])
                                
                                completion(true)
                            } else {
                                completion(false)
                                
                                return
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func uploadImages(_ id: String, image: UIImage, _ comletion: @escaping (String?) -> Void) {
        let storage = Storage.storage().reference().child(id).child("images").child(UUID().uuidString)
        
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
    
    private func createDynamicLink(_ completion: @escaping (String?) -> Void) {
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
        
        if let url = shareLink.url?.absoluteString {
            completion(url)
        } else {
            completion(nil)
        }
    }
    
    func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
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
