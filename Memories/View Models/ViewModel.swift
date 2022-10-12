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
    
    @Published var loadStatus: LoadDataStatus = .start
    @Published var loadMemoryByIDStatus: LoadDataStatus = .finish
    
    @Published var detailMemory: Memory?
    @Published var showDetail = false
    @Published var imageID = 0
    @Published var animattion = false
    
    @Published var shareURL: URL?
    
    func fetchAllMemories() {
        memories.removeAll()
        
        guard let id = Auth.auth().currentUser?.uid else { return }
        
        print(id)
        
        let db = Firestore.firestore().collection(id)
        
        db.getDocuments { snapshots, error in
            if let snapshots = snapshots, error == nil {
                
                if snapshots.documents.isEmpty {
                    self.loadStatus = .empty
                }
                
                for document in snapshots.documents {
                    let data = document.data()
                    let id = document.documentID
                    
                    if let name = data["name"] as? String, let timestamp = data["date"] as? Timestamp, let images = data["images"] as? [String] {
                        
                        let date = timestamp.dateValue()
                        let text = data["text"] as? String
                        
                        DispatchQueue.main.async {
                            self.memories.append(Memory(id: id, name: name, date: date, text: text, images: images.map { URL(string: $0) } ))
                            
                            self.loadStatus = .finish
                        }
                    }
                }
            }
        }
    }
    
    func fetchMemoryByLink(userID: String, memoryID: String, _ completion: @escaping (Memory?) -> Void) {
        Firestore.firestore().collection(userID).document(memoryID).getDocument { document, error in
            if let document = document, error == nil, let data = document.data(), let name = data["name"] as? String, let timestamp = data["date"] as? Timestamp, let images = data["images"] as? [String] {
                
                let date = timestamp.dateValue()
                let text = data["text"] as? String
                
                
                completion(Memory(id: memoryID, name: name, date: date, text: text, images: images.map { URL(string: $0) }))
            } else {
                completion(nil)
            }
        }
    }
}

struct Memory: Identifiable {
    var uuid = UUID()
    var id: String
    var name: String
    var date: Date
    var text: String?
    
    var images = [URL?]()
}

enum LoadDataStatus: Hashable {
    case start
    case finish
    case empty
}
