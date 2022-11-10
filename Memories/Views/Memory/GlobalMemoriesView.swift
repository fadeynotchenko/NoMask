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
    @State private var imageDownloaded = false
    @State private var reportSent = false
    
    //dialogs
    @State private var showReportDialog = false
    
    @State private var position: CGFloat = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("Background").edgesIgnoringSafeArea(.all)
                
                if memoryViewModel.loadMyMemoriesStatus == .start {
                    ProgressView()
                        .shadow(radius: 3)
                }
                
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(0..<memoryViewModel.globalMemories.count, id: \.self) { i in
                            let memory = memoryViewModel.globalMemories[i]
                            
                            MemoryCardView(imageDownloaded: $imageDownloaded, showReportDialog: $showReportDialog, currentMemory: $currentMemory, memory: memory)
                                .onAppear {
                                    //for infinity scroll
                                    if i == memoryViewModel.globalMemories.count - 1 {
                                        memoryViewModel.limit += Constants.fetchLimit
                                        
                                        memoryViewModel.fetchGlobalMemories()
                                    }
                                }
                        }
                    }
                    .offset(y: 70)
                    .padding(.bottom, 70)
                    .background(GeometryReader {
                        Color.clear.preference(key: ViewOffsetKey.self, value: -$0.frame(in: .named("scroll")).origin.y)
                    })
//                    .onPreferenceChange(ViewOffsetKey.self) {
//                        position = $0
//                    }
                }
                .coordinateSpace(name: "scroll")
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
            .overlay {
                if memoryViewModel.loadMemoryByIDStatus == .start {
                    ProgressView()
                        .frame(width: 50, height: 50)
                        .background(.ultraThickMaterial)
                        .cornerRadius(15)
                        .shadow(radius: 3)
                }
            }
            .toast(isPresenting: $imageDownloaded) {
                AlertToast(displayMode: .banner(.pop), type: .complete(.green), title: NSLocalizedString("imageDownloaded", comment: ""))
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
            .onAppear {
                memoryViewModel.fetchGlobalMemories()
                
                memoryViewModel.fetchSelfData()
                
                memoryViewModel.fetchAdmins()
            }
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
//            .opacity(position <= 0 ? (Double(abs(position) / 100) < 0 ? Double(abs(position) / 100) : 0) : 1)
            
            Spacer()
            
            ImageButton(systemName: "person.fill", color: .white) {
                showProfileView = true
//                memoryViewModel.limit = 10
//                memoryViewModel.fetchGlobalMemories()
            }
        }
        .frame(maxWidth: Constants.width - 20, alignment: .center)
        
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
