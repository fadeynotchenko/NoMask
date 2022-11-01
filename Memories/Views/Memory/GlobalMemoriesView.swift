//
//  GlobalMemories.swift
//  Memories
//
//  Created by Fadey Notchenko on 01.11.2022.
//

import SwiftUI

struct GlobalMemoriesView: View {
    
    
    @Namespace private var animation
    
    @EnvironmentObject private var memoryViewModel: MemoryViewModel
    
    var body: some View {
        GeometryReader { reader in
            
            let width = reader.size.width
            
            ZStack {
                Color("Background").edgesIgnoringSafeArea(.all)
                
                if memoryViewModel.globalMemories.isEmpty {
                    Text("empty")
                        .foregroundColor(.gray)
                } else if memoryViewModel.loadMyMemoriesStatus == .start {
                    ProgressView()
                        .shadow(radius: 3)
                }
                
                ScrollView {
                    LazyVStack(spacing: 20) {
                        
                        ForEach(memoryViewModel.globalMemories.sorted { $0.createdDate > $1.createdDate }, id: \.id) { memory in
                            Button {
                                
                            } label: {
//                                MemoryCardView(memory: Memory(id: memory.id, name: memory.name, date: memory.date, text: memory.text, images: memory.images), size: width, animatiom: animation)
                            }
                            
                        }
                    }
                    .offset(y: 70)
                    .padding(.bottom, 70)
                }
            }
            .overlay(alignment: .top) {
                Header(text: "Глобальные Воспоминания") {
                    ImageButton(systemName: "plus", color: .white) {
                        
                    }
                }
            }
            .onAppear {
                //fetch global memories
            }
        }
    }
}

extension GlobalMemoriesView {
//    openDetailView(memory)
}
