//
//  StoreViewModel.swift
//  Memories
//
//  Created by Fadey Notchenko on 16.10.2022.
//

import SwiftUI
import StoreKit

class Store: ObservableObject {
    @Published var products: [Product] = []
    @Published var purchased: [String] = []
    
    var taskHandle: Task<Void, Error>? = nil
    
    private let userDefaults = UserDefaults.standard
    
    init() {
        taskHandle = listenForTransactions()
    }
    
    @MainActor
    func fetchProducts() async {
        do {
            let products = try await Product.products(for: ["FN.Memories.FullVersion"])
            self.products = products
        } catch {
            print(error)
        }
    }
    
    func isPurchased(_ product: Product) async {
        guard let state = await product.currentEntitlement else { return }
        
        switch state {
        case .verified(let tr):
            purchased.append(tr.productID)
        case .unverified(_, _):
            break
        }
    }
    
    func restore() async -> Bool {
        try? await AppStore.sync()
                
        for await result in Transaction.currentEntitlements {
            if case let .verified(transaction) = result {
                purchased.append(transaction.productID)
                
                await transaction.finish()
                
                return true
            }
        }
        
        return false
    }
    
    func listenForTransactions() -> Task<Void, Error> {
            return Task.detached {
                for await result in Transaction.updates {
                    if case let .verified(transaction) = result {
                        self.purchased.append(transaction.productID)
                        await transaction.finish()
                    }
                }
            }
        }
    
    func purchase() async -> Bool {
        guard let product = products.first else { return false }
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verify):
                switch verify {
                case .verified(let transaction):
                    
                    purchased.append(transaction.productID)
                    
                    await transaction.finish()
                    
                    return true
                case .unverified:
                    break
                }
                
            case .userCancelled:
                break
            case .pending:
                break
            @unknown default:
                break
            }
        } catch {
            print(error)
        }
        
        return false
    }
}
