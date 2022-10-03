//
//  MemoryListView.swift
//  Memories
//
//  Created by Fadey Notchenko on 03.10.2022.
//

import SwiftUI

struct MemoryListView: View {
    
    @State private var showNewMemoryView = false
    
    @State private var scrollOffset: CGFloat = 0
    @Namespace private var animation
    
    var body: some View {
        GeometryReader { reader in
            let width = reader.size.width
            
            ZStack {
                Color("Background").edgesIgnoringSafeArea(.all)
            }
            .overlay {
                if showNewMemoryView {
                    NewMemoryView(dismiss: $showNewMemoryView)
                }
            }
            .overlay(alignment: .top) {
                header
                    .opacity(showNewMemoryView ? 0 : 1)
            }
        }
    }
    
    private var header: some View {
        VStack {
            HStack {
                Title(text: "Мои Воспоминания")
                
                Spacer()
                
                ImageButton(systemName: "plus", color: .white) {
                    withAnimation {
                        showNewMemoryView = true
                    }
                }
            }
            .shadow(radius: 3)
        }
        .padding()
    }
}

