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
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(loginViewModel)
        }
    }
    
    init() {
        FirebaseApp.configure()
    }
}
