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
import WidgetKit

struct MemoryListView: View {
    
    @State private var searchText = ""
    
    @EnvironmentObject private var memoryViewModel: MemoryViewModel
    @EnvironmentObject private var storeViewModel: StoreViewModel
    
    @State private var linkMemoryError = false
    
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
                        
                        ForEach(memories.sorted { $0.date > $1.date }, id: \.id) { memory in
                            Button {
                                openDetailView(memory)
                            } label: {
                                MemoryCardView(memory: memory, size: width, animatiom: animation)
                            }
                            
                        }
                    }
                    .offset(y: 70)
                    .padding(.bottom, 70)
                }
            }
            .overlay(alignment: .top) {
                header
            }
            .overlay {
                if let memory = memoryViewModel.detailMemory, memoryViewModel.showDetail {
                    MemoryDetailView(memory: memory, size: width, reader: reader, animation: animation)
                }
                
                if memoryViewModel.loadMemoryByIDStatus == .start {
                    ProgressView()
                        .frame(width: 50, height: 50)
                        .background(.ultraThickMaterial)
                        .cornerRadius(15)
                        .shadow(radius: 3)
                }
            }
            .toast(isPresenting: $memoryViewModel.imageDownloaded) {
                AlertToast(displayMode: .banner(.pop), type: .complete(.green), title: Constants.language == "ru" ? "Фотография добавлена в галерею" : "Photo added to gallery")
            }
            .fullScreenCover(isPresented: $memoryViewModel.showNewMemoryView) {
                NewMemoryView(dismiss: $memoryViewModel.showNewMemoryView)
            }
            .fullScreenCover(isPresented: $memoryViewModel.showProVersionView) {
                ProVersionView()
            }
            .onChange(of: memoryViewModel.shareURL) { url in
                
                if let url = url?.absoluteString {
                    
                    memoryViewModel.showNewMemoryView = false
                    memoryViewModel.showProVersionView = false
                    memoryViewModel.showPhotoGalleryView = false
                    
                    if url.count == "https://mymemoriesapp.com/id=SobGhqJXcqajgNNrkSCdQFPsOFT2/memoryID=LEoPPtyeB9A0k2fDqiOp".count {
                        
                        memoryViewModel.fetchMemoryByLink(url) { memory in
                            if let memory = memory {
                                memoryViewModel.loadMemoryByIDStatus = .finish
                                
                                openDetailView(memory)
                            } else {
                                withAnimation {
                                    memoryViewModel.loadMemoryByIDStatus = .finish
                                    
                                    linkMemoryError = true
                                }
                            }
                        }
                    } else {
                        linkMemoryError = true
                        memoryViewModel.shareURL = nil
                    }
                }
            }
            .onAppear {
                memoryViewModel.fetchAllMemories()
                
                if Constants.language == "ru" {
                    memoryViewModel.singleQuote = Constants.ruQuotes.randomElement()
                } else {
                    memoryViewModel.singleQuote = Constants.engQuotes.randomElement()
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
        Header(text: "mymemories") {
            Menu {
                Button {
                    if memories.count >= 3 && storeViewModel.isSubscription == false {
                        memoryViewModel.showProVersionView = true
                    } else {
                        memoryViewModel.showNewMemoryView = true
                    }
                } label: {
                    Label("new", systemImage: "plus")
                }
                
                Button {
                    memoryViewModel.showProVersionView = true
                } label: {
                    Label("Memories Pro", systemImage: "star")
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
}

extension MemoryListView {
    func openDetailView(_ memory: Memory) {
        withAnimation(.interactiveSpring(response: 0.8, dampingFraction: 0.8, blendDuration: 0.8)) {
            memoryViewModel.detailMemory = memory
            memoryViewModel.showDetail = true
        }
        
        withAnimation(.interactiveSpring(response: 0.8, dampingFraction: 0.8, blendDuration: 0.8).delay(0.1)) {
            memoryViewModel.animation = true
        }
    }
}
