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
import BottomSheet

struct GlobalMemoriesView: View {
    
    @EnvironmentObject private var memoryViewModel: ViewModel
    @EnvironmentObject private var cameraViewModel: CameraViewModel
    
    //views
    @State private var showBannedView = false
    @State private var showNewPostView = false
    @State private var showProfileView = false
    
    @State private var currentMemory: Post?
    
    //toasts
    @State private var reportSent = false
    
    //dialogs
    @State private var showReportDialog = false
    @State private var showDeleteDialog = false
    @State private var showBanUserDialog = false
    
    private var globalMemories: [Post] {
        let set = Set(memoryViewModel.ignorePosts)
        let set2 = Set(memoryViewModel.globalPosts)
        
        let arr = set2.filter { !set.contains($0.userID) }.sorted { $0.date > $1.date }
        
        return arr
    }
    
    var body: some View {
            ZStack {
                Color("Background").edgesIgnoringSafeArea(.all)
                
                if memoryViewModel.loadGlobalMemoriesStatus == .start {
                    ProgressView()
                        .shadow(radius: 3)
                }
                
                global
            }
            .accentColor(.white)
            .overlay(alignment: .top) {
                ZStack(alignment: .top) {
                    LinearGradient(colors: [.clear, .black.opacity(0.8)], startPoint: .bottom, endPoint: .top)
                        .edgesIgnoringSafeArea(.all)
                    
                    header
                }
                .frame(height: 100)
            }
            .fullScreenCover(isPresented: $memoryViewModel.userIsBannded) {
                BannedView()
            }
            .bottomSheet(isPresented: $showProfileView, detents: [.large()]) {
                ProfileView()
                    .environmentObject(memoryViewModel)
            }
            .bottomSheet(isPresented: $showNewPostView, detents: [.large()]) {
                NewPostView()
                    .environmentObject(memoryViewModel)
                    .environmentObject(cameraViewModel)
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
                            memoryViewModel.globalPosts = memoryViewModel.globalPosts.filter { $0.memoryID != currentMemory.memoryID }
                        }
                    }
                } label: {
                    Text("delete")
                }
            } message: {
                Text("delete_post_dialog")
            }
            .confirmationDialog("", isPresented: $showBanUserDialog) {
                Button(role: .destructive) {
                    banUser()
                } label: {
                    Text("ban_yes")
                }
            } message: {
                Text("ban_dialog")
            }
    }
    
    @ViewBuilder
    private var global: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(globalMemories) { memory in
                    MemoryCardView(showReportDialog: $showReportDialog, showDeleteDialog: $showDeleteDialog, showBanUserDialog: $showBanUserDialog, currentMemory: $currentMemory, memory: memory, isPersonal: false)
                }
            }
            .offset(y: 70)
            .padding(.bottom, 70)
            
            if memoryViewModel.loadGlobalMemoriesStatus == .finish, let document = memoryViewModel.last, document.documentID != Constants.LAST_POST_ID {
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
                showNewPostView.toggle()
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
                showProfileView.toggle()
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
    
    private func banUser() {
        guard let id = Auth.auth().currentUser?.uid else { return }
        guard let currentMemory = currentMemory else { return }
        
        memoryViewModel.ignorePosts.append(currentMemory.userID)
        
        Firestore.firestore().collection("User Data").document(id).updateData(["ignore": memoryViewModel.ignorePosts])
    }
}

struct ViewOffsetKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue = CGFloat.zero
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}
