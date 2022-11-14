//
//  PersonalMemoriesView.swift
//  No Mask
//
//  Created by Fadey Notchenko on 14.11.2022.
//

import SwiftUI

struct PersonalMemoriesView: View {
    
    @EnvironmentObject private var memoryViewModel: MemoryViewModel
    
    var body: some View {
        ZStack {
            Color("Background").edgesIgnoringSafeArea(.all)
            
            if memoryViewModel.loadMyMemoriesStatus == .start {
                ProgressView()
                    .shadow(radius: 3)
            } else if memoryViewModel.personalMemories.isEmpty {
                Text("empry")
                    .foregroundColor(.gray)
            }
            
            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach(memoryViewModel.personalMemories) { memory in
                        MemoryCardView(showReportDialog: .constant(false), currentMemory: .constant(nil), memory: memory)
                    }
                }
                .padding(.bottom, 70)
            }
            .onAppear {
                memoryViewModel.fetchPersonalMemories()
            }
            .navigationTitle(Text("my"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
