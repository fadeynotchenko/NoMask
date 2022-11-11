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
    @StateObject private var memoryViewModel = MemoryViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(memoryViewModel)
                .environmentObject(loginViewModel)
                .environment(\.colorScheme, .dark)
                .preferredColorScheme(.dark)
                .onAppear(perform: UIApplication.shared.addTapGestureRecognizer)
        }
    }
    
    init() {
        FirebaseApp.configure()
        
        do {
            try Auth.auth().useUserAccessGroup(Secrets.AccessGroup)
        } catch {
            print(error.localizedDescription)
        }
    }
}
