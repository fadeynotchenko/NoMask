//
//  MemoryCardPreview.swift
//  No Mask
//
//  Created by Fadey Notchenko on 09.11.2022.
//

import SwiftUI

struct MemoryCardPreview: View {
    
    var images: [UIImage]
    @State private var selection = 0
    
    var body: some View {
        TabView(selection: $selection) {
            ForEach(0..<images.count, id: \.self) { i in
                if let image = images[i] {
                    VStack(spacing: 0) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: Constants.width, height: Constants.height)
                            .shadow(radius: 3)
                            .clipped()
                            .transition(.identity)
                            .onTapGesture {
                                withAnimation {
                                    selection = selection == 0 ? 1 : 0
                                }
                            }
                    }
                    .background(.ultraThickMaterial)
                }
            }
        }
        .tabViewStyle(.page(indexDisplayMode: images.count == 1 ? .never : .always))
        .frame(width: Constants.width, height: Constants.height)
        .cornerRadius(15)
        .shadow(radius: 3)
    }
}

