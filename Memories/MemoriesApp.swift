//
//  MemoriesApp.swift
//  Memories
//
//  Created by Fadey Notchenko on 03.10.2022.
//

import SwiftUI
import Firebase

@main
struct MemoriesApp: App {
    
    @StateObject private var loginViewModel = LoginViewModel()
    @StateObject private var viewModel = MemoryViewModel()
    @StateObject private var store = Store()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(loginViewModel)
                .environmentObject(viewModel)
                .environmentObject(store)
                .environment(\.colorScheme, .dark)
                .preferredColorScheme(.dark)
                .onAppear(perform: UIApplication.shared.addTapGestureRecognizer)
                .onAppear {
                    if viewModel.language == "ru" {
                        viewModel.singleQuote = ruQuotes.randomElement()
                    } else {
                        viewModel.singleQuote = engQuotes.randomElement()
                    }
                }
                .onOpenURL { url in
                    if url.absoluteString.count > "https://mymemoriesapp.com/".count {
                        withAnimation {
                            viewModel.showNewMemoryView = false
                            viewModel.showProVersionView = false
                            
                            viewModel.shareURL = url
                        }
                    }
                }
                .task {
                    await store.fetchProducts()
                }
        }
    }
    
    init() {
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
