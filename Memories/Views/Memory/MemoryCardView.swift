//
//  MemoryCardView.swift
//  Memories
//
//  Created by Fadey Notchenko on 26.10.2022.
//

import SwiftUI
import AlertToast

struct MemoryCardView: View {
    
    let memory: Memory
    let size: CGFloat
    
    @State private var selection = 0
    
    @EnvironmentObject private var memoryViewModel: MemoryViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $selection) {
                ForEach(0..<memory.images.count, id: \.self) { i in
                    if let url = memory.images[i] {
                        VStack(spacing: 0) {
                            ImageItem(url: url, size: size - 20)
                                .contextMenu {
                                    Button {
                                        memoryViewModel.saveImageToGallery(url) { ans in
                                            if ans {
                                                memoryViewModel.imageDownloaded = true
                                            }
                                        }
                                    } label: {
                                        Label("saveimages", systemImage: "square.and.arrow.down")
                                    }
                                }
                        }
                        .background(.ultraThickMaterial)
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: memory.images.count == 1 ? .never : .always))
            .frame(width: size - 20, height: size - 20)
            .overlay(alignment: .topTrailing) {
//                Menu {
//
//                } label: {
//                    ImageButton(systemName: "ellipsis", color: .white) { }
//                }
//                .padding()
            }
            
            HStack(spacing: 0) {
                if let url = memory.userImage {
                    
                } else {
                    Image(systemName: "person.fill")
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(0.7)
                        .frame(width: 40, height: 40)
                        .foregroundColor(.white)
                        .background(Color("Background"))
                        .clipShape(Circle())
                        .padding(.leading)
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    Title(text: "\(memory.userName)", font: .system(size: 15))
                    
                    Text(memory.date.timeAgoDisplay())
                        .bold()
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
                .padding()
                
                Spacer()
            }
            .frame(maxWidth: size - 20)
            .background(.ultraThickMaterial)
            .cornerRadius(15, corners: [.bottomLeft, .bottomRight])
        }
        .background(.ultraThickMaterial)
        .cornerRadius(15)
        .shadow(radius: 3)
    }
}
