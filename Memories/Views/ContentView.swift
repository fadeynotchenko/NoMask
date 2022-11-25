//
//  ContentView.swift
//  Memories
//
//  Created by Fadey Notchenko on 03.10.2022.
//

import SwiftUI

struct ContentView: View {
    
    @AppStorage("LOGIN") private var LOGIN = false
    @AppStorage("EDIT_PROFILE") private var EDIT_PROFILE = false
    
    @EnvironmentObject private var memoryViewModel: ViewModel
    
    var body: some View {
        if LOGIN && EDIT_PROFILE == false {
            EditProfileView(isEntry: true)
        } else if LOGIN && EDIT_PROFILE {
            GlobalMemoriesView()
        } else {
            LoginView()
        }
    }
}
