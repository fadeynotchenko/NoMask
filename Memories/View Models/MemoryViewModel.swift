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
    
    @Published var memories = [Memory]()
    
    @Published var loadStatus: LoadDataStatus = .start
    @Published var loadMemoryByIDStatus: LoadDataStatus = .finish
    
    @Published var detailMemory: Memory?
    @Published var showDetail = false
    @Published var animation = false
    @Published var imageID = 0
    
    @Published var shareURL: URL?
    
    @Published var showNewMemoryView = false
    @Published var showProVersionView = false
    @Published var showPhotoGalleryView = false
    
    @Published var singleQuote: Quote?
    
    func fetchAllMemories() {
        guard let id = Auth.auth().currentUser?.uid else { return }
        
        self.loadStatus = .start
        
        Firestore.firestore().collection(id).addSnapshotListener { snapshots, error in
            if let documents = snapshots?.documents, error == nil {
                self.memories = documents.map { snapshot -> Memory in
                    let data = snapshot.data()
                    let name = data["name"] as! String
                    let date = (data["date"] as! Timestamp).dateValue()
                    let text = data["text"] as! String
                    let images = data["images"] as! [String]
                    
                    if let detailMemory = self.detailMemory, detailMemory.id == snapshot.documentID {
                        //update detail view
                        self.detailMemory = Memory(uuid: detailMemory.uuid, id: snapshot.documentID, name: name, date: date, text: text, images: images.map { URL(string: $0)! })
                    }
                    
                    return Memory(id: snapshot.documentID, name: name, date: date, text: text, images: images.map { URL(string: $0)! })
                }
                
                self.loadStatus = .finish
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
        
        Firestore.firestore().collection(id).document(documentID).getDocument { document, error in
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

extension String {
    func before(first delimiter: Character) -> String {
        if let index = firstIndex(of: delimiter) {
            let before = prefix(upTo: index)
            return String(before)
        }
        return ""
    }
    
    func after(first delimiter: Character) -> String {
        if let index = firstIndex(of: delimiter) {
            let after = suffix(from: index).dropFirst()
            return String(after)
        }
        return ""
    }
}
