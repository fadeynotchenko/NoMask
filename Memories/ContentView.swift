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
//            TabView(selection: $memoryViewModel.memoryTabSelection) {
//                MyMemoriesView()
//                    .tag(0)
//
//                GlobalMemoriesView()
//                    .tag(1)
//            }
//            .tabViewStyle(.page(indexDisplayMode: .never))
//            .edgesIgnoringSafeArea(.all)
//            .onAppear {
//                memoryViewModel.fetch()
//            }
            
            MyMemoriesView()
        } else {
            LoginView()
        }
    }
}
