//
//  PhotoGalleryDetailView.swift
//  Memories
//
//  Created by Fadey Notchenko on 27.10.2022.
//

import SwiftUI

struct PhotoGalleryDetailView: View {
    
    @EnvironmentObject private var memoryViewModel: MemoryViewModel
    
    var body: some View {
        VStack {
            Header(text: "photo") {
                ImageButton(systemName: "xmark", color: .white) {
                    memoryViewModel.showPhotoGalleryView = false
                }
            }
            
            Spacer()
        }
    }
}
