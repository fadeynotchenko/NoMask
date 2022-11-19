//
//  MemoriesApp.swift
//  Memories
//
//  Created by Fadey Notchenko on 03.10.2022.
//

import SwiftUI
import Firebase
import FirebaseCore
import AVFoundation

@main
struct MemoriesApp: App{
    
    @StateObject private var loginViewModel = LoginViewModel()
    @StateObject private var memoryViewModel = ViewModel()
    @StateObject private var cameraViewModel = CameraViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(memoryViewModel)
                .environmentObject(loginViewModel)
                .environmentObject(cameraViewModel)
                .environment(\.colorScheme, .dark)
                .preferredColorScheme(.dark)
                .onAppear(perform: UIApplication.shared.addTapGestureRecognizer)
                .onAppear {
                    memoryViewModel.fetchSelfData()
                    
                    memoryViewModel.fetchAdmins()
                    
                    cameraViewModel.preview = AVCaptureVideoPreviewLayer(session: cameraViewModel.session)
                }
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
