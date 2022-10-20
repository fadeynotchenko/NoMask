//
//  ProVersionView.swift
//  Memories
//
//  Created by Fadey Notchenko on 16.10.2022.
//

import SwiftUI
import AlertToast

struct ProVersionView: View {
    
    @Binding var dismiss: Bool
    
    @State private var restored = false
    @State private var error = false
    
    @EnvironmentObject private var store: Store
    @EnvironmentObject private var memoryViewModel: MemoryViewModel
    
    var body: some View {
        GeometryReader { reader in
            VStack(spacing: 15) {
                header
                
                Text("protext1")
                    .bold()
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Text("protext2")
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                
                Text("protext3")
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                
                Spacer()
                
                buyButton
                
                Button("restore") {
                    Task {
                        await store.restore { ans in
                            if ans {
                                restored = true
                            } else {
                                error = true
                            }
                        }
                    }
                }
                .disabled(!store.purchased.isEmpty)
            }
            .toast(isPresenting: $error) {
                AlertToast(displayMode: .banner(.pop), type: .error(.red), title: memoryViewModel.language == "ru" ? "Ошибка" : "Error")
            }
            .toast(isPresenting: $restored) {
                AlertToast(displayMode: .banner(.pop), type: .complete(.green), title: memoryViewModel.language == "ru" ? "Покупки восстановлены" : "Purchases restored")
            }
        }
    }
    
    private var header: some View {
        VStack {
            HStack {
                Title(text: "Memory Pro")
                
                Spacer()
                
                ImageButton(systemName: "xmark", color: .white) {
                    dismiss = false
                }
            }
        }
        .padding()
    }
    
    private var buyButton: some View {
        Button {
            
        } label: {
            if store.purchased.isEmpty, let product = store.products.first {
                TextButton(text: memoryViewModel.language == "ru" ? "Купить \(product.displayPrice)" : "Buy \(product.displayPrice)", size: 300, color: .white) {
                    Task {
                        await store.purchase()
                    }
                }
            } else {
                TextButton(text: "purchased", size: 300, color: .gray) {
                    
                }
                .disabled(true)
            }
        }
    }
}
