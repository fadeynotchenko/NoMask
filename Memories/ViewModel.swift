//
//  ViewModel.swift
//  Memories
//
//  Created by Fadey Notchenko on 04.10.2022.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseStorage

class ViewModel: ObservableObject {
    
    @Published var memories = [Memory]()
    
    @Published var detailMemory: Memory?
    @Published var showDetail = false
    @Published var imageID = 0
    @Published var video: URL?
    @Published var showVideoPlayer = false
    
    @Published var showFetchLoadingView = false
    @Published var memoriesIsEmpty = false
    
    @Published var animattion = false
    
    func fetchData() {
        memories.removeAll()
        
        guard let id = Auth.auth().currentUser?.uid else { return }
        
        print(id)
        
        let db = Firestore.firestore().collection(id)
        
        db.getDocuments { snapshots, error in
            if let snapshots = snapshots, error == nil {
                
                if !snapshots.documents.isEmpty {
                    self.showFetchLoadingView = true
                    self.memoriesIsEmpty = false
                } else {
                    self.memoriesIsEmpty = true
                }
                
                for document in snapshots.documents {
                    let data = document.data()
                    let id = document.documentID
                    
                    if let name = data["name"] as? String, let timestamp = data["date"] as? Timestamp {
                        
                        let date = timestamp.dateValue()
                        let text = data["text"] as? String
                        
                        //get images
                        db.document(id).collection("images").getDocuments { snapshots, error in
                            if let snapshots = snapshots, error == nil {
                                var images = [URL]()
                                
                                for document in snapshots.documents {
                                    let data = document.data()
                                    if let strurl = data["url"] as? String, let url = URL(string: strurl) {
                                        images.append(url)
                                    }
                                }
                                
                                db.document(id).collection("videos").getDocuments { snapshot, error in
                                    if let snapshot = snapshot, error == nil {
                                        
                                        var videos = [URL]()
                                        
                                        for document in snapshot.documents {
                                            let data = document.data()
                                            if let strurl = data["url"] as? String, let url = URL(string: strurl) {
                                                videos.append(url)
                                            }
                                        }
                                        
                                        self.memories.append(Memory(uuid: UUID(), id: id, name: name, date: date, text: text, images: images, videos: videos))
                                        self.showFetchLoadingView = false   
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

struct Memory: Identifiable {
    var uuid: UUID
    var id: String
    var name: String
    var date: Date
    var text: String?
    
    var images = [URL]()
    var videos = [URL]()
}
