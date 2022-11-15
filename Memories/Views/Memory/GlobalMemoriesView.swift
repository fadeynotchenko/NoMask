//
//  MemoryListView.swift
//  Memories
//
//  Created by Fadey Notchenko on 03.10.2022.
//

import SwiftUI
import CachedAsyncImage
import Firebase
import FirebaseStorage
import AlertToast
import FirebaseFirestore
import FirebaseAuth
import WidgetKit

struct GlobalMemoriesView: View {
    
    @State private var searchText = ""
    
    @EnvironmentObject private var memoryViewModel: MemoryViewModel
    
    //views
    @State private var showNewMemoryView = false
    @State private var showProfileView = false
    @State private var showBannedView = false
    @State private var showNickNameView = false
    
    @State private var currentMemory: Memory?
    
    //toasts
    @State private var reportSent = false
    
    //dialogs
    @State private var showReportDialog = false
    @State private var showDeleteDialog = false
    
    @State private var position: CGFloat = 0
    
    private var globalMemories: [Memory] {
        let set = Set(memoryViewModel.ignorePosts)
        let set2 = Set(memoryViewModel.globalMemories)
        
        let arr = set2.filter { !set.contains($0.userID) }.sorted { $0.date > $1.date }
        
        return arr
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("Background").edgesIgnoringSafeArea(.all)
                
                if memoryViewModel.loadGlobalMemoriesStatus == .start {
                    ProgressView()
                        .shadow(radius: 3)
                }
                
                global
            }
            .overlay(alignment: .top) {
                header
            }
            .fullScreenCover(isPresented: $showNewMemoryView) {
                NewMemoryView(dismiss: $showNewMemoryView)
            }
            .fullScreenCover(isPresented: $showProfileView) {
                ProfileView(dismiss: $showProfileView)
            }
            .fullScreenCover(isPresented: $memoryViewModel.userIsBannded) {
                BannedView()
            }
            .fullScreenCover(isPresented: $showNickNameView) {
                NicknameView(dismiss: $showNickNameView, showNewMemoryView: $showNewMemoryView)
            }
            .toast(isPresenting: $reportSent) {
                AlertToast(displayMode: .banner(.pop), type: .complete(.green), title: NSLocalizedString("reportSent", comment: ""))
            }
            .confirmationDialog("", isPresented: $showReportDialog) {
                Button(role: .destructive) {
                    sendReport()
                } label: {
                    Text("reportDialogButton")
                }
            } message: {
                Text("showReportDialog")
            }
            .confirmationDialog("", isPresented: $showDeleteDialog) {
                Button(role: .destructive) {
                    if let currentMemory = currentMemory {
                        Firestore.firestore().collection("Global Memories").document(currentMemory.memoryID).delete { _ in }
                        
                        withAnimation {
                            memoryViewModel.globalMemories = memoryViewModel.globalMemories.filter { $0.memoryID != currentMemory.memoryID }
                        }
                    }
                } label: {
                    Text("delete")
                }
            } message: {
                Text("delete_dialog")
            }
            .onAppear {
                memoryViewModel.fetchSelfData()
                
                memoryViewModel.fetchAdmins()
            }
        }
    }
    
    @ViewBuilder
    private var global: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(globalMemories) { memory in
                    MemoryCardView(showReportDialog: $showReportDialog, showDeleteDialog: $showDeleteDialog, currentMemory: $currentMemory, memory: memory)
                }
            }
            .offset(y: 70)
            .padding(.bottom, 70)
            
            if memoryViewModel.loadGlobalMemoriesStatus == .finish {
                fetchNextButton
            }
        }
        .onAppear {
            memoryViewModel.fetchGlobalMemories()
        }
    }
    
    private var header: some View {
        HStack {
            ImageButton(systemName: "plus", color: .white) {
                if memoryViewModel.userNickname.isEmpty {
                    showNickNameView = true
                } else {
                    showNewMemoryView = true
                }
            }
            
            Spacer()
            
            VStack(spacing: 5) {
                Title(text: "No Mask")
                
                Text("global")
                    .foregroundColor(.gray)
                    .bold()
                    .font(.system(size: 13))
                    .shadow(radius: 3)
            }
            
            Spacer()
            
            ImageButton(systemName: "person.fill", color: .white) {
                showProfileView = true
            }
        }
        .frame(maxWidth: Constants.width - 20, alignment: .center)
        
    }
    
    private var fetchNextButton: some View {
        TextButton(text: "fetchnext", size: 330, color: .white) {
            memoryViewModel.fetchGlobalMemoriesByLast()
        }
    }
}

extension GlobalMemoriesView {
    private func sendReport() {
        if let currentMemory = currentMemory {
            Firestore.firestore().collection("Reports").document().setData(["id": currentMemory.memoryID])
            
            reportSent = true
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

struct ViewOffsetKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue = CGFloat.zero
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}
