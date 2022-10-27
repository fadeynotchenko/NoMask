//
//  ProVersionView.swift
//  Memories
//
//  Created by Fadey Notchenko on 16.10.2022.
//

import SwiftUI
import AlertToast
import RevenueCat

struct ProVersionView: View {
    @State private var restored = false
    @State private var error = false
    
    @State private var offering: Offering?
    
    @EnvironmentObject private var memoryViewModel: MemoryViewModel
    @EnvironmentObject private var storeViewModel: StoreViewModel
    
    var body: some View {
        GeometryReader { reader in
            VStack(spacing: 15) {
                if offering != nil {
                    Header(text: "Memories Pro") {
                        ImageButton(systemName: "xmark", color: .white) {
                            memoryViewModel.showProVersionView = false
                        }
                    }
                    
                    proTitle
                    
                    benefit(text: "protext1", secondText: "second1")
                    
                    benefit(text: "protext2", secondText: "second2")
                    
                    Spacer()
                    
                    buyButton
                    
                    restoreButton
                } else {
                    Spacer()
                    
                    ProgressView()
                        .shadow(radius: 3)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    Spacer()
                }
            }
            .toast(isPresenting: $error) {
                AlertToast(displayMode: .banner(.pop), type: .error(.red), title: Constants.language == "ru" ? "Ошибка" : "Error")
            }
            .toast(isPresenting: $restored) {
                AlertToast(displayMode: .banner(.pop), type: .complete(.green), title: Constants.language == "ru" ? "Покупки восстановлены" : "Purchases restored")
            }
            .onAppear {
                Purchases.shared.getOfferings { offerings, error in
                    if let offer = offerings?.current, error == nil {
                        self.offering = offer
                    }
                }
            }
        }
    }
    
    private var proTitle: some View {
        Text("protitle")
            .foregroundColor(.white)
            .bold()
            .font(.title3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .multilineTextAlignment(.leading)
            .padding()
    }
    
    private func benefit(text: LocalizedStringKey, secondText: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(text)
                .foregroundColor(.gray)
                .bold()
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.ultraThickMaterial)
                .cornerRadius(15)
                .multilineTextAlignment(.leading)
            
            Text(secondText)
                .foregroundColor(.gray)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var buyButton: some View {
        if let offering = offering?.availablePackages.first {
            TextButton(text: storeViewModel.isSubscription ? "purchased" : "\(offering.storeProduct.localizedPriceString) / \(Constants.language == "ru" ? "Год" : "Year")", size: 330, color: .white) {
                Purchases.shared.purchase(package: offering) { transaction, info, error, called in
                    if info?.entitlements.all["pro"]?.isActive == true {
                        withAnimation {
                            storeViewModel.isSubscription = true
                        }
                    }
                }
            }
            .disabled(storeViewModel.isSubscription)
        }
    }
    
    private var restoreButton: some View {
        Button("restore") {
            Purchases.shared.restorePurchases { info, error in
                if info?.entitlements.all["pro"]?.isActive == true, error == nil {
                    withAnimation {
                        storeViewModel.isSubscription = true
                        restored = true
                    }
                } else {
                    self.error = true
                }
            }
        }
        .disabled(storeViewModel.isSubscription)
    }

}
