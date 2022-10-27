//
//  StoreViewModel.swift
//  Memories
//
//  Created by Fadey Notchenko on 23.10.2022.
//

import Foundation
import RevenueCat

class StoreViewModel: ObservableObject {
    
    @Published var isSubscription = false
    
    init() {
        Purchases.shared.getCustomerInfo { (info, error) in
            self.isSubscription = (info?.entitlements.all["pro"]?.isActive == true)
        }
    }
}
