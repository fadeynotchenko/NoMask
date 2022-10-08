//
//  MemoryListView.swift
//  Memories
//
//  Created by Fadey Notchenko on 03.10.2022.
//

import SwiftUI
import CachedAsyncImage
import Firebase
import AVKit

struct MemoryListView: View {
    
    @State private var showNewMemoryView = false
    @State private var searchText = ""
    
    @EnvironmentObject private var viewModel: ViewModel
    @Namespace private var animation
    
    private var memories: [Memory] {
        if searchText.isEmpty {
            return viewModel.memories
        }
        
        return viewModel.memories.filter { $0.name.lowercased().contains(searchText.lowercased()) }
    }
    
    var body: some View {
        GeometryReader { reader in
            let width = reader.size.width
            
            ZStack {
                Color("Background").edgesIgnoringSafeArea(.all)
                
                if viewModel.loadStatus == .empty {
                    Text("Список пуст")
                } else if viewModel.loadStatus == .start {
                    ProgressView()
                }
                
                ScrollView {
                    LazyVStack(spacing: 20) {
                        
                        searchView
                            .frame(width: width - 20)
                        
                        ForEach(memories.sorted { $0.date > $1.date }, id: \.id) { memory in
                            Button {
                                withAnimation(.interactiveSpring(response: 0.8, dampingFraction: 0.8, blendDuration: 0.8)) {
                                    viewModel.detailMemory = memory
                                    viewModel.showDetail = true
                                }
                                
                                withAnimation(.interactiveSpring(response: 0.8, dampingFraction: 0.8, blendDuration: 0.8).delay(0.1)) {
                                    viewModel.animattion = true
                                }
                            } label: {
                                MemoryCardView(memory, width)
                            }
                            
                        }
                    }
                    .offset(y: 70)
                    .padding(.bottom, 70)
                }
            }
            .overlay(alignment: .top) {
                header
                    .opacity(showNewMemoryView ? 0 : 1)
            }
            .overlay {
                if let memory = viewModel.detailMemory, viewModel.showDetail {
                    MemoryDetailView(memory, width, reader)
                }
            }
            .fullScreenCover(isPresented: $showNewMemoryView) {
                NewMemoryView(dismiss: $showNewMemoryView)
            }
            .task {
                viewModel.fetchData()
            }
        }
    }
    
    private var searchView: some View {
        HStack(spacing: 5) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Поиск по названию", text: $searchText)
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
                Title(text: "Мои Воспоминания")
                
                Spacer()
                
                Menu {
                    Button {
                        withAnimation {
                            showNewMemoryView = true
                        }
                    } label: {
                        Label("Новое воспоминание", systemImage: "plus")
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
                        Label("Выйти", systemImage: "rectangle.portrait.arrowtriangle.2.inward")
                    }
                } label: {
                    ImageButton(systemName: "ellipsis", color: .white) { }
                }
            }
        }
        .padding()
    }
    
    @ViewBuilder
    private func MemoryCardView(_ memory: Memory, _ size: CGFloat) -> some View {
        TabView(selection: viewModel.detailMemory?.uuid == memory.uuid ? $viewModel.imageID : nil) {
            ForEach(0..<memory.images.count, id: \.self) { i in
                if let url = memory.images[i] {
                    ZStack(alignment: .bottomTrailing) {
                        ImageItem(type: .url(url: url), size: size - 20)
                        
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
                }
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(width: size, height: size)
        .disabled(!viewModel.showDetail)
        .matchedGeometryEffect(id: memory.uuid, in: animation)
        .shadow(radius: 5)
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
                    
                    if let text = memory.text {
                        descriptionView(text)
                    }
                }
                .opacity(viewModel.animattion ? 1 : 0)
                .scaleEffect(viewModel.animattion ? 1 : 0.8, anchor: .bottom)
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
                Button {
                    showNewMemoryView = true
                } label: {
                    Label("Редактировать", systemImage: "square.and.pencil")
                }
                
                Button {
                    
                } label: {
                    Label("Поделиться", systemImage: "icloud.and.arrow.up")
                }
            } label: {
                ImageButton(systemName: "ellipsis", color: .white) { }
                    .padding()
            }
        }
        .transition(.identity)
    }
    
    private func photoStack(_ memory: Memory, _ size: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Title(text: "Фото")
                .padding(.leading)
            
            ScrollView(.horizontal, showsIndicators: false) {
                ScrollViewReader { value in
                    LazyHStack(spacing: 15) {
                        ForEach(0..<memory.images.count, id: \.self) { i in
                            Button {
                                withAnimation {
                                    viewModel.imageID = i
                                }
                            } label: {
                                if let url = memory.images[i] {
                                    ImageItem(type: .url(url: url), size: 150)
                                        .frame(width: size / 3, height: size / 3)
                                        .clipped()
                                        .cornerRadius(15)
                                        .overlay(RoundedRectangle(cornerRadius: 15).stroke(lineWidth: (viewModel.imageID == i) ? 4 : 0).foregroundColor(Color.blue))
                                        .id(i)
                                }
                            }
                        }
                    }
                    .padding(.leading)
                    .onChange(of: viewModel.imageID) { _ in
                        value.scrollTo(viewModel.imageID)
                    }
                }
            }
            .frame(height: 150)
        }
    }
    
    @ViewBuilder
    private func descriptionView(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Title(text: "Описание")
            
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
        viewModel.imageID = 0
        
        withAnimation(.interactiveSpring(response: 0.8, dampingFraction: 0.8, blendDuration: 0.8)) {
            viewModel.animattion = false
            viewModel.detailMemory = nil
            viewModel.showDetail = false
        }
    }
}
