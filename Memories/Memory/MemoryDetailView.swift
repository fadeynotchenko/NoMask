//
//  MemoryDetailView.swift
//  Memories
//
//  Created by Fadey Notchenko on 26.10.2022.
//

import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseFirestore
import AlertToast
import WidgetKit

struct MemoryDetailView: View {
    
    let memory: Memory
    let size: CGFloat
    let reader: GeometryProxy
    let animation: Namespace.ID
    
    @State private var deleteDialog = false
    @State private var memoryIsDownloaded = false
    @State private var imageDownloaded = false
    
    @EnvironmentObject private var memoryViewModel: MemoryViewModel
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                GeometryReader { proxy in
                    MemoryCardView(memory: memory, size: size, animatiom: animation)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .onChange(of: scale(reader.frame(in: .global).minY, proxy.frame(in: .global).minY)) { scale in
                            if scale <= 0.30 {
                                closeDetailView()
                            }
                        }
                }
                
                VStack(spacing: 20) {
                    photoStack(memory, size)
                    
                    if let text = memory.text, !text.isEmpty {
                        descriptionView(text)
                    }
                }
                .opacity(memoryViewModel.animation ? 1 : 0)
                .scaleEffect(memoryViewModel.animation ? 1 : 0.8, anchor: .bottom)
                .padding(.top, size - 20)
            }
        }
        .background(Color("Background").edgesIgnoringSafeArea(.all))
        .overlay(alignment: .topLeading) {
            ImageButton(systemName: "xmark", color: .white) {
                closeDetailView()
            }
            .padding()
        }
        .overlay(alignment: .topTrailing) {
            Menu {
                //for personal memory
                if memoryViewModel.shareURL == nil {
                    Button {
                        memoryViewModel.showNewMemoryView = true
                    } label: {
                        Label("edit", systemImage: "square.and.pencil")
                    }
                    
                    Button {
                        guard let id = Auth.auth().currentUser?.uid else { return }
                        
                        shareApp(link: "https://mymemoriesapp.com/id=\(id)/memoryID=\(memory.id)")
                    } label: {
                        Label("share", systemImage: "icloud.and.arrow.up")
                    }
                    
                    Button {
                        deleteDialog = true
                    } label: {
                        Label("delete", systemImage: "trash")
                    }
                } else {
                    Button {
                        if let id = Auth.auth().currentUser?.uid {
                            Firestore.firestore().collection(id).document().setData(["name": memory.name, "date": memory.date, "text": memory.text, "images": memory.images.map { $0.absoluteString }])
                            
                            memoryIsDownloaded = true
                        }
                    } label: {
                        Label("add2", systemImage: "plus")
                    }
                }
            } label: {
                ImageButton(systemName: "ellipsis", color: .white) { }
                    .padding()
            }
        }
        .toast(isPresenting: $imageDownloaded) {
            AlertToast(displayMode: .banner(.pop), type: .complete(.green), title: Constants.language == "ru" ? "Фотография добавлена в галерею" : "Photo added to gallery")
        }
        .toast(isPresenting: $memoryIsDownloaded) {
            AlertToast(displayMode: .banner(.pop), type: .complete(.green), title: Constants.language == "ru" ? "Воспоминание добавлено" : "Memory added")
        }
        .confirmationDialog("", isPresented: $deleteDialog) {
            Button {
                if let memory = memoryViewModel.detailMemory {
                    delete(memory)
                }
                
                closeDetailView()
            } label: {
                Text("delete")
                    .foregroundColor(.red)
            }
        } message: {
            Text("deletequestion")
        }
        .fullScreenCover(isPresented: $memoryViewModel.showPhotoGalleryView) {
            PhotoGalleryDetailView(width: size)
        }
        .transition(.identity)
    }
    
    
    private func photoStack(_ memory: Memory, _ size: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Title(text: "photo")
                    .padding(.leading)
                
                Spacer()
                
                //next update
                
                Button {
                    memoryViewModel.showPhotoGalleryView = true
                } label: {
                    HStack(spacing: 5) {
                        Text("all")

                        Text("(\(memory.images.count))")
                    }
                    .foregroundColor(.blue)
                }
                .padding(.horizontal)
            }
            .frame(maxWidth: size)
            
            ScrollView(.horizontal, showsIndicators: false) {
                ScrollViewReader { value in
                    LazyHStack(spacing: 15) {
                        ForEach(0..<memory.images.count, id: \.self) { i in
                            Button {
                                memoryViewModel.imageID = i
                            } label: {
                                if let url = memory.images[i] {
                                    ImageItem(type: .url(url: url), size: 150)
                                        .frame(width: size / 3, height: size / 3)
                                        .clipped()
                                        .cornerRadius(15)
                                        .overlay(RoundedRectangle(cornerRadius: 15).stroke(lineWidth: (memoryViewModel.imageID == i) ? 4 : 0).foregroundColor(Color.blue))
                                        .id(i)
                                        .contextMenu {
                                            Button {
                                                memoryViewModel.downloadImage(url) { ans in
                                                    if ans {
                                                        imageDownloaded = true
                                                    }
                                                }
                                            } label: {
                                                Label("saveimages", systemImage: "square.and.arrow.down")
                                            }
                                        }
                                }
                            }
                        }
                    }
                    .padding(.leading)
                    .onChange(of: memoryViewModel.imageID) { _ in
                        value.scrollTo(memoryViewModel.imageID)
                    }
                }
            }
            .frame(height: 150)
        }
    }
    
    private func descriptionView(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Title(text: "desc")
            
            Text(text)
                .foregroundColor(.gray)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading)
    }
}

extension MemoryDetailView {
    private func scale(_ main: CGFloat, _ min: CGFloat) -> CGFloat {
        let scale = main / min
        
        if scale < 0 {
            return 1
        }
        
        return scale
    }
    
    private func closeDetailView() {
        memoryViewModel.imageID = 0
        
        withAnimation(.interactiveSpring(response: 0.8, dampingFraction: 0.8, blendDuration: 0.8)) {
            memoryViewModel.animation = false
            memoryViewModel.showDetail = false
            memoryViewModel.detailMemory = nil
            memoryViewModel.shareURL = nil
        }
    }
    
    private func delete(_ memory: Memory) {
        guard let id = Auth.auth().currentUser?.uid else { return }
        
        memory.images.forEach { url in
            Storage.storage().reference(forURL: url.absoluteString).delete { _ in }
        }
        
        Firestore.firestore().collection(id).document(memory.id).delete()
        
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func shareApp(link: String) {
        let activityViewController = UIActivityViewController(activityItems: [link], applicationActivities: nil)
        
        let viewController = Coordinator.topViewController()
        activityViewController.popoverPresentationController?.sourceView = viewController?.view
        viewController?.present(activityViewController, animated: true, completion: nil)
    }
    
    
    enum Coordinator {
        static func topViewController(_ viewController: UIViewController? = nil) -> UIViewController? {
            let vc = viewController ?? UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController
            if let navigationController = vc as? UINavigationController {
                return topViewController(navigationController.topViewController)
            } else if let tabBarController = vc as? UITabBarController {
                return tabBarController.presentedViewController != nil ? topViewController(tabBarController.presentedViewController) : topViewController(tabBarController.selectedViewController)
                
            } else if let presentedViewController = vc?.presentedViewController {
                return topViewController(presentedViewController)
            }
            return vc
        }
    }
}
