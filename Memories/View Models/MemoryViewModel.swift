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
    
    //global data
    @Published var globalMemories = [Memory]()
    
    //admin
    @Published var admins = [String]()
    
    @Published var userNickname = "";
    @Published var userAvatar: URL?
    @Published var userIsBannded = false
    
    //load data status
    @Published var loadMyMemoriesStatus: LoadDataStatus = .start
    @Published var loadGlobalMemoriesStatus: LoadDataStatus = .start
    @Published var loadMemoryByIDStatus: LoadDataStatus = .finish
    
    @Published var imageDownloaded = false
    
    @Published var limit = Constants.FETCH_LIMIT
    @Published var last: QueryDocumentSnapshot?
    
    func fetchGlobalMemories() {
        self.loadMyMemoriesStatus = .start
        
        Firestore.firestore().collection("Global Memories").order(by: "date", descending: true).limit(to: limit).getDocuments { snapshots, error in
            if let documents = snapshots?.documents, error == nil {
                self.globalMemories = documents.map { snapshot -> Memory in
                    let data = snapshot.data()
                    
                    let date = (data["date"] as! Timestamp).dateValue()
                    let images = (data["images"] as! [String]).map { URL(string: $0)! }
                    let userID = data["userID"] as! String
                    let descText = data["desc"] as? String
                    
                    return Memory(memoryID: snapshot.documentID, userID: userID, descText: descText, date: date, images: images)
                }
                
                if let last = documents.last {
                    self.last = last
                }
                
                self.loadMyMemoriesStatus = .finish
            }
        }
    }
    
    func fetchGlobalMemoriesByLast() {
        if let last = last {
            Firestore.firestore().collection("Global Memories").order(by: "date", descending: true).limit(to: limit).start(atDocument: last).getDocuments { snapshots, error in
                if let documents = snapshots?.documents, error == nil {
                    let arr = documents.map { snapshot -> Memory in
                        let data = snapshot.data()
                        
                        let date = (data["date"] as! Timestamp).dateValue()
                        let images = (data["images"] as! [String]).map { URL(string: $0)! }
                        let userID = data["userID"] as! String
                        let descText = data["desc"] as? String
                        
                        return Memory(memoryID: snapshot.documentID, userID: userID, descText: descText, date: date, images: images)
                    }
                    
                    self.globalMemories.removeLast()
                    self.globalMemories.append(contentsOf: arr)
                    
                    if let last = documents.last {
                        self.last = last
                    }
                }
            }
        }
    }
    
    func fetchUserData(userID: String, _ completion: @escaping (URL?, String) -> ()) {
        Firestore.firestore().collection("User Data").document(userID).getDocument { snapshot, error in
            if let userData = snapshot?.data(), error == nil {
                let userImage = URL(string: (userData["image"] as? String ?? ""))
                let userNickname = userData["nickname"] as! String
                
                completion(userImage, userNickname)
            }
        }
    }
    
    func fetchSelfData() {
        guard let id = Auth.auth().currentUser?.uid else { return }
        
        Firestore.firestore().collection("User Data").document(id).addSnapshotListener { snapshot, error in
            if let data = snapshot?.data(), error == nil {
                self.userNickname = data["nickname"] as? String ?? ""
                
                self.userIsBannded = data["banned"] as? Bool ?? false
                
                if let url = data["image"] as? String, let userAvatar = URL(string: url) {
                    self.userAvatar = userAvatar
                }
            }
        }
    }
    
    func fetchAdmins() {
        Firestore.firestore().collection("Admins").document("ID").getDocument { snapshot, error in
            if let data = snapshot?.data(), error == nil {
                self.admins = data["admins"] as? [String] ?? []
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
    
     func uploadImage(image: UIImage, _ comletion: @escaping (String?) -> Void) {
        guard let id = Auth.auth().currentUser?.uid else { return }
        
        let storage = Storage.storage().reference().child(id).child("images").child("\(UUID().uuidString).jpg")
        var data: Data?
        
        data = image.jpegData(compressionQuality: 0.7)
        
        if let data = data {
            let _ = storage.putData(data) { _, error in
                if error != nil {
                    comletion(nil)
                }
                
                storage.downloadURL { url, error in
                    if error != nil {
                        comletion(nil)
                    }
                    
                    if let url = url {
                        comletion(url.absoluteString)
                    }
                }
            }
        }
    }
}
