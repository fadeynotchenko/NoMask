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
import CoreLocation

struct NewPostView: View {
    
    @EnvironmentObject private var memoryViewModel: ViewModel
    
    @StateObject private var cameraViewModel = CameraViewModel()
    @ObservedObject private var locationViewModel = LocationViewModel()
    
    @State private var images = [UIImage]()
    
    @State private var disabled = false
    @State private var download = false
    
    @State private var geoSelection = 0
    @State private var selection = 0
    @State private var photoSelection = 0
    
    @State private var firstImage: UIImage?
    @State private var secondImage: UIImage?
    
    @State private var text = ""
    
    @Environment(\.dismiss) private var dismiss
    
    private var locationString: String? {
        var result: String?
        if let placemark = locationViewModel.placemark, let country = placemark.country {
            
            result?.append(country)
            
            if let city = placemark.locality {
                result?.append(", \(city)")
            }
        }
        
        return result
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("Background").edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 10) {
                    if selection == 2 {
                        PostPreview
                    } else {
                        camera
                        
                        takePhotoButton
                    }
                    
                    Spacer()
                    
                    if selection == 0 {
                        firstNextButton
                    } else if selection == 1 {
                        secondNextButton
                    } else {
                        uploadButton
                    }
                }
                .ignoresSafeArea(.keyboard, edges: .all)
                .padding(.top)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    header
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                cameraViewModel.checkPermission()
            }
            .onChange(of: cameraViewModel.previewURL) { url in
                DispatchQueue.main.async {
                    if let url = url, let image = UIImage(contentsOfFile: url.path) {
                        withAnimation {
                            if selection == 0 {
                                firstImage = image
                            } else {
                                secondImage = image
                            }
                            
                            disabled = true
                        }
                    }
                    
                    cameraViewModel.retakePic()
                }
            }
            .overlay {
                if cameraViewModel.permission == false {
                    Permission(text: "camerapermission")
                }
                
                if download {
                    Download()
                }
            }
        }
    }
    
    private var header: some View {
        VStack(spacing: 5) {
            Text("new")
                .bold()
                .font(.headline)
            
            if selection != 2 {
                Text(selection == 0 ? "camera1" : "camera2")
                    .bold()
                    .font(.subheadline)
                    .foregroundColor(.gray)
            } else {
                Text("info")
                    .bold()
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
    }
    
    private var camera: some View {
        ZStack {
            ProgressView()
                .shadow(radius: 3)
            
            CameraPreview(camera: cameraViewModel)
                .frame(width: Constants.width, height: Constants.height)
                .cornerRadius(15)
                .shadow(radius: 3)
                .overlay {
                    if let image = firstImage, selection == 0 {
                        picture(image)
                    } else if let image = secondImage, selection == 1 {
                        picture(image)
                    }
                }
        }
        .background(.ultraThickMaterial)
        .frame(width: Constants.width, height: Constants.height)
        .cornerRadius(15)
        .shadow(radius: 3)
    }
    
    private var takePhotoButton: some View {
        Button {
            cameraViewModel.takePic()
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
    }
    
    private func picture(_ image: UIImage) -> some View {
        ZStack(alignment: .bottomTrailing) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: Constants.width, height: Constants.height)
                .cornerRadius(15)
                .shadow(radius: 3)
            
            //retake photo button
            Button {
                withAnimation {
                    if selection == 0 {
                        firstImage = nil
                    } else {
                        secondImage = nil
                    }
                    
                    disabled = false
                }
            } label: {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundColor(.white)
            }
            .padding(5)
            .background(.ultraThickMaterial)
            .clipShape(Circle())
            .shadow(radius: 3)
            .padding()
        }
    }
    
    private var firstNextButton: some View {
        TextButton(text: "next", size: 330, color: firstImage == nil ? .gray : .blue) {
            withAnimation {
                selection = 1
                
                disabled = false
                
                cameraViewModel.position = .front
                
                cameraViewModel.setUp()
                
            }
        }
        .disabled(firstImage == nil)
    }
    
    private var secondNextButton: some View {
        TextButton(text: "next", size: 330, color: secondImage == nil ? .gray : .blue) {
            withAnimation {
                images.append(firstImage!)
                images.append(secondImage!)
                
                selection = 2
            }
        }
        .disabled(secondImage == nil)
    }
    
    @ViewBuilder
    private var PostPreview: some View {
        VStack {
            VStack(spacing: 0) {
                TextField("optional", text: $text)
                    .padding()
                    .onChange(of: text) { _ in
                        text = String(text.prefix(Constants.DESCRIPTION_LIMIT))
                    }
                
                TabView(selection: $photoSelection) {
                    if let firstImage = firstImage {
                        photoTabItem(image: firstImage)
                            .tag(0)
                    }
                    
                    if let secondImage = secondImage {
                        photoTabItem(image: secondImage)
                            .tag(1)
                    }
                }
                .frame(maxHeight: Constants.height)
                .tabViewStyle(.page(indexDisplayMode: .always))
            }
            .frame(width: Constants.width)
            .background(.ultraThickMaterial)
            .cornerRadius(15)
        }
        .shadow(radius: 3)
        
        HStack {
            //location
            GeoButton(title: "nogeo", systemImage: "location.slash", id: 0, geoSelection: $geoSelection) {
                geoSelection = 0
            }

            GeoButton(title: locationString == nil ? "addgeo" : "\(locationString!)", systemImage: "location", id: 1, geoSelection: $geoSelection) {
                geoSelection = 1

                locationViewModel.requestPermission()
            }
        }
        .padding()
        .shadow(radius: 3)
    }
    
    @ViewBuilder
    private func photoTabItem(image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(height: Constants.height)
            .onTapGesture {
                withAnimation {
                    photoSelection = (photoSelection == 0) ? 1 : 0
                }
            }
    }
    
    private var uploadButton: some View {
        TextButton(text: "add", size: 330, color: (firstImage == nil || secondImage == nil) || download ? .gray : .blue) {
            
            withAnimation {
                download = true
                
                uploadToFirebase { ans in
                    download = false
                    
                    if ans {
                        withAnimation {
                            dismiss()
                        }
                        
                        DispatchQueue.main.async {
                            self.memoryViewModel.fetchGlobalMemories()
                        }
                    }
                }
            }
        }
        .disabled(download)
    }
}

extension NewPostView {
    private func uploadToFirebase(_ completion: @escaping (Bool) -> Void) {
        guard let id = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore().collection("Global Memories").document()
        
        var imageURLs = [String](repeating: "", count: images.count)
        
        var uploadedCount = 0
        
        images.enumerated().forEach { i, image in
            memoryViewModel.uploadImage(image: image) { url in
                if let url = url {
                    imageURLs[i] = url
                    uploadedCount += 1
                    
                    if uploadedCount == images.count {
                        
                        if let location = locationViewModel.location?.coordinate {
                            db.setData(["date": Date(), "images": imageURLs, "userID": id, "desc": text, "location": GeoPoint(latitude: location.latitude, longitude: location.longitude)])
                        } else {
                            db.setData(["date": Date(), "images": imageURLs, "userID": id, "desc": text])
                        }
                        
                        completion(true)
                    }
                } else {
                    completion(false)
                    
                    return
                }
            }
        }
    }
}

@MainActor
struct CameraPreview: UIViewRepresentable {
    @ObservedObject var camera: CameraViewModel
    
    public func makeUIView(context: Context) -> UIView {
        let frame = CGRect(x: 0, y: 0, width: Constants.width, height: Constants.height)
        let view = UIView(frame: frame)
        
        camera.preview = AVCaptureVideoPreviewLayer(session: camera.session)
        camera.preview.frame = view.frame
        
        camera.preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(camera.preview)
        
        DispatchQueue.main.async {
            camera.session.startRunning()
        }
        
        return view
    }
    
    public func updateUIView(_ uiView: UIView, context: Context) {
        
    }
}
