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
import UIKit

struct MemoryDetailView: View {
    
    let memory: Memory
    let size: CGFloat
    let reader: GeometryProxy
    let animation: Namespace.ID
    
    @State private var deleteDialog = false
    @State private var reportDialog = false
    @State private var reportIsSent = false
    @State private var memoryIsDownloaded = false
    
    @State private var position: CGFloat = 0
    
    @EnvironmentObject private var memoryViewModel: MemoryViewModel
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                MemoryCardView(memory: memory, size: size, animatiom: animation)
                
                VStack(spacing: 20) {
                    photoStack(size)
                    
                    if let text = memory.text, !text.isEmpty {
                        descriptionView(text)
                    }
                }
                .opacity(memoryViewModel.animation ? 1 : 0)
                .scaleEffect(memoryViewModel.animation ? 1 : 0.8, anchor: .bottom)
            }
            .background(GeometryReader {
                Color.clear.preference(key: ViewOffsetKey.self, value: -$0.frame(in: .named("scroll")).origin.y)
            })
            .onPreferenceChange(ViewOffsetKey.self) {
                position = $0
            }
        }
        .background(Color("Background").edgesIgnoringSafeArea(.all))
        .coordinateSpace(name: "scroll")
        .overlay(alignment: .topLeading) {
            ImageButton(systemName: "xmark", color: .white) {
                closeDetailView()
            }
            .padding()
        }
        .onChange(of: position) { _ in
            if position <= -100 {
                closeDetailView()
            }
        }
        .overlay(alignment: .topTrailing) {
            menu
        }
        .toast(isPresenting: $memoryIsDownloaded) {
            AlertToast(displayMode: .banner(.pop), type: .complete(.green), title: Constants.language == "ru" ? "Воспоминание добавлено" : "Memory added")
        }
        .toast(isPresenting: $memoryViewModel.imageDownloaded) {
            AlertToast(displayMode: .banner(.pop), type: .complete(.green), title: Constants.language == "ru" ? "Фотография добавлена в галерею" : "Photo added to gallery")
        }
        .toast(isPresenting: $reportIsSent) {
            AlertToast(displayMode: .banner(.pop), type: .complete(.green), title: Constants.language == "ru" ? "Жалоба отправлена" : "Complaint sent")
        }
        .confirmationDialog("", isPresented: $deleteDialog) {
            Button {
                if let memory = memoryViewModel.detailMemory {
                    delete(memory)
                }
                
                closeDetailView()
                
                WidgetCenter.shared.reloadAllTimelines()
            } label: {
                Text("delete")
                    .accentColor(.red)
            }
        } message: {
            Text("deletequestion")
        }
        .confirmationDialog("", isPresented: $reportDialog) {
            Button {
                if let userID = memory.userID {
                    Firestore.firestore().collection("Reports").document().setData(["id": memory.id, "userID": userID])
                    reportIsSent = true
                }
            } label: {
                Text("yesreport")
                    .accentColor(.red)
            }
        } message: {
            Text("report2")
        }
        .sheet(isPresented: $memoryViewModel.showPhotoGalleryView) {
            PhotoGalleryDetailView(width: size)
        }
        .transition(.identity)
    }
    
    private var menu: some View {
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
                        Firestore.firestore().collection("Self Memories").document(id).collection("Memories").document().setData(["name": memory.name, "date": memory.date, "text": memory.text, "images": memory.images.compactMap { $0?.absoluteString }])
                        
                        memoryIsDownloaded = true
                    }
                } label: {
                    Label("add2", systemImage: "plus")
                }
                
                Button {
                    reportDialog = true
                } label: {
                    Label("report", systemImage: "exclamationmark.triangle")
                }
            }
        } label: {
            ImageButton(systemName: "ellipsis", color: .white) { }
                .padding()
        }
    }
    
    private func photoStack(_ size: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Title(text: "photo")
                    .padding(.leading)
                
                Spacer()
                
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
                                withAnimation {
                                    memoryViewModel.imageID = i
                                }
                            } label: {
                                if let url = memory.images[i] {
                                    ImageItem(type: .url(url: url), size: 150)
                                        .frame(width: size / 3, height: size / 3)
                                        .clipped()
                                        .cornerRadius(15)
                                        .overlay(RoundedRectangle(cornerRadius: 15).stroke(lineWidth: (memoryViewModel.imageID == i) ? 4 : 0).foregroundColor(Color.blue))
                                        .id(i)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .onChange(of: memoryViewModel.imageID) { _ in
                        withAnimation {
                            value.scrollTo(memoryViewModel.imageID)
                        }
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
        
        Firestore.firestore().collection("Self Memories").document(id).collection("Memories").document(memory.id).delete { _ in }
        
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

struct ViewOffsetKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue = CGFloat.zero
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}
