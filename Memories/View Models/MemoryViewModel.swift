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
    @Published var userIsBannded = false
    
    //load data status
    @Published var loadMyMemoriesStatus: LoadDataStatus = .start
    @Published var loadGlobalMemoriesStatus: LoadDataStatus = .start
    @Published var loadMemoryByIDStatus: LoadDataStatus = .finish
    
    //detail memory
    
    @Published var shareURL: URL?
    
    //views
    @Published var showNewMemoryView = false
    @Published var showProfileView = false
    
    @Published var imageDownloaded = false
    
    func fetchMyMemories() {
        guard let id = Auth.auth().currentUser?.uid else { return }
        
        self.loadMyMemoriesStatus = .start
        self.memories.removeAll()
        
        //listening self memories
        Firestore.firestore().collection("Global Memories").getDocuments { snapshots, error in
            if let documents = snapshots?.documents, error == nil {
                self.memories = documents.map { snapshot -> Memory in
                    let data = snapshot.data()
                    
                    let date = (data["date"] as! Timestamp).dateValue()
                    let images = (data["images"] as! [String]).map { URL(string: $0)! }
                    let userName = data["userName"] as! String
                    let userID = data["userID"] as! String
                    let userImage = URL(string: (data["userImage"] as? String ?? ""))
                    
                    return Memory(userID: userID, userName: userName, userImage: userImage, date: date, images: images)
                }
                
                self.loadMyMemoriesStatus = .finish
            }
        }
        
        Firestore.firestore().collection("User Data").document(id).addSnapshotListener { snapshot, error in
            if let data = snapshot?.data(), error == nil {
                if let name = data["name"] as? String {
                    self.userName = name
                }
                
                if let userIsBanned = data["banned"] as? Bool {
                    self.userIsBannded = userIsBanned
                } else {
                    self.userIsBannded = false
                }
            }
        }
    }
    
//    func fetchMemoryByLink(_ url: String, _ completion: @escaping (Memory?) -> ()) {
//        withAnimation {
//            self.loadMemoryByIDStatus = .start
//        }
//        
//        let sub1 = url.after(first: "=")
//        let id = sub1.before(first: "/")
//        let documentID = sub1.after(first: "=")
//        
//        Firestore.firestore().collection("Self Memories").document(id).collection("Memories").document(documentID).getDocument { document, error in
//            if let document = document, error == nil, let data = document.data(), let name = data["name"] as? String, let timestamp = data["date"] as? Timestamp, let images = data["images"] as? [String] {
//                
//                let date = timestamp.dateValue()
//                let text = data["text"] as? String
//                
//                completion(Memory(id: document.documentID, name: name, date: date, text: text ?? "", userID: id, images: images.map { URL(string: $0)! }))
//                
//            } else {
//                completion(nil)
//            }
//        }
//    }
    
    func saveImageToGallery(_ url: URL, _ completion: @escaping (Bool) -> ()) {
        Storage.storage().reference(forURL: url.absoluteString).getData(maxSize: 10 * 1024 * 1024) { data, err in
            if let data = data, let image = UIImage(data: data), err == nil {
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
//    func fetch() {
//        let id = "cvENN1aPJ1dotPCKZf9DElBu4EK2"
//        Firestore.firestore().collection(id).getDocuments { snap, _ in
//            if let documents = snap?.documents {
//                for document in documents {
//                    let data = document.data()
//                    if let name = data["name"] as? String, let timestamp = data["date"] as? Timestamp, let images = data["images"] as? [String] {
//                        let text = data["text"] as? String
//                        Firestore.firestore().collection("Self Memories").document(id).collection("Memories").document().setData(["name": name, "date": timestamp.dateValue(), "images": images, "text": text])
//                    }
//
//                }
//            }
//        }
//    }
}
