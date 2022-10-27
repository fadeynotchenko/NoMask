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
    @StateObject private var viewModel = MemoryViewModel()
    @StateObject private var storeViewModel = StoreViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(loginViewModel)
                .environmentObject(viewModel)
                .environmentObject(storeViewModel)
                .environment(\.colorScheme, .dark)
                .preferredColorScheme(.dark)
                .onAppear(perform: UIApplication.shared.addTapGestureRecognizer)
                .onOpenURL { url in
                    if url.absoluteString.count > "https://mymemoriesapp.com/".count {
                        viewModel.shareURL = url
                    }
                }
        }
    }
    
    init() {
        Purchases.logLevel = .error
        Purchases.configure(withAPIKey: "")
        
        FirebaseApp.configure()
        
        do {
            try Auth.auth().useUserAccessGroup("CQ3SGH4DSY.FN.Memories")
        } catch {
            print(error.localizedDescription)
        }
    }
}

extension UIApplication {
    func addTapGestureRecognizer() {
        guard let window = windows.first else { return }
        let tapGesture = UITapGestureRecognizer(target: window, action: #selector(UIView.endEditing))
        tapGesture.requiresExclusiveTouchType = false
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = self
        window.addGestureRecognizer(tapGesture)
    }
}

extension UIApplication: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
