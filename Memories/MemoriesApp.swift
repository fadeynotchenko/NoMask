//
//  MemoriesApp.swift
//  Memories
//
//  Created by Fadey Notchenko on 03.10.2022.
//

import SwiftUI
import Firebase
import FirebaseCore

@main
struct MemoriesApp: App {
    
    @StateObject private var loginViewModel = LoginViewModel()
    @StateObject private var memoryViewModel = ViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(memoryViewModel)
                .environmentObject(loginViewModel)
                .environment(\.colorScheme, .dark)
                .preferredColorScheme(.dark)
                .onAppear(perform: UIApplication.shared.addTapGestureRecognizer)
                .onAppear {
                    memoryViewModel.fetchSelfData()
                    memoryViewModel.fetchAdmins()
                }
        }
    }
    
    init() {
        FirebaseApp.configure()
    }
}
