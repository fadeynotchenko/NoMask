//
//  PersonalMemoriesView.swift
//  No Mask
//
//  Created by Fadey Notchenko on 14.11.2022.
//

import SwiftUI
import FirebaseFirestore

struct PersonalMemoriesView: View {
    
    @EnvironmentObject private var viewModel: ViewModel
    
    @State private var showDeleteDialog = false
    @State private var currentMemory: Post?
    
    var body: some View {
        ZStack {
            Color("Background").edgesIgnoringSafeArea(.all)
            
            if viewModel.loadMyMemoriesStatus == .start {
                ProgressView()
                    .shadow(radius: 3)
            }
            
            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach(viewModel.personalMemories) { memory in
                        MemoryCardView(showReportDialog: .constant(false), showDeleteDialog: $showDeleteDialog, showBanUserDialog: .constant(false), currentMemory: $currentMemory, memory: memory, isPersonal: true)
                    }
                }
            }
            .confirmationDialog("", isPresented: $showDeleteDialog) {
                Button(role: .destructive) {
                    if let currentMemory = currentMemory {
                        Firestore.firestore().collection("Global Memories").document(currentMemory.memoryID).delete { _ in }
                        
                        withAnimation {
                            viewModel.globalPosts = viewModel.globalPosts.filter { $0.memoryID != currentMemory.memoryID }
                        }
                    }
                } label: {
                    Text("delete")
                }
            } message: {
                Text("delete_post_dialog")
            }
            .onAppear {
                DispatchQueue.main.async {
                    viewModel.fetchPersonalMemories()
                }
            }
            .navigationTitle(Text("my"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
