//
//  SettingsView.swift
//  No Mask
//
//  Created by Fadey Notchenko on 14.11.2022.
//

import SwiftUI
import Kingfisher

struct SettingsView: View {
    
    @State private var clearned = false
    
    @EnvironmentObject private var memoryViewModel: ViewModel
    
    private var cache = ImageCache.default
    
    private var cacheSize: UInt {
        do {
            return try cache.diskStorage.totalSize() / 1024 / 1024
        } catch {
            print(error.localizedDescription)
        }
        
        return 0
    }
    
    var body: some View {
        ZStack {
            Color("Background").edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 15) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Cache")
                        .foregroundColor(.gray)
                    
                    clearButton
                }
                
                Spacer()
            }
        }
        .navigationTitle(Text("settings"))
        .navigationBarTitleDisplayMode(.inline)
    }
    
    var clearButton: some View {
        TextButton(text: "Clear cache (\(clearned ? 0 : cacheSize) Mb)", size: Constants.width, color: .white) {
            cache.clearDiskCache()
            
            withAnimation {
                clearned = true
            }
        }
        
        .disabled(clearned)
    }
}

