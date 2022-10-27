//
//  MemoryCardView.swift
//  Memories
//
//  Created by Fadey Notchenko on 26.10.2022.
//

import SwiftUI

struct MemoryCardView: View {
    
    let memory: Memory
    let size: CGFloat
    let animatiom: Namespace.ID
    
    @EnvironmentObject private var memoryViewModel: MemoryViewModel
    
    var body: some View {
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
                                
                                Text(memory.date, format: .dateTime.year().month().day())
                                    .bold()
                                    .font(.system(size: size / 20))
                                    .foregroundColor(.white)
                            }
                            .padding(size / 30)
                            .shadow(radius: 3)
                        }
                }
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(width: size, height: size)
        .disabled(!memoryViewModel.showDetail)
        .matchedGeometryEffect(id: memory.uuid, in: animatiom)
        .shadow(radius: 3)
    }
}
