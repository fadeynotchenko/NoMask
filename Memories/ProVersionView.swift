//
//  ProVersionView.swift
//  Memories
//
//  Created by Fadey Notchenko on 16.10.2022.
//

import SwiftUI

struct ProVersionView: View {
    
    @Binding var dismiss: Bool
    
    @EnvironmentObject private var store: Store
    
    var body: some View {
        GeometryReader { reader in
            VStack(spacing: 15) {
                header
                
                Text("")
            }
        }
    }
    
    private var header: some View {
        VStack {
            HStack {
                Title(text: "Memory Pro")
                
                Spacer()
                
                ImageButton(systemName: "ellipsis", color: .white) {
                    dismiss = false
                }
            }
        }
        .padding()
    }
}
