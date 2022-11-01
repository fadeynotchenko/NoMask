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
            ZStack {
                Color("Background").edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 15) {
                    Group {
                        Header(text: "Memories Pro") {
                            ImageButton(systemName: "xmark", color: .white) {
                                memoryViewModel.showProVersionView = false
                            }
                        }
                        
                        if offering == nil {
                            Spacer()
                            
                            ProgressView()
                                .shadow(radius: 3)
                                .frame(maxWidth: .infinity, alignment: .center)
                            
                            Spacer()
                        } else {
                            
                            proTitle
                            
                            benefit(text: "protext1", secondText: "second1")
                            
                            benefit(text: "protext2", secondText: "second2")
                            
                            Spacer()
                            
                            buyButton
                            
                            restoreButton
                            
                            aboutText
                        }
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
    }
    
    private var proTitle: some View {
        Text("protitle")
            .foregroundColor(.white)
            .bold()
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
        .shadow(radius: 3)
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
            .padding(.top)
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
    
    private var aboutText: some View {
        VStack(alignment: .leading, spacing: 5) {
            Group {
                Text("pro1")
                
                HStack(spacing: 5) {
                    Link("terms", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                        .foregroundColor(.blue)
                    
                    Text("and")
                }
                
                Link("privacy", destination: URL(string: "https://mymemoriesapp.com/Privacy/Privacy.html")!)
                    .foregroundColor(.blue)
            }
            .font(.system(size: 16))
            .foregroundColor(.gray)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
    }
}
