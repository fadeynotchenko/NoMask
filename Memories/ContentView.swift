//
//  ContentView.swift
//  Memories
//
//  Created by Fadey Notchenko on 03.10.2022.
//

import SwiftUI

struct ContentView: View {
    
    @AppStorage("isLoggin") private var isLoggin = false
    @AppStorage("isProfile") private var isProfile = false
    
    @EnvironmentObject private var memoryViewModel: ViewModel
    
    var body: some View {
        if isLoggin && isProfile == false {
            EditProfileView(isEntry: true)
        } else if isLoggin && isProfile {
            GlobalMemoriesView()
        } else {
            LoginView()
        }
    }
}
