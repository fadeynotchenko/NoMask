//
//  Models.swift
//  Memories
//
//  Created by Fadey Notchenko on 18.10.2022.
//

import Foundation
import SwiftUI

struct Memory: Identifiable {
    var id = UUID()
    var userID: String
    var userName: String
    var userImage: URL?
    var date: Date
    var images: [URL]
}

struct GlobalMemory: Identifiable {
    var uuid = UUID()
    var id: String
    var name: String
    var date: Date
    var text: String
    
    var images = [URL]()
    
    var userName: String
    var likes: [String]
    var createdDate: Date
}

enum LoadDataStatus: Hashable {
    case start
    case finish
    case empty
}

enum ImageItemType {
    case image(image: UIImage)
    case url(url: URL)
}

struct WidgetMemory {
    var name: String
    var date: Date
    var image: Data
}

struct Quote {
    var text: String
    var author: String
}
