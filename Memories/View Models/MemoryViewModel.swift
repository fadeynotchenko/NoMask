//
//  ViewModel.swift
//  Memories
//
//  Created by Fadey Notchenko on 04.10.2022.
//

import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseFirestore
import FirebaseAuth
import AVKit

class MemoryViewModel: ObservableObject {
    
    //self data
    @Published var memories = [Memory]()
    @Published var userName = "";
    
    //
    @Published var globalMemories = [GlobalMemory]()
    
    //load data status
    @Published var loadMyMemoriesStatus: LoadDataStatus = .start
    @Published var loadGlobalMemoriesStatus: LoadDataStatus = .start
    @Published var loadMemoryByIDStatus: LoadDataStatus = .finish
    
    //detail memory
    @Published var detailMemory: Memory?
    @Published var showDetail = false
    @Published var animation = false
    @Published var imageID = 0
    
    @Published var shareURL: URL?
    
    //views
    @Published var showNewMemoryView = false
    @Published var showProVersionView = false
    @Published var showPhotoGalleryView = false
    @Published var showProfileView = false
    @Published var showPickerView = false
    
    @Published var imageDownloaded = false
    
    @Published var singleQuote: Quote?
    
    @Published var memoryTabSelection = 0
    
    func fetchMyMemories() {
        guard let id = Auth.auth().currentUser?.uid else { return }
        
        self.loadMyMemoriesStatus = .start
        
        //listening self memories
        Firestore.firestore().collection("Self Memories").document(id).collection("Memories").addSnapshotListener { snapshots, error in
            withAnimation {
                if let documents = snapshots?.documents, error == nil {
                    self.memories = documents.filter { $0.documentID != "User Data" }.map { snapshot -> Memory in
                        let data = snapshot.data()
                        let name = data["name"] as! String
                        let date = (data["date"] as! Timestamp).dateValue()
                        let text = data["text"] as! String
                        let images = data["images"] as! [String]
                        
                        if let detailMemory = self.detailMemory, detailMemory.id == snapshot.documentID {
                            //update detail view
                            self.detailMemory = Memory(uuid: detailMemory.uuid, id: snapshot.documentID, name: name, date: date, text: text, images: images.map { URL(string: $0)! })
                        }
                        
                        return Memory(id: snapshot.documentID, name: name, date: date, text: text, images: images.compactMap { URL(string: $0) })
                    }
                    
                    self.loadMyMemoriesStatus = .finish
                }
            }
        }
        
        Firestore.firestore().collection("User Data").document(id).addSnapshotListener { snapshot, error in
            if let data = snapshot?.data(), error == nil {
                self.userName = data["name"] as! String
            }
        }
    }
    
    func fetchMemoryByLink(_ url: String, _ completion: @escaping (Memory?) -> Void) {
        withAnimation {
            self.loadMemoryByIDStatus = .start
        }
        
        let sub1 = url.after(first: "=")
        let id = sub1.before(first: "/")
        let documentID = sub1.after(first: "=")
        
        Firestore.firestore().collection("Self Memories").document(id).collection("Memories").document(documentID).getDocument { document, error in
            if let document = document, error == nil, let data = document.data(), let name = data["name"] as? String, let timestamp = data["date"] as? Timestamp, let images = data["images"] as? [String] {
                
                let date = timestamp.dateValue()
                let text = data["text"] as? String
                
                completion(Memory(id: document.documentID, name: name, date: date, text: text ?? "", images: images.map { URL(string: $0)! }))
                
            } else {
                completion(nil)
            }
        }
    }
    
    func downloadImage(_ url: URL, _ completion: @escaping (Bool) -> Void) {
        Storage.storage().reference(forURL: url.absoluteString).getData(maxSize: 10 * 1024 * 1024) { data, err in
            if let data = data, let image = UIImage(data: data), err == nil {
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                
                completion(true)
            } else {
                completion(false)
            }
        }
    }
}
