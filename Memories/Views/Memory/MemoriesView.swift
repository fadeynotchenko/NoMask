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

struct MemoriesView: View {
    
    @State private var searchText = ""
    
    @EnvironmentObject private var memoryViewModel: MemoryViewModel
    
    @State private var linkMemoryError = false
    
    var body: some View {
        GeometryReader { reader in
            let width = reader.size.width
            
            ZStack {
                Color("Background").edgesIgnoringSafeArea(.all)
                
                if memoryViewModel.loadMyMemoriesStatus == .start {
                    ProgressView()
                        .shadow(radius: 3)
                }
                
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(memoryViewModel.memories.shuffled(), id: \.id) { memory in
                            MemoryCardView(memory: memory, size: width)
                        }
                    }
                    .offset(y: 70)
                    .padding(.bottom, 70)
                }
                .refreshable {
                    memoryViewModel.fetchMyMemories()
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
                if memoryViewModel.loadMemoryByIDStatus == .start {
                    ProgressView()
                        .frame(width: 50, height: 50)
                        .background(.ultraThickMaterial)
                        .cornerRadius(15)
                        .shadow(radius: 3)
                }
            }
//            .onChange(of: memoryViewModel.shareURL) { url in
//
//                if let url = url?.absoluteString {
//
//                    memoryViewModel.showProfileView = false
//                    memoryViewModel.showNewMemoryView = false
//
//                    if url.count == "https://mymemoriesapp.com/id=SobGhqJXcqajgNNrkSCdQFPsOFT2/memoryID=LEoPPtyeB9A0k2fDqiOp".count {
//
//                        memoryViewModel.fetchMemoryByLink(url) { memory in
//                            if let memory = memory {
//                                memoryViewModel.loadMemoryByIDStatus = .finish
//                            } else {
//                                withAnimation {
//                                    memoryViewModel.loadMemoryByIDStatus = .finish
//
//                                    linkMemoryError = true
//                                }
//                            }
//                        }
//                    } else {
//                        linkMemoryError = true
//                        memoryViewModel.shareURL = nil
//                    }
//                }
//            }
            .toast(isPresenting: $linkMemoryError) {
                AlertToast(displayMode: .banner(.pop), type: .error(.red), title: "Error")
            }
            .onAppear {
                memoryViewModel.fetchMyMemories()
            }
        }
    }
    
    private var header: some View {
        Title(text: "Memories")
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

