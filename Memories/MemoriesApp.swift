//
//  MemoriesApp.swift
//  Memories
//
//  Created by Fadey Notchenko on 03.10.2022.
//

import SwiftUI
import Firebase
import RevenueCat

@main
struct MemoriesApp: App {
    
    @StateObject private var loginViewModel = LoginViewModel()
    @StateObject private var memoryViewModel = MemoryViewModel()
    @StateObject private var storeViewModel = StoreViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(loginViewModel)
                .environmentObject(memoryViewModel)
                .environmentObject(storeViewModel)
                .environment(\.colorScheme, .dark)
                .preferredColorScheme(.dark)
                .onAppear(perform: UIApplication.shared.addTapGestureRecognizer)
                .onOpenURL { url in
                    if url.absoluteString.count > "https://mymemoriesapp.com/".count {
                        memoryViewModel.shareURL = url
                    }
                }
        }
    }
    
    init() {
        Purchases.logLevel = .error
        Purchases.configure(withAPIKey: Secrets.API)
        
        FirebaseApp.configure()
        
        do {
            try Auth.auth().useUserAccessGroup(Secrets.AccessGroup)
        } catch {
            print(error.localizedDescription)
        }
    }
}
