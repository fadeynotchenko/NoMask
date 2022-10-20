//
//  MemoryListView.swift
//  Memories
//
//  Created by Fadey Notchenko on 03.10.2022.
//

import SwiftUI
import CachedAsyncImage
import Firebase
import FirebaseStorage
import AlertToast
import FirebaseFirestore
import FirebaseAuth

struct MemoryListView: View {
    
    @State private var searchText = ""
    
    @State private var deleteDialog = false
    @State private var memoryIsDownloaded = false
    @State private var linkMemoryError = false
    
    @EnvironmentObject private var memoryViewModel: MemoryViewModel
    
    @Namespace private var animation
    
    private var memories: [Memory] {
        if searchText.isEmpty {
            return memoryViewModel.memories
        }
        
        return memoryViewModel.memories.filter { $0.name.lowercased().contains(searchText.lowercased()) }
    }
    
    var body: some View {
        GeometryReader { reader in
            let width = reader.size.width
            
            ZStack {
                Color("Background").edgesIgnoringSafeArea(.all)
                
                if memories.isEmpty {
                    Text("empty")
                        .foregroundColor(.gray)
                } else if memoryViewModel.loadStatus == .start {
                    ProgressView()
                        .shadow(radius: 3)
                }
                
                ScrollView {
                    LazyVStack(spacing: 20) {
                        quote
                            .frame(width: width - 20)
                        
                        searchView
                            .frame(width: width - 20)
                        
                        if memoryViewModel.loadMemoryByIDStatus == .start {
                            ProgressView()
                                .frame(width: 50, height: 50)
                                .background(.ultraThickMaterial)
                                .cornerRadius(15)
                                .shadow(radius: 3)
                        }
                        
                        ForEach(memories.sorted { $0.date > $1.date }, id: \.id) { memory in
                            Button {
                                withAnimation(.interactiveSpring(response: 0.8, dampingFraction: 0.8, blendDuration: 0.8)) {
                                    memoryViewModel.detailMemory = memory
                                    memoryViewModel.showDetail = true
                                }
                                
                                withAnimation(.interactiveSpring(response: 0.8, dampingFraction: 0.8, blendDuration: 0.8).delay(0.1)) {
                                    memoryViewModel.animattion = true
                                }
                            } label: {
                                MemoryCardView(memory, width)
                            }
                            
                        }
                    }
                    .offset(y: 70)
                    .padding(.bottom, 70)
                }
                .coordinateSpace(name: "scroll")
            }
            .overlay(alignment: .top) {
                header
//                    .opacity(scrolling ? 0 : 1)
            }
            .overlay {
                if let memory = memoryViewModel.detailMemory, memoryViewModel.showDetail {
                    MemoryDetailView(memory, width, reader)
                }
            }
            .sheet(isPresented: $memoryViewModel.showNewMemoryView) {
                NewMemoryView(dismiss: $memoryViewModel.showNewMemoryView)
            }
            .sheet(isPresented: $memoryViewModel.showProVersionView) {
                ProVersionView(dismiss: $memoryViewModel.showProVersionView)
            }
            .confirmationDialog("", isPresented: $deleteDialog) {
                Button {
                    if let memory = memoryViewModel.detailMemory {
                        delete(memory)
                    }
                    
                    animationDismiss()
                } label: {
                    Text("delete")
                        .foregroundColor(.red)
                }
            } message: {
                Text("deletequestion")
            }
            .onAppear {
                memoryViewModel.fetchAllMemories()
            }
            .toast(isPresenting: $linkMemoryError) {
                AlertToast(displayMode: .banner(.pop), type: .error(.red), title: memoryViewModel.language == "ru" ? "Ошибка загрузки" : "Loading error")
            }
            .onChange(of: memoryViewModel.shareURL) { url in
                
                if let url = url?.absoluteString {
                    
                    if url.count == "https://mymemoriesapp.com/id=SobGhqJXcqajgNNrkSCdQFPsOFT2/memoryID=LEoPPtyeB9A0k2fDqiOp".count {
                        
                        memoryViewModel.fetchMemoryByLink(url) { memory in
                            if let memory = memory {
                                memoryViewModel.loadMemoryByIDStatus = .finish
                                
                                withAnimation(.interactiveSpring(response: 0.8, dampingFraction: 0.8, blendDuration: 0.8)) {
                                    memoryViewModel.detailMemory = memory
                                    memoryViewModel.showDetail = true
                                }
                                
                                withAnimation(.interactiveSpring(response: 0.8, dampingFraction: 0.8, blendDuration: 0.8).delay(0.1)) {
                                    memoryViewModel.animattion = true
                                }
                            } else {
                                withAnimation {
                                    memoryViewModel.loadMemoryByIDStatus = .finish
                                    
                                    linkMemoryError = true
                                }
                            }
                        }
                    } else {
                        linkMemoryError = true
                    }
                }
            }
        }
    }
    
    private var searchView: some View {
        HStack(spacing: 5) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("search", text: $searchText)
                .overlay(alignment: .trailing) {
                    if !searchText.isEmpty {
                        Button {
                            withAnimation {
                                searchText = ""
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .frame(width: 20, height: 20)
                                .foregroundColor(.red)
                        }
                    }
                }
        }
        .padding(10)
        .background(.ultraThickMaterial)
        .cornerRadius(15)
        .shadow(radius: 3)
    }
    
    private var header: some View {
        VStack {
            HStack {
                Title(text: "mymemories")
                
                Spacer()
                
                Menu {
                    Button {
                        memoryViewModel.showNewMemoryView = true
                    } label: {
                        Label("new", systemImage: "plus")
                    }
                    
                    Button {
                        memoryViewModel.showProVersionView = true
                    } label: {
                        Label("Memory Pro", systemImage: "star")
                    }
                    
                    Button {
                        withAnimation {
                            do {
                                try Auth.auth().signOut()
                                
                                UserDefaults.standard.set(false, forKey: "isLoggin")
                            } catch {
                                //error
                            }
                        }
                    } label: {
                        Label("quit", systemImage: "rectangle.portrait.arrowtriangle.2.inward")
                    }
                } label: {
                    ImageButton(systemName: "ellipsis", color: .white) { }
                }
            }
        }
        .padding()
    }
    
    @ViewBuilder
    private var quote: some View {
        if let modelQuote = memoryViewModel.singleQuote {
            VStack(alignment: .leading, spacing: 15) {
                Text(modelQuote.text)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.leading)
                
                Text(modelQuote.author)
                    .bold()
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding()
            .background(.ultraThickMaterial)
            .cornerRadius(15)
            .shadow(radius: 3)
        }
    }
    
    @ViewBuilder
    private func MemoryCardView(_ memory: Memory, _ size: CGFloat) -> some View {
        TabView(selection: memoryViewModel.detailMemory?.uuid == memory.uuid ? $memoryViewModel.imageID : nil) {
            ForEach(0..<memory.images.count, id: \.self) { i in
                if let url = memory.images[i] {
                    ImageItem(type: .url(url: url), size: size - 20)
                        .overlay(alignment: .bottomTrailing) {
                            VStack(alignment: .trailing) {
                                Text(memory.name)
                                    .bold()
                                    .font(.system(size: size / 15))
                                    .foregroundColor(.white)
                                    .shadow(radius: 5)
                                
                                Text(memory.date, format: .dateTime.year().month().day())
                                    .bold()
                                    .font(.system(size: size / 20))
                                    .foregroundColor(.white)
                                    .shadow(radius: 5)
                            }
                            .padding(size / 30)
                        }
                        .contextMenu {
                            Button {
                                
                            } label: {
                                Label("saveimages", systemImage: "square.and.arrow.down")
                            }
                        }
                }
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(width: size, height: size)
        .disabled(!memoryViewModel.showDetail)
        .matchedGeometryEffect(id: memory.uuid, in: animation)
        .shadow(radius: 3)
    }
    
    @ViewBuilder
    private func MemoryDetailView(_ memory: Memory, _ size: CGFloat, _ reader: GeometryProxy) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                GeometryReader { proxy in
                    MemoryCardView(memory, size)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .onChange(of: scale(reader.frame(in: .global).minY, proxy.frame(in: .global).minY)) { scale in
                            if scale <= 0.30 {
                                animationDismiss()
                            }
                        }
                }
                
                VStack(spacing: 20) {
                    photoStack(memory, size)
                    
                    if let text = memory.text, !text.isEmpty {
                        descriptionView(text)
                    }
                }
                .opacity(memoryViewModel.animattion ? 1 : 0)
                .scaleEffect(memoryViewModel.animattion ? 1 : 0.8, anchor: .bottom)
                .padding(.top, size - 20)
            }
        }
        .background(Color("Background").edgesIgnoringSafeArea(.all))
        .overlay(alignment: .topLeading) {
            ImageButton(systemName: "xmark", color: .white) {
                animationDismiss()
            }
            .padding()
        }
        .overlay(alignment: .topTrailing) {
            Menu {
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
                            Firestore.firestore().collection(id).document().setData(["name": memory.name, "date": memory.date, "text": memory.text ?? "", "images": memory.images.map { $0.absoluteString }])
                            
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
        .transition(.identity)
        .toast(isPresenting: $memoryIsDownloaded) {
            AlertToast(displayMode: .banner(.pop), type: .complete(.green), title: memoryViewModel.language == "ru" ? "Воспоминание добавлено" : "Memory added")
        }
    }
    
    private func photoStack(_ memory: Memory, _ size: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Title(text: "photo")
                .padding(.leading)
            
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
                    .padding(.leading)
                    .onChange(of: memoryViewModel.imageID) { _ in
                        value.scrollTo(memoryViewModel.imageID)
                    }
                }
            }
            .frame(height: 150)
        }
    }
    
    @ViewBuilder
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

extension MemoryListView {
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
    
    private func scale(_ main: CGFloat, _ min: CGFloat) -> CGFloat {
        let scale = main / min
        
        if scale < 0 {
            return 1
        }
        
        return scale
    }
    
    private func animationDismiss() {
        memoryViewModel.imageID = 0
        
        withAnimation(.interactiveSpring(response: 0.8, dampingFraction: 0.8, blendDuration: 0.8)) {
            memoryViewModel.animattion = false
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
    }
}
