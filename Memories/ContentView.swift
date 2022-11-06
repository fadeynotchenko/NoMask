//
//  ContentView.swift
//  Memories
//
//  Created by Fadey Notchenko on 03.10.2022.
//

import SwiftUI

struct ContentView: View {
    
    @AppStorage("isLoggin") private var isLoggin = false
    
    @EnvironmentObject private var memoryViewModel: MemoryViewModel
    
    var body: some View {
        if isLoggin {
            MemoriesView()
        } else if memoryViewModel.userIsBannded {
            BannedView()
        } else {
            LoginView()
        }
    }
    
    private struct BannedView: View {
        var body: some View {
            ZStack {
                Color("Background").edgesIgnoringSafeArea(.all)
                
                Text("Your account is banned")
                    .foregroundColor(.gray)
            }
        }
    }
}
