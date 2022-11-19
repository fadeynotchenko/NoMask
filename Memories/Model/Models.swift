//
//  Models.swift
//  Memories
//
//  Created by Fadey Notchenko on 18.10.2022.
//

import Foundation
import SwiftUI

struct Post: Hashable, Identifiable {
    var id = UUID()
    var memoryID: String
    var userID: String
    var userNickname: String?
    var userImage: URL?
    var descText: String?
    var date: Date
    var images: [URL]
}

enum LoadDataStatus: Hashable {
    case start
    case finish
    case empty
}

enum AvatarImageType {
    case url(_ url: URL)
    case image(_ uiimage: UIImage)
    case empty
}
