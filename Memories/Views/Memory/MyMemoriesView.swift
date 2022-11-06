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

struct MyMemoriesView: View {
    
    @State private var searchText = ""
    
    @EnvironmentObject private var memoryViewModel: MemoryViewModel
    
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
                } else if memoryViewModel.loadMyMemoriesStatus == .start {
                    ProgressView()
                        .shadow(radius: 3)
                }
                
                ScrollView {
                    LazyVStack(spacing: 20) {
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
            .sheet(isPresented: $memoryViewModel.showNewMemoryView) {
                NewMemoryView()
            }
            .sheet(isPresented: $memoryViewModel.showProfileView) {
                ProfileView()
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
            .onChange(of: memoryViewModel.shareURL) { url in
                
                if let url = url?.absoluteString {
                    
                    memoryViewModel.showProfileView = false
                    memoryViewModel.showNewMemoryView = false
                    memoryViewModel.showPickerView = false
                    
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
            .toast(isPresenting: $linkMemoryError) {
                AlertToast(displayMode: .banner(.pop), type: .error(.red), title: "Error")
            }
            .onAppear {
                memoryViewModel.fetchMyMemories()
            }
        }
    }
    
    private var header: some View {
        VStack(spacing: 10) {
            Title(text: "Memories")
            
            HStack(spacing: 10) {
                Text("Мои Воспоминания")
                    .foregroundColor(.gray)
                    .bold()
                    .font(.system(size: 14))
//
//                Text("Глобальные")
//                    .foregroundColor(.gray)
//                    .bold()
//                    .font(.system(size: 14))
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .overlay(alignment: .leading) {
            ImageButton(systemName: "plus", color: .white) {
                memoryViewModel.showNewMemoryView = true
            }
            .padding()
            .padding(.top)
        }
        .overlay(alignment: .trailing) {
            ImageButton(systemName: "person.fill", color: .white) {
                memoryViewModel.showProfileView = true
            }
            .padding()
            .padding(.top)
        }
    }
}

extension MyMemoriesView {
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
