//
//  PhotoGalleryDetailView.swift
//  Memories
//
//  Created by Fadey Notchenko on 27.10.2022.
//

import SwiftUI
import Kingfisher

struct PhotoGalleryDetailView: View {
    
    let width: CGFloat
    
    @State private var fullScreenURLImage: URL?
    
    @EnvironmentObject private var memoryViewModel: MemoryViewModel
    
    var body: some View {
        ZStack {
            Color("Background").edgesIgnoringSafeArea(.all)
            
            VStack {
                Header(text: "photo") {
                    ImageButton(systemName: "xmark", color: .white) {
                        memoryViewModel.showPhotoGalleryView = false
                    }
                }
                
                ScrollView {
                    LazyVGrid(columns: [GridItem(), GridItem()], spacing: 15) {
                        if let memory = memoryViewModel.detailMemory {
                            ForEach(memory.images, id: \.self) { url in
                                if let url = url {
                                    Button {
                                        withAnimation {
                                            fullScreenURLImage = url
                                        }
                                    } label: {
                                        ImageItem(type: .url(url: url), size: width / 2.3)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .overlay {
                if let url = fullScreenURLImage {
                    ZStack {
                        KFImage(url)
                            .loadDiskFileSynchronously()
                            .resizable()
                            .scaledToFit()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color("Background"))
                    .edgesIgnoringSafeArea(.all)
                    .overlay(alignment: .topTrailing) {
                        ImageButton(systemName: "xmark", color: .white) {
                            withAnimation {
                                fullScreenURLImage = nil
                            }
                        }
                        .padding()
                    }
                }
            }
        }
    }
}
